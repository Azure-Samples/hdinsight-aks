package contoso.example;

import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.functions.FilterFunction;
import org.apache.flink.api.common.functions.MapFunction;
import org.apache.flink.api.common.serialization.SimpleStringEncoder;
import org.apache.flink.configuration.MemorySize;
import org.apache.flink.connector.file.sink.FileSink;
import org.apache.flink.connector.file.src.FileSource;
import org.apache.flink.core.fs.Path;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.sink.filesystem.rollingpolicies.DefaultRollingPolicy;
import org.apache.http.HttpEntity;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.ContentType;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.time.Duration;
import java.util.Base64;


public class ImageClassificationDemo {
    public static void main(String[] args) throws Exception {
        // 0. Set up the execution environment for the Flink streaming job
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment().setParallelism(8);

        // Checkpointing is enabled with an interval of 5000 milliseconds, and the checkpoint storage path is set to a location in ADLS Gen2
        env.enableCheckpointing(5000);
        String checkPointPath = "abfs://flink@cicihilogen2.dfs.core.windows.net/CheckPoint";
        env.getCheckpointConfig().setCheckpointStorage(checkPointPath);
        String path = "abfs://<container>@<account>.dfs.core.windows.net/data/dataset/multilabelFridgeObjects/Images/";

        // A FileSource is created to read image data from a specified path in ADLS Gen2. The source monitors the directory continuously every 180 seconds
        FileSource<ImageDataWithPath> fileSource = FileSource
                .forBulkFileFormat(new ImageStreamFormat(), new Path(path))
                .monitorContinuously(Duration.ofSeconds(180))
                .build();

        // Create a DataStream from the FileSource
        DataStream<ImageDataWithPath> images = env.fromSource(
                fileSource,
                WatermarkStrategy.noWatermarks(),
                "AzureADLSGen2FileSource"
        );

        // Each ImageDataWithPath object in the stream is processed by a map function, which calls an Azure ML service to classify the image
        DataStream<String> resultStream = images.map(new MapFunction<ImageDataWithPath, String>() {
            @Override
            public String map(ImageDataWithPath imageDataWithPath) throws Exception {
                String result;
                JSONObject resultJson = null;
                JSONArray resultArray = null;
                do {
                    result = callAzureML(imageDataWithPath.imageData);
                    result = result != null ? result.trim() : null; // Trim the result
                    if (result != null) {
                        if (result.startsWith("{")) { // Check if it's a JSONObject
                            resultJson = new JSONObject(result);
                        } else if (result.startsWith("[")) { // Check if it's a JSONArray
                            resultArray = new JSONArray(result);
                            if (resultArray.length() > 0) {
                                resultJson = resultArray.getJSONObject(0);
                            }
                        } else {
                            throw new JSONException("Invalid JSON: " + result);
                        }
                    }
                } while (resultJson != null && resultJson.has("error"));

                return "Path: " + imageDataWithPath.path + ", Classification: " + result;
            }
        }).filter(new FilterFunction<String>() { // Add a filter to remove nulls
            @Override
            public boolean filter(String value) throws Exception {
                return value != null && !value.contains("Classification: {}");   //A filter function is applied to remove any null values or classifications that resulted in an empty JSON object
            }
        });

        // 3.  The classified image data (as strings) are written to another location in ADLS Gen2 using a FileSink 
        // The sink rolls over files every 5 minutes or when the file size reaches 10 MiB.
        String outputPath = "abfs://<container>@<account>.dfs.core.windows.net/data/ImageClassificationJob/";

        final FileSink<String> sink = FileSink
                .forRowFormat(new Path(outputPath), new SimpleStringEncoder<String>("UTF-8"))
                .withRollingPolicy(
                        DefaultRollingPolicy.builder()
                                .withRolloverInterval(Duration.ofMinutes(5))
                                .withInactivityInterval(Duration.ofMinutes(5))
                                .withMaxPartSize(MemorySize.
                                        ofMebiBytes(10))
                                .build())
                .build();
        resultStream.sinkTo(sink);

        // 4. Start the Flink streaming job
        env.execute("Image Classification Job");
    }

    // sends an image to an Azure Machine Learning (ML) model for processing and returns the response from the model
    public static String callAzureML(byte[] imageBytes) {
        CloseableHttpClient httpClient = HttpClients.createDefault();
        JSONObject responseJson = new JSONObject(); // Initialize responseJson

        try {
            // Replace with your Azure ML service URL
            HttpPost httpPost = new HttpPost("https://<Azure ML service URL>");

            // Set the request body
            StringEntity requestEntity = new StringEntity(
                    new JSONObject()
                            .put("input_data", new JSONObject()
                                    .put("columns", new JSONArray().put("image"))
                                    .put("data", new JSONArray().put(new JSONArray().put(Base64.getEncoder().encodeToString(imageBytes))))
                            ).toString(),
                    ContentType.APPLICATION_JSON);

            httpPost.setEntity(requestEntity);

            // Set the API key header
            // Replace with your Azure ML service API key
            httpPost.setHeader("Authorization", "Bearer " + "<API key>");
            httpPost.setHeader("azureml-model-deployment", "model1-1");

            CloseableHttpResponse response = httpClient.execute(httpPost);

            try {
                HttpEntity responseEntity = response.getEntity();
                if (responseEntity != null) {
                    String responseString = EntityUtils.toString(responseEntity);
                    // Check if the classification was successful
                    try {
                        JSONArray jsonResponse = new JSONArray(responseString);
                        if (jsonResponse.length() > 0) {
                            JSONObject firstObject = jsonResponse.getJSONObject(0);
                            if (firstObject.has("error")) {
                                // If there's an "error" field in the response, assume the classification failed
                                responseJson.put("error", firstObject.getString("error"));
                            } else {
                                responseJson.put("result", firstObject);
                            }
                        }
                    } catch (JSONException e) {
                        responseJson.put("error", "Invalid JSON Response: " + e.getMessage());
                    }
                }
            } finally {
                response.close();
            }
        } catch (IOException e) {
            responseJson.put("error", e.getMessage());
        } finally {
            try {
                httpClient.close();
            } catch (IOException e) {
                // If there's already an error, append this one
                if (responseJson.has("error")) {
                    responseJson.put("error", responseJson.getString("error") + "; " + e.getMessage());
                } else {
                    responseJson.put("error", e.getMessage());
                }
            }
        }
        return responseJson.toString();
    }
}

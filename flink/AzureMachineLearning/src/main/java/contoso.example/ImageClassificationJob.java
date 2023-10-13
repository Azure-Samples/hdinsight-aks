package contoso.example;

import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.functions.MapFunction;
import org.apache.flink.api.common.serialization.SimpleStringEncoder;
import org.apache.flink.api.java.tuple.Tuple2;

import org.apache.flink.configuration.MemorySize;
import org.apache.flink.connector.file.sink.FileSink;
import org.apache.flink.core.fs.Path;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.sink.filesystem.rollingpolicies.DefaultRollingPolicy;
import org.apache.flink.streaming.api.windowing.assigners.TumblingEventTimeWindows;
import org.apache.flink.streaming.api.windowing.time.Time;
import org.apache.flink.streaming.api.windowing.windows.TimeWindow;
import org.apache.flink.streaming.api.functions.windowing.ProcessWindowFunction;
import org.apache.flink.util.Collector;
import org.apache.http.HttpEntity;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.ContentType;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.json.JSONArray;
import org.json.JSONObject;


import java.io.IOException;
import java.time.Duration;
import java.util.ArrayList;

import java.util.Base64;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;


public class ImageClassificationJob {

    public static void main(String[] args) throws Exception {
        // 0. Set up the execution environment for the Flink streaming job
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment().setParallelism(1);

        // add the custom source function
        DataStream<String> images = env.addSource(new ImageSourceFunction());

        // 1.2 Maps each image file path to a tuple containing the file path and the current system time
        DataStream<Tuple2<String, Long>> timestampedInput = images.map(new MapFunction<String, Tuple2<String, Long>>() {
            @Override
            public Tuple2<String, Long> map(String imageUrl) throws Exception {
                return Tuple2.of(imageUrl, System.currentTimeMillis());
            }
        });
        // 1.3 Assigns timestamps and watermarks to the data stream.
        // Watermarks are used by Flink to handle late data in event time windows.
        DataStream<Tuple2<String, Long>> withTimestampsAndWatermarks = timestampedInput.assignTimestampsAndWatermarks(
                WatermarkStrategy
                        .<Tuple2<String, Long>>forBoundedOutOfOrderness(Duration.ofSeconds(5))
                        .withTimestampAssigner((event, timestamp) -> event.f1)
        );

        // 2. Process image URL in 20-second windows
        // For each image file in the window, it calls the Azure ML service for image classification and collects the results.
        DataStream<String> resultStream = withTimestampsAndWatermarks.keyBy(x -> "dummy")
                .window(TumblingEventTimeWindows.of(Time.seconds(20)))
                .process(new ProcessWindowFunction<Tuple2<String, Long>, String, String, TimeWindow>() {
                    @Override
                    public void process(String key, Context context, Iterable<Tuple2<String, Long>> elements, Collector<String> out) throws Exception {
                        long count = 0;
                        List<String> results = new ArrayList<>();
                        for (Tuple2<String, Long> element : elements) {
                            // Initialize a variable to hold the aggregate result
                            // Call Azure ML service for image classification
                            String imageUrl = element.f0;
                            String result = callAzureML(imageUrl);
                            count++;
                            results.add("Image: " + imageUrl + ", Prediction: " + result);
                        }
                        out.collect("Window: " + context.window() + ", Image classification: " + results + ", Count: " + count);
                        System.out.println("Window: " + context.window() + ", Image classification: " + results + ", Count: " + count);
                    }
                    //  sends a POST request to the Azure ML service with the base64-encoded image data in the request body.
                    //  The response from the Azure ML service is printed to the console.
                    private String callAzureML(String imageUrl) throws IOException {
                        CloseableHttpClient httpClient = HttpClients.createDefault();

                        // Replace with your Azure ML service URL
                        HttpPost httpPost = new HttpPost("https://<Azure ML endpoint>.eastus2.inference.ml.azure.com/score");

                        // Set the request body
                        StringEntity requestEntity = new StringEntity(
                                new JSONObject()
                                        .put("input_data", new JSONObject()
                                                .put("columns", new JSONArray().put("image"))
                                                .put("data", new JSONArray().put(new JSONArray().put(Base64.getEncoder().encodeToString(readImage(imageUrl)))))
                                        ).toString(),
                                ContentType.APPLICATION_JSON);

                        httpPost.setEntity(requestEntity);

                        // Set the API key header
                        // Replace with your Azure ML service API key
                        httpPost.setHeader("Authorization", "Bearer " + "<Azure ML service API key>");
                        httpPost.setHeader("azureml-model-deployment", "model1-1");

                        CloseableHttpResponse response = httpClient.execute(httpPost);
                        String responseString = null; // Initialize responseString

                        try {
                            HttpEntity responseEntity = response.getEntity();
                            if (responseEntity != null) {
                                responseString = EntityUtils.toString(responseEntity);
                            }
                        } finally {
                            response.close();
                        }
                        return responseString;
                    }
                });

        // 3. sink to gen2
        String outputPath  = "abfs://<container>@<ADLS gen2 account>.dfs.core.windows.net/data/ImageClassificationJob/";
        final FileSink<String> sink = FileSink
                .forRowFormat(new Path(outputPath), new SimpleStringEncoder<String>("UTF-8"))
                .withRollingPolicy(
                        DefaultRollingPolicy.builder()
                                .withRolloverInterval(Duration.ofMinutes(2))
                                .withInactivityInterval(Duration.ofMinutes(3))
                                .withMaxPartSize(MemorySize.ofMebiBytes(5))
                                .build())
                .build();

        resultStream.sinkTo(sink);

        // 4. Start the Flink streaming job
        env.execute("Image Classification Job");
    }

    // reads an image file into a byte array,
    // which is used to base64-encode the image data before sending it to the Azure ML service.
    private static byte[] readImage(String path) throws IOException {
        return Files.readAllBytes(Paths.get(path));
    }
}




This example Java code is for Apache Flink Streaming job(DataStream API) that reads image files from a directory in ADLS gen2, sends them to an Azure Machine Learning (AML) service for image classification, and outputs the image classification result to a file in ADLS gen2.

Here’s a breakdown of what each part does!

Main code:
ImageClassificationDemo.java

**StreamExecutionEnvironment**: <br>
This is the context in which the program is executed. The environment provides methods to control the job execution (such as setting the parallelism) and to interact with the outside world (data access).

**set checkpoint**<br>
 Checkpointing is enabled with an interval of 5000 milliseconds, and the checkpoint storage path is set to a location in ADLS Gen2

```        env.enableCheckpointing(5000);
        String checkPointPath = "abfs://<container>@<account>.dfs.core.windows.net/CheckPoint";
        env.getCheckpointConfig().setCheckpointStorage(checkPointPath);
        String path = "abfs://<container>@<account>.dfs.core.windows.net/data/dataset/multilabelFridgeObjects/Images/";
```
**FileSource**<br>
A FileSource is created to read image data from a specified path in ADLS Gen2. The source monitors the directory continuously every 180 seconds
The monitorContinuously method in Apache Flink’s FileSource is used to put the source into continuous streaming mode.
In the context of below code, monitorContinuously(Duration.ofSeconds(180)) means that the source will periodically check the specified path for new files every 180 seconds and start reading those.
```
FileSource<ImageDataWithPath> fileSource = FileSource
                .forBulkFileFormat(new ImageStreamFormat(), new Path(path))
                .monitorContinuously(Duration.ofSeconds(180))
                .build();
```

**map function** <br>
Each ImageDataWithPath object in the stream is processed by a map function, which calls an Azure ML service to classify the image
```
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
```

**FileSink**: <br>
This is where the result of the image classification would be written to.
The classified image data (as strings) are written to another location in ADLS Gen2 using a FileSink, The sink rolls over files every 5 minutes or when the file size reaches 10 MiB.

```
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
```

**FileSink**: <br>
Start the Flink streaming job
```
env.execute("Image Classification Job");
```

**callAzureML**: <br>
It sends an image to an Azure Machine Learning (ML) model for processing and returns the response from the model
```
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
```

Please note that this code contains a hardcoded authorization token for the Azure ML service, which is generally not a good practice for security reasons.

## Requirements
### Azure Machine Learning
 In order to benefit from this tutorial, you will need:
• A basic understanding of Machine Learning
• An Azure account with an active subscription.
• An Azure ML workspace. 
• A Compute Cluster. 
• A python environment.

**Step1:** <br>
Open **Azure AI | Machine Learning Studio**, go to workspace | Nootbooks | Samples and clone below jobs folder into your own Files.
We will train a "the best" Image Classification Multi-Label model for a 'Fridge items' dataset.

```
Samples/SDK v2/sdk/python/jobs/automl-standalone-jobs/automl-image-classification-multilabel-task-fridge-items
```

![image](https://github.com/Baiys1234/hdinsight-aks-2/assets/35547706/a0edf9cf-3612-4be5-9c8b-8b1143b9f670  =200x)

The notebook in the sample explains how to setup and run an AutoML image classification-multilabel job and it goes over how you can use AutoML for training an Image Classification Multi-Label model. 

We use a toy dataset called Fridge Objects, which consists of 128 images of 4 labels of beverage container {can, carton, milk bottle, water bottle} photos taken on different backgrounds. It also includes a labels file in .csv format. This is one of the most common data formats for Image Classification Multi-Label: one csv file that contains the mapping of labels to a folder of images.

Datasets location:<br>
```
https://cvbp-secondary.z19.web.core.windows.net/datasets/image_classification/multilabelFridgeObjects.zip
```

**Step2:** <br>
Run below commands in the notebook:
```
Files/jobs/automl-standalone-jobs/automl-image-classification-multilabel-task-fridge-items/automl-image-classification-multilabel-task-fridge-items.ipynb**
```

1. Connect to Azure Machine Learning Workspace
2. MLTable with input Training Data
3. Compute target setup
4. Configure and run the AutoML for Images Classification-Multilabel training job
5. Retrieve the Best Trial (Best Model's trial/run)
6. Register best model and deploy
7. Get endpoint details

**Step3:** <br>
After Step2, you will get best Model and endpoint with registerred best model and deployment

best Model:<br>
![image](https://github.com/Baiys1234/hdinsight-aks-2/assets/35547706/641c69a7-4742-41b1-ad2f-c5fc57913461)

endpoint:<br>
![image](https://github.com/Baiys1234/hdinsight-aks-2/assets/35547706/14c535c6-9e9a-4cf0-af31-c58cddc22a94)

Azure ML service API key:<br>
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/91f664ba-157e-4466-a82e-a1324853c049)

### HDInsight Flink 1.16.0 on AKS

![image](https://github.com/Baiys1234/hdinsight-aks-2/assets/35547706/2110659a-440a-4800-819d-e5afe34d939d)

## Implemetation <br>
**upload source images file**: <br>
Data Source:<br>
https://cvbp-secondary.z19.web.core.windows.net/datasets/image_classification/multilabelFridgeObjects.zip into ADLS gen2,

we will use these images to try the predictions using above best model in Azure ML.

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/f4da644e-2c84-4a65-8c05-161cd9a9bebd)

**Develep on maven project, packag the jar and submit to HDInsight Flink cluster to run(Flink UI or Cluster webssh)** <br>
**Check the Stream JOB on Flink UI** <br>

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/a0013fed-3d05-4288-aec7-e789a7b9ef11)


**Check Image Prediction result file on ADLS gen2** <br>

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/b95c8f24-0317-4bdf-b660-d4f7f602a028)


```
Path: abfs://<container>@<account>.dfs.core.windows.net/data/dataset/multilabelFridgeObjects/Images/19.jpg, Classification: {"result":{"probs":[0.99552983045578,0.011675861664116383,0.05308690294623375,0.9984081387519836],"labels":["can","carton","milk_bottle","water_bottle"]}}

```

Above prediction result is given in a JSON format with two arrays: **`can` and `water_bottle`**. 

- The `labels` array represents the different classes that the model can predict. The classes are `"can"`, `"carton"`, `"milk_bottle"`, and `"water_bottle"`.

- The `probs` array represents the model's confidence (as a probability) that each corresponding class is present in the image. These probabilities range from 0 (class not present) to 1 (class definitely present).

Here's how to interpret the prediction:

- `"can"`: The model is **0.99%** confident that there's a can in the image.
- `"carton"`: The model is **0.01%** confident that there's a carton in the image.
- `"milk_bottle"`: The model is **0.05%** confident that there's a milk bottle in the image.
- `"water_bottle"`: The model is **0.99%** confident that there's a water bottle in the image.

According to this prediction, the model is highly confident that there's a can and a water bottle in the image, but it's not very confident about the presence of a carton or a milk bottle. 

**callAzureML(String imageUrl) in the ImageClassificationJob.java** <br>
This is a helper method that sends a POST request to an Azure ML service with base64-encoded image data in the request body. The response from the Azure ML service (which would be the classification result) is returned as a string.


After five images were processed then add more files into the input to do prediction

Input Source:<br>
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/9009bcc3-bb44-4778-a2f1-26609e683fcd)

Output Source:<br>

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/d31cc240-5b8d-42aa-b17c-7464962bbc9c)

```
Path: abfs://<container>@<account>.dfs.core.windows.net/data/dataset/multilabelFridgeObjects/Images/4.jpg, Classification: {"result":{"probs":[0.017827719449996948,0.05383646860718727,0.06719976663589478,0.9998056292533875],"labels":["can","carton","milk_bottle","water_bottle"]}}
```

## Clean up <br>
Donot forget to clean up the resources we created above.









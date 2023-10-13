This example Java code is for Apache Flink Streaming job(DataStream API) that reads image files from a directory in ADLS gen2, sends them to an Azure Machine Learning (AML) service for image classification, and outputs the image classification result to a file in ADLS gen2.

Here’s a breakdown of what each part does!

**StreamExecutionEnvironment**: This is the context in which the program is executed. The environment provides methods to control the job execution (such as setting the parallelism) and to interact with the outside world (data access).

**ImageSourceFunction**: This is a user-defined function that generates a stream of image URLs.

**MapFunction**: This function takes an image URL and returns a tuple containing the URL and the current timestamp.

**WatermarkStrategy**: This strategy deals with event time and watermarks, which are crucial for handling out-of-order events in stream processing.

**ProcessWindowFunction**: This function processes each window of image URLs. For each URL, it calls an Azure ML model to classify the image, and then collects the results.

**callAzureML**: This is a helper method that sends an HTTP POST request to an Azure ML model with the image data, and returns the model’s prediction.

**FileSink**: This is where the result of the image classification would be written to.

Please note that this code doesn’t handle any exceptions that might occur during file I/O or HTTP requests and it contains a hardcoded authorization token for the Azure ML service, which is generally not a good practice for security reasons.

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
![image](https://github.com/Baiys1234/hdinsight-aks-2/assets/35547706/607534ec-75f3-4dad-b5b3-d39d05fb5fd8)

### HDInsight Flink 1.16.0 on AKS

![image](https://github.com/Baiys1234/hdinsight-aks-2/assets/35547706/2110659a-440a-4800-819d-e5afe34d939d)

## Implemetation <br>
**upload source images file**: <br>
https://cvbp-secondary.z19.web.core.windows.net/datasets/image_classification/multilabelFridgeObjects.zip into ADLS gen2,
we will use these images to try the predictions using above best model in Azure ML.
![image](https://github.com/Baiys1234/hdinsight-aks-2/assets/35547706/38805770-88f0-48be-b5a2-a8160e830140)

**Develep on maven project, packag the jar and submit to HDInsight Flink cluster to run(Flink UI or Cluster webssh)** <br>
**Check the Stream JOB on Flink UI** <br>

![image](https://github.com/Baiys1234/hdinsight-aks-2/assets/35547706/2744345a-ccc1-44e5-b781-85a74a468330)

**Check Image Prediction result file on ADLS gen2** <br>

```
Window: TimeWindow{start=1697164140000, end=1697164160000}, Image classification: [Image: abfs://<container>@<ADLSgen2 account>.dfs.core.windows.net/data/dataset/multilabelFridgeObjects/Images/\1.jpg, Prediction: [{"probs": [0.04639384523034096, 0.9998229146003723, 0.013027748093008995, 0.0031216121278703213], "labels": ["can", "carton", "milk_bottle", "water_bottle"]}], ...... Image: abfs://<container>@<ADLSgen2 account>.dfs.core.windows.net/data/dataset/multilabelFridgeObjects/Images/\99.jpg, Prediction: [{"probs": [0.028434578329324722, 0.9936914443969727, 0.9988549947738647, 0.04662548005580902], "labels": ["can", "carton", "milk_bottle", "water_bottle"]}]], Count: 60
```

Take below for example,
```
 Image: abfs://<container>@<ADLSgen2 account>.dfs.core.windows.net/data/dataset/multilabelFridgeObjects/Images/\99.jpg, Prediction: [{"probs": [0.028434578329324722, 0.9936914443969727, 0.9988549947738647, 0.04662548005580902], "labels": ["can", "carton", "milk_bottle", "water_bottle"]}
```

Above prediction result is given in a JSON format with two arrays: **`probs` and `labels`**. 

- The `labels` array represents the different classes that the model can predict. The classes are `"can"`, `"carton"`, `"milk_bottle"`, and `"water_bottle"`.

- The `probs` array represents the model's confidence (as a probability) that each corresponding class is present in the image. These probabilities range from 0 (class not present) to 1 (class definitely present).

Here's how to interpret the prediction:

- `"can"`: The model is **2.84%** confident that there's a can in the image.
- `"carton"`: The model is **99.37%** confident that there's a carton in the image.
- `"milk_bottle"`: The model is **99.89%** confident that there's a milk bottle in the image.
- `"water_bottle"`: The model is **4.66%** confident that there's a water bottle in the image.

According to this prediction, the model is highly confident that there's a carton and a milk bottle in the image, but it's not very confident about the presence of a can or a water bottle. 
 
**ProcessWindowFunction in the ImageClassificationJob.java** <br>
The ProcessWindowFunction is a special type of window function in Apache Flink that provides more flexibility than other window functions like ReduceFunction or AggregateFunction. It gives you access to additional information such as the window and the timestamp of the elements.

In my code, for each element in the window, we're calling an Azure ML service to classify an image and then collecting the results. 
Once all elements have been processed, we’re emitting a string that contains the window information, image classification results, and count of images processed.

#Ref
https://nightlies.apache.org/flink/flink-docs-release-1.16/docs/dev/datastream/operators/windows/#processwindowfunction

**callAzureML(String imageUrl) in the ImageClassificationJob.java** <br>
This is a helper method that sends a POST request to an Azure ML service with base64-encoded image data in the request body. The response from the Azure ML service (which would be the classification result) is returned as a string.

## Clean up <br>
Donot forget to clean up the resources we created above.









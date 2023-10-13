This example Java code is for Apache Flink Streaming job(DataStream API) that reads image files from a directory in ADLS gen2, sends them to an Azure Machine Learning (AML) service for image classification, and outputs the image classification result to a file in ADLS gen2 . 
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
### Azure Machine Learning ###
 In order to benefit from this tutorial, you will need:
• A basic understanding of Machine Learning
• An Azure account with an active subscription.
• An Azure ML workspace. 
• A Compute Cluster. 
• A python environment.

**Steps:** <br>
**Step1:** <br>
Open Azure AI | Machine Learning Studio, go to workspace | Nootbooks | Samples and clone below jobs folder into your own Files.
We will use Train "the best" Image Classification Multi-Label model for a 'Fridge items' dataset.

Samples/SDK v2/sdk/python/jobs/automl-standalone-jobs/automl-image-classification-multilabel-task-fridge-items

![image](https://github.com/Baiys1234/hdinsight-aks-2/assets/35547706/a0edf9cf-3612-4be5-9c8b-8b1143b9f670)

The notebook in the sample explains how to setup and run an AutoML image classification-multilabel job and it goes over how you can use AutoML for training an Image Classification Multi-Label model. 

We use a toy dataset called Fridge Objects, which consists of 128 images of 4 labels of beverage container {can, carton, milk bottle, water bottle} photos taken on different backgrounds. It also includes a labels file in .csv format. This is one of the most common data formats for Image Classification Multi-Label: one csv file that contains the mapping of labels to a folder of images.

Datasets location:<br>
https://cvbp-secondary.z19.web.core.windows.net/datasets/image_classification/multilabelFridgeObjects.zip

**Step2:** <br>
Run below commands in the notebook:
**Files/jobs/automl-standalone-jobs/automl-image-classification-multilabel-task-fridge-items/automl-image-classification-multilabel-task-fridge-items.ipynb**

1. Connect to Azure Machine Learning Workspace
2. MLTable with input Training Data
3. Compute target setup
4. Configure and run the AutoML for Images Classification-Multilabel training job
5. Retrieve the Best Trial (Best Model's trial/run)
6. Register best model and deploy
7. Get endpoint details

**Step3:** <br>
After Step2, you will get best Model and endpoint with registerred best model and deployment

best Model:
(![image](https://github.com/Baiys1234/hdinsight-aks-2/assets/35547706/641c69a7-4742-41b1-ad2f-c5fc57913461) =500x)

model list:
![image](https://github.com/Baiys1234/hdinsight-aks-2/assets/35547706/ec77261f-9315-49d1-9ef0-bb559a1a09ee)

endpoint:
![image](https://github.com/Baiys1234/hdinsight-aks-2/assets/35547706/14c535c6-9e9a-4cf0-af31-c58cddc22a94)












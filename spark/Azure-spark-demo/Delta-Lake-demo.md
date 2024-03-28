# Run queries on Delta Lake  tables on Azure HDInsight on AKS
### A quick guide to set up and run a Delta Lake workload on a HDInsight on AKS Spark cluster


## Introduction
Delta Lake is an open-source storage layer that brings ACID transactions and schema enforcement to Apache Spark and big data workloads. It enables you to create, append, and upsert data into tables using standard SQL or DataFrame APIs. Delta Lake also supports streaming ingestion, batch and streaming queries, and data versioning.
Azure HDInsight is a fully managed cloud service that allows you to run Apache Spark clusters on Azure. You can use HDInsight on AKS to create a Spark cluster with Delta Lake enabled and run your Delta Lake workloads on it. In this document, we will show you how to do that in a few simple steps.


## Prerequisites
* 	An Azure subscription. If you don't have one, you can create a [free account](https://azure.microsoft.com/en-in/free/).
* 	An Azure Data Lake Store Gen2 account. This will be used to store your data and configuration files. Click [here](https://learn.microsoft.com/en-us/azure/storage/blobs/create-data-lake-storage-account) for more details.
* 	An Apache Spark 3.3 cluster in Azure HDInsight on AKS. For more details, click [here](https://learn.microsoft.com/en-us/azure/hdinsight-aks/quickstart-create-cluster).


## Step 1: Create a Spark cluster on Azure HDInsight on AKS
### Follow these steps to create a Spark cluster with Delta Lake on HDInsight:
1.	Sign in to the Azure portal and select Create a resource.
2.	Search for Azure HDInsight on AKS pool and select it.
3.	Once the cluster pool is created, click on “Create New” to create a cluster.
4.	Enter a cluster name, select Spark 3.3.1 as the cluster type, and enter the rest on the information as per requirement.
5.	On the Storage option, select your Azure Storage account and container, and enter a storage access key, along with the container and MSI name.
6.	On the Configuration + pricing tab, select the number and size of the head and worker nodes, and the region and resource group for your cluster.
7.	Review the summary and create the cluster.
To refer the complete steps click [here](https://learn.microsoft.com/en-us/azure/hdinsight-aks/quickstart-create-cluster).

### It may take a few minutes for the cluster to be provisioned. You can monitor the status on the portal or using the Azure CLI or PowerShell.

## Step 2: Upload your data and configuration files to Azure Storage
Before you can run your Delta Lake workloads on HDInsight, you need to upload your data and configuration files to your Azure Storage account. You can use any tool or method that supports Azure Storage, such as Azure portal, Azure Storage Explorer, Azure CLI, or PowerShell. For this document, we will use Azure portal as an example.
### Follow these steps to upload your data and configuration files to Azure Storage:
1.	Launch Azure portal and sign in into your Azure Storage account.
2.	Expand the Storage Accounts node and select your storage account and container.
3.	Create a new folder called delta-lake-demo and upload your data. In this example we are using the following [data](https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2023-01.parquet).
## Step 3: Launch your Spark cluster and run Delta Lake queries
Now that you have your Spark cluster and your data and configuration files ready, you can connect to your cluster and run Delta Lake queries using Azure Data Studio and the Spark SQL extension.
### Follow these steps to connect to your Spark cluster and run Delta Lake queries:
1.	Launch Azure HDInsight on AKS cluster and select the Jupyter notebook from the Overview and create a notebook.


## Step 4: Type the following queries in the Notebook
### Load your data into a dataframe:
1.	df = spark.read.format("parquet").load("abfss://<container name>@<storage name>.dfs.core.windows.net/year=2022/*")
2.	df.show()
Convert the parquet data to Delta format:
3.	df.write.format("delta").mode("overwrite").save("abfss://<container name>@<storage name>.dfs.core.windows.net/<folder name>")
### Load the delta format data in a new dataframe
4.	delta_df = spark.read.format("delta").load("abfss://<container name>@<storage name>.dfs.core.windows.net/< folder name>")
5.	delta_df.show()
6.	delta_df.createOrReplaceTempView("SparkDelta")
### Find out the average taxe fare
7.	avgDf = spark.sql("SELECT AVG(total_amount) as avg, vendorid FROM SparkDelta GROUP BY vendorid")
### Save the average fare in a new folder
8.	avgDf.write.format("delta").mode("overwrite").save("abfss://<container name>@<storage name>.dfs.core.windows.net/nyctaxi/avgamount/")

## Conclusion
In this document, we have shown you how to set up and run a Delta Lake workload on a Spark cluster on Azure HDInsight. You have learned how to create a Spark cluster with Delta Lake enabled, upload your data and configuration files to Azure Storage, and connect to your cluster and run Delta Lake queries. You can use this as a starting point to explore more features and capabilities of Delta Lake and HDInsight.







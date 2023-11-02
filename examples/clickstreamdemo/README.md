# HDInsight on AKS Demo - Clickstream data

It showcases how you can build an end-to-end use case for click stream data using Apache Flink, Apache Spark, and Trino workloads with HDInsight on AKS.

## Pre-requisites

* Apache Kafka cluster with HDInsight
* ADLS Gen2 storage and user-assigned managed identity (MSI)
* Apache Flink cluster with HDInsight on AKS
* Apache Spark cluster with HDInsight on AKS
* Trino cluster with HDInsight on AKS
* Power BI

## Scenario

For this scenario, we are going to cover the following path:
1. Streaming the data from Kafka topic and store it in a ADLS Gen2 via Data Streams in Apache Flink with HDInsight on AKS.
2. Once the data lands in ADLS Gen2, we will transform it using spark cluster with HDInsight on AKS.
3. Query it using Trino CLI.
4. Consume in Power BI using Trino connector for HDInsight on AKS.

## Demo steps

### Step 1: Create a Kafka cluster with HDInsight

* Create a [Kafka cluster on HDInsight](/azure/hdinsight/kafka/apache-kafka-get-started) inside a VNet.

> [!Note]
> Make sure to use the same VNet when you create a HDInsight on AKS cluster so as to establish communication among them.

* Create Kafka topic and produce messages as described [here](/azure/hdinsight-aks/flink/create-kafka-table-flink-kafka-sql-connector#prepare-topic-and-data-on-hdinsight-kafka)

### Step 2: Create Apache Flink cluster with HDInsight on AKS

* Create a [Flink cluster with HDInsight on AKS](/azure/hdinsight-aks/flink/flink-create-cluster-portal) inside the **same VNet** as Kafka cluster.
  
* Using the Flink file system connector, write the events into ADLS Gen2 via DataStream API. Refer the [java project](src/main/java/contoso/example/KafkaSinkToGen2.java) and [pom.xml](pom.xml) to build the jar and package it.

  Download the repository and use VS code/IntelliJ/any IDE to build the jar using the following command:

  ```
    $ mvn clean package <brokerIPs> <topicName> <groupId> <outputPath>
  ```
  
  Arguements:
  * `brokerIPs`: The IP address of Kakfa brokers with port separated by comma. For example: `0.0.0.0:9092, 0.0.0.1:9093`
  * `topicName`: Name of the Kafka topic in the previous step. For example: `click_events`
  * `groupId'`: Group ID to group messages for the consumers. You can provide any group ID. For example: `my-group`
  * `outputPath`: Location in ADLS Gen2 to sink the data. For example: `abfs://<container-name>@<storage-account-name>.dfs.core.windows.net/click_events`

  **For example: $ mvn clean package "0.0.0.0:9092, 0.0.0.1:9093" "click_events" "my-group" "abfs://container1@demostorage.dfs.core.windows.net/click_events"**

* Submit the job on Flink dashboard UI or use [Flink jobs option](https://techcommunity.microsoft.com/t5/analytics-on-azure-blog/running-your-first-apache-flink-job-with-azure-hdinsight-on-aks/ba-p/3953618) in your Flink cluster in Azure portal

  ![image](https://github.com/snehalsonwane/HDInsight_AKS_Demo/assets/99327040/b6f83cd1-2d4c-4e2a-ab22-b54563861b2e)

* Validate in your ALDS Gen2 that data is getting consumed.

  ![image](https://github.com/snehalsonwane/HDInsight_AKS_Demo/assets/99327040/21f30444-becf-4726-9ee4-cd3bc17cc737)

  > [!Note] Make sure the user-assigned managed identity associated with the Flink cluster have `storage blob data contributor` access on the storage account.

### Step 3: Create Apache Spark cluster with HDInsight on AKS

* Create a Spark cluster with HDInsight on AKS in the same cluster pool (where you created the Apache Flink cluster). Refer this [documentation](https://techcommunity.microsoft.com/t5/analytics-on-azure-blog/get-started-with-your-first-hdinsight-on-aks-cluster/ba-p/3952525)

* Convert the files dumped by Flink job in ADLS Gen2 into CSV format.  

  > [!Note] The data dumped by Flink is in Json format. You can convert the data files into any format (For e.g delta using flink-delta connector).

* Open your spark cluster, and in jupyter notebook load the data from our ADLS Gen2 and convert it into CSV files. Refer the following code.

      ```
      from pyspark.sql import SparkSession
      from pyspark.sql.types import StructType, StructField, StringType
      
      # Create a Spark session
      spark = SparkSession.builder.appName("HDInsight_AKS_Demo").getOrCreate()
      
      # Define input and output paths
      inputpath="abfss://container@storageaccount.dfs.core.windows.net/sourcefolderpath"
      outputpath="abfss://container@storageaccount.dfs.core.windows.net/destinationfolderpath"
      
      # Define schema based on the Python script's output structure
      schema = StructType([
      StructField("userName", StringType(), True),
      StructField("visitURL", StringType(), True),
      StructField("ts", StringType(), True)
      ])
      
      # Read the data into a DataFrame with the defined schema
      df = (spark.read.schema(schema)
      .format("json")
      .option("header", "true")
      .option("recursiveFileLookup", "true")  # Add this option for recursive reading
      .load(inputpath))
      
      # Write the DataFrame out to your desired format
      df.write.mode('overwrite').format("csv").save(outputpath)
      ```

### Step 4: Create Trino cluster with HDInsight on AKS

* Create [Trino cluster with Hive catalog enabled](https://learn.microsoft.com/en-us/azure/hdinsight-aks/trino/trino-create-cluster) in the same cluster pool and enable web ssh.
  
* Access [Trino CLI using webssh](https://learn.microsoft.com/en-us/azure/hdinsight-aks/trino/trino-ui-web-ssh) and we will create schema and table for our CSV files.

* Create a schema under your hive catalog in Trino cluster. Refer the following example for hive catalog with name as "hivewarehouse".

  ```
  trino> CREATE SCHEMA hivewarehouse.example;
  ```

* Create a table using register_table procedure.
  
  ```
  trino> CREATE TABLE hivewarehouse.example.clickevents(
       userName VARCHAR,
       visitURL VARCHAR,
       ts VARCHAR
       ) WITH (
       format = 'CSV',
       external_location = 'abfss://container@storageaccount.dfs.core.windows.net/destinationfolderpath');
  ```
      
* Query the data

  ```
  trino> SELECT COUNT(*) FROM hivewarehouse.example.clickevents;
  ```

### Step 5: Visualize using Trino Power BI connector for HDInsight on AKS

* For this, let's connect to our trino cluster from Power BI desktop. Open your PowerBI desktop and search for [Trino connector for HDInsight on AKS](https://learn.microsoft.com/en-us/power-query/connectors/azure-hdinsight-on-aks-trino) and click connect.

  <img width="482" alt="image" src="https://github.com/snehalsonwane/HDInsight_AKS_Demo/assets/99327040/90fbd418-d090-4dbb-92b3-d1d3011cffff">

* Fill in the details in the dialog box for trino cluster url.
  
  <img width="507" alt="image" src="https://github.com/snehalsonwane/HDInsight_AKS_Demo/assets/99327040/35acdf11-ce04-4ec8-b1db-7455cc035f88">
     
* You can query the data in Power BI.

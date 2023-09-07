# Azure HDInsight Flink on AKS + Azure Databricks Delta Live Tabls 

这个例子使用Azure HDInsight Flink SQL Stream API on AKS 读取Kafka on Azure HDInsight的流数据到ADLS GEN2，然后使用Azure Databricks的Delta Live Tables功能，构建强大的实时管道，将应用程序集成到更广泛的 Lakehouse 架构中。
当然，也可以使用FLink的DataStream API更加灵活的处理应用程序

![image](https://github.com/Azure-Samples/hdinsight-aks/assets/35547706/d542b32e-90d2-4a95-90a5-0c34c375b2f8)

## 环境准备

  . HDInsight Flink 1.16.0 on AKS <br>
  . HDInsight Kafka 3.2.0 <br>
  . Azure Databricks <br>
  . ADLS gen2 Storage Account <br>

## 什么是Databricks Delta Live Tables(DLT)？

DLT 是一个 ETL 框架，它使用一种简单的声明性方法来构建可靠的数据管道并自动按大规模管理相关的基础架构，减少了数据工程师和科学家在复杂的操作任务上所花费的时间。
现在通常可用在Microsoft Azure，AWS和Google Cloud平台上。

DLT 完全支持 Python 和 SQL，并针对流式和批处理工作负载进行了定制。

Azure Databricks 的DLT 文档：<br>
https://learn.microsoft.com/en-us/azure/databricks/delta-live-tables/

## Auto Loader在DLT中的运用

Auto Loader（自动加载程序）会在新数据文件到达云存储空间时以增量方式高效地对其进行处理，而无需进行任何其他设置。

自动加载程序会在新数据文件到达云存储空间时以增量方式高效地对其进行处理。 
自动加载程序可以从 AWS S3 (s3://)、Azure Data Lake Storage Gen2 (ADLS Gen2, abfss://)、Google Cloud Storage (GCS, gs://)、Azure Blob 存储 (wasbs://)、ADLS Gen1 (adl://) 和 Databricks File System (DBFS, dbfs:/) 加载数据文件。 自动加载程序可以引入 JSON、CSV、PARQUET、AVRO、ORC、TEXT 和 BINARYFILE 文件格式。

自动加载程序提供了名为 cloudFiles 的结构化流式处理源。 给定云文件存储上的输入目录路径后，cloudFiles 源将在新文件到达时自动处理这些文件，你也可以选择处理该目录中的现有文件。 自动加载程序在增量实时表中同时支持 Python 和 SQL。

可以使用自动加载程序处理数十亿个文件以迁移或回填表。 自动加载程序可缩放以支持每小时近实时引入数百万个文件。

**Databricks 建议在增量实时表中使用自动加载程序来引入增量数据。**

Azure Databricks 的auto loader 运行在DLT的 文档：<br>
https://learn.microsoft.com/en-us/azure/databricks/ingestion/auto-loader/dlt

## 实施步骤：

### Step1: 在Kafka集群上准备一个topic，这个topic接受来之OpenAky API的
### Step2: 登陆webssh，使用sql-client.sh进到Flink SQL环境，创建Kafka table

** --Create Kafka Table ON Flink：**
``` SQL
CREATE TABLE kafka_airplanes_state_real_time (
   `date` STRING,
   `geo_altitude` FLOAT,
   `icao24` STRING,
   `latitude` FLOAT,
   `true_track` FLOAT,
   `velocity` FLOAT,
   `spi` BOOLEAN,
   `origin_country` STRING,
   `minute` STRING,
   `squawk` STRING,
   `sensors` STRING,
   `hour` STRING,
   `baro_altitude` FLOAT,
   `time_position` BIGINT,
   `last_contact` BIGINT,
   `callsign` STRING,
   `event_time` STRING,
   `on_ground` BOOLEAN,
   `category` STRING,
   `vertical_rate` FLOAT,
   `position_source` INT,
   `current_time` STRING,
   `longitude` FLOAT
 ) WITH (
    'connector' = 'kafka',  
    'topic' = 'airplanes_state_real_time',  
    'scan.startup.mode' = 'latest-offset',  
    'properties.bootstrap.servers' = '<Broker 1>:9092,<Broker 2>:9092,<Broker 3>:9092', 
    'format' = 'json' 
);
```

### Step3: 在Flink SQL上，创建ADLS gen2 table

``` SQL
CREATE TABLE adlsgen2_airplanes_state_real_time (
   `date` STRING,
   `geo_altitude` FLOAT,
   `icao24` STRING,
   `latitude` FLOAT,
   `true_track` FLOAT,
   `velocity` FLOAT,
   `spi` BOOLEAN,
   `origin_country` STRING,
   `minute` STRING,
   `squawk` STRING,
   `sensors` STRING,
   `hour` STRING,
   `baro_altitude` FLOAT,
   `time_position` BIGINT,
   `last_contact` BIGINT,
   `callsign` STRING,
   `event_time` STRING,
   `on_ground` BOOLEAN,
   `category` STRING,
   `vertical_rate` FLOAT,
   `position_source` INT,
   `current_time` STRING,
   `longitude` FLOAT
 ) WITH (
     'connector' = 'filesystem',
     'path' = 'abfs://<container>@<ADLS gen2 account name>.dfs.core.windows.net/flink/airplanes_state_real_time/',
     'format' = 'json'
 );
```

### Step4: 在Flink SQL上，将Kafka table sink到ADLS gen2 table

``` SQL
Flink SQL > insert into adlsgen2_airplanes_state_real_time select * from kafka_airplanes_state_real_time;
```
![image](https://github.com/Azure-Samples/hdinsight-aks/assets/35547706/3d02469d-6c20-4b6f-83e8-f53856de28f5)

### Step5: 在Flink UI 查看 sink的streaming job

![image](https://github.com/Azure-Samples/hdinsight-aks/assets/35547706/cc97a851-561f-40a0-a170-1d9784f69d28)

### Step6: Azure portal上查看ADLS gen2是否有增量的数据生成

![image](https://github.com/Azure-Samples/hdinsight-aks/assets/35547706/bc8d11ed-6d7b-4105-8263-e4a5d9335b21)

### Step7: ADB 上，使用Service Principle对ADLS gen2进行身份验证，然后mount ADLS gen2到 ADB DBFS的mnt路径

-- 在Azure Portal的AAD上获取 service principle appid, tenant id 和 secret key.
![image](https://github.com/Azure-Samples/hdinsight-aks/assets/35547706/cc7c26d1-3c40-4ae0-b7f8-0d12cfe9e6e2)

-- 在ADLSgen2 Portal上的IAM里给上面创建的 service principle 赋予 the Storage Blob Data Owner 的角色
![image](https://github.com/Azure-Samples/hdinsight-aks/assets/35547706/c83b4b99-2990-41ee-aa79-b7c8eb096524)

-- 在notebook上, mount ADLS gen2 到 DBFS的/mnt 路径

![image](https://github.com/Azure-Samples/hdinsight-aks/assets/35547706/5101c711-67c3-43dd-963e-532280cdabde)

![image](https://github.com/Azure-Samples/hdinsight-aks/assets/35547706/dfd12ad0-c0fb-4241-bd8d-f31b0c58939f)

-- 在notebook上 准备 autoloader sink ADLS gen2到delta lake的code。这个例子使用SQL的语法

``` SQL
%sql
CREATE OR REFRESH STREAMING TABLE airplanes_state_real_time2
AS SELECT * FROM cloud_files("dbfs:/mnt/contosoflinkgen2/flink/airplanes_state_real_time/", "json")
```

![image](https://github.com/Azure-Samples/hdinsight-aks/assets/35547706/5a125d1e-bb35-48f2-8409-65e59b315fd6)

### Step8: ADB 上，定义 DLT Pipline，使用AUTO loader sink ADLS gen2到Delta lake

![image](https://github.com/Azure-Samples/hdinsight-aks/assets/35547706/57385e15-40be-4127-9acf-ac0272b675b8)

![image](https://github.com/Azure-Samples/hdinsight-aks/assets/35547706/20b1a7c6-2266-4f48-8293-0a053c0a699b)

### Step9: ADB 的Notebook上 查看 Delta Live Table 

![image](https://github.com/Azure-Samples/hdinsight-aks/assets/35547706/d5d695b9-b288-4bd1-a3f8-7ba52603e641)






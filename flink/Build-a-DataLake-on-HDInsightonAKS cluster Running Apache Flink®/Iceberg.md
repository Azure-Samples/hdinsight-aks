This example demonstrates how to use Iceberg Table managed in Hive catalog in Azure HDInsight on AKS running Flink Cluster

## Apache Iceberg
Apache Iceberg is an open table format for huge analytic datasets. Iceberg adds tables to compute engines like Apache Flink, using a high-performance table format that works just like a SQL table. Apache Iceberg supports both Apache Flink’s DataStream API and Table API.

## Prerequisites

HDInsight Flink 1.16.0 on AKS

## Download required jar on webssh

Once you launch webssh, let us start downloading the dependencies required to the SSH node, to illustrate the Iceberg table managed in Hive catalog.

```
wget https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-flink-runtime-1.16/1.3.0/iceberg-flink-runtime-1.16-1.3.0.jar -P $FLINK_HOME/lib
wget https://repo1.maven.org/maven2/org/apache/parquet/parquet-column/1.12.2/parquet-column-1.12.2.jar -P $FLINK_HOME/lib
```

## Start the Apache Flink SQL Client

```
./bin/sql-client.sh
```

## Create Iceberg Table managed in Hive catalog

With the following steps, we illustrate how you can create Flink-Iceberg Catalog using Hive catalog

``` SQL
CREATE CATALOG hive_catalog WITH (
  'type'='iceberg',
  'catalog-type'='hive',
  'uri'='thrift://hive-metastore:9083',
  'clients'='5',
  'property-version'='1',
  'warehouse'='abfss://<container>@<storage_name>.dfs.core.windows.net/ieberg-output');

USE CATALOG hive_catalog;
```

Note: <br>
In the above step, the container and storage account need not be same as specified during the cluster creation.
In case you want to specify another storage account, you can update core-site.xml with fs.azure.account.key.<account_name>.dfs.core.windows.net: <azure_storage_key> using configuration management.

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/ff2e6388-9b36-41de-8f94-f1ef6c9a95bb)

## Add dependencies to server classpath

Add dependencies to server classpath in Flink SQL

``` SQL
ADD JAR '/opt/flink-webssh/lib/iceberg-flink-runtime-1.16-1.3.0.jar';
  ADD JAR '/opt/flink-webssh/lib/parquet-column-1.12.2.jar';
```

or

Add dependencies to server classpath in sql-client.sh
```
./bin/sql-client.sh -j /opt/flink-webssh/lib/iceberg-flink-runtime-1.16-1.3.0.jar -j /opt/flink-webssh/lib/parquet-column-1.12.2.jar
```

## Create Database
``` SQL
CREATE DATABASE iceberg_db_2;
  USE iceberg_db_2;
```

## Create Table
``` SQL
    CREATE TABLE `hive_catalog`.`iceberg_db_2`.`iceberg_sample_2`
    (
    id BIGINT COMMENT 'unique id',
    data STRING
    )
    PARTITIONED BY (data);
```

## Insert Data into the Iceberg Table
``` SQL
 INSERT INTO `hive_catalog`.`iceberg_db_2`.`iceberg_sample_2` VALUES (1, 'a');
```

## Output of the Iceberg Table

You can view the Iceberg Table output on the ABFS container <br>
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/1ee6e84d-b320-4b36-9e26-cc10cc4934d2)

## Clean up the resource


## FileSystem SQL Connector 

This connector provides access to partitioned files in filesystems supported by the Flink FileSystem abstraction.
The file system connector itself is included in Flink and does not require an additional dependency. 
The corresponding jar can be found in the Flink distribution inside the /lib directory.

Ref#<br>
https://nightlies.apache.org/flink/flink-docs-release-1.16/docs/connectors/table/filesystem/

## In Azure HDInsight on AKS running Flink cluster 
We provide `flink-azure-fs-hadoop` which is located in `/opt/flink-webssh/plugins/azure-fs-hadoop` of the Flink distribution.
This JAR file contains the Azure Blob File System (ABFS) driver, which enables Flink to access Azure Blob Storage data directly.

**JAR location on webssh pob** <br>
```
pod@sshnode-0 [ ~/plugins/azure-fs-hadoop ]$ pwd
/opt/flink-webssh/plugins/azure-fs-hadoop
pod@sshnode-0 [ ~/plugins/azure-fs-hadoop ]$ ls -l
total 27152
-rw-rw-rw- 1 flink flink 27800309 Aug  7 11:36 flink-azure-fs-hadoop-1.16.0-0.0.18.jar
```

**Credential Configuration** <br>
In Azure HDInsight on AKS running Flink cluster, basically we uses Azure user managed identity to access the ADLS Gen2 storage accounts using abfs.

## Create ADLS gen2 table on Flink SQL  

**create ADLS gen2 table by using SQL Client CLI on webssh pob to enter Flink SQL environment** <br>

Faced the error of "java.lang.ClassNotFoundException: org.apache.flink.table.planner.delegation.DialectFactory" <br>

``` SQL
pod@sshnode-0 [ ~ ]$ bin/sql-client.sh
.....

Flink SQL> CREATE TABLE csvtab (
>   c0 STRING,
>   c1 STRING,
>   c2 STRING,
>   c3 STRING,
>   c4 STRING,
>   c5 STRING,
>   c6 STRING
> ) WITH (
>   'connector' = 'filesystem',
>   'path' = 'abfss://<container>@<accountname>.dfs.core.windows.net/data/testdelta.csv',
>   'format' = 'csv'
> );
[INFO] Execute statement succeed.

Flink SQL> select * from csvtab;
[ERROR] Could not execute SQL statement. Reason:
java.lang.ClassNotFoundException: org.apache.flink.table.planner.delegation.DialectFactory
```

**Cause** <br>

The org.apache.flink.table.planner.delegation.DialectFactory class is part of the flink-table-planner_2.12-1.16.0-0.0.18.jar and 
not part of the flink-table-planner-loader-1.16.0-0.0.18.jar.

The flink-table-planner-loader is a new module introduced in Flink 1.15 that replaces flink-table-planner_2.12 and avoids the need for a Scala suffix. 
However, for backwards compatibility, users can still swap it with flink-table-planner_2.12 located in opt/.

If you’re encountering issues with the flink-table-planner-loader, you can swap it with the flink-table-planner_2.12.jar as you’ve done. This should resolve the ClassNotFoundException and allow you to run your SQL query.

Ref# <br>
https://nightlies.apache.org/flink/flink-docs-release-1.16/docs/dev/configuration/advanced/

**Solution** <br>
```
mv /opt/flink-webssh/opt/flink-table-planner_2.12-1.16.0-0.0.18.jar /opt/flink-webssh/lib/flink-table-planner_2.12-1.16.0-0.0.18.jar
mv /opt/flink-webssh/lib/flink-table-planner-loader-1.16.0-0.0.18.jar /opt/flink-webssh/opt/flink-table-planner-loader-1.16.0-0.0.18.jar
```
Note: <br>
To use Hive dialect in Flink, also need to swap `flink-table-planner-loader` with the `flink-table-planner_2.12.jar`

Ref# <br>
https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/hive-dialect-flink <br>
https://nightlies.apache.org/flink/flink-docs-release-1.16/docs/connectors/table/hive/overview/  <br>

Create Again: <br>
``` SQL
Flink SQL> CREATE TABLE csvtab (
>   c0 STRING,
>   c1 STRING,
>   c2 STRING,
>   c3 STRING,
>   c4 STRING,
>   c5 STRING,
>   c6 STRING
> ) WITH (
>   'connector' = 'filesystem',
>   'path' = 'abfss://<container>@<accountname>.dfs.core.windows.net/data/testdelta.csv',
>   'format' = 'csv'
> );
> 
[INFO] Execute statement succeed.

Flink SQL> SET 'execution.runtime-mode' = 'batch';
[INFO] Session property has been set.

Flink SQL> SET 'sql-client.execution.result-mode' = 'tableau';
[INFO] Session property has been set.

Flink SQL> select count(*) from csvtab;
+--------+
| EXPR$0 |
+--------+
|     31 |
+--------+
```

## Apache Hive on Apache Flink

Flink offers a two-fold integration with Hive. <br>

.The first step is to use Hive Metastore (HMS) as a persistent catalog with Flink’s HiveCatalog for storing Flink specific metadata across sessions.
For example, users can store their Kafka or ElasticSearch or ADLS gen2 or CDC SQL or JDBC tables in Hive Metastore by using HiveCatalog, and reuse them later on in SQL queries.

.The second is to offer Flink as an alternative engine for reading and writing Hive tables.
The HiveCatalog is designed to be “out of the box” compatible with existing Hive installations. You don't need to modify your existing Hive Metastore or change the data placement or partitioning of your tables.

Please refer README.md for more details

## Create a ADLS gen2 file in persistent catalog with Flink’s HiveCatalog 

**Create Hive catalog and connect to the hive catalog on Flink SQL on webssh pod** <br>
Note: As we already prepared HMS running on our Flink cluster, no need to do any configuration on current Flink with hms cluster.

on webssh pod <br>
```
pod@sshnode-0 [ ~ ]$ bin/sql-client.sh
```

Flink SQL:<br>
``` SQL
CREATE CATALOG myhive WITH (
    'type' = 'hive'
);

USE CATALOG myhive;

CREATE TABLE csvtab (
  c0 STRING,
  c1 STRING,
  c2 STRING,
  c3 STRING,
  c4 STRING,
  c5 STRING,
  c6 STRING
) WITH (
  'connector' = 'filesystem',
  'path' = 'abfss://<container>@<accountname>.dfs.core.windows.net/data/testdelta.csv',
  'format' = 'csv'
);

Flink SQL> show tables;
+------------------+
|       table name |
+------------------+
|           csvtab |
|  hivesampletable |
+------------------+
2 rows in set
``` 

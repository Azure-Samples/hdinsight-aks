## Using a combination of Vector.dev (a logging agent), Azure HDInsight Kafka and Azure HDInsight Flink on AKS to store logs in Iceberg format can provide a hugely cost effective and powerful logging solution worth looking at the following diagram:

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/f0ce02d0-1293-427c-916d-500aa4e3a833)


Logs coming from a source to Azure HDInsight Kafka. Flink reads the data from Azure HDInsight Kafka and allows you to run queries on the data and then the data back to ADLSgen2 in a Iceberg format table suitable for long time storage and querying.


## Prerequisites
. Apache Flink Cluster on HDInsight on AKS with Hive Metastore 3.1.2 <br>
. Apache Kafka cluster on HDInsight <br>
. Vector 0.34.0  <br>

## Vector(logging agent)

Vector is a high-performance observability data pipeline that enables you to collect, transform, and route all of your logs and metrics.![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/564e8370-57f8-4a3d-b231-8c1c501d6daf)
In this blog, we will use vector.dev as a logging agent that can submit logs to a Kafka cluster.

#Ref<br>
https://vector.dev/docs/setup/quickstart/

**Install Vector on any node of HDInsight Kafka cluster directly:**

```
root@hn0-kafkad:/home/sshuser# curl --proto '=https' --tlsv1.2 -sSfL https://sh.vector.dev | bash
                                   __   __  __
                                   \ \ / / / /
                                    \ V / / /
                                     \_/  \/

                                   V E C T O R
                                    Installer


--------------------------------------------------------------------------------
Website: https://vector.dev
Docs: https://vector.dev/docs/
Community: https://vector.dev/community/
--------------------------------------------------------------------------------

>>> We'll be installing Vector via a pre-built archive at https://packages.timber.io/vector/0.34.0/
>>> Ready to proceed? (y/n)

>>> y

--------------------------------------------------------------------------------

>>> Downloading Vector via https://packages.timber.io/vector/0.34.0/vector-0.34.0-x86_64-unknown-linux-gnu.tar.gz ✓
>>> Unpacking archive to /root/.vector ... ✓
>>> Adding Vector path to /root/.zprofile ✓
>>> Adding Vector path to /root/.profile ✓
>>> Install succeeded! 🚀
>>> To start Vector:

    vector --config /root/.vector/config/vector.yaml

>>> More information at https://vector.dev/docs/
```


**Once Vector is installed, let’s check to make sure that it’s working correctly:**

```
root@hn0-kafkad:/home/sshuser# vector --version

Command 'vector' not found, did you mean:

  command 'victor' from deb spark

Try: apt install <deb name>

root@hn0-kafkad:/home/sshuser# echo $PATH
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
root@hn0-kafkad:/home/sshuser# export PATH=$PATH:/root/.vector/bin
root@hn0-kafkad:/home/sshuser# source ~/.bashrc
root@hn0-kafkad:/home/sshuser# vector --version
vector 0.34.0 (x86_64-unknown-linux-gnu c909b66 2023-11-07 15:07:26.748571656)
```

## Iceberg Catalog in Apache Flink® on HDInsight on AKS

Apache Iceberg is an open table format for huge analytic datasets. Iceberg adds tables to compute engines like Apache Flink, using a high-performance table format that works just like a SQL table. Apache Iceberg supports both Apache Flink’s DataStream API and Table API.

How use Iceberg Table managed in Hive catalog, with Apache Flink on HDInsight on AKS cluster.<br>

https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-catalog-iceberg-hive

## Running Vector to generate sample data to Kafka topic

**Create kafka topic: apache_logs on Kafka cluster**

```
root@hn0-kafkad:/home/sshuser# /usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create --replication-factor 2 --partitions 3 --bootstrap-server <broker_ip>:9092 --topic apache_logs
```

**Create a configuration file called vector2.toml**

Vector topologies are defined using a configuration file that tells it which components to run and how they should interact. Vector topologies are made up of three types of components: <br>

. Sources collect or receive data from observability data sources into Vector <br>
. Transforms manipulate or change that observability data as it passes through your topology <br>
. Sinks send data onwards from Vector to external services or destinations <br>

More details at https://vector.dev/docs/ 

```
root@hn0-kafkad:/home/sshuser# cat /root/.vector/config/vector2.toml
data_dir = "/home/sshuser/vector"

[api]
enabled = true

[sinks.my_sink_id.encoding]
codec = "json"

[sources.my_source_id]
type = "demo_logs"
count = 1000000
format = "json"
interval = 1
lines = [ "line1" ]

[transforms.parse_apache_logs]
type = "remap"
inputs = ["my_source_id"]
source = '''
  parsed_json = parse_json!(.message)
  .host = parsed_json.host
  .user_identifier = parsed_json."user-identifier"
  .datetime = parsed_json.datetime
  .method = parsed_json.method
  .request = parsed_json.request
  .protocol = parsed_json.protocol
  .status = parsed_json.status
  .bytes = parsed_json.bytes
  .referer = parsed_json.referer
  del(.message)
'''

[sinks.my_sink_id]
type = "kafka"
inputs = [ "parse_apache_logs" ]
bootstrap_servers = "<broker_ip>:9092"
topic = "apache_logs"
```

**Running Vector**
```
root@hn0-kafkad:~/.vector/config# vector --config /root/.vector/config/vector2.toml
2023-12-10T09:19:42.424282Z  INFO vector::app: Log level is enabled. level="vector=info,codec=info,vrl=info,file_source=info,tower_limit=info,rdkafka=info,buffers=info,lapin=info,kube=info"
2023-12-10T09:19:42.425358Z  INFO vector::app: Loading configs. paths=["/root/.vector/config/vector2.toml"]
2023-12-10T09:19:42.434168Z  INFO vector::topology::running: Running healthchecks.
2023-12-10T09:19:42.434326Z  INFO vector: Vector has started. debug="false" version="0.34.0" arch="x86_64" revision="c909b66 2023-11-07 15:07:26.748571656"
2023-12-10T09:19:42.436676Z  INFO vector::internal_events::api: API server running. address=127.0.0.1:8686 playground=http://127.0.0.1:8686/playground
2023-12-10T09:19:42.460280Z  INFO vector::topology::builder: Healthcheck passed.
```
**Confirming Kafka message**
```
/usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh --bootstrap-server <broker_ip>:9092 --topic apache_logs --from-beginning

{"bytes":13819,"datetime":"10/Dec/2023:09:19:57","host":"35.97.94.126","method":"DELETE","protocol":"HTTP/1.0","referer":"https://for.eus/observability/metrics/production","request":"/wp-admin","service":"vector","source_type":"demo_logs","status":"404","timestamp":"2023-12-10T09:19:57.442369206Z","user_identifier":"meln1ks"}
{"bytes":31286,"datetime":"10/Dec/2023:09:20:00","host":"182.132.243.149","method":"PUT","protocol":"HTTP/1.0","referer":"https://we.abudhabi/apps/deploy","request":"/wp-admin","service":"vector","source_type":"demo_logs","status":"500","timestamp":"2023-12-10T09:20:00.442309537Z","user_identifier":"BryanHorsey"}
```

## Flink job to read from the logs topic

Flink can read the data from the logs topic and save it to ADLSgen2 using a table format from Apache Iceberg. <br>
Flink is then pulling in the data and storing it for long term storage in Iceberg format on ADLS gen2 with Flink ready to work on your data to spot patterns such as errors or malicious use and send it wherever you need.

Details:<br>
HDInsight Kafka will hold the newest logs as they come in and Flink can copy that data to ADLS gen2 in a format that is efficient and available to query at any time for any historic queries you might like to run.<br>
In Flink you can create a new Catalog which facilitates the storage to ADLS gen2 for you.<br>
Then you can create a table in the catalog and send data to it.<br>
Heres the full Job for flink to read the data and send it to ADLS gen2

**1. Download iceberg, parquet, Kafka client and flink kafka connector dependencies into webssh pod**

In thi blog, I use SSH on Azure portal to login to webssh pod to submit jar, run flink sql etc

#Ref
https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-web-ssh-on-portal-to-flink-sql

```
wget https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-flink-runtime-1.16/1.3.0/iceberg-flink-runtime-1.16-1.3.0.jar -P $FLINK_HOME/lib
wget https://repo1.maven.org/maven2/org/apache/parquet/parquet-column/1.12.2/parquet-column-1.12.2.jar -P $FLINK_HOME/lib

wget https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.2.0/kafka-clients-3.2.0.jar  -P $FLINK_HOME/lib
wget https://repo1.maven.org/maven2/org/apache/flink/flink-connector-kafka/1.16.0/flink-connector-kafka-1.16.0.jar  -P $FLINK_HOME/lib
```

**2. Connect to the Flink SQL console using**

```
bin/sql-client.sh
```

**3. Create Flink-Iceberg Catalog using Hive catalog**
``` SQL
CREATE CATALOG hive_catalog WITH (
  'type'='iceberg',
  'catalog-type'='hive',
  'uri'='thrift://hive-metastore:9083',
  'clients'='5',
  'property-version'='1',
  'warehouse'='abfs://<container>@<storage_account>.dfs.core.windows.net/ieberg-output');

USE CATALOG hive_catalog;

-- Add Kafka connector and Iceberg dependecies
ADD JAR '/opt/flink-webssh/lib/iceberg-flink-runtime-1.16-1.3.0.jar';
ADD JAR '/opt/flink-webssh/lib/parquet-column-1.12.2.jar';
ADD JAR '/opt/flink-webssh/lib/flink-connector-kafka-1.16.0.jar';
ADD JAR '/opt/flink-webssh/lib/kafka-clients-3.2.0.jar';

CREATE DATABASE IF NOT EXISTS logs_database;
USE logs_database;
```

**4. Create Kafka Table**
``` sql
CREATE TEMPORARY TABLE apache_logs (
  `bytes` INT,
  `datetime` STRING,
  `host` STRING,
  `method` STRING,
  `protocol` STRING,
  `referer` STRING,
  `request` STRING,
  `service` STRING,
  `source_type` STRING,
  `status` STRING,
  `mytimestamp` TIMESTAMP(3) METADATA FROM 'timestamp',  -- assuming timestamp is in standard format
  `user_identifier` STRING,
    WATERMARK FOR mytimestamp AS mytimestamp - INTERVAL '5' SECONDS
) WITH (
    'connector' = 'kafka',
    'topic' = 'apache_logs',
    'properties.bootstrap.servers' = '<broker_ip1>:9092,<broker_ip2>:9092,<broker_ip3>:9092',
    'properties.group.id' = 'flink',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json',
    'json.fail-on-missing-field' = 'false',
    'json.ignore-parse-errors' = 'true'
);
``` 

**5. Create Iceberg Table**
``` sql
CREATE TABLE  IF NOT EXISTS  archive_apache_logs (
  `bytes` INT,
  `datetime` STRING,
  `host` STRING,
  `method` STRING,
  `protocol` STRING,
  `referer` STRING,
  `request` STRING,
  `service` STRING,
  `source_type` STRING,
  `status` STRING,
  `mytimestamp` TIMESTAMP(3),
  `user_identifier` STRING
) WITH (
    'format-version'='1'
);
```

**5. Iceberg for long term and low cost storage**

``` SQL
SET 'execution.checkpointing.interval' = '60 s';

Flink SQL> INSERT INTO archive_apache_logs(`bytes`, `datetime`, `host`, `method`, `protocol`, `referer`,`request`, `service`, `mytimestamp`)
> SELECT `bytes`, `datetime`, `host`, `method`, `protocol`, `referer`, `request`, `service`, CURRENT_TIMESTAMP FROM apache_logs;
[INFO] Submitting SQL update statement to the cluster...
[INFO] SQL update statement has been successfully submitted to the cluster:
Job ID: 80e6a48543655c41567eb38eaf29f840
```

**6. Check job on Flink Dashboard UI**

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/687215d4-b8d8-4439-b0cd-194b9ca9ddfa)

**7. Check Archived file on ADLS gen2 using a table format from Apache Iceberg**

Apache Iceberg for long term and low cost storage

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/8331ee3a-9515-43e0-a748-22e7ad0c0e06)

## Cleanup the resource

. Delete Apache Flink Cluster on HDInsight on AKS  <br>
. Delete Apache Kafka cluster on HDInsight <br>
. Uninstall Vector 0.34.0  <br>









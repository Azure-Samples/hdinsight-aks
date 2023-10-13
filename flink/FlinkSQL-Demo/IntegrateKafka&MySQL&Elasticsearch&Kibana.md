
This example refers Flink doc Demo example(https://flink.apache.org/2020/07/28/flink-sql-demo-building-an-end-to-end-streaming-application/ ) to implement on HDInsight Flink on AKS.

It describes how to use Flink SQL to integrate Kafka, MySQL, Elasticsearch, and Kibana to quickly build a real-time analytics application.. All exercises are performed in the Flink SQL CLI, and the entire process uses standard SQL syntax, without a single line of Java/Scala code or IDE installation. The final result of This demo is shown in the following figure:

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/482a0fbe-1e35-4a96-ae59-c5075ca24b6f)

## Prerequisites
• HDInsight Flink 1.16.0 with Hive Metastore 3.1.2 on AKS
• HDInsight Kafka 3.2.0
• MySQL 8.0.33
• Elasticsearch-7.17.11
• Kibana-7.17.11
• For this demonstration, we are using an Ubuntu VM 20.04 in the same VNET as HDInsight on AKS, install Elasticsearch and Kibana on this VM

## Environment preparation
**MySQL on Azure:**<br>
a pre-populated category table in the database, The category table will be joined with data in Kafka to enrich the real-time data.

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/3cccde14-c6a7-4505-9a0b-d02b5b3cf365)

The category tablle:<br>

``` sql
mysql> select count(*) from category;
+----------+
| count(*) |
+----------+
|     4998 |
+----------+
1 row in set (0.26 sec)
```

**Flink SQL CLI:** <br>
used to submit queries and visualize their results.

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/03a5ac7d-cb2e-4c62-a893-3879d2c422c2)

Add dependencies:<br>
Once you launch the Secure Shell (SSH), let us start downloading the dependencies required to the SSH node

```
wget https://repo1.maven.org/maven2/org/apache/flink/flink-connector-kafka/1.16.0/flink-connector-kafka-1.16.0.jar
wget https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.2.0/kafka-clients-3.2.0.jar
wget https://repo1.maven.org/maven2/org/apache/flink/flink-connector-jdbc/1.16.0/flink-connector-jdbc-1.16.0.jar
wget https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar
wget https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-elasticsearch7/1.16.0/flink-sql-connector-elasticsearch7-1.16.0.jar
```

```
msdata@sshnode-0 [ ~ ]$ ls -l
total 36224
-rw-rw-rw-  1 flink flink    11357 Aug  7 11:18 LICENSE
-rw-rw-rw-  1 flink flink   537600 Aug  7 11:45 NOTICE
-rw-rw-rw-  1 flink flink     1309 Aug  7 11:18 README.txt
drwxrwxrwx  2 flink flink     4096 Aug  7 11:42 bin
drwxrwxrwx  3 root  root      4096 Sep 13 11:12 conf
drwxrwxrwx  7 flink flink     4096 Aug  7 11:42 examples
-rw-rw-r--  1 user  user  248888 Oct 20  2022 flink-connector-jdbc-1.16.0.jar
-rw-rw-r--  1 user  user  396461 Oct 20  2022 flink-connector-kafka-1.16.0.jar
-rw-rw-r--  1 user  user  28428885 Oct 20  2022 flink-sql-connector-elasticsearch7-1.16.0.jar
-rw-rw-r--  1 user  user  4941003 May  3  2022 kafka-clients-3.2.0.jar
drwxrwxrwx  2 flink flink     4096 Aug  7 11:42 lib
drwxrwxrwx  2 flink flink     4096 Aug  7 11:45 licenses
drwxrwxrwx  1 flink flink     4096 Sep 13 11:24 log
-rw-rw-r--  1 user  user  2481560 Apr 16 22:11 mysql-connector-j-8.0.33.jar
drwxrwxrwx  1 flink flink     4096 Aug  7 12:31 opt
drwxrwxrwx 11 flink flink     4096 Aug  7 12:31 plugins
```

**Flink Cluster:** <br>
Run Query
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/cac221c9-e68b-4a6b-a46e-76c174b9bb18)

**Kafka:** <br>
used as a data source. Elasticsearch: used as a data sink. Kibana: used to visualize the data in Elasticsearch.

Please refer https://supportability.visualstudio.com/AzureHDinsight/_wiki/wikis/AzureHDinsight/860498/-Hilo-DStreamAPI-SinkKafkaToElastic for Elasticsearch and Kibana Installation.

Kafka topic creation:
```
/usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create --replication-factor 2 --partitions 6 --topic user_behavior_csv --bootstrap-server <broker>:9092
/usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create --replication-factor 2 --partitions 6 --topic user_behavior_json --bootstrap-server <broker>:9092
```

**Flink SQL CLI client** <br>
```
bin/sql-client.sh -j flink-connector-jdbc-1.16.0.jar -j flink-connector-kafka-1.16.0.jar -j flink-sql-connector-elasticsearch7-1.16.0.jar -j kafka-clients-3.2.0.jar -j mysql-connector-j-8.0.33.jar
```

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/7b3ae58c-933c-44f3-9a27-caf5891e5ec1)

## Prepare user_behavior topic on HDInsight Kafka
This data contains the user behavior on the day of November 27, 2017 (behaviors include “click”, “like”, “purchase” and "add to shopping cart" events). Each row represents a user behavior event, with the user ID, product ID, product category ID, event type, and timestamp in JSON format. Note that the dataset is from the Alibaba Cloud Tianchi public dataset(https://tianchi.aliyun.com/dataset/649 )

Download UserBehavior.csv.zip into Kafka cluster VM, and use below command to produce to user_behavior topic on Kakfa
```
cat /home/sshuser/UserBehavior.csv | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh --bootstrap-server wn0-kafkad:9092 --topic user_behavior_csv
```

**UserBehavior.csv** <br>
Randomly select about 1 million users who have behaviors including click, purchase, adding item to shopping cart and item favoring during November 25 to December 03, 2017. The dataset is organized in a very similar form to MovieLens-20M, i.e., each line represents a specific user-item interaction, which consists of user ID, item ID, item's category ID, behavior type and timestamp, separated by commas. The detailed descriptions of each field are as follows:

```
User ID:	An integer, the serialized ID that represents a user
Item ID:	An integer, the serialized ID that represents an item
Category ID:	An integer, the serialized ID that represents the category which the corresponding item belongs to
Behavior type:	A string, enum-type from ('pv', 'buy', 'cart', 'fav')
Timestamp:	An integer, the timestamp of the behavior

Behavior:
pv:	Page view of an item's detail page, equivalent to an item click
buy:	Purchase an item
cart:	Add an item to shopping cart
fav:	Favor an item
```

CSV format:<br>
```
/usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh --bootstrap-server wn0-kafkad:9092 --topic user_behavior_csv --from-beginning

1000488,2002034,883960,pv,1511867823
1000488,928518,4756105,pv,1511867934
1000488,2032668,1080785,pv,1511868247
1000488,2324504,4801426,pv,1511868288
1000488,2147704,4818107,pv,1511868587
```

**Transform csv to Json on Flink SQL** <br>
```
bin/sql-client.sh -j flink-connector-jdbc-1.16.0.jar -j flink-connector-kafka-1.16.0.jar -j flink-sql-connector-elasticsearch7-1.16.0.jar -j kafka-clients-3.2.0.jar -j mysql-connector-j-8.0.33.jar
```

```
CREATE CATALOG myhive WITH (
    'type' = 'hive'
);

USE CATALOG myhive;

CREATE TABLE kafka_user_behavior_csv (
    user_id BIGINT,
    item_id BIGINT,
    category_id BIGINT,
    behavior STRING,
    ts BIGINT,
    ts1 AS TO_TIMESTAMP(FROM_UNIXTIME(`ts`)),
    proctime AS PROCTIME(),
    WATERMARK FOR ts1 AS ts1 - INTERVAL '5' SECOND 
) WITH (
    'connector' = 'kafka', 
    'topic' = 'user_behavior_csv',
    'scan.startup.mode' = 'earliest-offset',
    'properties.bootstrap.servers'='<broker1>:96,<broker2>:9092,<broker3>:9092',
    'format' = 'csv');


CREATE TABLE kafka_user_behavior_json (
    user_id BIGINT,
    item_id BIGINT,
    category_id BIGINT,
    behavior STRING,
    ts TIMESTAMP(3),
    PRIMARY KEY (user_id) NOT ENFORCED
) WITH (
   'connector' = 'upsert-kafka', 
   'topic' = 'user_behavior_json',
   'properties.bootstrap.servers'='<broker1>:96,<broker2>:9092,<broker3>:9092',
   'key.format' = 'json',
   'value.format' = 'json'
);

insert into kafka_user_behavior_json select user_id,item_id,category_id,behavior,ts1 from kafka_user_behavior_csv;
/usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh --bootstrap-server wn0-kafkad:9092 --topic user_behavior_json --from-beginning
```

**Json format:**
```
/usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh --bootstrap-server wn0-kafkad:9092 --topic user_behavior_json --from-beginning

{"user_id":1002271,"item_id":1373369,"category_id":2939262,"behavior":"pv","ts":"2017-11-24 16:50:32"}
{"user_id":1002271,"item_id":495551,"category_id":4082778,"behavior":"pv","ts":"2017-11-24 16:51:15"}
{"user_id":1002271,"item_id":4183036,"category_id":4148053,"behavior":"pv","ts":"2017-11-24 16:51:42"}
{"user_id":1002271,"item_id":4257740,"category_id":4082778,"behavior":"pv","ts":"2017-11-24 16:53:46"}
{"user_id":1002271,"item_id":1864347,"category_id":4756105,"behavior":"pv","ts":"2017-11-24 16:56:12"}
{"user_id":1002271,"item_id":4227780,"category_id":2558244,"behavior":"pv","ts":"2017-11-24 16:56:36"}
```

## Real-world scenarios


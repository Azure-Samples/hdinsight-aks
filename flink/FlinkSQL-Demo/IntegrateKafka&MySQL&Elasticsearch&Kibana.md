
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

Run the following DDL statement in SQL CLI to create a table that connects to the topic in the Kafka cluster:

``` SQL
CREATE TABLE kafka_user_behavior (
    user_id BIGINT,
    item_id BIGINT,
    category_id BIGINT,
    behavior STRING,
    ts TIMESTAMP(3),
    proctime AS PROCTIME(),   -- generates processing-time attribute using computed column
    WATERMARK FOR ts AS ts - INTERVAL '5' SECOND  -- generates processing-time attribute using computed column
) WITH (
    'connector' = 'kafka',  -- using kafka connector
    'topic' = 'user_behavior_json',  -- kafka topic
    'scan.startup.mode' = 'earliest-offset',  -- reading from the beginning
    'properties.bootstrap.servers'='<broker1>:96,<broker2>:9092,<broker3>:9092',  -- kafka broker address
    'format' = 'json');   -- the data format is json
select * from kafka_user_behavior;
```

The Above snippet declares five fields based on the data format. In addition, it uses the computed column syntax and built-in PROCTIME() function to declare a virtual column that generates the processing-time attribute. It also uses the WATERMARK syntax to declare the watermark strategy on the ts field (tolerate 5-seconds out-of-order). Therefore, the ts field becomes an event-time attribute.

After creating the kafka_user_behavior table in the SQL CLI, run **SHOW TABLES;** and **DESCRIBE kafka_user_behavior ;** to see registered tables and table details. Also, run the command **SELECT * FROM kafka_user_behavior ;** directly in the SQL CLI to preview the data (press q to exit).

**Hourly Trading Volume**

create an Elasticsearch result table in the SQL CLI. We need two columns in this case: hour_of_day and buy_cnt (trading volume).

There is no need to create the buy_cnt_per_hour index in Elasticsearch in advance since Elasticsearch will automatically create the index if it does not exist.

``` SQL
CREATE TABLE elastic_buy_cnt_per_hour (
    hour_of_day BIGINT,
    buy_cnt BIGINT
) WITH (
    'connector' = 'elasticsearch-7', -- using elasticsearch connector 
    'hosts' = 'http://10.0.0.7:9200',  -- elasticsearch address
    'index' = 'elastic_buy_cnt_per_hour'  -- elasticsearch index name, similar to database table name
);
```

The hourly trading volume is the number of “buy” behaviors completed each hour. Therefore, we can use a TUMBLE window function to assign data into hourly windows. Then, we count the number of “buy” records in each window. To implement this, we can filter out the “buy” data first and then apply COUNT(*).

Here, we use the built-in HOUR function to extract the value for each hour in the day from a TIMESTAMP column. Use INSERT INTO to start a Flink SQL job that continuously writes results into the Elasticsearch buy_cnt_per_hour index. The Elasticearch result table can be seen as a materialized view of the query.

``` SQL
INSERT INTO elastic_buy_cnt_per_hour
SELECT HOUR(TUMBLE_START(ts, INTERVAL '1' HOUR)), COUNT(*)
FROM kafka_user_behavior
WHERE behavior = 'buy'
GROUP BY TUMBLE(ts, INTERVAL '1' HOUR);
```

After running the previous query in the Flink SQL CLI, we can observe the submitted task on Flink WEB UI

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/8854c0ed-9f18-480e-b245-975ab0b52277)


Using Kibana to Visualize Results:

Access Kibana at http://<elasticsearch>:5601. First, configure an index pattern by clicking "Management" in the left-side toolbar and find "Index Patterns". Next, click "Create Index Pattern" and enter the full index name elastic_buy_cnt_per_hour to create the index pattern. After creating the index pattern, we can explore data in Kibana.

You can see that during 11:00~15:00 the number of transactions have the Highest value for the entire day.

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/e0c48451-376e-4eab-9739-09c31b384f28)

**Cumulative number of Unique Visitors every 10-min**

Let’s create another Elasticsearch table in the SQL CLI to store the UV results. This table contains 3 columns: date, time and cumulative UVs. The date_str and time_str column are defined as primary key, Elasticsearch sink will use them to calculate the document ID and work in upsert mode to update UV values under the document ID.

``` SQL
CREATE TABLE elastic_cumulative_uv(
    date_str STRING,
    time_str STRING,
    uv BIGINT,
    PRIMARY KEY (date_str, time_str) NOT ENFORCED
) WITH (
    'connector' = 'elasticsearch-7',
    'hosts' = 'http://10.0.0.7:9200',
    'index' = 'elastic_cumulative_uv'
);
```

We can extract the date and time using DATE_FORMAT function based on the ts field. As the section title describes, we only need to report every 10 minutes. So, we can use SUBSTR and the string concat function || to convert the time value into a 10-minute interval time string, such as 12:00, 12:10. Next, we group data by date_str and perform a COUNT DISTINCT aggregation on user_id to get the current cumulative UV in this day. Additionally, we perform a MAX aggregation on time_str field to get the current stream time: the maximum event time observed so far. As the maximum time is also a part of the primary key of the sink, the final result is that we will insert a new point into the elasticsearch every 10 minute. And every latest point will be updated continuously until the next 10-minute point is generated.
``` SQL
INSERT INTO elastic_cumulative_uv
SELECT date_str, MAX(time_str), COUNT(DISTINCT user_id) as uv
FROM (
  SELECT
    DATE_FORMAT(ts, 'yyyy-MM-dd') as date_str,
    SUBSTR(DATE_FORMAT(ts, 'HH:mm'),1,4) || '0' as time_str,
    user_id
  FROM kafka_user_behavior)
GROUP BY date_str,time_str;
```
On Flink WEB UI:
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/36261870-288f-4475-ba52-2cce0bb3057d)


After submitting this query, we create an elastic_cumulative_uv index pattern in Kibana. We then create a “Line” (line graph) on the dashboard, by selecting the elastic_cumulative_uv index, and drawing the cumulative UV curve according to the configuration on the left side of the following figure before finally saving the curve.

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/7ec724f7-4253-4d14-af68-d97671c6486d)


**Top Categories**

The last visualization represents the category rankings to inform us on the most popular categories in our e-commerce site. Since our data source offers events for more than 5,000 categories without providing any additional significance to our analytics, we would like to reduce it so that it only includes the top-level categories. We will use the data in our MySQL database by joining it as a dimension table with our Kafka events to map sub-categories to top-level categories.

Create a table in the SQL CLI to make the data in MySQL accessible to Flink SQL.

The underlying JDBC connector implements the LookupTableSource interface, so the created JDBC table category_dim can be used as a temporal table (i.e. lookup table) out-of-the-box in the data enrichment.

``` SQL
CREATE TABLE category_dim (
    sub_category_id BIGINT,
    parent_category_name STRING
) WITH (
  'connector' = 'jdbc',
  'url' = 'jdbc:mysql://<mysql server>.mysql.database.azure.com:3306/mydb',
  'table-name' = 'category',
  'username' = '<Username>',
  'password' = '<Password>',
    'lookup.cache.max-rows' = '5000',
    'lookup.cache.ttl' = '10min'
);
```

In addition, create an Elasticsearch table to store the category statistics.

``` SQL
CREATE TABLE top_category (
    category_name STRING PRIMARY KEY NOT ENFORCED,
    buy_cnt BIGINT
) WITH (
    'connector' = 'elasticsearch-7',
    'hosts' = 'http://10.0.0.7:9200',
    'index' = 'top_category'
);
```

In order to enrich the category names, we use Flink SQL’s temporal table joins to join a dimension table. You can access more information about temporal joins in the Flink documentation.

Additionally, we use the CREATE VIEW syntax to register the query as a logical view, allowing us to easily reference this query in subsequent queries and simplify nested queries. Please note that creating a logical view does not trigger the execution of the job and the view results are not persisted. Therefore, this statement is lightweight and does not have additional overhead.

``` SQL
CREATE VIEW rich_user_behavior AS
SELECT U.user_id, U.item_id, U.behavior, C.parent_category_name as category_name
FROM kafka_user_behavior AS U LEFT JOIN category_dim FOR SYSTEM_TIME AS OF U.proctime AS C
ON U.category_id = C.sub_category_id;
```

Finally, we group the dimensional table by category name to count the number of buy events and write the result to Elasticsearch’s top_category index.
``` SQL
INSERT INTO top_category
SELECT category_name, COUNT(*) buy_cnt
FROM rich_user_behavior
WHERE behavior = 'buy'
GROUP BY category_name;
```

on Flink WEB UI:
![image.png](/.attachments/image-2cc91f4b-7d80-4d7b-b6ab-0c32ed865571.png)

After submitting the query, we create a top_category index pattern in Kibana. We then create a “Horizontal Bar” (bar graph) on the dashboard, by selecting the top_category index and drawing the category ranking according to the configuration on the left side of the following diagram before finally saving the list.

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/27b1e3c9-0833-4793-86b8-a9834067335e)



## Ref
https://flink.apache.org/2020/07/28/flink-sql-demo-building-an-end-to-end-streaming-application/

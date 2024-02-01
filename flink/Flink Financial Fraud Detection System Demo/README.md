## What is Real-Time Streaming Processing and why is it important?

Real-time streaming processing involves the immediate ingestion of data from a source, its subsequent processing, and the delivery of valuable insights to a destination. 
This stands in contrast to traditional batch processing, which handles static data sets. Streaming processing allows organizations to interpret data as it comes in, 
offering a dynamic and immediate method for data analysis. In certain scenarios, it’s vital to make decisions based on real-time data flow processing, and the insights 
derived from this processing can have significant business impacts. The advantage of a real-time streaming approach is the ability to instantly identify or respond to changes, 
events, or trends as they happen, facilitating quicker decision-making and more prompt responses. 
Although we refer to it as “real-time”, it actually occurs near real-time with a slight delay of a few milliseconds.

## What is Apache Flink® in Azure HDInsight on AKS?

Apache Flink clusters in HDInsight on AKS are a fully managed service. <br>
See more about [Apache Flink clusters in HDInsight on AKS](https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-overview)

Apache Flink is an excellent choice to develop and run many different types of applications due to its extensive features set. Flink’s features include support for stream and batch processing, sophisticated state management, event-time processing semantics, and exactly once consistency guarantees for state. Flink doesn't have a single point of failure. Flink has been proven to scale to thousands of cores and terabytes of application state, delivers high throughput and low latency, and powers some of the world’s most demanding stream processing applications.

• **Fraud detection**: Flink can be used to detect fraudulent transactions or activities in real time by applying complex rules and machine learning models on streaming data.<br>
• **Anomaly detection**: Flink can be used to identify outliers or abnormal patterns in streaming data, such as sensor readings, network traffic, or user behavior.<br>
• **Rule-based alerting**: Flink can be used to trigger alerts or notifications based on predefined conditions or thresholds on streaming data, such as temperature, pressure, or stock prices.<br>
• **Business process monitoring**: Flink can be used to track and analyze the status and performance of business processes or workflows in real time, such as order fulfillment, delivery, or customer service.<br>
• **Web application (social network)**: Flink can be used to power web applications that require real-time processing of user-generated data, such as messages, likes, comments, or recommendations.<br>

## What is Change Data Capture(CDC)

CDC Connectors for Apache Flink® is a set of source connectors for Apache Flink®, ingesting changes from different databases using change data capture (CDC). 
The CDC Connectors for Apache Flink® integrate Debezium as the engine to capture data changes. So it can fully leverage the ability of Debezium. 
See more about what is [Debezium](https://github.com/debezium/debezium).

## What is Flink MySQL CDC Connector
Flink supports to interpret Debezium JSON and Avro messages as INSERT/UPDATE/DELETE messages into Apache Flink SQL system.

See more about what is [MySQL CDC Connector](https://ververica.github.io/flink-cdc-connectors/master/content/connectors/mysql-cdc.html)

The MySQL CDC connector is a Flink Source connector, which allows for reading snapshot data and incremental data from MySQL database
with exactly once processing even failures happen. 

## Design Financial Real-time Fraud Detection based on CDC(Change Data Capture) technology and Flink Real Time Data Streaming processing

In this demo, our objective is to construct a financial fraud detection system that operates in real-time (or near real-time). 
This system will pinpoint suspicious transaction activities for each individual user within a sliding window of one hour, 
particularly focusing on transactions occurring in different countries. 
Upon detecting any suspicious activities, we will display them on our analytics dashboard. 
Additionally, we will alert the user by sending a push notification and an email. 
Concurrently, we will update the “suspicious_activities” flag in the user_profile to “true” to prevent further transactions.

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/83d120b0-c7f9-4b1a-82e8-f0a7e4b74577)

Here’s a step-by-step explanation:<br>
1. Payment User Profile and Transactions: The process starts with user profile and transaction data, which are stored and processed in MySQL database. <br>
2. Flink Datastream API to use MySQL CDC Connector to capture MySQL table binlog: store binlogs of payment.transactions and payment.user_profile table in MySQL database to Kafka topics. <br>
3. Flink SQL to join payment.transactions and payment.user_profile by userId: join result sinks to a "transaction_mid" intermediate Kafka topic  <br>
4. Flink DataStream API to set 'user_suspicious_activity' flag:  "transaction_mid" intermediate Kafka topic as a source, aggregate transaction amounts for each user over 1 hour window, mark user profile’s 'user_suspicious_activity' flag, and sink to "suspicious_activities" Kafka destination topic and ADLS gen2 <br>
5. Consumers of destination topic: After we detected suspicious activity for each individual user and published this activity to "suspicious_activities" kafka topic and ADLS gen2, it can be used for analytics service and notification service.

## Prerequisites
• HDInsight Flink 1.16.0 on AKS
• HDInsight Kafka 3.2.0
• Use MSI to access ADLSgen2
• HDInsight Flink on AKS and HDInsight Kafka are in the same Vnet
• Maven project development on Azure VM in the same Vnet  
• MySQL 8.0 on Azure 

## Payment User Profile and Transactions in MySQL Database:

``` SQL
mysql> use payment;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> show tables;
+-------------------+
| Tables_in_payment |
+-------------------+
| transactions      |
| user_profile      |
+-------------------+
2 rows in set (0.23 sec)

mysql> describe user_profile;
+---------------------+-----------------+------+-----+---------+--------------------------+
| Field               | Type            | Null | Key | Default | Extra                    |
+---------------------+-----------------+------+-----+---------+--------------------------+
| my_row_id           | bigint unsigned | NO   | PRI | NULL    | auto_increment INVISIBLE |
| id                  | int             | YES  |     | NULL    |                          |
| name                | varchar(50)     | YES  |     | NULL    |                          |
| surname             | varchar(50)     | YES  |     | NULL    |                          |
| middle_name         | varchar(50)     | YES  |     | NULL    |                          |
| phone_number        | varchar(20)     | YES  |     | NULL    |                          |
| mail_address        | varchar(100)    | YES  |     | NULL    |                          |
| suspicious_activity | tinyint(1)      | YES  |     | NULL    |                          |
+---------------------+-----------------+------+-----+---------+--------------------------+
8 rows in set (0.23 sec)

mysql> describe transactions;
+-----------+-----------------+------+-----+---------+--------------------------+
| Field     | Type            | Null | Key | Default | Extra                    |
+-----------+-----------------+------+-----+---------+--------------------------+
| my_row_id | bigint unsigned | NO   | PRI | NULL    | auto_increment INVISIBLE |
| user_id   | int             | YES  |     | NULL    |                          |
| amount    | decimal(10,4)   | YES  |     | NULL    |                          |
| currency  | char(3)         | YES  |     | NULL    |                          |
| type      | varchar(20)     | YES  |     | NULL    |                          |
| country   | varchar(50)     | YES  |     | NULL    |                          |
| timestamp | varchar(50)     | YES  |     | NULL    |                          |
+-----------+-----------------+------+-----+---------+--------------------------+
7 rows in set (0.23 sec)
```
## Flink Datastream API to use MySQL CDC Connector to capture MySQL table binlog

**sink payment.user_profile and payment.transaction binlog to kafka** <br>

``` java
        String kafka_brokers = "<Kafka broker list:9092>";

        // configure a JSON converter to format decimal numbers as numeric values.
        Map<String, Object> customConverterConfigs = new HashMap<>();
        customConverterConfigs.put(JsonConverterConfig.DECIMAL_FORMAT_CONFIG, "numeric");

        // MySQL source
        MySqlSource<String> mySqlSource = MySqlSource.<String>builder()
                .hostname("<mysql hostname>")
                .port(<mysql port>)
                .databaseList("payment") //
                .tableList("payment.user_profile") //  // replace with payment.transaction
                .username("<user_name>")
                .password("<Password>")
                .deserializer(new JsonDebeziumDeserializationSchema(false,customConverterConfigs)) //
                .build();

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        // set checkpoint interval: 3s
        env.enableCheckpointing(3000);

        DataStreamSource<String> stream = env.fromSource(mySqlSource, WatermarkStrategy.noWatermarks(), "MySQL Source")
                .setParallelism(1);

        // 3. sink table user_profile binlog to kafka
        KafkaSink<String> sink = KafkaSink.<String>builder()
                .setBootstrapServers(kafka_brokers)
                .setRecordSerializer(KafkaRecordSerializationSchema.builder()
                        .setTopic("user_profile")  // replace with transaction
                        .setValueSerializationSchema(new SimpleStringSchema())
                        .build()
                )
                .setDeliveryGuarantee(DeliveryGuarantee.EXACTLY_ONCE)
                .build();

        stream.sinkTo(sink);
```
**submit above jar to cluster to run** <br>

on Azure HDInsight Flink on AKS cluster webssh pob
```
example:
bin/flink run -c contoso.example.MySqlBinlogSinkToKafka2 -j FlinkMysqCDCSinkToKafka-1.0-SNAPSHOT.jar
bin/flink run -c contoso.example.MySqlBinlogSinkToKafka1 -j FlinkMysqCDCSinkToKafka-1.0-SNAPSHOT.jar
```

**consume topics on Kafka cluster** 
```
/usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh --bootstrap-server wn0-contos:9092 --topic user_profile --from-beginning
/usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh --bootstrap-server wn0-contos:9092 --topic transactions --from-beginning
```

**payment.user_profile topic description**
``` json
//lets assume json in the below describes data inside offset-0
{
  "before": null,
  "after": {
    "my_row_id": 6,
    "id": 1,
    "name": "John",
    "surname": "Doe",
    "middle_name": "Smith",
    "phone_number": "+372 12345678",
    "mail_address": "john.doe@gmail.com",
    "suspicious_activity": 0
  },
  "source": {
    "version": "1.6.4.Final",
    "connector": "mysql",
    "name": "mysql_binlog_source",
    "ts_ms": 1706699263000,
    "snapshot": "false",
    "db": "payment",
    "sequence": null,
    "table": "user_profile",
    "server_id": 3260756151,
    "gtid": null,
    "file": "mysql-bin.000008",
    "pos": 29000,
    "row": 0,
    "thread": null,
    "query": null
  },
  "op": "c",
  "ts_ms": 1706699263778,
  "transaction": null
}
```
**payment.transaction topic description**
``` json
//lets assume json in the below describes data inside offset-1
{
  "before": null,
  "after": {
    "my_row_id": 20,
    "user_id": 1,
    "amount": 5,
    "currency": "EUR",
    "type": "purchase",
    "country": "Estonia",
    "timestamp": "2024-01-31 06:10:00"
  },
  "source": {
    "version": "1.6.4.Final",
    "connector": "mysql",
    "name": "mysql_binlog_source",
    "ts_ms": 1706699441000,
    "snapshot": "false",
    "db": "payment",
    "sequence": null,
    "table": "transactions",
    "server_id": 3260756151,
    "gtid": null,
    "file": "mysql-bin.000008",
    "pos": 30587,
    "row": 0,
    "thread": null,
    "query": null
  },
  "op": "c",
  "ts_ms": 1706699441991,
  "transaction": null
}
```
``` json
//lets assume json in the below describes data inside offset-2
{
  "before": null,
  "after": {
    "my_row_id": 23,
    "user_id": 1,
    "amount": 20000,
    "currency": "EUR",
    "type": "purchase",
    "country": "Netherland",
    "timestamp": "2024-01-31 06:20:00"
  },
  "source": {
    "version": "1.6.4.Final",
    "connector": "mysql",
    "name": "mysql_binlog_source",
    "ts_ms": 1706699739000,
    "snapshot": "false",
    "db": "payment",
    "sequence": null,
    "table": "transactions",
    "server_id": 3260756151,
    "gtid": null,
    "file": "mysql-bin.000008",
    "pos": 31682,
    "row": 0,
    "thread": null,
    "query": null
  },
  "op": "c",
  "ts_ms": 1706699739685,
  "transaction": null
}
```

**main jar in Maven**
``` xml
    <properties>
        <maven.compiler.source>1.8</maven.compiler.source>
        <maven.compiler.target>1.8</maven.compiler.target>
        <flink.version>1.16.0</flink.version>
        <java.version>1.8</java.version>
        <scala.binary.version>2.12</scala.binary.version>
        <kafka.version>3.2.0</kafka.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-java</artifactId>
            <version>${flink.version}</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.apache.flink/flink-streaming-java -->
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-streaming-java</artifactId>
            <version>${flink.version}</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.apache.flink/flink-clients -->
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-clients</artifactId>
            <version>${flink.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-connector-kafka</artifactId>
            <version>${flink.version}</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/com.ververica/flink-connector-mysql-cdc -->
        <dependency>
            <groupId>com.ververica</groupId>
            <artifactId>flink-connector-mysql-cdc</artifactId>
            <version>2.3.0</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/io.debezium/debezium-embedded -->
        <dependency>
            <groupId>io.debezium</groupId>
            <artifactId>debezium-core</artifactId>
            <version>1.6.4.Final</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/com.ververica/flink-connector-debezium -->
        <dependency>
            <groupId>com.ververica</groupId>
            <artifactId>flink-connector-debezium</artifactId>
            <version>2.3.0</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/io.debezium/debezium-connector-mysql -->
        <dependency>
            <groupId>io.debezium</groupId>
            <artifactId>debezium-connector-mysql</artifactId>
            <version>1.6.4.Final</version>
        </dependency>
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
            <version>2.13.1</version>
        </dependency>
        <dependency>
            <groupId>org.json</groupId>
            <artifactId>json</artifactId>
            <version>20210307</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.apache.flink/flink-table-common -->
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-table-common</artifactId>
            <version>${flink.version}</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.apache.flink/flink-table-planner -->
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-table-planner_2.12</artifactId>
            <version>${flink.version}</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.apache.flink/flink-table-api-scala -->
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-table-api-scala_2.12</artifactId>
            <version>${flink.version}</version>
        </dependency>
        <dependency>
            <groupId>com.fasterxml.jackson.datatype</groupId>
            <artifactId>jackson-datatype-jsr310</artifactId>
            <version>2.12.3</version> <!-- Use the version compatible with your project -->
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.apache.flink/flink-connector-files -->
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-connector-files</artifactId>
            <version>${flink.version}</version>
        </dependency>
```
## Flink SQL to join payment.transactions and payment.user_profile kafka topic by userId

**Prepare jar** 
```
wget https://repo1.maven.org/maven2/org/apache/flink/flink-connector-jdbc/1.16.0/flink-connector-jdbc-1.16.0.jar
wget https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar
wget https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.2.0/kafka-clients-3.2.0.jar
wget https://repo1.maven.org/maven2/org/apache/flink/flink-connector-kafka/1.16.0/flink-connector-kafka-1.16.0.jar
```

**Flink SQL Client on Cluster webssh** 
```
bin/sql-client.sh -j kafka-clients-3.2.0.jar -j flink-connector-kafka-1.16.0.jar -j flink-connector-jdbc-1.16.0.jar  -j mysql-connector-j-8.0.33.jar
```

**join payment.transactions and payment.user_profile kafka topic and store the join result to transaction_mid intermediate Kafka topic**
``` SQL
CREATE TABLE user_profile (
  my_row_id BIGINT,
  id BIGINT,
  name STRING,
  surname STRING,
  middle_name STRING,
  phone_number STRING,
  mail_address STRING,
  suspicious_activity BOOLEAN
) WITH (
  'connector' = 'kafka',
  'topic' = 'user_profile',
  'properties.group.id' = 'mygroup1',
  'properties.bootstrap.servers' = '<kafka broker list:9092>',
  'format' = 'debezium-json',
  'scan.startup.mode' = 'earliest-offset'
);

CREATE TABLE transactions (
  `my_row_id` BIGINT,
  `user_id` BIGINT,
  `amount` STRING,
  `currency` STRING,
  `type` STRING,
  `country` STRING,
  `timestamp` TIMESTAMP(3),
  WATERMARK FOR `timestamp` AS `timestamp` - INTERVAL '5' SECOND 
) WITH (
  'connector' = 'kafka',
  'topic' = 'transactions',
  'properties.group.id' = 'mygroup2',
  'properties.bootstrap.servers' = '<kafka broker list:9092>',
  'format' = 'debezium-json',
  'scan.startup.mode' = 'earliest-offset'
);


CREATE TABLE transaction_mid (
   user_id BIGINT,
   user_name STRING,
   user_surname STRING,
   user_middle_name STRING,
   user_phone_number STRING,
   user_mail_address STRING,
   user_suspicious_activity BOOLEAN,
   transaction_amount STRING, 
   transaction_currency STRING,
   transaction_type STRING,
   transaction_country STRING,
   transaction_timestamp TIMESTAMP(3),
   PRIMARY KEY (user_id) NOT ENFORCED
 ) WITH (
   'connector' = 'upsert-kafka',
   'topic' = 'transaction_mid',
   'properties.bootstrap.servers' = '<kafka broker list:9092>',
   'key.format' = 'json',
   'value.format' = 'json'
 );

INSERT INTO transaction_mid
 SELECT
   t.user_id,
   u.name AS user_name,
   u.surname AS user_surname,
   u.middle_name AS user_middle_name,
   u.phone_number AS user_phone_number,
   u.mail_address AS user_mail_address,
   u.suspicious_activity AS user_suspicious_activity,
  CAST(t.amount AS STRING) AS transaction_amount,
   t.currency AS transaction_currency,
   t.type AS transaction_type,
   t.country AS transaction_country,
   t.`timestamp` AS transaction_timestamp
 FROM transactions t
 JOIN user_profile u ON t.user_id = u.id;
```

**consume transaction_mid on Kafka cluster** 

```
/usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh --bootstrap-server wn0-contos:9092 --topic transaction_mid --from-beginning
```

``` json
{
  "user_id": 17,
  "user_name": "Jay",
  "user_surname": "Doe",
  "user_middle_name": "Smith",
  "user_phone_number": "+372 12345694",
  "user_mail_address": "jay.doe@gmail.com",
  "user_suspicious_activity": false,
  "transaction_amount": "10000.0",
  "transaction_currency": "EUR",
  "transaction_type": "purchase",
  "transaction_country": "Poland",
  "transaction_timestamp": "2024-01-31 07:33:00"
}
```

``` json
{
  "user_id": 17,
  "user_name": "Jay",
  "user_surname": "Doe",
  "user_middle_name": "Smith",
  "user_phone_number": "+372 12345694",
  "user_mail_address": "jay.doe@gmail.com",
  "user_suspicious_activity": false,
  "transaction_amount": "20000.0",
  "transaction_currency": "EUR",
  "transaction_type": "purchase",
  "transaction_country": "Netherland",
  "transaction_timestamp": "2024-01-31 07:32:00"
}
```

## Flink DataStream API to set 'user_suspicious_activity' flag
Now. let's read "transaction_mid" intermediate Kafka topic as a source, aggregate transaction amounts for each user over 1 hour window, mark user profile’s 'user_suspicious_activity' flag , then sink to "suspicious_activities" Kafka destination topic and ADLS gen2 <br>

**Fraud rule:**
Each user within hour purchased more than 30000 EUR in different countries this case will be assumed as fraud case and user profile’s ”suspicious_activity” flag will be enabled and future transactions will be blocked for this user.

``` java
KafkaSource<String> source = KafkaSource.<String>builder()
                .setBootstrapServers(kafka_brokers)
                .setTopics("transaction_mid")
                .setGroupId("my-group")
                .setStartingOffsets(OffsetsInitializer.earliest())
                .setValueOnlyDeserializer(new SimpleStringSchema())
                .build();

        DataStream<String> stream = env.fromSource(source, WatermarkStrategy.noWatermarks(), "Kafka Source");

        // 3. transformation:
        SingleOutputStreamOperator<Transaction> transactions = stream.map(new MapFunction<String, Transaction>() {
            @Override
            public Transaction map(String value) throws Exception {
                ObjectMapper objectMapper = new ObjectMapper();
                Transaction transaction = objectMapper.readValue(value, Transaction.class);
                return transaction;
            }
        });

        KeyedStream<Transaction, Long> keyed = transactions.keyBy(transaction -> transaction.user_id);
        WindowedStream<Transaction, Long, TimeWindow> windowed = keyed.window(TumblingProcessingTimeWindows.of(Time.hours(1)));

        SingleOutputStreamOperator<String> result = windowed.apply(new WindowFunction<Transaction, String, Long, TimeWindow>() {
            @Override
            public void apply(Long userId, TimeWindow window, Iterable<Transaction> transactions, Collector<String> out) throws Exception {
                BigDecimal totalAmount = BigDecimal.ZERO;
                Set<String> countries = new HashSet<>();
                String user_id = null;
                String user_name = null;
                String user_surname = null;
                String user_middle_name = null;
                String user_phone_number = null;
                String user_mail_address = null;
                Boolean user_suspicious_activity = false;
                String transaction_currency = null;

                for (Transaction transaction : transactions) {
                    totalAmount = totalAmount.add(transaction.transaction_amount);
                    countries.add(transaction.transaction_country);
                    user_id = String.valueOf(transaction.user_id);
                    user_surname = transaction.user_surname;
                    user_middle_name = transaction.user_middle_name;
                    user_phone_number = transaction.user_phone_number;
                    user_mail_address = transaction.user_mail_address;
                    transaction_currency = transaction.transaction_currency;
                }

                if (totalAmount.compareTo(new BigDecimal("30000")) > 0 && countries.size() > 1) {
                    user_suspicious_activity = true;
                }

                JSONObject json = new JSONObject();
                json.put("user_id", user_id);
                json.put("user_name", user_name);
                json.put("user_surname", user_surname);
                json.put("user_middle_name", user_middle_name);
                json.put("user_phone_number", user_phone_number);
                json.put("user_mail_address", user_mail_address);
                json.put("user_suspicious_activity", user_suspicious_activity);
                json.put("transaction_amount", totalAmount);
                json.put("transaction_currency", transaction_currency);
                json.put("transaction_countries", new JSONArray(countries));
                json.put("window_start_time", window.getStart());
                json.put("window_end_time", window.getEnd());

                out.collect(json.toString());
            }
        }
        );

        // 4.1 sink to suspicious_activities kafka topic
        KafkaSink<String> sinkToKafka = KafkaSink.<String>builder()
                .setBootstrapServers(kafka_brokers)
                .setProperty("transaction.timeout.ms","900000")
                .setRecordSerializer(KafkaRecordSerializationSchema.builder()
                        .setTopic("suspicious_activities")
                        .setValueSerializationSchema(new SimpleStringSchema())
                        .build())
                .setDeliveryGuarantee(DeliveryGuarantee.EXACTLY_ONCE)
                .build();

        // 4.2 sink to ADLS gen2
        String outputPath  = "abfs://<container>@<storage_account_name>.dfs.core.windows.net/flink/suspicious_activities";
        final FileSink<String> sinkToGen2 = FileSink
                .forRowFormat(new Path(outputPath), new SimpleStringEncoder<String>("UTF-8"))
                .withRollingPolicy(
                        DefaultRollingPolicy.builder()
                                .withRolloverInterval(Duration.ofMinutes(2))
                                .withInactivityInterval(Duration.ofMinutes(3))
                                .withMaxPartSize(MemorySize.ofMebiBytes(5))
                                .build())
                .build();

        result.sinkTo(sinkToKafka);
        result.sinkTo(sinkToGen2);
```

**submit above jar to cluster to run** <br>
```
bin/flink run -c contoso.example.SuspiciousActivities -j FlinkMysqCDCSinkToKafka-1.0-SNAPSHOT.jar
```

**checking job on Flink UI Dashboard** <br>

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/b644d71f-040f-4d7b-895c-99a38bc0f987)


**consume suspicious_activities on Kafka cluster** 

```
/usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh --bootstrap-server wn0-contos:9092 --topic transaction_mid --from-beginning
```

``` json
//lets check "user_id": "1" json data: "user_suspicious_activity": true as  "transaction_amount": 40010 > 30000
{
  "user_suspicious_activity": true,
  "user_phone_number": "+372 12345678",
  "window_end_time": 1706709600000,
  "user_id": "1",
  "transaction_countries": [
    "Netherland",
    "Estonia"
  ],
  "transaction_amount": 40010,
  "user_surname": "Doe",
  "user_middle_name": "Smith",
  "window_start_time": 1706706000000,
  "user_mail_address": "john.doe@gmail.com",
  "transaction_currency": "EUR"
}
```

``` json
//lets check "user_id": "17" json data: "user_suspicious_activity": true as  "transaction_amount": 34005 > 30000
{
  "user_suspicious_activity": true,
  "user_phone_number": "+372 12345694",
  "window_end_time": 1706709600000,
  "user_id": "17",
  "transaction_countries": [
    "Netherland",
    "Poland",
    "Estonia"
  ],
  "transaction_amount": 40010,
  "user_surname": "Doe",
  "user_middle_name": "Smith",
  "window_start_time": 1706706000000,
  "user_mail_address": "jay.doe@gmail.com",
  "transaction_currency": "EUR"
}
```

``` json
//lets check "user_id": "5" json data: "user_suspicious_activity": false as  "transaction_amount": 5
{
  "user_suspicious_activity": false,
  "user_phone_number": "+372 12345682",
  "window_end_time": 1706709600000,
  "user_id": "5",
  "transaction_countries": [
    "Estonia"
  ],
  "transaction_amount": 5,
  "user_surname": "Doe",
  "user_middle_name": "Smith",
  "window_start_time": 1706706000000,
  "user_mail_address": "jack.doe@gmail.com",
  "transaction_currency": "EUR"
}
```

**check result on ADLS gen2 on Azure portal**

**data in MySQL for reference**
``` SQL
mysql> select user_id, sum(amount) from transactions group by user_id;
+---------+-------------+
| user_id | sum(amount) |
+---------+-------------+
|       1 |  40010.0000 |
|       2 |   3500.0000 |
|       3 |  12505.0000 |
|       4 |      5.0000 |
|       5 |      5.0000 |
|       6 |      5.0000 |
|       7 |      5.0000 |
|       8 |      5.0000 |
|       9 |      5.0000 |
|      10 |      5.0000 |
|      11 |      5.0000 |
|      12 |      5.0000 |
|      13 |      5.0000 |
|      14 |      5.0000 |
|      15 |      5.0000 |
|      16 |      5.0000 |
|      17 |  34005.0000 |
|      18 |      5.0000 |
|      19 |      5.0000 |
|      20 |      5.0000 |
+---------+-------------+
20 rows in set (0.24 sec)
```
## Clean up the resource
• HDInsight Flink 1.16.0 on AKS <br>
• HDInsight Kafka 3.2.0 <br>
• ADLSgen2 <br>
• MySQL 8.0 on Azure <br>


This example uses Kafka SQL Connector to create a Kafka table on FLINK SQL.

## What is Kafka SQL Connector on Flink

The Kafka connector allows for reading data from and writing data into Kafka topics.

https://nightlies.apache.org/flink/flink-docs-master/docs/connectors/table/kafka/

## Prerequisites
•	HDInsight Kafka 3.2.0<br>
•	HDInsight Flink 1.16.0 on AKS<br>

## How to Create a Kafka table on Flink SQL
### Step1: prepare topic and data on HDInsight Kafka

--  prepare message weblog.py
<br>
``` py

user_set = [
        'John',
        'XiaoMing',
        'Mike',
        'Tom',
        'Machael',
        'Zheng Hu',
        'Zark',
        'Tim',
        'Andrew',
        'Pick',
        'Sean',
        'Luke',
        'Chunck'
]

web_set = [
        'https://google.com',
        'https://facebook.com?id=1',
        'https://tmall.com',
        'https://baidu.com',
        'https://taobao.com',
        'https://aliyun.com',
        'https://apache.com',
        'https://flink.apache.com',
        'https://hbase.apache.com',
        'https://github.com',
        'https://gmail.com',
        'https://stackoverflow.com',
        'https://python.org'
]

def main():
        while True:
                if random.randrange(10) < 4:
                        url = random.choice(web_set[:3])
                else:
                        url = random.choice(web_set)

                log_entry = {
                        'userName': random.choice(user_set),
                        'visitURL': url,
                        'ts': datetime.now().strftime("%m/%d/%Y %H:%M:%S")
                }

                print(json.dumps(log_entry))
                time.sleep(0.05)

if __name__ == "__main__":
    main()
```
--  pipline to Kafka topic
<br>


```
sshuser@hn0-contsk:~$ python weblog.py | /usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh --bootstrap-server wn0-contsk:9092 --topic click_events

```

**otehr commands on Kafka**
<br>

```
-- create topic
/usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create --replication-factor 2 --partitions 3 --topic click_events --bootstrap-server wn0-contsk:9092

-- delete topic
/usr/hdp/current/kafka-broker/bin/kafka-topics.sh --delete  --topic click_events --bootstrap-server wn0-contsk:9092

-- consume topic
sshuser@hn0-contsk:~$ /usr/hdp/current/kafka-broker/bin/kafka-console-consumer.sh --bootstrap-server wn0-contsk:9092 --topic click_events --from-beginning
{"userName": "Luke", "visitURL": "https://flink.apache.com", "ts": "06/26/2023 14:33:43"}
{"userName": "Tom", "visitURL": "https://stackoverflow.com", "ts": "06/26/2023 14:33:43"}
{"userName": "Chunck", "visitURL": "https://google.com", "ts": "06/26/2023 14:33:44"}
{"userName": "Chunck", "visitURL": "https://facebook.com?id=1", "ts": "06/26/2023 14:33:44"}
{"userName": "John", "visitURL": "https://tmall.com", "ts": "06/26/2023 14:33:44"}
{"userName": "Andrew", "visitURL": "https://facebook.com?id=1", "ts": "06/26/2023 14:33:44"}
{"userName": "John", "visitURL": "https://tmall.com", "ts": "06/26/2023 14:33:44"}
{"userName": "Pick", "visitURL": "https://google.com", "ts": "06/26/2023 14:33:44"}
{"userName": "Mike", "visitURL": "https://tmall.com", "ts": "06/26/2023 14:33:44"}
{"userName": "Zheng Hu", "visitURL": "https://tmall.com", "ts": "06/26/2023 14:33:44"}
{"userName": "Luke", "visitURL": "https://facebook.com?id=1", "ts": "06/26/2023 14:33:44"}
{"userName": "John", "visitURL": "https://flink.apache.com", "ts": "06/26/2023 14:33:44"}
.....
```


### Step2: download Kafka SQL Connector jar and Dependencies on webssh

```
wget https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.2.0/kafka-clients-3.2.0.jar
wget https://repo1.maven.org/maven2/org/apache/flink/flink-connector-kafka/1.16.0/flink-connector-kafka-1.16.0.jar
```

### Step3: webssh to Flink sql-client with Kafka SQL client jars

```
sshuser@pod-0 [ /opt/flink-webssh ]$ bin/sql-client.sh -j flink-connector-kafka-1.16.0.jar -j kafka-clients-3.2.0.jar
```

### Step4: create Kafka table on FLink SQL and select this table

``` sql
CREATE CATALOG myhive WITH (
    'type' = 'hive'
);

USE CATALOG myhive;


CREATE TABLE KafkaTable (
  `userName` STRING,
  `visitURL` STRING,
  `ts` TIMESTAMP(3) METADATA FROM 'timestamp'
) WITH (
  'connector' = 'kafka',
  'topic' = 'click_events',
  'properties.bootstrap.servers' = '10.0.0.38:9092,10.0.0.39:9092,10.0.0.40:9092',
  'properties.group.id' = 'my_group',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'json'
)

select * from KafkaTable;
``` 
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/5d200948-7199-4410-a883-9fab27a87d78)

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/7fce5365-da10-498a-b13b-2cc5073402a1)


### Step5: produce message on this topic on HDI Kafka side

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/42e25980-d8c0-4c60-9fb7-6c835cb11b79)


### Step6: monitor table data on FLINK sql

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/609052b7-6346-4757-8f96-9f6ccb163063)


**Streaming job on Flink UI:**

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/4028a443-46ff-4903-bab8-82ab4bd8da0d)



## Ref
https://nightlies.apache.org/flink/flink-docs-master/docs/connectors/table/kafka/<br>

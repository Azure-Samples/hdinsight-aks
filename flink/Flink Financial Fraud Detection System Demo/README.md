## What is Real-Time Streaming Processing and why is it important?

Real-time streaming processing involves the immediate ingestion of data from a source, its subsequent processing, and the delivery of valuable insights to a destination. 
This stands in contrast to traditional batch processing, which handles static data sets. Streaming processing allows organizations to interpret data as it comes in, 
offering a dynamic and immediate method for data analysis. In certain scenarios, it’s vital to make decisions based on real-time data flow processing, and the insights 
derived from this processing can have significant business impacts. The advantage of a real-time streaming approach is the ability to instantly identify or respond to changes, 
events, or trends as they happen, facilitating quicker decision-making and more prompt responses. 
Although we refer to it as “real-time”, it actually occurs near real-time with a slight delay of a few milliseconds.

## What is Apache Flink® in Azure HDInsight on AKS?

Apache Flink clusters in HDInsight on AKS are a fully managed service. <br>

https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-overview

Apache Flink is an excellent choice to develop and run many different types of applications due to its extensive features set. Flink’s features include support for stream and batch processing, sophisticated state management, event-time processing semantics, and exactly once consistency guarantees for state. Flink doesn't have a single point of failure. Flink has been proven to scale to thousands of cores and terabytes of application state, delivers high throughput and low latency, and powers some of the world’s most demanding stream processing applications.

**Fraud detection**: Flink can be used to detect fraudulent transactions or activities in real time by applying complex rules and machine learning models on streaming data.<br>
**Anomaly detection**: Flink can be used to identify outliers or abnormal patterns in streaming data, such as sensor readings, network traffic, or user behavior.<br>
**Rule-based alerting**: Flink can be used to trigger alerts or notifications based on predefined conditions or thresholds on streaming data, such as temperature, pressure, or stock prices.<br>
**Business process monitoring**: Flink can be used to track and analyze the status and performance of business processes or workflows in real time, such as order fulfillment, delivery, or customer service.<br>
**Web application (social network)**: Flink can be used to power web applications that require real-time processing of user-generated data, such as messages, likes, comments, or recommendations.<br>

## What is Change Data Capture(CDC)

CDC Connectors for Apache Flink® is a set of source connectors for Apache Flink®, ingesting changes from different databases using change data capture (CDC). 
The CDC Connectors for Apache Flink® integrate Debezium as the engine to capture data changes. So it can fully leverage the ability of Debezium. 
See more about what is [Debezium](https://github.com/debezium/debezium).

## What is Flink MySQL CDC Connector
Flink supports to interpret Debezium JSON and Avro messages as INSERT/UPDATE/DELETE messages into Apache Flink SQL system.

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
2. Flink MySQL CDC Connector: Using Flink Datastream API to store binlogs of payment.transactions and payment.user_profile table in MySQL database to a Kafka topic. <br>
3. Flink SQL: Join payment.transactions and payment.user_profile by the userId and sink to a "transaction_mid" intermediate Kafka topic  <br>
4. Flink DataStream: "transaction_mid" intermediate Kafka topic as a source, aggregate transaction amounts for each user over 1 hour window, mark user profile’s 'user_suspicious_activity' flag, and sink to "suspicious_activities" Kafka destination topic <br>
6. Consumers of destination topic: After we detected suspicious activity for each individual user and published this activity to "suspicious_activities" kafka topic, it can be used for analytics service and notification service.



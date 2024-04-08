---
page_type: sample
languages: java
products:
  - azure
  - azure-hdinsight-on-aks
description: "Examples in this repository demonstrate how to use the Kafka Consumer, Producer APIs with an OAuth based Kafka on HDInsight on AKS cluster."
urlFragment: hdinsight-aks
---

# Java-based example of using the Kafka Consumer and Producer APIs

The examples in this repository demonstrate how to use the Kafka Consumer, Producer APIs with an OAuth based Kafka on HDInsight on AKS cluster.

## Prerequisites

* Apache Kafka on AKS HDInsight cluster. To learn how to create the AKS Kafka cluster, see [Start with Apache Kafka on HDInsight AKS](https://learn.microsoft.com/en-us/azure/hdinsight-aks/quickstart-create-cluster).
* [Java Developer Kit (JDK) version 11](https://aka.ms/azure-jdks) or an equivalent, such as OpenJDK.
* [Apache Maven](https://maven.apache.org/download.cgi) properly [installed](https://maven.apache.org/install.html) according to Apache.  Maven is a project build system for Java projects.
* An SSH client like Putty.

## Understand the code

The application consists primarily of four files:
* `pom.xml`: This file defines the project dependencies, Java version, and packaging methods.
* `Producer.java`: This file sends random sentences to Kafka using the `producer` API.
* `Consumer.java`: This file uses the `consumer` API to read data from Kafka and emit it to `STDOUT`.
* `AdminClientWrapper.java`: This file uses the admin APIs to `create`, `describe`, and `delete` Kafka topics.
* `Run.java`: The command-line interface used to run the producer and consumer code.

### Pom.xml

The important things to understand in the `pom.xml` file are:

* **Dependencies:** This project relies on the Kafka producer and consumer APIs, which are provided by the `kafka-oauth-client` uber package. The following XML code defines this dependency:

```xml
<!-- Kafka oauth client for producer/consumer operations -->
<dependency>
  <groupId>com.microsoft.azure.hdinsight</groupId>
  <artifactId>kafka-oauth-client</artifactId>
  <version>${kafka.oauth.version}</version>
</dependency>
```

The `${kafka.oauth..version}` entry is declared in the `<properties>..</properties>` section of `pom.xml`, and is configured to the Kafka version of the HDInsight on AKS cluster.

* **Plugins:** Maven plugins provide various capabilities. In this project, the following plugins are used:
* `maven-compiler-plugin`: Used to set the Java version used by the project to 11. This is the version of Java used by HDInsight on AKS.
* `maven-shade-plugin`: Used to generate an uber jar that contains this application as well as any dependencies. It is also used to set the entry point of the application, so that you can directly run the Jar file without having to specify the main class.

### Producer.java

The producer communicates with the Kafka broker hosts (worker nodes) and sends data to a Kafka topic. The following code snippet is from the [Producer.java](https://github.com/Azure-Samples/hdinsight-aks/blob/main/kafka/kafka-oauth-producer-consumer/src/main/java/com/microsoft/example/Producer.java) file from the [GitHub repository](https://github.com/Azure-Samples/hdinsight-aks) and shows how to set the producer properties.

```java
Properties properties = getPropertiesFromFile(filePath);
properties.setProperty(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
properties.setProperty(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
```

### Consumer.java

The consumer communicates with the Kafka broker hosts (worker nodes), and reads records in a loop. The following code snippet from the [Consumer.java](https://github.com/Azure-Samples/hdinsight-aks/blob/main/kafka/kafka-oauth-producer-consumer/src/main/java/com/microsoft/example/Consumer.java) file sets the consumer properties.

```java
// Configure the consumer
Properties properties = getPropertiesFromFile(filePath);
// Set the consumer group (all consumers must belong to a group).
properties.setProperty(ConsumerConfig.GROUP_ID_CONFIG, groupId);
// Set how to serialize key/value pairs
properties.setProperty(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG,"org.apache.kafka.common.serialization.StringDeserializer");
properties.setProperty(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG,"org.apache.kafka.common.serialization.StringDeserializer");
// When a group is first created, it has no offset stored to start reading from. This tells it to start
// with the earliest record in the stream.
properties.setProperty(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG,"earliest");
properties.setProperty(ConsumerConfig.FETCH_MAX_BYTES_CONFIG,"10485880");
```

In this code, the consumer is configured to read from the start of the topic (`auto.offset.reset` is set to `earliest`.)

### Run.java

The [Run.java](https://github.com/Azure-Samples/hdinsight-aks/blob/main/kafka/kafka-oauth-producer-consumer/src/main/java/com/microsoft/example/Run.java) file provides a command-line interface that runs either the producer or consumer code. 
You must provide the `client.properties` file path as a parameter. 
You can optionally include a `group ID` value, which is used by the consumer process. 
If you create multiple consumer instances using the same `group ID`, they'll load balance reading from the topic.

## Use Pre-built JAR files

Download the jars from the [AKS Kafka Get Started Azure sample](https://github.com/Azure-Samples/hdinsight-aks/tree/main/kafka/Prebuilt-Jars).
Use the command below to copy the jars to your cluster.

```cmd
scp kafka-oauth-producer-consumer.jar sshuser@VM_Public_IP:kafka-oauth-producer-consumer.jar
```

## Build the JAR files from code

If you would like to skip this step, prebuilt jars can be downloaded from the `Prebuilt-Jars` subdirectory in kafka directory. <br>
Download the `kafka-oauth-producer-consumer.jar`. <br>
Execute step 4 to copy the jar to your client VM.

1. Download and extract the examples from [https://github.com/Azure-Samples/hdinsight-aks](https://github.com/Azure-Samples/hdinsight-aks).
2. Change directory to `kafka/kafka-oauth-producer-consumer`
3. Use the following command to build the application: `mvn clean package`. This command creates a directory named `target`, that contains a file named `kafka-oauth-producer-consumer-3.6.0-1.2.0-SNAPSHOT.jar`.
4. Copy `kafka-oauth-producer-consumer*.jar` to your client machine. When prompted enter the password for the SSH user.

```cmd
scp ./target/kafka-oauth-producer-consumer*.jar sshuser@VM_PUBLIC_IP:kafka-oauth-producer-consumer.jar
```

## Run the example

1. Replace `sshuser` with the SSH user for your cluster, and replace `VM_PUBLIC_IP` with the public ip of client VM. Open an SSH connection to the client vm, by entering the following command. If prompted, enter the password for the SSH user account.
> ssh sshuser@VM_PUBLIC_IP

2. Create a client.properties file. You can check the samples of `client.properties` file in [resources directory](https://github.com/Azure-Samples/hdinsight-aks/tree/main/kafka/kafka-oauth-producer-consumer/src/main/resources). In this example we are using `vm_based_client.properties` file as example.<br>
> **NOTE**: Your VM should be an authorized user to access the kafka cluster.

3. Create Kafka topic, `myTest`, by entering the following command: 
```bash
# For example run, we are creating vm_based_client.properties file in same directory where my uber jar is present.
java -jar kafka-oauth-producer-consumer.jar create myTest ./vm_based_client.properties
```
By default, `myTest` topic will be created with partition count as 8 and replication-factor as 3.

4. Describe Kafka topic `myTest`, by entering the following command:
```bash
java -jar kafka-oauth-producer-consumer.jar describe myTest ./vm_based_client.properties
```

5. To run the producer and write data to the topic, use the following command:
```bash
java -jar kafka-oauth-producer-consumer.jar producer myTest ./vm_based_client.properties
```
By default, number of messages produced will be 1L.

6. Once the producer has finished, use the following command to read from the topic:
```bash
java -jar kafka-oauth-producer-consumer.jar consumer myTest ./vm_based_client.properties
```
The records read, along with a count of records, is displayed.

7. Press Ctrl + C to stop the infinite running consumer.

### Multiple consumers

Kafka consumers use a consumer group when reading records. Using the same group with multiple consumers results in load balanced reads from a topic. Each consumer in the group receives a portion of the records.

The consumer application accepts a parameter that is used as the `group ID`. For example, the following command starts a consumer using a `group ID` of `myGroup`:
```bash
java -jar kafka-oauth-producer-consumer.jar consumer myTest ./vm_based_client.properties myGroup
```

Use __Ctrl + C__ to exit the consumer.

> [!IMPORTANT]  
> There cannot be more consumer instances in a consumer group than partitions. In this example, one consumer group can contain up to eight consumers since that is the number of partitions are 8 in the topic. Or you can have multiple consumer groups, each with no more than eight consumers.

Records stored in Kafka are stored in the order they're received within a partition. To achieve in-ordered delivery for records *within a partition*, create a consumer group where the number of consumer instances matches the number of partitions. To achieve in-ordered delivery for records *within the topic*, create a consumer group with only one consumer instance.

## Common Issues faced

1. **Topic creation fails**: If your topic creation fails then make sure the client you are using kafka client that have enough privileges to access the Kafka cluster. You will get unauthorized error on console if client is present in Kafka ACL.
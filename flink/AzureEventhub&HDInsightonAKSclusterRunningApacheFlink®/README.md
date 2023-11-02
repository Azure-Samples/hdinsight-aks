## Connect Apache Flink® on HDInsight on AKS with Azure Event Hubs for Apache Kafka®

A well known use case for Apache Flink is stream analytics. The popular choice by many users to use the data streams, which are ingested using Apache Kafka. Typical installations of Flink and Kafka start with event streams being pushed to Kafka, which can be consumed by Flink jobs. Azure Event Hubs provides an Apache Kafka endpoint on an event hub, which enables users to connect to the event hub using the Kafka protocol.

In this demo, we explore how to use Flink 1.16.0 on HDInsight on AKS to read data from an Auzre Event Hubs Kafka endpoint and write it to Azure Data Lake Storage Gen2.

Here's a breakdown of what each part of the code in java does:

1. **Set up the execution environment**:<br>
   The `StreamExecutionEnvironment` is the context in which a program is executed. The parallelism parameter (set to 1 here) determines the number of concurrent tasks that the Flink job can perform.

2. **Read from Event Hubs Kafka**: <br>
This part of the code sets up a Kafka source that reads from an Event Hubs Kafka endpoint. The properties for the Kafka source are loaded from a file specified by the `input` command-line argument.

3. **Write to Azure Data Lake Storage Gen2**: <br>
This part of the code sets up a sink that writes the data to Azure Data Lake Storage Gen2. The `FileSink` is configured with a rolling policy, which determines when a new file should be started.

4. **Execute the job**: <br>
Finally, the `execute` method is called to start the execution of the Flink job.

## Prerequisites

• Flink 1.16.0 on HDInsight on AKS
• Azure Eventhub(Note:Make sure connectivity between Azure Eventhub and Flink cluster)
• For this demonstration, we are using a Azure Windows VM as maven project develop env in the same VNET as HDInsight on AKS

**Flink 1.16.0 on HDInsight on AKS**

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/bdab1a06-0407-4b5d-a976-1aba1ba82452)

**Azure Eventhub and its network setting**
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/9171dc53-ab08-4326-85b7-a5b08e4d4f7e)


## Set up Flink Cluster on HDInsight on AKS

### Eventhub Instance: click_events (contseventhub/click_events) | Generate data (preview)

Select Dataset: Clickstream data Repeat Send: 100
```
[
    {
        "timeStamp": "2020-12-29 9:30:20",
        "ipAddress": "123.45.60.45",
        "userId": "469b775c-6ab0-48ce-b321-08dc26c3b6cf",
        "sessionId": "a7f4b4bb-1107-4a35-b1dd-fb666de8edc7",
        "path": "/.netlify/functions/registration",
        "queryParameters": "?token=12345-ABCD",
        "referrerUrl": "http://example.com/about.html",
        "os": "Windows",
        "browser": "Chrome",
        "timeToCompletePage": 2100,
        "eventFirstTimestamp": 365476,
        "eventDuration": 1000,
        "eventScore": 95,
        "deviceType": "phone",
        "isLead": true,
        "diagnostics": ""
    },
……………
    {
        "timeStamp": "2020-07-25 9:15:25",
        "ipAddress": "90.12.45.67",
        "userId": "31ceebd2-0273-4841-9bf9-316e7bed8845",
        "sessionId": "531d32f2-502e-41f9-9451-3fcdac6ac1ba",
        "path": "/.netlify/functions/contact",
        "queryParameters": "?from=socialMedia",
        "referrerUrl": "http://example.com/contact.html",
        "os": "Windows",
        "browser": "Chrome",
        "timeToCompletePage": 3700,
        "eventFirstTimestamp": 426368,
        "eventDuration": 1900,
        "eventScore": 50,
        "deviceType": "phone",
        "isLead": false,
        "diagnostics": null
    }
]
```

### source code on Maven project
**maven pom.xml**<br>
``` xml
        <!-- https://mvnrepository.com/artifact/org.apache.flink/flink-connector-kafka -->
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-connector-kafka</artifactId>
            <version>${flink.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-connector-files</artifactId>
            <version>${flink.version}</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.apache.kafka/kafka-clients -->
        <dependency>
            <groupId>org.apache.kafka</groupId>
            <artifactId>kafka-clients</artifactId>
            <version>3.2.0</version>
        </dependency>
```
**Run the Flink producer adding the bootstrap.servers and the producer.config info**<br>
``` xml
bootstrap.servers=<NamespaceName>.servicebus.windows.net:9093
client.id=consumer
transaction.timeout.ms=700000
sasl.mechanism=PLAIN
security.protocol=SASL_SSL
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \
username="$ConnectionString" \
password="Endpoint=sb://<NamespaceName>.servicebus.windows.net/;SharedAccessKeyName=<KeyName>;SharedAccessKey=<KeyValue>";
```

Note:<br>
How to get an Eventhub connection string and Credential

https://learn.microsoft.com/en-us/azure/event-hubs/event-hubs-get-connection-string

**main source code: EventHubSinkToGen2.java**
``` java
public class EventhubSinkToGen2 {
    public static void main(String[] args) throws Exception {

        // 1. get stream execution environment
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment().setParallelism(1);
        ParameterTool parameters = ParameterTool.fromArgs(args);
        String input = parameters.get("input");
        Properties properties = new Properties();
        properties.load(new FileReader(input));

        // 2. read  eventhub kafka message as stream input
        KafkaSource<String> source = KafkaSource.<String>builder().setProperties(properties)
                .setTopics("click_events")
                .setGroupId("mygroup1")
                .setStartingOffsets(OffsetsInitializer.earliest())
                .setValueOnlyDeserializer(new SimpleStringSchema())
                .build();

        DataStream<String> stream = env.fromSource(source, WatermarkStrategy.noWatermarks(), "Eventhub Kafka Source");

        // 3. sink to gen2
        String outputPath  = "abfs://container01@contosoflinkgen2.dfs.core.windows.net/flink/eventhub_click_events";
        final FileSink<String> sink = FileSink
                .forRowFormat(new Path(outputPath), new SimpleStringEncoder<String>("UTF-8"))
                .withRollingPolicy(
                        DefaultRollingPolicy.builder()
                                .withRolloverInterval(Duration.ofMinutes(5))
                                .withInactivityInterval(Duration.ofMinutes(3))
                                .withMaxPartSize(MemorySize.ofMebiBytes(5))
                                .build())
                .build();

        stream.sinkTo(sink);

        // 4. run stream
        env.execute("eventhub kafka sink to adls gen2");
    }
}
```

### Packaging the JAR for Flink and upload it into Flink webssh pod, and put consumer.config into the machine where flink cli runs
```
xxxx@pod-0 [ ~/jar ]$ pwd
/opt/flink-webssh/jar
xxxx@pod-0 [ ~/jar ]$ ls FlinkEventhubDemo-1.0-SNAPSHOT.jar consumer.config
FlinkEventhubDemo-1.0-SNAPSHOT.jar  consumer.config

xxxx@pod-0 [ ~/jar ]$ bin/flink run -c contoso.example.EventhubSinkToGen2 -jar jar/FlinkEventhubDemo-1.0-SNAPSHOT.jar --input jar/consumer.config 
Job has been submitted with JobID 4678dbf011f5a54e565aeb2e3b532ad2
```

**Check Streaming job on Flink UI**
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/3718924b-ebe2-4728-8526-c25cfa0e9d56)

**Check output in ADLS gen2 on Azure portal**

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/6b236bb6-f69e-46f3-ba23-ae07601226f4)


## Clean Up the resource

• Flink 1.16.0 on HDInsight on AKS
• Azure Eventhub

## Reference
https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-how-to-setup-event-hub






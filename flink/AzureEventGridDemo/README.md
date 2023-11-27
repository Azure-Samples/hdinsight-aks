![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/b29b249a-f453-4436-a8cf-3e15cdf5fd18)


Azure IoT Hub as an Event Grid source

Azure IoT Hub emits the following event types:
Event type	                             Description
Microsoft.Devices.DeviceCreated	         Published when a device is registered to an IoT hub.
Microsoft.Devices.DeviceDeleted	         Published when a device is deleted from an IoT hub.
Microsoft.Devices.DeviceConnected	       Published when a device is connected to an IoT hub.
Microsoft.Devices.DeviceDisconnected	   Published when a device is disconnected from an IoT hub.
Microsoft.Devices.DeviceTelemetry        Published when a telemetry message is sent to an IoT hub.

In this demo,

Azure IoT Hub integrates with Azure Event Grid so that you can send event notifications to other services and trigger downstream processes.


Search IOT hub on Azure Portal:
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/98ef9409-6a59-420c-8600-bdf04afb28b5)


![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/e1da19fc-a621-4cc8-a290-64fd5a021bd2)


Azure Event Grid is a fully managed event routing service that uses a publish-subscribe model. Event Grid has built-in support for Azure services like Azure Functions and Azure Logic Apps, and can deliver event alerts to non-Azure services using webhooks. For a complete list of the event handlers that Event Grid supports, see https://learn.microsoft.com/en-us/azure/event-grid/overview

MQTT messaging:
IoT devices and applications can communicate with each other over MQTT. 
Event Grid can also be used to route MQTT messages to Azure services or custom endpoints for further data analysis, visualization, or storage. This integration with Azure services enables you to build data pipelines that start with data ingestion from your IoT devices.



Use the Azure portal to configure which events to publish from each IoT hub.

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/94355b46-800a-4210-bd76-56db6f8cac6e)

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/ea91c910-7f1c-443a-962c-36b8a59abf6e)

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/a82c1c22-8047-4c72-ba89-b3e59ce6153e)

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/7d1fa235-bdcd-4944-8c5f-3234e4b56abc)

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/d7989633-a08d-41b7-8475-f2b88c8367f1)

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/5bf245ed-ffea-4ae9-a813-cec48fcbaeb2)

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/32843958-7fcb-461e-959c-68e6d6405f38)

Run the Flink Consumer adding the bootstrap.servers and the consumer.config:
``` XML
bootstrap.servers=<eventhub>.servicebus.windows.net:9093
client.id=<consumer>
transaction.timeout.ms=700000
sasl.mechanism=PLAIN
security.protocol=SASL_SSL
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \
username="$ConnectionString" \
password="Endpoint=sb://<eventhub>.servicebus.windows.net/;SharedAccessKeyName=policy1;SharedAccessKey=<access_key>";
```

pom.xml
``` XML
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
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
            <version>2.15.2</version>
        </dependency>
```

**main source code:  <EventhubSinkToGen2.java>**

Read eventhub consumer properties:(resources/input)
``` java
        ParameterTool parameters = ParameterTool.fromArgs(args);
        String input = parameters.get("input");
        Properties properties = new Properties();
        properties.load(new FileReader(input));
```

Read  eventhub kafka message as stream input
``` java
 KafkaSource<String> source = KafkaSource.<String>builder().setProperties(properties)
                .setTopics("test")
                .setGroupId("group1")
                .setStartingOffsets(OffsetsInitializer.latest())
                .setValueOnlyDeserializer(new CustomDeserializationSchema())
                .build();
```

Sink to Gen2
``` java
String outputPath  = "abfs://flink@cicihilogen2.dfs.core.windows.net/eventhub/test";
        final FileSink<String> sink = FileSink
                .forRowFormat(new Path(outputPath), new SimpleStringEncoder<String>("UTF-8"))
                .withRollingPolicy(
                        DefaultRollingPolicy.builder()
                                .withRolloverInterval(Duration.ofMinutes(5))
                                .withInactivityInterval(Duration.ofMinutes(3))
                                .withMaxPartSize(MemorySize.ofMebiBytes(5))
                                .build())
                .build();

**source function:  <CustomDeserializationSchema.java>**

json format message on Azure eventhub entity: <br>

``` json
 {
    "type": "Microsoft.Devices.DeviceTelemetry",
    "source": "/SUBSCRIPTIONS/AA4378DE-7509-4707-9D28-E220534548AD/RESOURCEGROUPS/CICI-HILO-EASTUS2/PROVIDERS/MICROSOFT.DEVICES/IOTHUBS/CONTOSOIOTHUB",
    "subject": "devices/device1",
    "id": "bebfb7ba-acfa-c567-d7ee-b7cf33b7ef63",
    "time": "2023-11-27T05:48:35.7750000Z",
    "specversion": "1.0",
    "data": {
      "body": "eyJ0ZW1wZXJhdHVyZSI6MzQuMTIxODczNDUwMzg3MjQsImh1bWlkaXR5Ijo2MS42MDM0NzM1MzU5MDQwOX0=",
      "properties": {},
      "systemProperties": {
        "iothub-connection-auth-generation-id": "638365932302747633",
        "iothub-connection-auth-method": "{\"scope\":\"device\",\"type\":\"sas\",\"issuer\":\"iothub\",\"acceptingIpFilterRule\":null}",
        "iothub-connection-device-id": "device1",
        "iothub-enqueuedtime": "2023-11-27T05:48:35.7750000Z",
        "iothub-message-source": "Telemetry"
      }
    },
    "EventProcessedUtcTime": "2023-11-27T05:50:22.6230858Z",
    "PartitionId": 0,
    "EventEnqueuedUtcTime": "2023-11-27T05:48:36.0980000Z"
  },

Custom deserialization schema to decode the body data with the base64 string <br>

``` java
public String deserialize(byte[] message) throws IOException {
        try {
            // Parse the JSON
            JsonNode jsonNode = objectMapper.readTree(message);
            String body = jsonNode.get("data").get("body").asText();

            // Decode the base64 message
            byte[] decodedBytes = Base64.getDecoder().decode(body);
            return new String(decodedBytes);
        } catch (IllegalArgumentException e) {
            // Handle the case where the input is not a valid Base64 string
            System.err.println("Failed to decode message: " + new String(message));
            throw new IOException("Failed to decode Base64 string", e);
        }
```

## Submit job on web ssh

You're required to select SSH during creation of Flink Cluster
Once the Flink cluster is created, you can observe on the left pane the Settings option to access Secure Shell.
Connecting to webssh pod, wget the jar into webssh pod and submit the job.
After you submitted the job, please go to Flink Dashboard UI and click on the running job

```
wget https://<storage_account>.blob.core.windows.net/jar/FlinkEventhubDemo-1.0-SNAPSHOT.jar
wget https://<storage_account>.blob.core.windows.net/jar/consumer.config
```

```
bin/flink run -c contoso.example.EventhubSinkToGen2 -jar FlinkEventhubDemo-1.0-SNAPSHOT.jar --input consumer.config 
Job has been submitted with JobID ffd5cc6699fd58643fa7aa6414958b4b
```

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/51cd5f83-e799-41e5-b049-84cc9120dda4)

## Confirm streaming job on Flink Dashboard
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/c532bacd-2197-4eb3-8c62-6349369ea609)

## Check output file in ADLS gen2 on Azure portal
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/a165cc8e-cfa7-4fa9-92e1-f78715bb5b32)










# Using CoProcessFunction to realize event time join with 2 input streams

This Flink job demo provides an example about how to use CoProcessFunction to realize event time join with 2 input streams.

A CoProcessFunction allows you to use one stream to influence how another is processed, or to enrich another stream. In this example, there are 2 input sources: Customer and Trade. We alwayse get the latest trade and customer information with enriched trade output events. We will check the timestamp of there 2 event streams, if there is an update on customer timestamp and the trade timestamp is greater than customer timestamp, we will update the enriched trade events. 


## Requirements
**Azure HDInsight Flink 1.17 on AKS**
https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-create-cluster-portal

## Running

**Submit the jar into Azure HDInsight Flink 1.17 on AKS through Flink UI and check job running details on Flink UI**

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/79356581-3491-49f8-b828-ba5e3bb4e9a5)


**Confirm output file in ADLS gen2 on Portal**

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/c85f0c5a-7b08-4bbb-a1bf-6a2dd4c94c9c)


## Clean up
Donot forget to clean up the Flink clsuter we created above.

## Reference documents

CoProcessFunction: https://nightlies.apache.org/flink/flink-docs-master/api/java/org/apache/flink/streaming/api/functions/co/CoProcessFunction.html

Process Function: https://nightlies.apache.org/flink/flink-docs-master/docs/dev/datastream/operators/process_function/

Using Watermark Strategies: https://nightlies.apache.org/flink/flink-docs-master/docs/dev/datastream/event-time/generating_watermarks/#using-watermark-strategies

Using Keyed State: https://nightlies.apache.org/flink/flink-docs-master/docs/dev/datastream/fault-tolerance/state/#using-keyed-state

File Sink: https://nightlies.apache.org/flink/flink-docs-master/docs/connectors/datastream/filesystem/#file-sink

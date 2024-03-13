# Using Side Outputs to produce additional side output result streams from the main stream

This Flink job demo provides an example about how to realize events deduplication in Flink.

Here's a breakdown of what each part of the code in java does:

**Main code: App.java**
1. **Setting up the execution environment**: The StreamExecutionEnvironment.getExecutionEnvironment() method is used to set up the execution environment for the Flink job.

2. **Creating a data stream**: env.fromSource() is used to generate 10,000 integers from 1 to 10 randomly using example event model defined in ExampleEvent.java under model

3. **Getting unique events and duplicate events using Process funtion with Side Outpue**: DeduplicateStream function defined in DeduplicateStream.java under function part is used to generate unitque events with regular output and duplicate events with side output

4. **Retrieving unitque event list and duplicate event list**: Define 2 ArrayList to add unique events and duplicate events separately.
 
5. **Verifying the result**: Print the duplicate events size and unique event sizes to verify the result
 
**Flink DeduplicateStream funtion: DeduplicateStream.java**: Using a KeyedProcesFunction to check wehther the key has been seen before. If the key has been seen before, then emit the record to side output as Duplicate events. If the key hasn't been seen before, then emit the record to regular output as unique events 

**Model: ExampleEvent.java**: Define the data structure with id and timestamp for example events


## Requirements
**Azure HDInsight Flink 1.17 on AKS**
https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-create-cluster-portal

## Running
1. Put the generated Jar in your Azure Storage Account and copy the jar file url:
   ![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/f8a2cf2d-56f4-460f-a60b-8d51cec8d6b2)

2. Download the Jar to Flink web ssh:
   ```
   wget https://guodongwangstore.blob.core.windows.net/websshupload/Deduplication-1.0-SNAPSHOT.jar
   ```
3. Submit the jar into Azure HDInsight Flink 1.17 through web ssh session, then we can see the generated jobs run successfully in Flink UI and we can get the results for Duplicates events counts and Unique event counts: 
   ```
   bin/flink run -c deduplication.operator.App -jar Deduplication-1.0-SNAPSHOT.jar
   ```
   ![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/482114e7-c578-45f7-9cba-4bbd8595f683)
   ![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/06b00997-5cd1-46ae-9ad0-979133e76b56)


## Clean up
Donot forget to clean up the Flink clsuter we created above.

## Reference documents
Flink Side Outputs: https://nightlies.apache.org/flink/flink-docs-release-1.17/docs/dev/datastream/side_output/

KeyedProcessFunction: https://nightlies.apache.org/flink/flink-docs-master/docs/dev/datastream/operators/process_function/#the-keyedprocessfunction

Using Watermark Strategies: https://nightlies.apache.org/flink/flink-docs-master/docs/dev/datastream/event-time/generating_watermarks/#using-watermark-strategies

Using Keyed State: https://nightlies.apache.org/flink/flink-docs-master/docs/dev/datastream/fault-tolerance/state/#using-keyed-state


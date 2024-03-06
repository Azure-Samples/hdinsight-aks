# Using Side Outputs to produce additional side output result streams from the main stream

This Flink job demo provides an example about how to split main stream to 2 side output result streams which writes to ADLS gen2.
## Requirements
**Azure HDInsight Flink 1.17 on AKS**
https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-create-cluster-portal

## **Main code: SideOutputsSample.java**
Here’s a breakdown of what each part does!
1. **Setting up the execution environment**: The StreamExecutionEnvironment.getExecutionEnvironment() method is used to set up the execution environment for the Flink job.

2. **Creating a data stream**: The getData(env) is used to create a data stream from inputs.

3. **Defining the OutputTag for the side output**: OutputTag class is used to identify a side output stream

4. **Emitting data to a side output using Process function'**: Process function is used to define how to emit side output data to different side stream.

5. **Retrieving the side output stream using getSideOutput(OutputTag)**: getSideOutput(OutputTag) is used on the result of the DataStream operaion, which will give you a DataStream that is typed to the result of the side output stream
 
6. **Creating 2 sinks for Azure Data Lake Storage Gen2 for 2 output side streams**: For each output side steram, A FileSink object is created with the output path and a SimpleStringEncoder. The withRollingPolicy method is used to set a rolling policy for the sink.

7. **Adding the sink function to the 2 side stream**: The sinkTo  method is used to add the sink function to the processed stream. Each processed element will be written to a file in Azure Data Lake Storage Gen2.

8. **Generating Random Tuples of <Long, Long>**: getData(StreamExecutionEnvironment env) is used to generate Random Tuples of <Long, Long>.

9. **Executing the job**: Finally, the env.execute() method is used to execute the Flink job. This will start reading messages from generated random tuples, emit the date to 2 side outputs using Process function, and sink them to Azure Data Lake Storage Gen2.

## Running

**Submit the jar into Azure HDInsight Flink 1.17 on AKS through Flink UI and check job running details on Flink UI**

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/bad5d355-d495-48dd-ba01-9a4778fd9059)

**Confirm output file in ADLS gen2 on Portal**

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/fec5452f-c514-4d89-b761-e8ec146e286f)

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/28754f18-1210-4148-8dbb-184010a2f6d8)


## Clean up
Donot forget to clean up the Flink clsuter we created above.

## Reference documents
Flink Side Outputs: https://nightlies.apache.org/flink/flink-docs-release-1.17/docs/dev/datastream/side_output/
File Sink: https://nightlies.apache.org/flink/flink-docs-release-1.13/docs/connectors/datastream/file_sink/



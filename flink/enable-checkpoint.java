public StreamExecutionEnvironment createPipeline(
         String tablePath,
         int sourceParallelism,
         int sinkParallelism) {

     DeltaSink<RowData> deltaSink = getDeltaSink(tablePath);
     StreamExecutionEnvironment env = getStreamExecutionEnvironment();

     // Using Flink Delta Sink in processing pipeline
     env
         .addSource(new DeltaExampleSourceFunction())
         .setParallelism(sourceParallelism)
         .sinkTo(deltaSink)
         .name("MyDeltaSink")
         .setParallelism(sinkParallelism);

     return env;
 }

 /**
  * An example of Flink Delta Sink configuration.
  */
 @Override
 public DeltaSink<RowData> getDeltaSink(String tablePath) {
     return DeltaSink
         .forRowData(
             new Path(TABLE_PATH),
             new Configuration(),
             Utils.FULL_SCHEMA_ROW_TYPE)
         .build();
 }
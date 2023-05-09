public StreamExecutionEnvironment createPipeline(
         String tablePath,
         int sourceParallelism,
         int sinkParallelism) {

     DeltaSource<RowData> deltaSink = getDeltaSource(tablePath);
     StreamExecutionEnvironment env = getStreamExecutionEnvironment();

     env
         .fromSource(deltaSink, WatermarkStrategy.noWatermarks(), "bounded-delta-source")
         .setParallelism(sourceParallelism)
         .addSink(new ConsoleSink(Utils.FULL_SCHEMA_ROW_TYPE))
         .setParallelism(1);

     return env;
 }

 /**
  * An example of Flink Delta Source configuration that will read all columns from Delta table
  * using the latest snapshot.
  */
 @Override
 public DeltaSource<RowData> getDeltaSource(String tablePath) {
     return DeltaSource.forBoundedRowData(
         new Path(tablePath),
         new Configuration()
     ).build();
 }
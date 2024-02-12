This blog refers https://github.com/apache/flink-training/blob/master/README.md

## Purpose of this test

The goal of this blog is to merge two DataStreams in Apache Flink using Flink DataStream API to join together the TaxiRide and TaxiFare records for each ride.

## Set up testing environment

• Flink 1.17.0 on HDInsight on AKS <br>
• Use MSI to access ADLSgen2  <br>
• Maven project development on Azure VM in the same Vnet <br>

## Use the taxi Data Streams

These exercises use data [generators](https://github.com/apache/flink-training/tree/master/common/src/main/java/org/apache/flink/training/exercises/common/sources) that produce simulated event streams. The data is inspired by the [New York City Taxi & Limousine Commission's](https://www.nyc.gov/site/tlc/index.page) public [data set](https://uofi.app.box.com/v/NYCtaxidata) about taxi rides in New York City.

**Schema of taxi ride events** <br>

[TaxiRide.java](https://github.com/Baiys1234/hdinsight-aks/blob/main/flink/MergeTwoDataStreams(Rides%20and%20Fares)/src/main/java/contoso/example/datatypes/TaxiRide.java)

Our taxi data set contains information about individual taxi rides in New York City.
Each ride is represented by two events: a trip start, and a trip end.
Each event consists of ten fields:

```
rideId         : Long      // a unique id for each ride
taxiId         : Long      // a unique id for each taxi
driverId       : Long      // a unique id for each driver
isStart        : Boolean   // TRUE for ride start events, FALSE for ride end events
eventTime      : Instant   // the timestamp for this event
startLon       : Float     // the longitude of the ride start location
startLat       : Float     // the latitude of the ride start location
endLon         : Float     // the longitude of the ride end location
endLat         : Float     // the latitude of the ride end location
passengerCnt   : Short     // number of passengers on the ride
```

**Schema of taxi fare events** <br>
[TaxiFare.java](https://github.com/Baiys1234/hdinsight-aks/blob/main/flink/MergeTwoDataStreams(Rides%20and%20Fares)/src/main/java/contoso/example/datatypes/TaxiFare.java)

There is also a related data set containing fare data about those same rides, with the following fields:
```
rideId         : Long      // a unique id for each ride
taxiId         : Long      // a unique id for each taxi
driverId       : Long      // a unique id for each driver
startTime      : Instant   // the start time for this ride
paymentType    : String    // CASH or CARD
tip            : Float     // tip for this ride
tolls          : Float     // tolls for this ride
totalFare      : Float     // total fare collected
```

**Merged Ride and Fare events** <br>

[RideAndFare.java](https://github.com/Baiys1234/hdinsight-aks/blob/main/flink/MergeTwoDataStreams(Rides%20and%20Fares)/src/main/java/contoso/example/datatypes/RideAndFare.java)

Format: <br>
```
"<" + ride.toString() + " / " + fare.toString() + ">"
```

## Testing steps

### Filtering a Stream (Ride Cleansing) <br>
The task is to cleanse a stream of TaxiRide events by removing events that start or end outside of New York City.
The GeoUtils utility class provides a static method isInNYC(float lon, float lat) to check if a location is within the NYC area.

**Input Data** <br>
It is based on a stream of TaxiRide events, as described above in Using the Taxi ride Data Streams.

[GeoUtils.java](https://github.com/Baiys1234/hdinsight-aks/blob/main/flink/MergeTwoDataStreams(Rides%20and%20Fares)/src/main/java/contoso/example/utils/GeoUtils.java) <br>

``` java
    /**
     * Checks if a location specified by longitude and latitude values is within the geo boundaries
     * of New York City.
     *
     * @param lon longitude of the location to check
     * @param lat latitude of the location to check
     * @return true if the location is within NYC boundaries, otherwise false.
     */
    public static boolean isInNYC(float lon, float lat) {

        return !(lon > LON_EAST || lon < LON_WEST) && !(lat > LAT_NORTH || lat < LAT_SOUTH);
    }
```

### Stateful Enrichment (Rides and Fares)

Join together the TaxiRide and TaxiFare records for each ride.

For each distinct rideId, there are exactly three events:

• a TaxiRide START event <br>
• a TaxiRide END event<br>
• a TaxiFare event (whose timestamp happens to match the start time)<br>

The result should be a DataStream<RideAndFare>, with one record for each distinct rideId. Each tuple should pair the TaxiRide START event for some rideId with its matching TaxiFare.

**Input Data**<br>

Cleansed TaxiRide START event <br>
[TaxiRideGenerator.java](https://github.com/Baiys1234/hdinsight-aks/blob/main/flink/MergeTwoDataStreams(Rides%20and%20Fares)/src/main/java/contoso/example/source/TaxiRideGenerator.java)

TaxiRide Event Data Example<br>
```
1,START,2020-01-01T12:00:20Z,-73.76764,40.88664,-73.843834,40.78967,3,2013000185,2013000185
2,START,2020-01-01T12:00:40Z,-73.85604,40.77413,-73.80203,40.84287,3,2013000108,2013000108
3,START,2020-01-01T12:01:00Z,-73.86453,40.763325,-73.84797,40.7844,3,2013000134,2013000134
4,START,2020-01-01T12:01:20Z,-73.86093,40.767902,-73.781784,40.868633,3,2013000062,2013000062
5,START,2020-01-01T12:01:40Z,-73.85884,40.77057,-73.75468,40.903137,3,2013000087,2013000087
```

TaxiFare event<br>
[TaxiFareGenerator.java](https://github.com/Baiys1234/hdinsight-aks/blob/main/flink/MergeTwoDataStreams(Rides%20and%20Fares)/src/main/java/contoso/example/source/TaxiFareGenerator.java)

TaxiFare Event Data Example<br>
```
1,2013000185,2013000185,2020-01-01T12:00:20Z,CASH,33.0,0.0,118.0
2,2013000108,2013000108,2020-01-01T12:00:40Z,CARD,14.0,0.0,48.0
3,2013000134,2013000134,2020-01-01T12:01:00Z,CASH,12.0,0.0,41.0
4,2013000062,2013000062,2020-01-01T12:01:20Z,CARD,13.0,0.0,44.0
5,2013000087,2013000087,2020-01-01T12:01:40Z,CASH,14.0,0.0,46.0
```

**Output stream by using [new RideAndFare(ride, fare)]** <br>
[RideAndFare.java](https://github.com/Baiys1234/hdinsight-aks/blob/main/flink/MergeTwoDataStreams(Rides%20and%20Fares)/src/main/java/contoso/example/datatypes/RideAndFare.java)

Enriched TaxiRide with Fare Output example<br>
```
<1,START,2020-01-01T12:00:20Z,-73.76764,40.88664,-73.843834,40.78967,3,2013000185,2013000185 / 1,2013000185,2013000185,2020-01-01T12:00:20Z,CASH,33.0,0.0,118.0>
<2,START,2020-01-01T12:00:40Z,-73.85604,40.77413,-73.80203,40.84287,3,2013000108,2013000108 / 2,2013000108,2013000108,2020-01-01T12:00:40Z,CARD,14.0,0.0,48.0>
<3,START,2020-01-01T12:01:00Z,-73.86453,40.763325,-73.84797,40.7844,3,2013000134,2013000134 / 3,2013000134,2013000134,2020-01-01T12:01:00Z,CASH,12.0,0.0,41.0>
<4,START,2020-01-01T12:01:20Z,-73.86093,40.767902,-73.781784,40.868633,3,2013000062,2013000062 / 4,2013000062,2013000062,2020-01-01T12:01:20Z,CARD,13.0,0.0,44.0>
<5,START,2020-01-01T12:01:40Z,-73.85884,40.77057,-73.75468,40.903137,3,2013000087,2013000087 / 5,2013000087,2013000087,2020-01-01T12:01:40Z,CASH,14.0,0.0,46.0>
```

**Enrichment code** <br>
[RideAndFareSolution.java]( https://github.com/Baiys1234/hdinsight-aks/blob/main/flink/MergeTwoDataStreams(Rides%20and%20Fares)/src/main/java/contoso/example/solution/RidesAndFaresSolution.java)

``` java
public class RidesAndFaresSolution {

    private final SourceFunction<TaxiRide> rideSource;
    private final SourceFunction<TaxiFare> fareSource;
    private final SinkFunction<RideAndFare> sink;

    /** Creates a job using the sources and sink provided. */
    public RidesAndFaresSolution(
            SourceFunction<TaxiRide> rideSource,
            SourceFunction<TaxiFare> fareSource,
            SinkFunction<RideAndFare> sink) {

        this.rideSource = rideSource;
        this.fareSource = fareSource;
        this.sink = sink;
    }

    /**
     * Creates and executes the pipeline using the StreamExecutionEnvironment provided.
     *
     * @throws Exception which occurs during job execution.
     * @param env The {StreamExecutionEnvironment}.
     * @return {JobExecutionResult}
     */
    public JobExecutionResult execute(StreamExecutionEnvironment env) throws Exception {

        // A stream of taxi ride START events, keyed by rideId.
        DataStream<TaxiRide> rides =
                env.addSource(rideSource).filter(ride -> ride.isStart).keyBy(ride -> ride.rideId);

        rides.print();

        // A stream of taxi fare events, also keyed by rideId.
        DataStream<TaxiFare> fares =
                env.addSource(fareSource).keyBy(fare -> fare.rideId);
        fares.print();

        // Create the pipeline.
        DataStream<RideAndFare> enrichedStream = rides.connect(fares)
                .flatMap(new EnrichmentFunction())
                .uid("enrichment") // uid for this operator's state
                .name("enrichment"); // name for this operator in the web UI

        enrichedStream.print();

        // 3. sink output to gen2
        String outputPath  = "abfs://<container>@<storage_account>.dfs.core.windows.net/flink/data/JoinedRidesWithFares";
        final FileSink<RideAndFare> sink = FileSink
                .forRowFormat(new Path(outputPath), new SimpleStringEncoder<RideAndFare>("UTF-8"))
                .withRollingPolicy(
                        DefaultRollingPolicy.builder()
                                .withRolloverInterval(Duration.ofMinutes(2))
                                .withInactivityInterval(Duration.ofMinutes(3))
                                .withMaxPartSize(MemorySize.ofMebiBytes(5))
                                .build())
                .build();

        enrichedStream.sinkTo(sink);

        // Execute the pipeline and return the result.
        return env.execute("Join Rides with Fares");
    }

    /** Creates and executes the pipeline using the default StreamExecutionEnvironment. */
    public JobExecutionResult execute() throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        return execute(env);
    }

    /**
     * Main method.
     *
     * @throws Exception which occurs during job execution.
     */
    public static void main(String[] args) throws Exception {

        // 0. Set up the execution environment for the Flink streaming job
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment().setParallelism(1);
        env.enableCheckpointing(10000);
        String checkPointPath = "abfs://<container>@<storage_account>.dfs.core.windows.net/CheckPoint";
        env.getCheckpointConfig().setCheckpointStorage(checkPointPath);

        RidesAndFaresSolution job =
                new RidesAndFaresSolution(
                        new TaxiRideGenerator(),
                        new TaxiFareGenerator(),
                        new PrintSinkFunction<>());

        job.execute(env);
    }

    public static class EnrichmentFunction
            extends RichCoFlatMapFunction<TaxiRide, TaxiFare, RideAndFare> {

        private ValueState<TaxiRide> rideState;
        private ValueState<TaxiFare> fareState;

        @Override
        public void open(Configuration config) {

            rideState =
                    getRuntimeContext()
                            .getState(new ValueStateDescriptor<>("saved ride", TaxiRide.class));
            fareState =
                    getRuntimeContext()
                            .getState(new ValueStateDescriptor<>("saved fare", TaxiFare.class));
        }

        @Override
        public void flatMap1(TaxiRide ride, Collector<RideAndFare> out) throws Exception {

            TaxiFare fare = fareState.value();
            if (fare != null) {
                fareState.clear();
                out.collect(new RideAndFare(ride, fare));
            } else {
                rideState.update(ride);
            }
        }

        @Override
        public void flatMap2(TaxiFare fare, Collector<RideAndFare> out) throws Exception {

            TaxiRide ride = rideState.value();
            if (ride != null) {
                rideState.clear();
                out.collect(new RideAndFare(ride, fare));
            } else {
                fareState.update(fare);
            }
        }
    }
}

```
**Submit the jar in maven to cluster to run**

```
bin/flink run -c contoso.example.solution.RidesAndFaresSolution -j MergeTwoDataStreamsDemo-1.0-SNAPSHOT.jar
Job has been submitted with JobID 52900ff5980fedbfe0f39241e32206a4
```

**Check job on Flink Dashboard UI**

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/bfec13ba-29d2-4316-9bf3-20a4dc62cc3b)


**Check enriched Taxi Ride with Fare on output ADLS gen2 on portal**

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/912b7b43-14ea-400a-9dbb-5291f6b03ab8)

output example<br>
```
<2,START,2020-01-01T12:00:40Z,-73.85604,40.77413,-73.80203,40.84287,3,2013000108,2013000108 / 2,2013000108,2013000108,2020-01-01T12:00:40Z,CARD,14.0,0.0,48.0>
<3,START,2020-01-01T12:01:00Z,-73.86453,40.763325,-73.84797,40.7844,3,2013000134,2013000134 / 3,2013000134,2013000134,2020-01-01T12:01:00Z,CASH,12.0,0.0,41.0>
<4,START,2020-01-01T12:01:20Z,-73.86093,40.767902,-73.781784,40.868633,3,2013000062,2013000062 / 4,2013000062,2013000062,2020-01-01T12:01:20Z,CARD,13.0,0.0,44.0>
<1,START,2020-01-01T12:00:20Z,-73.76764,40.88664,-73.843834,40.78967,3,2013000185,2013000185 / 1,2013000185,2013000185,2020-01-01T12:00:20Z,CASH,33.0,0.0,118.0>
```

## Clean up resouces

• Flink 1.17.0 on HDInsight on AKS <br>
• Use MSI to access ADLSgen2  <br>
• Maven project development on Azure VM in the same Vnet <br>

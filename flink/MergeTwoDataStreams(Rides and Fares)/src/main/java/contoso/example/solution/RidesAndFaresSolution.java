package contoso.example.solution;

import org.apache.flink.api.common.JobExecutionResult;
import org.apache.flink.api.common.serialization.SimpleStringEncoder;
import org.apache.flink.api.common.state.ValueState;
import org.apache.flink.api.common.state.ValueStateDescriptor;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.configuration.MemorySize;
import org.apache.flink.connector.file.sink.FileSink;
import org.apache.flink.core.fs.Path;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.co.RichCoFlatMapFunction;
import org.apache.flink.streaming.api.functions.sink.PrintSinkFunction;
import org.apache.flink.streaming.api.functions.sink.SinkFunction;
import org.apache.flink.streaming.api.functions.sink.filesystem.rollingpolicies.DefaultRollingPolicy;
import org.apache.flink.streaming.api.functions.source.SourceFunction;
import contoso.example.datatypes.RideAndFare;
import contoso.example.datatypes.TaxiFare;
import contoso.example.datatypes.TaxiRide;
import contoso.example.source.TaxiFareGenerator;
import contoso.example.source.TaxiRideGenerator;
import org.apache.flink.util.Collector;

import java.time.Duration;

/**
 * Java reference implementation for the Stateful Enrichment exercise from the Flink training.
 *
 * <p>The goal for this exercise is to enrich TaxiRides with fare information.
 */
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

        // A stream of taxi fare events, also keyed by rideId.
        DataStream<TaxiFare> fares =
                env.addSource(fareSource).keyBy(fare -> fare.rideId);

        // Create the pipeline.
        DataStream<RideAndFare> enrichedStream = rides.connect(fares)
                .flatMap(new EnrichmentFunction())
                .uid("enrichment") // uid for this operator's state
                .name("enrichment"); // name for this operator in the web UI


        // 3. sink to gen2
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

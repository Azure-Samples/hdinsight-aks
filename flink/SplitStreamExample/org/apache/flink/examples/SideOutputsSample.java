package org.apache.flink.examples;

import org.apache.flink.api.common.serialization.SimpleStringEncoder;
import org.apache.flink.api.connector.sink.Sink;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.configuration.MemorySize;
import org.apache.flink.connector.file.sink.FileSink;
import org.apache.flink.core.fs.Path;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.datastream.SingleOutputStreamOperator;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.ProcessFunction;
import org.apache.flink.streaming.api.functions.sink.filesystem.rollingpolicies.DefaultRollingPolicy;
import org.apache.flink.util.Collector;
import org.apache.flink.util.OutputTag;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class SideOutputsSample {
    private static final int INPUT_MAX = 100;
    private static final int MAX_NUMBER_OF_ELEMENTS = 10000;

    public static void main(String[] args) throws Exception {
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        // Create a DataStream from input
        final DataStream<Tuple2<Long, Long>> tuples = getData(env);

        // Define the OutputTag for the side output
        final OutputTag<Tuple2<Long, Long>> oddOutputTag = new OutputTag<Tuple2<Long, Long>>("odd"){};
        final OutputTag<Tuple2<Long, Long>> evenOutputTag = new OutputTag<Tuple2<Long, Long>>("even"){};

        // Split the Stream based on the Selector criterion - 'odd' and 'even'
        SingleOutputStreamOperator<Tuple2<Long, Long>> out = tuples.process(new ProcessFunction<Tuple2<Long, Long>, Tuple2<Long, Long>>(){

            @Override
            public void processElement(Tuple2<Long, Long> value, Context ctx, Collector<Tuple2<Long, Long>> out) throws Exception {
                // Apply the splitting logic
                if ((value.f0 + value.f1) % 2 == 0) {
                    // Emit 'even' tuples to the 'even' side output
                    ctx.output(evenOutputTag, value);
                } else {
                    // Emit 'odd' tuples to the 'odd' side output
                    ctx.output(oddOutputTag, value);
                }
            }
        });

        // Select the split streams based on 'odd' vs 'even'
        DataStream<Tuple2<Long, Long>> odd = out.getSideOutput(oddOutputTag);
        DataStream<Tuple2<Long, Long>> even = out.getSideOutput(evenOutputTag);

        // Write 'odd' split as CSV
        //odd.writeAsCsv("/tmp/sumOdd", FileSystem.WriteMode.OVERWRITE).setParallelism(1);
        // Write 'even' split as text
        //even.writeAsText("/tmp/sumEven", FileSystem.WriteMode.OVERWRITE).setParallelism(1);
        // sink to gen2
        String oddoutputPath  = "abfs://container3@guodongwangstore.dfs.core.windows.net/flink/data/sumOdd";
        final FileSink<Tuple2<Long, Long>>  oddsink = FileSink
                .forRowFormat(new Path(oddoutputPath), new SimpleStringEncoder<Tuple2<Long, Long>> ("UTF-8"))
                .withRollingPolicy(
                        DefaultRollingPolicy.builder()
                                .withRolloverInterval(Duration.ofMinutes(2))
                                .withInactivityInterval(Duration.ofMinutes(3))
                                .withMaxPartSize(MemorySize.ofMebiBytes(5))
                                .build())
                .build();

        odd.sinkTo(oddsink);

        String evenoutputPath  = "abfs://container3@guodongwangstore.dfs.core.windows.net/flink/data/sumEven";
        final FileSink<Tuple2<Long, Long>>  evensink = FileSink
                .forRowFormat(new Path(evenoutputPath), new SimpleStringEncoder<Tuple2<Long, Long>> ("UTF-8"))
                .withRollingPolicy(
                        DefaultRollingPolicy.builder()
                                .withRolloverInterval(Duration.ofMinutes(2))
                                .withInactivityInterval(Duration.ofMinutes(3))
                                .withMaxPartSize(MemorySize.ofMebiBytes(5))
                                .build())
                .build();

        even.sinkTo(evensink);


        // Process the Stream
        env.execute();
    }

    /**
     * Generate Random Tuples of <Long, Long>
     *
     * @param env - {@link StreamExecutionEnvironment}
     * @return {@link DataStream<Tuple2>}
     */
    public static DataStream<Tuple2<Long, Long>> getData(StreamExecutionEnvironment env) {
        List<Tuple2<Long, Long>> list = new ArrayList<>();
        Random rnd = new Random();
        for (int i = 0; i < MAX_NUMBER_OF_ELEMENTS; i++) {
            long r = rnd.nextInt(INPUT_MAX);
            list.add(new Tuple2<>(r, r + rnd.nextInt(10)));
        }
        // Create a DataStream from the collection
        return env.fromCollection(list);
    }
}

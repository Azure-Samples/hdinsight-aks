package deduplication.operator;

import deduplication.operator.functions.DeduplicateStream;
import deduplication.operator.model.ExampleEvent;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.api.connector.source.util.ratelimit.RateLimiterStrategy;
import org.apache.flink.connector.datagen.source.DataGeneratorSource;
import org.apache.flink.runtime.testutils.MiniClusterResourceConfiguration;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.datastream.SingleOutputStreamOperator;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.test.util.MiniClusterWithClientResource;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Random;

public class App {
    public static void main(String[] args) throws Exception {
        new MiniClusterWithClientResource(
                new MiniClusterResourceConfiguration.Builder()
                        .setNumberSlotsPerTaskManager(2)
                        .setNumberTaskManagers(1)
                        .build()
        );

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        Random random = new Random();

        // Generate 10,000 integers from 1 to 10 - It should take ~10 to work through the 10,000 integers
        DataStream<ExampleEvent> exampleEvents = env.fromSource(
                new DataGeneratorSource<>(
                        (a) -> new ExampleEvent(random.nextInt(10) + 1),
                        10000,
                        RateLimiterStrategy.perSecond(10000),
                        TypeInformation.of(ExampleEvent.class)
                ),
                WatermarkStrategy
                        .<ExampleEvent>forBoundedOutOfOrderness(Duration.ZERO)
                        .withTimestampAssigner((event, timestamp) -> event.timestamp),
                "randomExampleEvents",
                TypeInformation.of(ExampleEvent.class)
        );

        SingleOutputStreamOperator<ExampleEvent> uniqueEvents = exampleEvents
                .keyBy((event) -> event.id)
                .process(new DeduplicateStream(Duration.ofSeconds(30)));

        env.execute();

        ArrayList<ExampleEvent> uniqueEventsList = new ArrayList<>();
        ArrayList<ExampleEvent> duplicatedEventsList = new ArrayList<>();

        uniqueEvents.executeAndCollect().forEachRemaining(uniqueEventsList::add);
        uniqueEvents.getSideOutput(DeduplicateStream.DUPLICATE_EVENTS).executeAndCollect().forEachRemaining(duplicatedEventsList::add);

        int totalEventsGenerated = uniqueEventsList.size() + duplicatedEventsList.size();
        System.out.println("Generated Items: " + totalEventsGenerated);
        System.out.println("Caught Duplicates: " + duplicatedEventsList.size());
        System.out.println("Unique Events: " + uniqueEventsList.size());
    }
}

package deduplication.operator.functions;

import deduplication.operator.model.ExampleEvent;
import org.apache.flink.api.common.state.ValueState;
import org.apache.flink.api.common.state.ValueStateDescriptor;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.streaming.api.functions.KeyedProcessFunction;
import org.apache.flink.util.Collector;
import org.apache.flink.util.OutputTag;

import java.time.Duration;

/**
 * Checks if a key has been seen before.
 */
public class DeduplicateStream extends KeyedProcessFunction<Integer, ExampleEvent, ExampleEvent> {
    private ValueState<Boolean> hasBeenSeen;
    private final Duration deduplicationTimeRange;
    public static OutputTag<ExampleEvent> DUPLICATE_EVENTS =
            new OutputTag<>("DuplicateEvents", TypeInformation.of(ExampleEvent.class));

    public DeduplicateStream(Duration deduplicationTimeRange) {
        this.deduplicationTimeRange = deduplicationTimeRange;
    }

    @Override
    public void open(Configuration parameters) {
        this.hasBeenSeen = getRuntimeContext()
                .getState(new ValueStateDescriptor<>("hasBeenSeenState", Boolean.class));
    }

    @Override
    public void processElement(ExampleEvent event, KeyedProcessFunction<Integer, ExampleEvent, ExampleEvent>.Context ctx, Collector<ExampleEvent> out) throws Exception {
        // We've seen this key before, ignore it if it has been seen
        if (hasBeenSeen.value() != null && hasBeenSeen.value()) {
            ctx.output(DUPLICATE_EVENTS, event);
            return;
        }

        ctx.timerService().registerEventTimeTimer(ctx.timestamp() + deduplicationTimeRange.toMillis());
        hasBeenSeen.update(true);
        out.collect(event);
    }

    @Override
    public void onTimer(long timestamp, KeyedProcessFunction<Integer, ExampleEvent, ExampleEvent>.OnTimerContext ctx, Collector<ExampleEvent> out) {
        hasBeenSeen.clear();
    }
}

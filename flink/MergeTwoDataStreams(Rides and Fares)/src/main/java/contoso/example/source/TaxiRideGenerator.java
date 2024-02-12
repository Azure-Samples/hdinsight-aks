package contoso.example.source;

import org.apache.flink.streaming.api.functions.source.SourceFunction;
import contoso.example.datatypes.TaxiRide;

import java.util.ArrayList;
import java.util.List;
import java.util.PriorityQueue;
import java.util.Random;

/**
 * This SourceFunction generates a data stream of TaxiRide records.
 *
 * <p>The stream is produced out-of-order.
 */
public class TaxiRideGenerator implements SourceFunction<TaxiRide> {

    public static final int SLEEP_MILLIS_PER_EVENT = 10;
    private static final int BATCH_SIZE = 5;
    private volatile boolean running = true;

    @Override
    public void run(SourceContext<TaxiRide> ctx) throws Exception {

        PriorityQueue<TaxiRide> endEventQ = new PriorityQueue<>(100);
        long id = 0;
        long maxStartTime = 0;

        while (running) {

            // generate a batch of START events
            List<TaxiRide> startEvents = new ArrayList<TaxiRide>(BATCH_SIZE);
            for (int i = 1; i <= BATCH_SIZE; i++) {
                TaxiRide ride = new TaxiRide(id + i, true);
                startEvents.add(ride);
                // the start times may be in order, but let's not assume that
                maxStartTime = Math.max(maxStartTime, ride.getEventTimeMillis());
            }

            // enqueue the corresponding END events
            for (int i = 1; i <= BATCH_SIZE; i++) {
                endEventQ.add(new TaxiRide(id + i, false));
            }

            // release the END events coming before the end of this new batch
            // (this allows a few END events to precede their matching START event)
            while (endEventQ.peek().getEventTimeMillis() <= maxStartTime) {
                TaxiRide ride = endEventQ.poll();
                ctx.collect(ride);
            }

            // then emit the new START events (out-of-order)
            java.util.Collections.shuffle(startEvents, new Random(id));
            startEvents.iterator().forEachRemaining(r -> ctx.collect(r));

            // prepare for the next batch
            id += BATCH_SIZE;

            // don't go too fast
            Thread.sleep(BATCH_SIZE * SLEEP_MILLIS_PER_EVENT);
        }
    }

    @Override
    public void cancel() {
        running = false;
    }
}

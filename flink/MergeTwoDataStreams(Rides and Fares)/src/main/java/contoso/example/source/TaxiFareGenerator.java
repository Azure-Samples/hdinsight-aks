package contoso.example.source;

import org.apache.flink.streaming.api.functions.source.SourceFunction;
import contoso.example.datatypes.TaxiFare;
import contoso.example.utils.DataGenerator;

import java.time.Duration;
import java.time.Instant;

/**
 * This SourceFunction generates a data stream of TaxiFare records.
 *
 * <p>The stream is generated in order.
 */
public class TaxiFareGenerator implements SourceFunction<TaxiFare> {

    private volatile boolean running = true;
    private Instant limitingTimestamp = Instant.MAX;

    /** Create a bounded TaxiFareGenerator that runs only for the specified duration. */
    public static TaxiFareGenerator runFor(Duration duration) {
        TaxiFareGenerator generator = new TaxiFareGenerator();
        generator.limitingTimestamp = DataGenerator.BEGINNING.plus(duration);
        return generator;
    }

    @Override
    public void run(SourceContext<TaxiFare> ctx) throws Exception {

        long id = 1;

        while (running) {
            TaxiFare fare = new TaxiFare(id);

            // don't emit events that exceed the specified limit
            if (fare.startTime.compareTo(limitingTimestamp) >= 0) {
                break;
            }

            ++id;
            ctx.collect(fare);

            // match our event production rate to that of the TaxiRideGenerator
            Thread.sleep(TaxiRideGenerator.SLEEP_MILLIS_PER_EVENT);
        }
    }

    @Override
    public void cancel() {
        running = false;
    }
}

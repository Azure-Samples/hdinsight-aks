package contoso.example;

import org.apache.flink.streaming.api.functions.source.RichParallelSourceFunction;
import org.apache.flink.table.data.GenericRowData;
import org.apache.flink.table.data.RowData;
import org.apache.flink.table.data.StringData;
import com.github.javafaker.Faker;
import org.apache.flink.table.data.TimestampData;

import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.concurrent.ThreadLocalRandom;

public class LordSourceFunction extends RichParallelSourceFunction<RowData> {
    private volatile boolean isRunning = true;

    @Override
    public void run(SourceContext<RowData> ctx) throws Exception {
        Faker faker = new Faker();
        while (isRunning) {
            ZonedDateTime now = ZonedDateTime.now(ZoneId.systemDefault());
            ZonedDateTime fiveHundredYearsAgo = now.minusYears(500);
            long randomTimestamp = ThreadLocalRandom
                    .current()
                    .nextLong(fiveHundredYearsAgo.toInstant().toEpochMilli(), now.toInstant().toEpochMilli());

            // Convert the timestamp to a TimestampData
            TimestampData event_time = TimestampData.fromEpochMillis(randomTimestamp);

            // Create a new row
            GenericRowData row = new GenericRowData(3);
            row.setField(0, StringData.fromString(faker.lordOfTheRings().character()));
            row.setField(1, StringData.fromString(faker.lordOfTheRings().location()));
            row.setField(2, event_time);

            // Sleep for 5 seconds
            Thread.sleep(5000);

            // Emit the row
            ctx.collect(row);

        }
    }

    @Override
    public void cancel() {
        isRunning = false;
    }
}

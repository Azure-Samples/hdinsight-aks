package contoso.example.CEP.generator;
import org.apache.flink.streaming.api.functions.source.SourceFunction;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Random;
public class LocalWeatherGenerator implements SourceFunction<LocalWeatherData> {
            private volatile boolean isRunning = true;
            private final Random random = new Random();
            private LocalDateTime dateTime = LocalDateTime.parse("2023-01-01T00:55:00", DateTimeFormatter.ISO_LOCAL_DATE_TIME);
            // Define the sequence of skyCondition and stationPressure values
            private final String[] skyConditions = {"SCT:04 50", "FEW:02 44", "FEW:02 60", "FEW:02 250", "CLR:00", "SCT:04 100 BKN:07 200","SCT:04 50",
                    "FEW:02 44",
                    "FEW:02 60",
                    "FEW:02 250",
                    "CLR:00",
                    "SCT:04 100 BKN:07 200",
                    "SCT:04 100 BKN:07 250",
                    "SCT:04 100 BKN:07 230",
                    "OVC:08 60,29.36,15",
                    "OVC:08 60,29.37,15",
                    "OVC:08 60,29.36,15",
                    "OVC:08 60,29.36,17",
                    "OVC:08 65,29.36,14",
                    "BKN:07 70 BKN:07 85",
                    "SCT:04 75 BKN:07 95",
                    "CLR:00,29.44",
                    "CLR:00,29.48",
                    "CLR:00,29.52",
                    "CLR:00,29.56",
                    "CLR:00,29.58",
                    "FEW:02 25,29.6",
                    "FEW:02 250,29.62",
                    "CLR:00,29.64",
                    "CLR:00,29.64",
                    "FEW:02 250,29.64",
                    "CLR:00,29.65",
                    "FEW:02 250,29.67",
                    "FEW:02 250,29.69" };
            private final float[] stationPressures = {29.36f, 29.37f, 29.36f, 30.36f, 30.36f, 30.44f};
            private int index = 0;
            @Override
            public void run(SourceContext<LocalWeatherData> ctx) throws Exception {
                while (isRunning) {
                    int temperature = getTemperature(dateTime.getMonthValue());
                    int windSpeed = random.nextInt(21);

                    // Get the current skyCondition and stationPressure from the sequences
                    String skyCondition = skyConditions[index % skyConditions.length];
                    float stationPressure = stationPressures[index % stationPressures.length];
                    index++;

                    ctx.collect(new LocalWeatherData("72306613713", dateTime.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME), temperature, skyCondition, stationPressure, windSpeed));
                    dateTime = dateTime.plusHours(1);
                    Thread.sleep(10); // sleep for a while before generating the next data
                }
            }

            @Override
            public void cancel() {
                isRunning = false;
            }

            private int getTemperature(int month) {
                if (month == 12 || month == 1 || month == 2) {
                    return -20 + random.nextInt(31); // -20 ~ 10
                } else if (month == 3 || month == 4 || month == 5) {
                    return 5 + random.nextInt(20); // 5 ~ 24
                } else if (month >= 6 && month <= 7) {
                    return 20 + random.nextInt(21); // 20 ~ 27
                } else if (month >= 8 && month <= 9) {
                    return 20 + random.nextInt(21); // 25 ~ 44
                } else { // month == 10 || month == 11
                    return 10 + random.nextInt(16); // 10 ~ 25
                }
            }

}


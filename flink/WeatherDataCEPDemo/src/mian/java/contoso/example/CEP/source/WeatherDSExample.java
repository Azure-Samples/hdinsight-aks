package contoso.example.CEP.source;

import com.microsoft.azure.flink.config.KustoConnectionOptions;
import com.microsoft.azure.flink.config.KustoWriteOptions;
import com.microsoft.azure.kusto.KustoWriteSink;
import contoso.example.CEP.generator.LocalWeatherData;
import contoso.example.CEP.generator.LocalWeatherGenerator;
import org.apache.flink.api.common.functions.FilterFunction;
import org.apache.flink.api.java.functions.KeySelector;
import org.apache.flink.connector.base.DeliveryGuarantee;
import org.apache.flink.connector.jdbc.JdbcConnectionOptions;
import org.apache.flink.connector.jdbc.JdbcExecutionOptions;
import org.apache.flink.connector.jdbc.JdbcSink;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.datastream.KeyedStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.AscendingTimestampExtractor;
import org.apache.flink.streaming.api.windowing.time.Time;

import java.sql.PreparedStatement;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;

public class WeatherDSExample {
    public static void main(String[] args) throws Exception {
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        // use LocalWeatherGenerator to generator local weather data
        DataStream<LocalWeatherData> weatherDataStream = env.addSource(new LocalWeatherGenerator());

        // assign the Measurement Timestamp:
        DataStream<LocalWeatherData> localWeatherDataDataStream = weatherDataStream
                .assignTimestampsAndWatermarks(new AscendingTimestampExtractor<LocalWeatherData>() {
                    @Override
                    public long extractAscendingTimestamp(LocalWeatherData localWeatherData) {
                        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
                        Date measurementTime;
                        try {
                            measurementTime = dateFormat.parse(localWeatherData.getDate());
                        } catch (ParseException e) {
                            throw new RuntimeException("Unable to parse date " + localWeatherData.getDate(), e);
                        }
                        return measurementTime.getTime();
                    }
                });

        // First build a KeyedStream over the Data with LocalWeather:
        KeyedStream<LocalWeatherData, String> localWeatherDataByStation = localWeatherDataDataStream
                // Filter for Non-Null Temperature Values, because we might have missing data:
                .filter(new FilterFunction<LocalWeatherData>() {
                    @Override
                    public boolean filter(LocalWeatherData localWeatherData) throws Exception {
                        return localWeatherData.getTemperature() != null;
                    }
                })
                // Now create the keyed stream by the Station WBAN identifier:
                .keyBy(new KeySelector<LocalWeatherData, String>() {
                    @Override
                    public String getKey(LocalWeatherData localWeatherData) throws Exception {
                        return localWeatherData.getStation();
                    }
                });

        // Now take the Maximum Temperature per day from the KeyedStream:
        DataStream<LocalWeatherData> maxTemperaturePerDay =
                localWeatherDataByStation
                        // Use non-overlapping tumbling window with 1 day length:
                        .timeWindow(Time.days(1))
                        // And use the maximum temperature:
                        .maxBy("temperature");

        // Configure Azure Kusto connection options
        String appId = "<client_id>";
        String appKey = "<appkey>";
        String tenantId = "<tenant_id>";
        String clusterUrl = "https://<adxname>.<region>.kusto.windows.net";
        String database = "DB1";
        String tableName = "WeatherTable";

        // Define KustoConnectionOptions
        KustoConnectionOptions kustoConnectionOptions = KustoConnectionOptions.builder()
                .withAppId(appId)
                .withAppKey(appKey)
                .withTenantId(tenantId)
                .withClusterUrl(clusterUrl).build();

        // Define KustoWriteOptions
        KustoWriteOptions kustoWriteOptions = KustoWriteOptions.builder()
                .withDatabase(database)
                .withTable(tableName)
                .withDeliveryGuarantee(DeliveryGuarantee.AT_LEAST_ONCE)
                .build();

        // Sink data to Azure Kusto
        KustoWriteSink.builder().setWriteOptions(kustoWriteOptions)
                .setConnectionOptions(kustoConnectionOptions).build(maxTemperaturePerDay,1);

        // Sink data to postgres DB
        maxTemperaturePerDay.addSink(
                JdbcSink.sink(
                        "INSERT INTO WeatherTable (station, date, temperature, skyCondition, stationPressure, windSpeed) VALUES (?, ?, ?, ?, ?, ?)",
                        (PreparedStatement statement, LocalWeatherData weatherData) -> {
                            statement.setString(1, weatherData.getStation());
                            // Convert the date string to a Timestamp
                            SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
                            Date parsedDate = null;
                            try {
                                parsedDate = dateFormat.parse(weatherData.getDate());
                            } catch (ParseException e) {
                                throw new RuntimeException(e);
                            }
                            java.sql.Timestamp timestamp = new java.sql.Timestamp(parsedDate.getTime());

                            statement.setTimestamp(2, timestamp);
                            statement.setString(3, weatherData.getTemperature().toString());
                            statement.setString(4, weatherData.getSkyCondition());
                            statement.setString(5, weatherData.getStationPressure().toString());
                            statement.setString(6, weatherData.getWindSpeed().toString());
                        },
                        new JdbcExecutionOptions.Builder()
                                .withBatchSize(1000)
                                .withBatchIntervalMs(200)
                                .withMaxRetries(5)
                                .build(),
                        new JdbcConnectionOptions.JdbcConnectionOptionsBuilder()
                                .withUrl("jdbc:postgresql://<postgresservername>.postgres.database.azure.com:5432/<dbname>")
                                .withDriverName("org.postgresql.Driver")
                                .withUsername("<dbusername>")
                                .withPassword("<password>")
                                .build()
                )
        );

        // Add your CEP logic here...
        env.execute("Take the Maximum Temperature per day");
    }
}

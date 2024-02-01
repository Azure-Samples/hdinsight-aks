package contoso.example;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.functions.MapFunction;
import org.apache.flink.api.common.serialization.SimpleStringEncoder;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.configuration.MemorySize;
import org.apache.flink.connector.base.DeliveryGuarantee;

import org.apache.flink.connector.file.sink.FileSink;
import org.apache.flink.connector.kafka.sink.KafkaRecordSerializationSchema;
import org.apache.flink.connector.kafka.sink.KafkaSink;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;

import org.apache.flink.core.fs.Path;
import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.flink.streaming.api.datastream.*;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.sink.filesystem.rollingpolicies.DefaultRollingPolicy;
import org.apache.flink.streaming.api.functions.windowing.WindowFunction;
import org.apache.flink.streaming.api.windowing.assigners.TumblingProcessingTimeWindows;
import org.apache.flink.streaming.api.windowing.time.Time;
import org.apache.flink.streaming.api.windowing.windows.TimeWindow;
import org.apache.flink.util.Collector;
import org.json.JSONArray;
import org.json.JSONObject;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.HashSet;
import java.util.Set;

public class SuspiciousActivities {
    public static void main(String[] args) throws Exception {
        // 1. get stream execution environment
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment().setParallelism(6);

        // 2. read kafka message as stream input
        String kafka_brokers = "<Kafka Broker list:9092>";
        KafkaSource<String> source = KafkaSource.<String>builder()
                .setBootstrapServers(kafka_brokers)
                .setTopics("transaction_mid")
                .setGroupId("my-group")
                .setStartingOffsets(OffsetsInitializer.earliest())
                .setValueOnlyDeserializer(new SimpleStringSchema())
                .build();

        DataStream<String> stream = env.fromSource(source, WatermarkStrategy.noWatermarks(), "Kafka Source");

        // 3. transformation:
        SingleOutputStreamOperator<Transaction> transactions = stream.map(new MapFunction<String, Transaction>() {
            @Override
            public Transaction map(String value) throws Exception {
                ObjectMapper objectMapper = new ObjectMapper();
                Transaction transaction = objectMapper.readValue(value, Transaction.class);
                return transaction;
            }
        });

        KeyedStream<Transaction, Long> keyed = transactions.keyBy(transaction -> transaction.user_id);
        WindowedStream<Transaction, Long, TimeWindow> windowed = keyed.window(TumblingProcessingTimeWindows.of(Time.hours(1)));

        SingleOutputStreamOperator<String> result = windowed.apply(new WindowFunction<Transaction, String, Long, TimeWindow>() {
            @Override
            public void apply(Long userId, TimeWindow window, Iterable<Transaction> transactions, Collector<String> out) throws Exception {
                BigDecimal totalAmount = BigDecimal.ZERO;
                Set<String> countries = new HashSet<>();
                String user_id = null;
                String user_name = null;
                String user_surname = null;
                String user_middle_name = null;
                String user_phone_number = null;
                String user_mail_address = null;
                Boolean user_suspicious_activity = false;
                String transaction_currency = null;

                for (Transaction transaction : transactions) {
                    totalAmount = totalAmount.add(transaction.transaction_amount);
                    countries.add(transaction.transaction_country);
                    user_id = String.valueOf(transaction.user_id);
                    user_surname = transaction.user_surname;
                    user_middle_name = transaction.user_middle_name;
                    user_phone_number = transaction.user_phone_number;
                    user_mail_address = transaction.user_mail_address;
                    transaction_currency = transaction.transaction_currency;
                }

                if (totalAmount.compareTo(new BigDecimal("30000")) > 0 && countries.size() > 1) {
                    user_suspicious_activity = true;
                }

                JSONObject json = new JSONObject();
                json.put("user_id", user_id);
                json.put("user_name", user_name);
                json.put("user_surname", user_surname);
                json.put("user_middle_name", user_middle_name);
                json.put("user_phone_number", user_phone_number);
                json.put("user_mail_address", user_mail_address);
                json.put("user_suspicious_activity", user_suspicious_activity);
                json.put("transaction_amount", totalAmount);
                json.put("transaction_currency", transaction_currency);
                json.put("transaction_countries", new JSONArray(countries));
                json.put("window_start_time", window.getStart());
                json.put("window_end_time", window.getEnd());

                out.collect(json.toString());
            }
        }
        );

        // 4. sink click into another kafka events topic
        KafkaSink<String> sinkToKafka = KafkaSink.<String>builder()
                .setBootstrapServers(kafka_brokers)
                .setProperty("transaction.timeout.ms","900000")
                .setRecordSerializer(KafkaRecordSerializationSchema.builder()
                        .setTopic("suspicious_activities")
                        .setValueSerializationSchema(new SimpleStringSchema())
                        .build())
                .setDeliveryGuarantee(DeliveryGuarantee.EXACTLY_ONCE)
                .build();

        // 4. sink to gen2
        String outputPath  = "abfs://container1@cicihilogen2.dfs.core.windows.net/flink/suspicious_activities";
        final FileSink<String> sinkToGen2 = FileSink
                .forRowFormat(new Path(outputPath), new SimpleStringEncoder<String>("UTF-8"))
                .withRollingPolicy(
                        DefaultRollingPolicy.builder()
                                .withRolloverInterval(Duration.ofMinutes(2))
                                .withInactivityInterval(Duration.ofMinutes(3))
                                .withMaxPartSize(MemorySize.ofMebiBytes(5))
                                .build())
                .build();

        result.sinkTo(sinkToKafka);
        result.sinkTo(sinkToGen2);

        // 5. execute the stream
        env.execute("published this activity to suspicious_activities kafka topic and ADLS gen2");
    }
}

package contoso.example;

import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.connector.base.DeliveryGuarantee;
import org.apache.flink.connector.kafka.sink.KafkaRecordSerializationSchema;
import org.apache.flink.connector.kafka.sink.KafkaSink;
import org.apache.flink.streaming.api.datastream.DataStreamSource;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import com.ververica.cdc.debezium.JsonDebeziumDeserializationSchema;
import com.ververica.cdc.connectors.mysql.source.MySqlSource;
import org.apache.kafka.connect.json.JsonConverterConfig;

import java.util.HashMap;
import java.util.Map;

public class MySqlBinlogSinkToKafka1 {
    public static void main(String[] args) throws Exception {

        String kafka_brokers = "<Kafka Broker list:9092>";

        Map<String, Object> customConverterConfigs = new HashMap<>();
        customConverterConfigs.put(JsonConverterConfig.DECIMAL_FORMAT_CONFIG, "numeric");

        MySqlSource<String> mySqlSource = MySqlSource.<String>builder()
                .hostname("<mysql on Azure host name>")
                .port(3306)
                .databaseList("payment")
                .tableList("payment.transactions")
                .username("<user_name>")
                .password("<Password>")
                .deserializer(new JsonDebeziumDeserializationSchema(false, customConverterConfigs)) // 
                .build();

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        // set checkpoint interval: 3s
        env.enableCheckpointing(3000);

        DataStreamSource<String> stream = env.fromSource(mySqlSource, WatermarkStrategy.noWatermarks(), "MySQL Source")
                .setParallelism(1);
        stream.print();

        // 3. sink table transaction binlog to kafka
        KafkaSink<String> sink = KafkaSink.<String>builder()
                .setBootstrapServers(kafka_brokers)
                .setRecordSerializer(KafkaRecordSerializationSchema.builder()
                        .setTopic("transactions")
                        .setValueSerializationSchema(new SimpleStringSchema())
                        .build()
                )
                .setDeliveryGuarantee(DeliveryGuarantee.EXACTLY_ONCE)
                .build();

        stream.sinkTo(sink);

        env.execute("Sink MySQL Table transactions Binlog To Kafka");
    }
}

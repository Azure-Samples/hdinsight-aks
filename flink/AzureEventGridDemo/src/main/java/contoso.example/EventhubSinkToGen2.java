package contoso.example;

import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.serialization.SimpleStringEncoder;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.api.java.utils.ParameterTool;
import org.apache.flink.configuration.MemorySize;
import org.apache.flink.connector.file.sink.FileSink;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.core.fs.Path;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.sink.filesystem.rollingpolicies.DefaultRollingPolicy;

import java.io.FileReader;
import java.time.Duration;
import java.util.Properties;

public class EventhubSinkToGen2 {
    public static void main(String[] args) throws Exception {

        // 1. get stream execution environment
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        // checkpointing is set to 10 seconds
        env.enableCheckpointing(10000);
        String checkPointPath = "<container>@<storage_account>.dfs.core.windows.net/CheckPoint";
        env.getCheckpointConfig().setCheckpointStorage(checkPointPath);

        ParameterTool parameters = ParameterTool.fromArgs(args);
        String input = parameters.get("input");
        Properties properties = new Properties();
        properties.load(new FileReader(input));

        // 2. read  eventhub kafka message as stream input
        KafkaSource<String> source = KafkaSource.<String>builder().setProperties(properties)
                .setTopics("test")
                .setGroupId("group1")
                .setStartingOffsets(OffsetsInitializer.latest())
                .setValueOnlyDeserializer(new CustomDeserializationSchema())
                .build();

        DataStream<String> stream = env.fromSource(source, WatermarkStrategy.noWatermarks(), "Eventhub Kafka Source");

        // 3. sink to gen2
        String outputPath  = "abfs://<container>@<storage_account>.dfs.core.windows.net/eventhub/test";
        final FileSink<String> sink = FileSink
                .forRowFormat(new Path(outputPath), new SimpleStringEncoder<String>("UTF-8"))
                .withRollingPolicy(
                        DefaultRollingPolicy.builder()
                                .withRolloverInterval(Duration.ofMinutes(5))
                                .withInactivityInterval(Duration.ofMinutes(3))
                                .withMaxPartSize(MemorySize.ofMebiBytes(5))
                                .build())
                .build();

        stream.sinkTo(sink);

        // 4. run stream
        env.execute("eventhub kafka sink to adls gen2");
    }
}

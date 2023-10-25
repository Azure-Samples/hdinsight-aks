package contoso.example;

import org.apache.flink.api.common.serialization.SimpleStringEncoder;
import org.apache.flink.configuration.MemorySize;
import org.apache.flink.connector.file.sink.FileSink;
import org.apache.flink.core.fs.Path;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.sink.filesystem.rollingpolicies.DefaultRollingPolicy;

import java.time.Duration;

public class ServiceBusToAdlsGen2 {

    public static void main(String[] args) throws Exception {

        // Set up the execution environment
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        final String connectionString = "Endpoint=sb://contososervicebus.servicebus.windows.net/;SharedAccessKeyName=policy1;SharedAccessKey=<key>";
        final String topicName = "topic1";
        final String subName = "subscription1";

        // Create a source function for Azure Service Bus
        SessionBasedServiceBusSource sourceFunction = new SessionBasedServiceBusSource(connectionString, topicName, subName);

        // Create a data stream using the source function
        DataStream<String> stream = env.addSource(sourceFunction);

        // Process the data (this is where you'd put your processing logic)
        DataStream<String> processedStream = stream.map(value -> processValue(value));
        processedStream.print();

        // 3. sink to gen2
        String outputPath = "abfs://<container>@<account>.dfs.core.windows.net/data/ServiceBus/Topic1";
//        String outputPath = "src/ServiceBugOutput/";

        final FileSink<String> sink = FileSink
                .forRowFormat(new Path(outputPath), new SimpleStringEncoder<String>("UTF-8"))
                .withRollingPolicy(
                        DefaultRollingPolicy.builder()
                                .withRolloverInterval(Duration.ofMinutes(2))
                                .withInactivityInterval(Duration.ofMinutes(3))
                                .withMaxPartSize(MemorySize.
                                        ofMebiBytes(5))
                                .build())
                .build();
        // Add the sink function to the processed stream
        processedStream.sinkTo(sink);

        // Execute the job
        env.execute("ServiceBusToDataLakeJob");
    }

    private static String processValue(String value) {
        // Implement your processing logic here
        return value;
    }
}

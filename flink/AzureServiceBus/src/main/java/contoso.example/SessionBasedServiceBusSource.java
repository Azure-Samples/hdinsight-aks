package contoso.example;

import com.azure.messaging.servicebus.ServiceBusClientBuilder;
import com.azure.messaging.servicebus.ServiceBusSessionReceiverAsyncClient;
import org.apache.flink.streaming.api.functions.source.RichParallelSourceFunction;
import org.apache.flink.streaming.api.functions.source.SourceFunction;

public class SessionBasedServiceBusSource extends RichParallelSourceFunction<String> {

    private final String connectionString;
    private final String topicName;
    private final String subscriptionName;
    private volatile boolean isRunning = true;
    private ServiceBusSessionReceiverAsyncClient sessionReceiver;

    public SessionBasedServiceBusSource(String connectionString, String topicName, String subscriptionName) {
        this.connectionString = connectionString;
        this.topicName = topicName;
        this.subscriptionName = subscriptionName;
    }

    @Override
    public void run(SourceFunction.SourceContext<String> ctx) throws Exception {
        ServiceBusSessionReceiverAsyncClient sessionReceiver = new ServiceBusClientBuilder()
                .connectionString(connectionString)
                .sessionReceiver()
                .topicName(topicName)
                .subscriptionName(subscriptionName)
                .buildAsyncClient();

        sessionReceiver.acceptNextSession()
                .flatMapMany(session -> session.receiveMessages())
                .doOnNext(message -> {
                    try {
                        ctx.collect(message.getBody().toString());
                    } catch (Exception e) {
                        System.out.printf("An error occurred: %s.", e.getMessage());
                    }
                })
                .doOnError(error -> System.out.printf("An error occurred: %s.", error.getMessage()))
                .blockLast();
    }

    @Override
    public void cancel() {
        isRunning = false;
        if (sessionReceiver != null) {
            sessionReceiver.close();
        }
    }
}

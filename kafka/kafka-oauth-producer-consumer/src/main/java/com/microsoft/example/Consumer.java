package com.microsoft.example;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;

import java.time.Duration;
import java.util.Collections;
import java.util.Properties;

import static com.microsoft.example.CommonUtils.getPropertiesFromFile;

public class Consumer {
    public static void consume(String filePath, String groupId, String topicName) throws Exception {
        // Configure the consumer
        Properties properties = getPropertiesFromFile(filePath);
        // Set the consumer group (all consumers must belong to a group).
        properties.setProperty(ConsumerConfig.GROUP_ID_CONFIG, groupId);
        // Set how to serialize key/value pairs
        properties.setProperty(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG,"org.apache.kafka.common.serialization.StringDeserializer");
        properties.setProperty(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG,"org.apache.kafka.common.serialization.StringDeserializer");
        // When a group is first created, it has no offset stored to start reading from. This tells it to start
        // with the earliest record in the stream.
        properties.setProperty(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG,"earliest");
        properties.setProperty(ConsumerConfig.FETCH_MAX_BYTES_CONFIG, "10485880");

        // specify the protocol for Domain Joined clusters
        //properties.setProperty(CommonClientConfigs.SECURITY_PROTOCOL_CONFIG, "SASL_PLAINTEXT");

        try (KafkaConsumer<String, String> consumer = new KafkaConsumer<>(properties)) {

            // Subscribe to the 'test' topic
            consumer.subscribe(Collections.singletonList(topicName));

            // Loop until ctrl + c
            int messagesCount = 0;
            while (messagesCount < Constants.MAX_MESSAGES) {
                ConsumerRecords<String, String> records = consumer.poll(Duration.ofSeconds(30));
                // Did we get any?
                if (records.count() != 0) {
                    for(ConsumerRecord<String, String> record: records) {
                        // Display record and count
                        System.out.printf("key=%s, value=%s, partition=%d, offset=%d%n",
                                record.key(), record.value(), record.partition(), record.offset());
                    }
                }
                messagesCount += records.count();
            }
            // Poll for records
            System.out.printf("Total records consumed: %d\n", messagesCount);

        } catch (Exception exception) {
            System.out.println(exception.getMessage());
            throw new Exception(exception.toString());
        }
    }
}

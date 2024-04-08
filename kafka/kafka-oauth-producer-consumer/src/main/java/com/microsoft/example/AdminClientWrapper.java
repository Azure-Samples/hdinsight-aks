package com.microsoft.example;

import org.apache.kafka.clients.admin.*;
import org.apache.kafka.clients.producer.ProducerConfig;

import java.io.IOException;
import java.util.Collections;
import java.util.Properties;

import static com.microsoft.example.CommonUtils.getPropertiesFromFile;


public class AdminClientWrapper {

    public static void describeTopics(String filePath, String topicName) throws IOException {
        // Set properties used to configure admin client
        Properties properties = getPropertiesFromFile(filePath);

        try (final AdminClient adminClient = KafkaAdminClient.create(properties)) {
            // Make async call to describe the topic.
            final DescribeTopicsResult describeTopicsResult = adminClient.describeTopics(Collections.singleton(topicName));

            TopicDescription description = describeTopicsResult.values().get(topicName).get();
            System.out.println(description.toString());
        } catch (Exception e) {
            System.out.println("Describe denied");
            System.out.println(e.getMessage());
            //throw new RuntimeException(e.getMessage(), e);
        }
    }

    public static void deleteTopics(String filePath, String topicName) throws IOException {
        // Set properties used to configure admin client
        Properties properties = getPropertiesFromFile(filePath);

        try (final AdminClient adminClient = KafkaAdminClient.create(properties)) {
            final DeleteTopicsResult deleteTopicsResult = adminClient.deleteTopics(Collections.singleton(topicName));
            deleteTopicsResult.values().get(topicName).get();
            System.out.println("Topic " + topicName + " deleted");
        } catch (Exception e) {
            System.out.println("Delete Topics denied");
            System.out.println(e.getMessage());
            //throw new RuntimeException(e.getMessage(), e);
        }
    }

    public static void createTopics(String filePath, String topicName) throws IOException {
        // Set properties used to configure admin client
        Properties properties = getPropertiesFromFile(filePath);
        properties.setProperty(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
        properties.setProperty(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");

        try (final AdminClient adminClient = KafkaAdminClient.create(properties)) {
            final NewTopic newTopic = new NewTopic(topicName, Constants.NUM_PARTITIONS, Constants.REPLICATION_FACTOR);

            final CreateTopicsResult createTopicsResult = adminClient.createTopics(Collections.singleton(newTopic));
            createTopicsResult.values().get(topicName).get();
            System.out.println("Topic " + topicName + " created");
        } catch (Exception e) {
            System.out.println("Create Topics denied");
            System.out.println(e.getMessage());
            //throw new RuntimeException(e.getMessage(), e);
        }
    }
}

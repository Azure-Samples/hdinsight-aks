package com.microsoft.example;

import java.util.UUID;

// Handle starting producer or consumer
public class Run {
    public static void main(String[] args) throws Exception {
        if(args.length < 3) {
            usage();
        }

        String topicName = args[1];
        String filePath = args[2];

        switch(args[0].toLowerCase()) {
            case "producer":
                Producer.produce(filePath, topicName);
                break;
            case "consumer":
                // Either a groupId was passed in, or we need a random one
                String groupId;
                if(args.length == 4) {
                    groupId = args[3];
                } else {
                    groupId = UUID.randomUUID().toString();
                }
                Consumer.consume(filePath, groupId, topicName);
                break;
            case "describe":
                AdminClientWrapper.describeTopics(filePath, topicName);
                break;
            case "create":
                AdminClientWrapper.createTopics(filePath, topicName);
                break;
            case "delete":
                AdminClientWrapper.deleteTopics(filePath, topicName);
                break;
            default:
                usage();
        }
        System.exit(0);
    }
    // Display usage
    public static void usage() {
        System.out.println("Usage:");
        System.out.println("kafka-oauth-producer-consumer.jar <producer|consumer|describe|create|delete> <topicName> <clientPropertiesFilePath> [groupid]");
        System.exit(1);
    }
}

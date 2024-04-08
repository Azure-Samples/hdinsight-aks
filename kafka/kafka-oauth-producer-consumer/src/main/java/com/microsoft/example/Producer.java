package com.microsoft.example;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.io.IOException;
import java.util.Properties;
import java.util.Random;

import static com.microsoft.example.CommonUtils.getPropertiesFromFile;
import static com.microsoft.example.Constants.MAX_MESSAGES;

public class Producer
{
    public static void produce(String filePath, String topicName) throws IOException
    {

        Properties properties = getPropertiesFromFile(filePath);
        properties.setProperty(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
        properties.setProperty(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");

        try (KafkaProducer<String, String> producer = new KafkaProducer<>(properties)) {
            Random random = new Random();
            String[] sentences = new String[] {
                    "the cow jumped over the moon",
                    "an apple a day keeps the doctor away",
                    "four score and seven years ago",
                    "snow white and the seven dwarfs",
                    "i am at two with nature"
            };

            String progressAnimation = "|/-\\";
            // Produce a bunch of records
            for(int i = 0; i < MAX_MESSAGES; i++) {
                // Pick a sentence at random
                String sentence = sentences[random.nextInt(sentences.length)];
                String key = String.valueOf(i);
                // Send the sentence to the test topic
                try {
                    producer.send(new ProducerRecord<>(topicName, key, sentence)).get();
                }
                catch (Exception ex) {
                    System.out.println(ex.getMessage());
                    throw new IOException(ex.toString());
                }
                String progressBar = "\r" + progressAnimation.charAt(i % progressAnimation.length()) + " " + i;
                System.out.write(progressBar.getBytes());
            }
        }
    }
}

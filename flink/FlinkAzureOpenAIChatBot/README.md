**Below blog code integrates Apache Flink 1.17.0 on HDInsight on AKS with OpenAI to create an intelligent chatbot that can answer questions about U.S. Presidents. The chatbot’s responses are processed in real-time using Flink, allowing it to provide immediate feedback.**

OpenAI’s GPT-4 model is capable of understanding and generating human-like text, making it a powerful tool for building intelligent chatbots.

## Prerequisites
• Flink 1.17.0 on HDInsight on AKS <br>
• Azure OpenAI service <br>
• Maven Project <br>

## Flink on HDInsight on AKS <br>

https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-overview

## Azure OpenAI service  <br>

https://learn.microsoft.com/en-us/azure/ai-services/openai/overview

The Azure OpenAI service provides REST API access to OpenAI's powerful language models on the Azure cloud. These models can be easily adapted to your specific task including but not limited to content generation, summarization, semantic search, and natural language to code translation. Users can access the service through REST APIs, Python SDK, .NET SDK, or our web-based interface in the Azure OpenAI Studio.

OpenAI’s GPT-4 model is capable of understanding and generating human-like text, making it a powerful tool for building intelligent chatbots.

**Retrieve key and endpoint** <br>
To successfully make a call against Azure OpenAI, you need an endpoint and a key.
```
Variable name	 Value
ENDPOINT     	 This value can be found in the Keys & Endpoint section when examining your resource from the Azure portal. An example endpoint is: https://docs-test-001.openai.azure.com/. 
API-KEY	       This value can be found in the Keys & Endpoint section when examining your resource from the Azure portal. You can use either KEY1 or KEY2.
```

Go to your resource in the Azure portal. The Keys & Endpoint section can be found in the Resource Management section. Copy your endpoint and access key as you'll need both for authenticating your API calls. You can use either KEY1 or KEY2. Always having two keys allows you to securely rotate and regenerate keys without causing a service disruption.

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/e3096bb2-2fb2-4a77-b1e0-05eb3a5ab582)


## Maven Depedencies

``` xml
 <properties>
        <maven.compiler.source>1.8</maven.compiler.source>
        <maven.compiler.target>1.8</maven.compiler.target>
        <flink.version>1.17.0</flink.version>
        <java.version>1.8</java.version>
    </properties>
    <dependencies>
        <!-- https://mvnrepository.com/artifact/org.apache.flink/flink-streaming-java -->
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-streaming-java</artifactId>
            <version>${flink.version}</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.apache.flink/flink-core -->
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-core</artifactId>
            <version>${flink.version}</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.apache.flink/flink-clients -->
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-clients</artifactId>
            <version>${flink.version}</version>
        </dependency>
  <!-- https://mvnrepository.com/artifact/com.azure/azure-ai-openai -->
        <dependency>
            <groupId>com.azure</groupId>
            <artifactId>azure-ai-openai</artifactId>
            <version>1.0.0-beta.3</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/com.azure/azure-identity -->
        <dependency>
            <groupId>com.azure</groupId>
            <artifactId>azure-identity</artifactId>
            <version>1.12.2</version>
            <scope>compile</scope>
        </dependency>
```

## Main Source Code in java
``` java
package contoso.example;

import com.azure.ai.openai.OpenAIClient;
import com.azure.ai.openai.OpenAIClientBuilder;
import com.azure.ai.openai.models.*;
import com.azure.core.credential.AzureKeyCredential;
import org.apache.flink.streaming.api.datastream.AsyncDataStream;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.async.AsyncFunction;
import org.apache.flink.streaming.api.functions.async.ResultFuture;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.TimeUnit;

public class test2 {
    public static void main(String[] args) throws Exception {
        // create Apache Flink execution environment
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment().setParallelism(1);

        // create an input stream
        DataStream<String> testStream = env.fromElements("Bill Smith","Joe Biden","Donald John Trump","William Jefferson Clinton","Franklin Delano Roosevelt","Abraham Lincoln","George Washington");

        // create a processing stream
        DataStream<String> resultDataStream = AsyncDataStream.unorderedWait(
                testStream, new AsyncHttpRequestFunction(), 60000, TimeUnit.MILLISECONDS, 100);

        // output data
        resultDataStream.print();

        // execute the job
        env.execute("Flink plus OpenAI");
    }

    public static class AsyncHttpRequestFunction implements AsyncFunction<String, String> {

        @Override
        public void asyncInvoke(String input, ResultFuture<String> resultFuture) {
            OpenAIClient client = null;
            try {
                // OpenAI API endpoint for text completion
                String azureOpenaiKey = "0762e377c9b54819a267a142adcbcfcb";
                String endpoint = "https://hanaoai-sc.openai.azure.com/";
                String deploymentOrModelId = "gpt40409";

                client = new OpenAIClientBuilder()
                        .endpoint(endpoint)
                        .credential(new AzureKeyCredential(azureOpenaiKey))
                        .buildClient();

                List<ChatMessage> chatMessages = new ArrayList<>();
                chatMessages.add(new ChatMessage(ChatRole.SYSTEM, "Assistant is an intelligent chatbot designed to help users answer their tax related questions.\n" +
                        "Instructions: \n" +
                        "- Only answer questions related to President of the United States. \n" +
                        "- If you're unsure of an answer, you can say \"I don't know\" or \"I'm not sure\" and recommend users go to the IRS website for more information. \""));
                chatMessages.add(new ChatMessage(ChatRole.USER, "Can you help me?"));
                chatMessages.add(new ChatMessage(ChatRole.ASSISTANT, "Of course! What can I do for you?"));
                chatMessages.add(new ChatMessage(ChatRole.USER, "Birthday and Which term of presidency of President of the United States: " + input));

                ChatCompletions chatCompletions = client.getChatCompletions(deploymentOrModelId, new ChatCompletionsOptions(chatMessages));

                System.out.printf("Model ID=%s is created at %s.%n", chatCompletions.getId(), chatCompletions.getCreatedAt());

                for (ChatChoice choice : chatCompletions.getChoices()) {
                    ChatMessage message = choice.getMessage();
                    System.out.printf("Index: %d, Chat Role: %s.%n", choice.getIndex(), message.getRole());
                    System.out.println("Message:");
                    System.out.println(message.getContent());
                }

                System.out.println();
                CompletionsUsage usage = chatCompletions.getUsage();
                System.out.printf("Usage: number of prompt token is %d, "
                                + "number of completion token is %d, and number of total tokens in request and response is %d.%n",
                        usage.getPromptTokens(), usage.getCompletionTokens(), usage.getTotalTokens());
            } catch (Exception e) {
                e.printStackTrace();
            }
            }

        @Override
        public void timeout(String input, ResultFuture<String> resultFuture) throws Exception {
            System.out.println("Timeout occurred for input: " + input);
            resultFuture.complete(Collections.emptyList());
        }

        }
    }

```
## breakdown of the Code <br>
• The **main** method sets up the Flink execution environment, creates an input data stream, sets up the processing stream, prints the output data, and then executes the job.<br>
• The **AsyncHttpRequestFunctio**n class implements the AsyncFunction interface, which allows for asynchronous I/O operations in Flink. This is useful for operations that are I/O-bound, such as making HTTP requests.<br>
• The **asyncInvoke** method is where the actual processing happens. It takes an input string and a ResultFuture object. The input string is a name of a U.S. president, and the ResultFuture is used to output the result of the processing.<br>
• Inside the asyncInvoke method, an OpenAIClient is created using the provided Azure OpenAI key, endpoint, and model ID. This client is used to interact with the OpenAI API.<br>
• A list of ChatMessage objects is created. These messages simulate a conversation with the OpenAI API. The conversation starts with a system message, followed by a user message asking for help, an assistant message offering help, and finally a user message asking for the birthday and term of presidency of the input president.<br>
• The getChatCompletions method of the OpenAIClient is called with the model ID and the list of chat messages. This sends the conversation to the OpenAI API and gets a response.<br>
• The response from the OpenAI API is printed out. This includes the model ID, the creation time of the model, the content of the messages, and the usage statistics.<br>
• If an exception occurs during the processing, it’s caught and its stack trace is printed.<br>
This code demonstrates how to integrate Apache Flink with Azure OpenAI to process a stream of data in real-time. It’s a powerful combination for big data processing and AI.<br>

## Output
```
Model ID=chatcmpl-9ZrsbpNazsfcgPO6Fcs2LaqvHnvKD is created at 2024-06-14T03:27:01Z.
Index: 0, Chat Role: assistant.
Message:
I'm sorry, but there has never been a President of the United States named Bill Smith. Let me know if you have any other questions or need information on another topic related to the President of the United States!

Usage: number of prompt token is 119, number of completion token is 43, and number of total tokens in request and response is 162.
Model ID=chatcmpl-9ZrsfiYleYzdjDn9McwT4sxwU4oRQ is created at 2024-06-14T03:27:05Z.
Index: 0, Chat Role: assistant.
Message:
Joe Biden, the President of the United States, was born on November 20, 1942. He is currently serving his first term as President, which began on January 20, 2021.

Usage: number of prompt token is 119, number of completion token is 42, and number of total tokens in request and response is 161.
Model ID=chatcmpl-9ZrsjFfB35chhFBzRKTS7ZfjHu6t8 is created at 2024-06-14T03:27:09Z.
Index: 0, Chat Role: assistant.
Message:
Donald John Trump was born on June 14, 1946. He served as the President of the United States during his first term from January 20, 2017, to January 20, 2021.

Usage: number of prompt token is 120, number of completion token is 45, and number of total tokens in request and response is 165.
Model ID=chatcmpl-9ZrsmmaK1I5nrZtWo03lFYwZj1UKi is created at 2024-06-14T03:27:12Z.
Index: 0, Chat Role: assistant.
Message:
William Jefferson Clinton, commonly known as Bill Clinton, was born on August 19, 1946. He served as the President of the United States during two terms, from January 20, 1993, to January 20, 2001.

Usage: number of prompt token is 120, number of completion token is 52, and number of total tokens in request and response is 172.
Model ID=chatcmpl-9Zrsq6QbQfVjxtX3Ijzr9eJZyD52Y is created at 2024-06-14T03:27:16Z.
Index: 0, Chat Role: assistant.
Message:
Franklin Delano Roosevelt, the 32nd President of the United States, was born on January 30, 1882. He served four terms as President, from March 4, 1933, until his death on April 12, 1945.

Usage: number of prompt token is 121, number of completion token is 55, and number of total tokens in request and response is 176.
Model ID=chatcmpl-9Zrsu5WqqmNGnnXTDUrtpJrHgRQ2a is created at 2024-06-14T03:27:20Z.
Index: 0, Chat Role: assistant.
Message:
Abraham Lincoln, the 16th President of the United States, was born on February 12, 1809. He served two terms as President. His first term began on March 4, 1861, and his second term started on March 4, 1865. However, he was assassinated in April 1865, early into his second term.

Usage: number of prompt token is 119, number of completion token is 77, and number of total tokens in request and response is 196.
Model ID=chatcmpl-9Zrt2IMUYtyzdd5EszIsVwwH5g2qi is created at 2024-06-14T03:27:28Z.
Index: 0, Chat Role: assistant.
Message:
George Washington, the first President of the United States, was born on February 22, 1732. He served two terms as President, from April 30, 1789, to March 4, 1797.

Usage: number of prompt token is 119, number of completion token is 47, and number of total tokens in request and response is 166.
```

## Clean up the resource
• Flink 1.17.0 on HDInsight on AKS <br>
• Azure OpenAI service <br>

## Reference





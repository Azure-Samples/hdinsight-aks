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
                String azureOpenaiKey = System.getenv("AZURE_OPENAI_API_KEY");;
                String endpoint = System.getenv("AZURE_OPENAI_ENDPOINT");;
                String deploymentOrModelId = "gpt-4";

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


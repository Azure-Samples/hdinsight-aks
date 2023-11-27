package contoso.example;

import org.apache.flink.api.common.serialization.DeserializationSchema;

import java.io.IOException;
import java.util.Base64;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.flink.api.common.typeinfo.BasicTypeInfo;
import org.apache.flink.api.common.typeinfo.TypeInformation;

// custom deserialization schema to decode the base64 string
public class CustomDeserializationSchema implements DeserializationSchema<String> {
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public String deserialize(byte[] message) throws IOException {
        try {
            // Parse the JSON
            JsonNode jsonNode = objectMapper.readTree(message);
            String body = jsonNode.get("data").get("body").asText();

            // Decode the base64 message
            byte[] decodedBytes = Base64.getDecoder().decode(body);
            return new String(decodedBytes);
        } catch (IllegalArgumentException e) {
            // Handle the case where the input is not a valid Base64 string
            System.err.println("Failed to decode message: " + new String(message));
            throw new IOException("Failed to decode Base64 string", e);
        }
    }

    @Override
    public boolean isEndOfStream(String nextElement) {
        return false;
    }

    @Override
    public TypeInformation<String> getProducedType() {
        return BasicTypeInfo.STRING_TYPE_INFO;
    }
}

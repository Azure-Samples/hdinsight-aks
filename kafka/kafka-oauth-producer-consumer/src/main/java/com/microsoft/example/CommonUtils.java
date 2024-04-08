package com.microsoft.example;

import java.io.FileReader;
import java.io.IOException;
import java.util.Properties;

public class CommonUtils {
    public static Properties getPropertiesFromFile(String filePath) throws IOException {
        Properties properties = new Properties();
        properties.load(new FileReader(filePath));
        return properties;
    }
}
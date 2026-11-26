package com.example.notes_app;

import org.junit.jupiter.api.Test;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.MutablePropertySources;
import org.springframework.core.env.PropertiesPropertySource;
import org.springframework.core.env.PropertySourcesPropertyResolver;

import java.io.IOException;
import java.io.Reader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.Properties;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * BE-06: the app listens on $PORT (Railway injects it) and on 8080 without it.
 * Reads the production file directly: the test classpath has its own
 * application.properties, which shadows it.
 */
class ServerPortConfigTest {

    private static String serverPort(Map<String, Object> environment) throws IOException {
        Properties properties = new Properties();
        try (Reader reader = Files.newBufferedReader(Path.of("src/main/resources/application.properties"))) {
            properties.load(reader);
        }
        MutablePropertySources sources = new MutablePropertySources();
        sources.addLast(new MapPropertySource("environment", environment));
        sources.addLast(new PropertiesPropertySource("application.properties", properties));
        return new PropertySourcesPropertyResolver(sources).getProperty("server.port");
    }

    @Test
    void usesPortFromTheEnvironment() throws IOException {
        assertEquals("9000", serverPort(Map.of("PORT", "9000")));
    }

    @Test
    void defaultsTo8080() throws IOException {
        assertEquals("8080", serverPort(Map.of()));
    }
}

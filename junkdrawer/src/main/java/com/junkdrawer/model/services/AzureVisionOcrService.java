package com.junkdrawer.model.services;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
public class AzureVisionOcrService {

    private static final Logger logger = LoggerFactory.getLogger(AzureVisionOcrService.class);

    @Value("${app.azure.vision.endpoint:}")
    private String endpoint;

    @Value("${app.azure.vision.api-key:}")
    private String apiKey;

    @Value("${app.azure.vision.language:es}")
    private String language;

    @Value("${app.azure.vision.ocr-timeout-seconds:30}")
    private long timeoutSeconds;

    private final ObjectMapper objectMapper = new ObjectMapper();

    public Optional<String> extractText(byte[] imageBytes) {
        if (imageBytes == null || imageBytes.length == 0) {
            return Optional.empty();
        }

        if (endpoint == null || endpoint.isBlank() || apiKey == null || apiKey.isBlank()) {
            logger.warn("Azure Vision OCR no configurado: endpoint o api key ausentes");
            return Optional.empty();
        }

        try {
            String normalizedEndpoint = endpoint.endsWith("/") ? endpoint.substring(0, endpoint.length() - 1) : endpoint;
            String queryLanguage = URLEncoder.encode(language, StandardCharsets.UTF_8);
            URI uri = URI.create(normalizedEndpoint + "/vision/v4.0/ocr?language=" + queryLanguage + "&detectOrientation=true");

            HttpClient client = HttpClient.newBuilder()
                    .connectTimeout(Duration.ofSeconds(10))
                    .build();

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(uri)
                    .timeout(Duration.ofSeconds(timeoutSeconds))
                    .header("Ocp-Apim-Subscription-Key", apiKey)
                    .header("Content-Type", "application/octet-stream")
                    .POST(HttpRequest.BodyPublishers.ofByteArray(imageBytes))
                    .build();

            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
            logger.error(response.toString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                logger.warn("Azure Vision OCR devolvio HTTP {}: {}", response.statusCode(), response.body());
                return Optional.empty();
            }

            String text = parseOcrText(response.body());
            if (text.isBlank()) {
                return Optional.empty();
            }
            return Optional.of(text);
        } catch (IOException | InterruptedException exception) {
            if (exception instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            logger.warn("Fallo al invocar Azure Vision OCR: {}", exception.getMessage());
            return Optional.empty();
        } catch (Exception exception) {
            logger.warn("No se pudo procesar respuesta OCR de Azure Vision: {}", exception.getMessage());
            return Optional.empty();
        }
    }

    private String parseOcrText(String responseBody) throws IOException {
        JsonNode root = objectMapper.readTree(responseBody);
        JsonNode regions = root.get("regions");
        if (regions == null || !regions.isArray()) {
            return "";
        }

        StringBuilder textBuilder = new StringBuilder();
        for (JsonNode region : regions) {
            JsonNode lines = region.get("lines");
            if (lines == null || !lines.isArray()) {
                continue;
            }

            for (JsonNode line : lines) {
                JsonNode words = line.get("words");
                if (words == null || !words.isArray()) {
                    continue;
                }

                StringBuilder lineBuilder = new StringBuilder();
                for (JsonNode word : words) {
                    String token = word.path("text").asText("").trim();
                    if (token.isEmpty()) {
                        continue;
                    }
                    if (lineBuilder.length() > 0) {
                        lineBuilder.append(' ');
                    }
                    lineBuilder.append(token);
                }

                if (lineBuilder.length() > 0) {
                    if (textBuilder.length() > 0) {
                        textBuilder.append('\n');
                    }
                    textBuilder.append(lineBuilder);
                }
            }
        }

        return textBuilder.toString().trim();
    }
}

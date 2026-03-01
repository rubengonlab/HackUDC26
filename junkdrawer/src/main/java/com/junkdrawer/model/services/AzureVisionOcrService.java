/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
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
    private final HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

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
            
            URI uri = URI.create(normalizedEndpoint + "/computervision/imageanalysis:analyze?api-version=2024-02-01&features=read&language=" + queryLanguage);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(uri)
                    .timeout(Duration.ofSeconds(timeoutSeconds))
                    .header("Ocp-Apim-Subscription-Key", apiKey)
                    .header("Content-Type", "application/octet-stream")
                    .POST(HttpRequest.BodyPublishers.ofByteArray(imageBytes))
                    .build();

            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
            
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                logger.error("Azure Vision OCR devolvio HTTP {}: {}", response.statusCode(), response.body());
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
        JsonNode readResult = root.get("readResult");
        if (readResult == null) {
            return "";
        }

        StringBuilder textBuilder = new StringBuilder();
        JsonNode blocks = readResult.get("blocks");
        
        if (blocks != null && blocks.isArray()) {
            for (JsonNode block : blocks) {
                JsonNode lines = block.get("lines");
                if (lines != null && lines.isArray()) {
                    for (JsonNode line : lines) {
                        String text = line.path("text").asText("").trim();
                        if (!text.isEmpty()) {
                            textBuilder.append(text).append("\n");
                        }
                    }
                }
            }
        }

        return textBuilder.toString().trim();
    }
}
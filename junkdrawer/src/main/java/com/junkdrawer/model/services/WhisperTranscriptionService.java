package com.junkdrawer.model.services;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
public class WhisperTranscriptionService {

    private static final Logger logger = LoggerFactory.getLogger(WhisperTranscriptionService.class);

    @Value("${app.whisper.enabled:true}")
    private boolean whisperEnabled;

    @Value("${app.whisper.api-url:http://whisper:8000/v1/audio/transcriptions}")
    private String whisperApiUrl;

    @Value("${app.whisper.api-token:sk-dummy-key}")
    private String whisperApiToken;

    @Value("${app.whisper.model:medium}")
    private String whisperModel;

    @Value("${app.whisper.timeout-seconds:180}")
    private long whisperTimeoutSeconds;

    private final ObjectMapper objectMapper = new ObjectMapper();

    public Optional<String> transcribe(Path audioPath) {
        if (!whisperEnabled) {
            return Optional.empty();
        }

        try {
            return callTranscriptionApi(audioPath);
        } catch (Exception exception) {
            logger.warn("No se pudo transcribir audio con la API de Whisper: {}", exception.getMessage());
            return Optional.empty();
        }
    }

    private Optional<String> callTranscriptionApi(Path audioPath) throws IOException, InterruptedException {
        if (!Files.exists(audioPath) || !Files.isRegularFile(audioPath)) {
            return Optional.empty();
        }

        String boundary = "----JunkDrawerBoundary" + UUID.randomUUID();
        byte[] body = buildMultipartBody(audioPath, boundary);

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(15))
                .build();

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(whisperApiUrl))
                .timeout(Duration.ofSeconds(whisperTimeoutSeconds))
                .header("Authorization", "Bearer " + whisperApiToken)
                .header("Content-Type", "multipart/form-data; boundary=" + boundary)
                .POST(HttpRequest.BodyPublishers.ofByteArray(body))
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            logger.warn("Error de transcripcion. HTTP {}: {}", response.statusCode(), response.body());
            return Optional.empty();
        }

        JsonNode root = objectMapper.readTree(response.body());
        JsonNode textNode = root.get("text");
        if (textNode == null || textNode.isNull()) {
            return Optional.empty();
        }

        String text = textNode.asText().trim();
        if (text.isBlank()) {
            return Optional.empty();
        }

        return Optional.of(text);
    }

    private byte[] buildMultipartBody(Path audioPath, String boundary) throws IOException {
        byte[] fileBytes = Files.readAllBytes(audioPath);
        String fileName = audioPath.getFileName().toString();
        String lineBreak = "\r\n";
        String separator = "--" + boundary;

        ByteArrayOutputStream output = new ByteArrayOutputStream();
        output.write((separator + lineBreak).getBytes());
        output.write(("Content-Disposition: form-data; name=\"file\"; filename=\"" + fileName + "\"" + lineBreak).getBytes());
        output.write(("Content-Type: application/octet-stream" + lineBreak + lineBreak).getBytes());
        output.write(fileBytes);
        output.write(lineBreak.getBytes());

        output.write((separator + lineBreak).getBytes());
        output.write(("Content-Disposition: form-data; name=\"model\"" + lineBreak + lineBreak).getBytes());
        output.write(whisperModel.getBytes());
        output.write(lineBreak.getBytes());

        output.write((separator + "--" + lineBreak).getBytes());
        return output.toByteArray();
    }
}

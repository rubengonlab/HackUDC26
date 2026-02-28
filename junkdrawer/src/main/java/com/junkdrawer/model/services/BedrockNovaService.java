package com.junkdrawer.model.services;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.List;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.bedrockruntime.BedrockRuntimeClient;
import software.amazon.awssdk.services.bedrockruntime.model.ContentBlock;
import software.amazon.awssdk.services.bedrockruntime.model.ConversationRole;
import software.amazon.awssdk.services.bedrockruntime.model.ConverseRequest;
import software.amazon.awssdk.services.bedrockruntime.model.ConverseResponse;
import software.amazon.awssdk.services.bedrockruntime.model.Message;

@Service
public class BedrockNovaService {

    public record AiProcessingResult(String category, String title) {
    }

    private final BedrockRuntimeClient bedrockClient;
    private final ObjectMapper objectMapper;
    private static final String MODEL_ID = "amazon.nova-lite-v1:0";
    private static final String RESPONSE_FIELD = "response";
    private static final String TITLE_FIELD = "title";

    public BedrockNovaService() {
        this.bedrockClient = BedrockRuntimeClient.builder()
                .region(Region.EU_NORTH_1)
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
        this.objectMapper = new ObjectMapper();
    }

    public String clasificarTexto(List<String> categories, String text) {
        return procesarTexto(categories, text).category();
    }

    public AiProcessingResult procesarTexto(List<String> categories, String text) {
        String prompt = buildPrompt(categories, text);

        Message message = Message.builder()
                .content(ContentBlock.fromText(prompt))
                .role(ConversationRole.USER)
                .build();

        ConverseRequest request = ConverseRequest.builder()
                .modelId(MODEL_ID)
                .messages(List.of(message))
                .build();

        try {
            ConverseResponse response = bedrockClient.converse(request);
            String rawResponse = response.output().message().content().get(0).text();
            return extractResponse(rawResponse);
        } catch (Exception e) {
            System.err.println("Error al invocar Bedrock: " + e.getMessage());
            throw new RuntimeException("Fallo en la comunicación con AWS Bedrock", e);
        }
    }

    private String buildPrompt(List<String> categories, String text) {
        String categoriesJson = categories.stream()
                .map(this::toJsonString)
                .collect(Collectors.joining(", ", "[", "]"));

        return """
                Eres un sistema de clasificacion de texto estricto y automatizado.
                Tu unica tarea es analizar el texto proporcionado y clasificarlo en la categoria mas adecuada de la lista permitida.

                <categorias_permitidas>
                %s
                </categorias_permitidas>

                <texto>
                %s
                </texto>

                Instrucciones obligatorias:
                1. Analiza el contenido dentro de la etiqueta <texto> y comparalo con las opciones en <categorias_permitidas>.
                2. Selecciona EXACTAMENTE UNA categoria de la lista. No inventes categorias nuevas.
                3. Tu respuesta debe ser UNICAMENTE un objeto JSON valido.
                4. No incluyas saludos, explicaciones ni bloques markdown. Solo devuelve JSON puro.
                5. En caso de que el texto no encaje con ninguna categoría, devuelve {"response":"sin_categoria","title":"..."}.
                6. Incluye siempre un "title" corto (maximo 7 palabras) que resuma el texto.

                Formato de salida esperado:
                {"response":"nombre_de_la_categoria_elegida","title":"titulo_resumido"}
                """.formatted(categoriesJson, text);
    }

    private String toJsonString(String value) {
        return "\"" + value
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t") + "\"";
    }

    private AiProcessingResult extractResponse(String rawResponse) {
        if (rawResponse == null || rawResponse.isBlank()) {
            throw new IllegalStateException("La respuesta del modelo llegó vacía");
        }

        String trimmed = rawResponse.trim();
        JsonNode root = parseJsonNode(trimmed);
        JsonNode responseNode = root.get(RESPONSE_FIELD);
        if (responseNode == null || responseNode.isNull()) {
            throw new IllegalStateException("La respuesta JSON no contiene el campo 'response'");
        }

        String response = responseNode.asText().trim();
        if (response.isEmpty()) {
            throw new IllegalStateException("El campo 'response' está vacío");
        }

        JsonNode titleNode = root.get(TITLE_FIELD);
        String title = null;
        if (titleNode != null && !titleNode.isNull()) {
            String parsedTitle = titleNode.asText().trim();
            if (!parsedTitle.isEmpty()) {
                title = parsedTitle;
            }
        }

        return new AiProcessingResult(response, title);
    }

    private JsonNode parseJsonNode(String rawResponse) {
        try {
            return objectMapper.readTree(rawResponse);
        } catch (Exception ignored) {
            int start = rawResponse.indexOf('{');
            int end = rawResponse.lastIndexOf('}');
            if (start >= 0 && end > start) {
                String possibleJson = rawResponse.substring(start, end + 1);
                try {
                    return objectMapper.readTree(possibleJson);
                } catch (Exception inner) {
                    throw new IllegalStateException("No se pudo parsear el JSON de respuesta del modelo", inner);
                }
            }
            throw new IllegalStateException("No se pudo parsear el JSON de respuesta del modelo");
        }
    }
}

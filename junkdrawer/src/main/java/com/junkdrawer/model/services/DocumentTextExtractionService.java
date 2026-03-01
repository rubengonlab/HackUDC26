/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.model.services;

import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;

import javax.imageio.ImageIO;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.apache.tika.exception.TikaException;
import org.apache.tika.metadata.Metadata;
import org.apache.tika.metadata.TikaCoreProperties;
import org.apache.tika.parser.AutoDetectParser;
import org.apache.tika.parser.ParseContext;
import org.apache.tika.sax.BodyContentHandler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.xml.sax.SAXException;

@Service
public class DocumentTextExtractionService {

    private static final Logger logger = LoggerFactory.getLogger(DocumentTextExtractionService.class);
    private static final Set<String> PLAIN_TEXT_EXTENSIONS = Set.of(
            "txt", "md", "js", "ts", "py", "java", "json", "yaml", "yml", "xml", "csv", "html", "css", "sql", "sh");

    private final AutoDetectParser tikaParser = new AutoDetectParser();
    private final AzureVisionOcrService azureVisionOcrService;

    public DocumentTextExtractionService(AzureVisionOcrService azureVisionOcrService) {
        this.azureVisionOcrService = azureVisionOcrService;
    }

    public Optional<String> extractText(byte[] fileBytes, String originalFileName, String mimeType) {
        if (fileBytes == null || fileBytes.length == 0) {
            return Optional.empty();
        }

        String extension = extensionOf(originalFileName);
        if (PLAIN_TEXT_EXTENSIONS.contains(extension)) {
            String text = new String(fileBytes, StandardCharsets.UTF_8).trim();
            return text.isBlank() ? Optional.empty() : Optional.of(text);
        }

        String parsed = parseWithTika(fileBytes, originalFileName, mimeType);
        if (!parsed.isBlank()) {
            return Optional.of(parsed);
        }

        if ("pdf".equals(extension) || "application/pdf".equalsIgnoreCase(mimeType)) {
            return extractTextFromScannedPdf(fileBytes);
        }

        return Optional.empty();
    }

    private String parseWithTika(byte[] fileBytes, String originalFileName, String mimeType) {
        try {
            BodyContentHandler handler = new BodyContentHandler(-1);
            Metadata metadata = new Metadata();
            if (originalFileName != null) {
                metadata.set(TikaCoreProperties.RESOURCE_NAME_KEY, originalFileName);
            }
            if (mimeType != null && !mimeType.isBlank()) {
                metadata.set(Metadata.CONTENT_TYPE, mimeType);
            }
            tikaParser.parse(new java.io.ByteArrayInputStream(fileBytes), handler, metadata, new ParseContext());
            return handler.toString().trim();
        } catch (IOException | SAXException | TikaException exception) {
            logger.warn("No se pudo extraer texto con Tika: {}", exception.getMessage());
            return "";
        }
    }

    private Optional<String> extractTextFromScannedPdf(byte[] fileBytes) {
        StringBuilder textBuilder = new StringBuilder();
        try (PDDocument pdf = PDDocument.load(fileBytes)) {
            PDFRenderer renderer = new PDFRenderer(pdf);
            for (int pageIndex = 0; pageIndex < pdf.getNumberOfPages(); pageIndex++) {
                BufferedImage image = renderer.renderImageWithDPI(pageIndex, 180);
                byte[] imageBytes = toPngBytes(image);
                Optional<String> pageText = azureVisionOcrService.extractText(imageBytes);
                if (pageText.isPresent() && !pageText.get().isBlank()) {
                    if (textBuilder.length() > 0) {
                        textBuilder.append('\n');
                    }
                    textBuilder.append(pageText.get().trim());
                }
            }
        } catch (Exception exception) {
            logger.warn("No se pudo extraer texto OCR de PDF escaneado: {}", exception.getMessage());
        }

        String text = textBuilder.toString().trim();
        return text.isBlank() ? Optional.empty() : Optional.of(text);
    }

    private byte[] toPngBytes(BufferedImage image) throws IOException {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        ImageIO.write(image, "png", output);
        return output.toByteArray();
    }

    private String extensionOf(String fileName) {
        if (fileName == null) {
            return "";
        }
        int index = fileName.lastIndexOf('.');
        if (index < 0 || index == fileName.length() - 1) {
            return "";
        }
        return fileName.substring(index + 1).toLowerCase(Locale.ROOT);
    }
}

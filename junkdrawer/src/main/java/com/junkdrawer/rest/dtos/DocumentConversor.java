/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.rest.dtos;

import java.util.List;

import org.springframework.stereotype.Component;

import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.entities.Document;

@Component
public class DocumentConversor {

    public DocumentDto toDocumentDto(Document document, String contentUrl) {
        Capture capture = document.getCapture();
        return new DocumentDto(
                document.getId(),
                capture.getId(),
                document.getFileName(),
                document.getOriginalFileName(),
                document.getMimeType(),
                document.getSize(),
                document.getStoragePath(),
                contentUrl,
                capture.getCreatedAt(),
                capture.getCategoryStatus().name(),
                capture.getCategory() != null ? capture.getCategory().getId() : null,
                capture.getTitle(),
                capture.getContextText(),
                document.getParsedText(),
                document.getReorderedParsedText(),
                document.getTextStatus() != null ? document.getTextStatus().name() : null);
    }

    public List<DocumentDto> toDocumentDtos(List<Document> documents,
            java.util.function.Function<Document, String> contentUrlBuilder) {
        return documents.stream()
                .map(document -> toDocumentDto(document, contentUrlBuilder.apply(document)))
                .toList();
    }
}

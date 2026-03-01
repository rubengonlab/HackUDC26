/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.rest.dtos;

import java.time.LocalDateTime;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "Document", description = "Recurso de documento asociado a una captura.")
public class DocumentDto {

    private Long id;
    private Long captureId;
    private String fileName;
    private String originalFileName;
    private String mimeType;
    private Long size;
    private String storagePath;
    private String contentUrl;
    private LocalDateTime createdAt;
    private String categoryStatus;
    private Long categoryId;
    private String title;
    private String contextText;
    private String parsedText;
    private String reorderedParsedText;
    private String textStatus;

    public DocumentDto() {
    }

    public DocumentDto(Long id, Long captureId, String fileName, String originalFileName, String mimeType, Long size,
            String storagePath, String contentUrl, LocalDateTime createdAt, String categoryStatus, Long categoryId,
            String title, String contextText, String parsedText, String reorderedParsedText, String textStatus) {
        this.id = id;
        this.captureId = captureId;
        this.fileName = fileName;
        this.originalFileName = originalFileName;
        this.mimeType = mimeType;
        this.size = size;
        this.storagePath = storagePath;
        this.contentUrl = contentUrl;
        this.createdAt = createdAt;
        this.categoryStatus = categoryStatus;
        this.categoryId = categoryId;
        this.title = title;
        this.contextText = contextText;
        this.parsedText = parsedText;
        this.reorderedParsedText = reorderedParsedText;
        this.textStatus = textStatus;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getCaptureId() {
        return captureId;
    }

    public void setCaptureId(Long captureId) {
        this.captureId = captureId;
    }

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public String getOriginalFileName() {
        return originalFileName;
    }

    public void setOriginalFileName(String originalFileName) {
        this.originalFileName = originalFileName;
    }

    public String getMimeType() {
        return mimeType;
    }

    public void setMimeType(String mimeType) {
        this.mimeType = mimeType;
    }

    public Long getSize() {
        return size;
    }

    public void setSize(Long size) {
        this.size = size;
    }

    public String getStoragePath() {
        return storagePath;
    }

    public void setStoragePath(String storagePath) {
        this.storagePath = storagePath;
    }

    public String getContentUrl() {
        return contentUrl;
    }

    public void setContentUrl(String contentUrl) {
        this.contentUrl = contentUrl;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public String getCategoryStatus() {
        return categoryStatus;
    }

    public void setCategoryStatus(String categoryStatus) {
        this.categoryStatus = categoryStatus;
    }

    public Long getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(Long categoryId) {
        this.categoryId = categoryId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getContextText() {
        return contextText;
    }

    public void setContextText(String contextText) {
        this.contextText = contextText;
    }

    public String getParsedText() {
        return parsedText;
    }

    public void setParsedText(String parsedText) {
        this.parsedText = parsedText;
    }

    public String getReorderedParsedText() {
        return reorderedParsedText;
    }

    public void setReorderedParsedText(String reorderedParsedText) {
        this.reorderedParsedText = reorderedParsedText;
    }

    public String getTextStatus() {
        return textStatus;
    }

    public void setTextStatus(String textStatus) {
        this.textStatus = textStatus;
    }
}

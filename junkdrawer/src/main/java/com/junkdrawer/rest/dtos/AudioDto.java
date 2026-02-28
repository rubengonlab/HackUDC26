package com.junkdrawer.rest.dtos;

import java.time.LocalDateTime;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "Audio", description = "Recurso de audio asociado a una captura.")
public class AudioDto {

    @Schema(description = "Identificador del audio", example = "1")
    private Long id;

    @Schema(description = "Identificador de la captura asociada", example = "10")
    private Long captureId;

    @Schema(description = "Nombre interno del fichero", example = "8ec1e247-44c2-4122-a631-1efd8cce1b25.mp3")
    private String fileName;

    @Schema(description = "Nombre original del fichero", example = "nota-voz.mp3")
    private String originalFileName;

    @Schema(description = "Tipo MIME del fichero", example = "audio/mpeg")
    private String mimeType;

    @Schema(description = "Tamano del fichero en bytes", example = "98321")
    private Long size;

    @Schema(description = "Ruta de almacenamiento en servidor", example = "uploads/audio/8ec1e247-44c2-4122-a631-1efd8cce1b25.mp3")
    private String storagePath;

    @Schema(description = "URL publica para reproducir/descargar el audio", example = "http://localhost:8080/audio/1/content")
    private String contentUrl;

    @Schema(description = "Fecha de creacion de la captura", example = "2026-02-28T13:00:00")
    private LocalDateTime createdAt;

    @Schema(description = "Estado de categoria de la captura", example = "PENDING")
    private String categoryStatus;

    @Schema(description = "Id de categoria si existe", example = "2", accessMode = Schema.AccessMode.READ_ONLY)
    private Long categoryId;

    @Schema(description = "Titulo resumido generado para la captura", example = "Resumen de reunion", accessMode = Schema.AccessMode.READ_ONLY)
    private String title;

    @Schema(description = "Contexto/transcripcion asociada", example = "Notas de voz sobre roadmap")
    private String contextText;

    public AudioDto() {
    }

    public AudioDto(Long id, Long captureId, String fileName, String originalFileName, String mimeType, Long size,
            String storagePath, String contentUrl, LocalDateTime createdAt, String categoryStatus, Long categoryId,
            String title, String contextText) {
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
}

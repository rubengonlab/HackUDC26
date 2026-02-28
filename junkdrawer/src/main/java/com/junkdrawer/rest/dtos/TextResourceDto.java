package com.junkdrawer.rest.dtos;

import java.time.LocalDateTime;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "TextResource", description = "Recurso de texto creado: nota o enlace.")
public class TextResourceDto {

    @Schema(description = "Tipo de recurso", example = "NOTE")
    private String kind;

    @Schema(description = "Id del recurso especifico", example = "12")
    private Long id;

    @Schema(description = "Id de la captura asociada", example = "20")
    private Long captureId;

    @Schema(description = "Fecha de creacion de la captura", example = "2026-02-28T13:00:00")
    private LocalDateTime createdAt;

    @Schema(description = "Estado de categoria de la captura", example = "UNCATEGORIZED")
    private String categoryStatus;

    @Schema(description = "Id de categoria si existe", example = "2")
    private Long categoryId;

    @Schema(description = "Contexto adicional", example = "Ideas para backlog")
    private String contextText;

    @Schema(description = "Titulo para NOTE", example = "Idea")
    private String title;

    @Schema(description = "Contenido para NOTE", example = "Mejorar onboarding")
    private String content;

    @Schema(description = "URL para LINK", example = "https://docs.spring.io")
    private String url;

    @Schema(description = "Origen detectado para LINK", example = "docs.spring.io")
    private String origin;

    public TextResourceDto() {
    }

    public String getKind() {
        return kind;
    }

    public void setKind(String kind) {
        this.kind = kind;
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

    public String getContextText() {
        return contextText;
    }

    public void setContextText(String contextText) {
        this.contextText = contextText;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public String getOrigin() {
        return origin;
    }

    public void setOrigin(String origin) {
        this.origin = origin;
    }
}

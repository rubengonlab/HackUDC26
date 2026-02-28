package com.junkdrawer.rest.dtos;

import java.time.LocalDateTime;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "Capture", description = "Captura unificada con su tipo y datos asociados.")
public class CaptureDto {

    @Schema(description = "Id de la captura", example = "10")
    private Long id;

    @Schema(description = "Fecha de creacion", example = "2026-03-01T09:15:00")
    private LocalDateTime createdAt;

    @Schema(description = "Tipo de captura", example = "AUDIO")
    private String captureType;

    @Schema(description = "Estado de categoria", example = "PENDING")
    private String categoryStatus;

    @Schema(description = "Id de categoria", example = "2")
    private Long categoryId;

    @Schema(description = "Nombre de categoria", example = "Trabajo")
    private String categoryName;

    @Schema(description = "Titulo generado por IA", example = "Resumen reunion equipo")
    private String title;

    @Schema(description = "Contexto de captura", example = "Notas de voz del sprint")
    private String contextText;

    @Schema(description = "Origen si aplica", example = "youtube")
    private String origin;

    @Schema(description = "Datos de nota cuando captureType=NOTE")
    private NoteDataDto note;

    @Schema(description = "Datos de link cuando captureType=LINK")
    private LinkDataDto link;

    @Schema(description = "Datos de audio cuando captureType=AUDIO")
    private AudioDataDto audio;

    @Schema(description = "Datos de imagen cuando captureType=IMAGE")
    private FileDataDto image;

    @Schema(description = "Datos de documento cuando captureType=DOCUMENT")
    private FileDataDto document;

    public static class NoteDataDto {
        private Long id;
        private String content;

        public Long getId() {
            return id;
        }

        public void setId(Long id) {
            this.id = id;
        }

        public String getContent() {
            return content;
        }

        public void setContent(String content) {
            this.content = content;
        }
    }

    public static class LinkDataDto {
        private Long id;
        private String url;
        private String origin;

        public Long getId() {
            return id;
        }

        public void setId(Long id) {
            this.id = id;
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

    public static class AudioDataDto {
        private Long id;
        private String fileName;
        private String originalFileName;
        private String mimeType;
        private Long size;
        private String storagePath;
        private String contentUrl;

        public Long getId() {
            return id;
        }

        public void setId(Long id) {
            this.id = id;
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
    }

    public static class FileDataDto {
        private Long id;
        private String fileName;
        private String originalFileName;
        private String mimeType;
        private Long size;
        private String storagePath;

        public Long getId() {
            return id;
        }

        public void setId(Long id) {
            this.id = id;
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
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public String getCaptureType() {
        return captureType;
    }

    public void setCaptureType(String captureType) {
        this.captureType = captureType;
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

    public String getCategoryName() {
        return categoryName;
    }

    public void setCategoryName(String categoryName) {
        this.categoryName = categoryName;
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

    public String getOrigin() {
        return origin;
    }

    public void setOrigin(String origin) {
        this.origin = origin;
    }

    public NoteDataDto getNote() {
        return note;
    }

    public void setNote(NoteDataDto note) {
        this.note = note;
    }

    public LinkDataDto getLink() {
        return link;
    }

    public void setLink(LinkDataDto link) {
        this.link = link;
    }

    public AudioDataDto getAudio() {
        return audio;
    }

    public void setAudio(AudioDataDto audio) {
        this.audio = audio;
    }

    public FileDataDto getImage() {
        return image;
    }

    public void setImage(FileDataDto image) {
        this.image = image;
    }

    public FileDataDto getDocument() {
        return document;
    }

    public void setDocument(FileDataDto document) {
        this.document = document;
    }
}

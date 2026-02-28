package com.junkdrawer.rest.dtos;

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

    public AudioDto() {
    }

    public AudioDto(Long id, Long captureId, String fileName, String originalFileName, String mimeType, Long size,
            String storagePath) {
        this.id = id;
        this.captureId = captureId;
        this.fileName = fileName;
        this.originalFileName = originalFileName;
        this.mimeType = mimeType;
        this.size = size;
        this.storagePath = storagePath;
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
}

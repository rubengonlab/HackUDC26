/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.rest.dtos;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "UpdateCaptureParams", description = "Campos editables de una captura y de su recurso asociado.")
public class UpdateCaptureParamsDto {

    @Schema(description = "Nuevo id de categoria para la captura", example = "2")
    private Long categoryId;

    @Schema(description = "Nuevo titulo de la captura", example = "Resumen actualizado")
    private String title;

    @Schema(description = "Nuevo contexto de la captura", example = "Contexto ajustado por usuario")
    private String contextText;

    @Schema(description = "Nuevo texto reordenado segun el tipo (NOTE/AUDIO/IMAGE)")
    private String reorderedText;

    @Schema(description = "Nuevo nombre de audio generado por IA (AUDIO)", example = "Resumen reunion")
    private String audioName;

    @Schema(description = "Nuevo nombre de imagen generado por IA (IMAGE)", example = "Factura marzo")
    private String imageName;

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

    public String getReorderedText() {
        return reorderedText;
    }

    public void setReorderedText(String reorderedText) {
        this.reorderedText = reorderedText;
    }

    public String getAudioName() {
        return audioName;
    }

    public void setAudioName(String audioName) {
        this.audioName = audioName;
    }

    public String getImageName() {
        return imageName;
    }

    public void setImageName(String imageName) {
        this.imageName = imageName;
    }
}

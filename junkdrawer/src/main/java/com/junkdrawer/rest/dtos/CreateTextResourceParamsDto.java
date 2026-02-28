package com.junkdrawer.rest.dtos;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

@Schema(name = "CreateTextResourceParams", description = "Parametros para crear un recurso de texto.")
public class CreateTextResourceParamsDto {

    @Schema(description = "Contenido libre o URL", example = "https://docs.spring.io", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank
    private String content;

    @Schema(description = "Contexto adicional opcional", example = "Referencia de documentacion")
    private String contextText;

    public CreateTextResourceParamsDto() {
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getContextText() {
        return contextText;
    }

    public void setContextText(String contextText) {
        this.contextText = contextText;
    }
}

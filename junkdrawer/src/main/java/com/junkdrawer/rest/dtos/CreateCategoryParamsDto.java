package com.junkdrawer.rest.dtos;

import jakarta.validation.constraints.NotBlank;
import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "CreateCategoryParams", description = "Parametros para crear una categoria.")
public class CreateCategoryParamsDto {

    @Schema(description = "Nombre de la categoria", example = "Personal", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank
    private String name;

    public CreateCategoryParamsDto() {
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}

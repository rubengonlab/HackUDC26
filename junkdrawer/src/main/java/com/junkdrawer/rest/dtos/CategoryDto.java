package com.junkdrawer.rest.dtos;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "Category", description = "Categoria de clasificacion de capturas.")
public class CategoryDto {

    @Schema(description = "Identificador de la categoria", example = "1")
    private Long id;

    @Schema(description = "Nombre de la categoria", example = "Trabajo")
    private String name;

    public CategoryDto() {}

    public CategoryDto(Long id, String name) {
        this.id = id;
        this.name = name;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}

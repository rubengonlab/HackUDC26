package com.junkdrawer.rest.dtos;

import java.util.List;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "Block", description = "DTO de paginacion con elementos y si hay mas resultados.")
public class BlockDto<T> {

    @Schema(description = "Lista de elementos de la pagina actual")
    private List<T> items;

    @Schema(description = "Indica si existen mas elementos en paginas posteriores", example = "true")
    private boolean existMoreItems;

    public BlockDto() {
    }

    public BlockDto(List<T> items, boolean existMoreItems) {
        this.items = items;
        this.existMoreItems = existMoreItems;
    }

    public List<T> getItems() {
        return items;
    }

    public void setItems(List<T> items) {
        this.items = items;
    }

    public boolean getExistMoreItems() {
        return existMoreItems;
    }

    public void setExistMoreItems(boolean existMoreItems) {
        this.existMoreItems = existMoreItems;
    }
}

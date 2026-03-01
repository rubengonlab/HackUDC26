package com.junkdrawer.rest.controllers;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.junkdrawer.model.common.DuplicateInstanceException;
import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.entities.Category;
import com.junkdrawer.model.services.CategoryService;
import com.junkdrawer.rest.dtos.CategoryConversor;
import com.junkdrawer.rest.dtos.CategoryDto;
import com.junkdrawer.rest.dtos.CreateCategoryParamsDto;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

@Tag(name = "Categorias", description = "Operaciones para gestionar categorias.")
@RestController
@RequestMapping("/categories")
public class CategoryController {

    @Autowired
    private CategoryService categoryService;

    @Autowired
    private CategoryConversor categoryConversor;

    @Operation(summary = "Crear categoria", description = "Crea una nueva categoria.")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Categoria creada",
                    content = @Content(schema = @Schema(implementation = CategoryDto.class))),
            @ApiResponse(responseCode = "400", description = "Datos invalidos o categoria duplicada")
    })
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public void createCategory(@Valid @RequestBody CreateCategoryParamsDto params) {
        categoryService.createCategory(params.getName());
    }

    @Operation(summary = "Obtener categoria", description = "Obtiene una categoria por id.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Categoria encontrada",
                    content = @Content(schema = @Schema(implementation = CategoryDto.class))),
            @ApiResponse(responseCode = "404", description = "Categoria no encontrada")
    })
    @GetMapping("/{id}")
    public CategoryDto getCategory(@PathVariable Long id) throws InstanceNotFoundException {
        Category category = categoryService.getCategory(id);
        return categoryConversor.toCategoryDto(category);
    }

    @Operation(summary = "Listar categorias", description = "Devuelve la lista de categorias ordenada por nombre.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Listado de categorias")
    })
    @GetMapping
    public List<CategoryDto> getCategories() {
        List<Category> categories = categoryService.getCategories();
        return categoryConversor.toCategoryDtos(categories);
    }
}

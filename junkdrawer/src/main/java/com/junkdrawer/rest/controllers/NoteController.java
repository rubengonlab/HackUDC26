package com.junkdrawer.rest.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.junkdrawer.model.entities.Note;
import com.junkdrawer.model.services.Block;
import com.junkdrawer.model.services.NoteService;
import com.junkdrawer.rest.dtos.BlockDto;
import com.junkdrawer.rest.dtos.TextResourceConversor;
import com.junkdrawer.rest.dtos.TextResourceDto;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;

@Tag(name = "Notas", description = "Operaciones para consultar notas.")
@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/notes")
public class NoteController {

    @Autowired
    private NoteService noteService;

    @Autowired
    private TextResourceConversor textResourceConversor;

    @Operation(summary = "Listar notas", description = "Listado paginado de todas las notas con datos de captura.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Listado paginado")
    })
    @GetMapping
    public BlockDto<TextResourceDto> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Block<Note> notes = noteService.getAll(page, size);
        return new BlockDto<>(
                notes.getItems().stream().map(textResourceConversor::toTextResourceDto).toList(),
                notes.getExistMoreItems());
    }
}

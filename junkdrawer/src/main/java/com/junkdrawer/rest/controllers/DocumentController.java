/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.rest.controllers;

import java.nio.file.Path;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.entities.Document;
import com.junkdrawer.model.services.Block;
import com.junkdrawer.model.services.DocumentService;
import com.junkdrawer.rest.dtos.BlockDto;
import com.junkdrawer.rest.dtos.DocumentConversor;
import com.junkdrawer.rest.dtos.DocumentDto;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;

@Tag(name = "Document", description = "Operaciones para gestionar recursos de documento.")
@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/document")
public class DocumentController {

    @Autowired
    private DocumentService documentService;

    @Autowired
    private DocumentConversor documentConversor;

    @Operation(summary = "Crear documento", description = "Crea una captura DOCUMENT y guarda el archivo enviado.")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Documento creado",
                    content = @Content(schema = @Schema(implementation = DocumentDto.class))),
            @ApiResponse(responseCode = "400", description = "Archivo invalido")
    })
    @PostMapping(consumes = "multipart/form-data")
    @ResponseStatus(HttpStatus.CREATED)
    public DocumentDto create(
            @RequestPart MultipartFile file,
            @RequestParam(required = false) String contextText,
            @RequestParam(required = false) Long categoryId) throws InstanceNotFoundException {

        Document document = documentService.create(file, contextText, categoryId);
        return documentConversor.toDocumentDto(document, buildContentUrl(document.getId()));
    }

    @Operation(summary = "Actualizar documento", description = "Actualiza metadata de categoria/contexto del documento.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Documento actualizado",
                    content = @Content(schema = @Schema(implementation = DocumentDto.class))),
            @ApiResponse(responseCode = "404", description = "Documento no encontrado")
    })
    @PutMapping("/{id}")
    public DocumentDto update(
            @PathVariable Long id,
            @RequestParam(required = false) String contextText) throws InstanceNotFoundException {

        Document document = documentService.update(id, contextText);
        return documentConversor.toDocumentDto(document, buildContentUrl(document.getId()));
    }

    @Operation(summary = "Eliminar documento", description = "Elimina entidad de documento y fichero fisico.")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Documento eliminado"),
            @ApiResponse(responseCode = "404", description = "Documento no encontrado")
    })
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) throws InstanceNotFoundException {
        documentService.delete(id);
    }

    @Operation(summary = "Obtener documento", description = "Obtiene un documento por id.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Documento encontrado",
                    content = @Content(schema = @Schema(implementation = DocumentDto.class))),
            @ApiResponse(responseCode = "404", description = "Documento no encontrado")
    })
    @GetMapping("/{id}")
    public DocumentDto getById(@PathVariable Long id) throws InstanceNotFoundException {
        Document document = documentService.getById(id);
        return documentConversor.toDocumentDto(document, buildContentUrl(document.getId()));
    }

    @Operation(summary = "Listar documentos", description = "Listado paginado de documentos.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Listado paginado")
    })
    @GetMapping
    public BlockDto<DocumentDto> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Block<Document> documents = documentService.getAll(page, size);
        return new BlockDto<>(
                documentConversor.toDocumentDtos(documents.getItems(), document -> buildContentUrl(document.getId())),
                documents.getExistMoreItems());
    }

    @Operation(summary = "Contenido de documento", description = "Devuelve el binario del documento.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Contenido de documento"),
            @ApiResponse(responseCode = "404", description = "Documento no encontrado")
    })
    @GetMapping("/{id}/content")
    public ResponseEntity<Resource> getContent(@PathVariable Long id) throws InstanceNotFoundException {
        Document document = documentService.getById(id);
        Path path = Path.of(document.getStoragePath());
        Resource resource = new FileSystemResource(path);
        if (!resource.exists()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Fichero de documento no encontrado");
        }

        MediaType mediaType = MediaType.APPLICATION_OCTET_STREAM;
        if (document.getMimeType() != null) {
            try {
                mediaType = MediaType.parseMediaType(document.getMimeType());
            } catch (Exception ignored) {
                mediaType = MediaType.APPLICATION_OCTET_STREAM;
            }
        }

        return ResponseEntity.ok()
                .contentType(mediaType)
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + document.getOriginalFileName() + "\"")
                .body(resource);
    }

    private String buildContentUrl(Long documentId) {
        return "/document/" + documentId + "/content";
    }
}

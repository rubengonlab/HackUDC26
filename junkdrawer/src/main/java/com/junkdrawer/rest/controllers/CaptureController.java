/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.rest.controllers;

import java.time.LocalDate;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.services.Block;
import com.junkdrawer.model.services.CaptureService;
import com.junkdrawer.rest.dtos.BlockDto;
import com.junkdrawer.rest.dtos.CaptureConversor;
import com.junkdrawer.rest.dtos.CaptureDto;
import com.junkdrawer.rest.dtos.UpdateCaptureParamsDto;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

@Tag(name = "Capturas", description = "Consulta unificada de capturas con filtros.")
@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/captures")
public class CaptureController {

    @Autowired
    private CaptureService captureService;

    @Autowired
    private CaptureConversor captureConversor;

    @Operation(summary = "Listar capturas",
            description = "Filtra por un día, categoria y tipo de archivo. Se pueden combinar filtros. Siempre ordenadas por más recientes.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Listado paginado")
    })
    @GetMapping
    public BlockDto<CaptureDto> getCaptures(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String fileType,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Capture.CaptureType captureType = parseCaptureType(fileType);
        Block<Capture> captures = captureService.getCaptures(date, date, categoryId, captureType, page, size);

        return new BlockDto<>(captureConversor.toCaptureDtos(captures.getItems()), captures.getExistMoreItems());
    }

    @Operation(summary = "Editar captura",
            description = "Modifica campos generales de captura y campos específicos del recurso asociado.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Captura actualizada"),
            @ApiResponse(responseCode = "404", description = "Captura no encontrada")
    })
    @PatchMapping("/{id}")
    public CaptureDto patchCapture(@PathVariable Long id, @Valid @RequestBody UpdateCaptureParamsDto params)
            throws com.junkdrawer.model.common.InstanceNotFoundException {

        Capture capture = captureService.patchCapture(
                id,
                params.getCategoryId(),
                params.getTitle(),
                params.getContextText(),
                params.getReorderedText(),
                params.getAudioName(),
                params.getImageName());

        return captureConversor.toCaptureDto(capture);
    }

    @Operation(summary = "Listar tipos de captura usados",
            description = "Devuelve los CaptureType que existen realmente en capturas.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Listado de tipos usados")
    })
    @GetMapping("/types")
    public List<String> getUsedCaptureTypes() {
        return captureService.getUsedCaptureTypes().stream()
                .map(Enum::name)
                .toList();
    }

    @Operation(summary = "Listar días con capturas",
            description = "Devuelve días (distinct) en los que hay capturas, paginados y ordenados por más reciente.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Listado paginado de días")
    })
    @GetMapping("/days")
    public BlockDto<LocalDate> getCaptureDays(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Block<LocalDate> days = captureService.getCaptureDays(page, size);
        return new BlockDto<>(days.getItems(), days.getExistMoreItems());
    }

    @Operation(summary = "Listar capturas con categoría pendiente",
            description = "Devuelve las capturas cuyo estado de categoría está pendiente de aprobación.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Listado paginado de pendientes")
    })
    @GetMapping("/pending-category")
    public BlockDto<CaptureDto> getPendingCategoryCaptures(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Block<Capture> captures = captureService.getPendingCategoryCaptures(page, size);
        return new BlockDto<>(captureConversor.toCaptureDtos(captures.getItems()), captures.getExistMoreItems());
    }

    @Operation(summary = "Aprobar estados de captura",
            description = "Aprueba estado de categoría, texto o ambos. target=all|category|text.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Estado aprobado"),
            @ApiResponse(responseCode = "404", description = "Captura no encontrada")
    })
    @PostMapping("/{id}/approve")
    public CaptureDto approveCaptureStatus(@PathVariable Long id, @RequestParam(defaultValue = "all") String target)
            throws com.junkdrawer.model.common.InstanceNotFoundException {

        Capture capture = captureService.approveStatuses(id, target);
        return captureConversor.toCaptureDto(capture);
    }

    @Operation(summary = "Rechazar estados de captura",
            description = "Rechaza estado de categoría, texto o ambos. target=all|category|text.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Estado rechazado"),
            @ApiResponse(responseCode = "404", description = "Captura no encontrada")
    })
    @PostMapping("/{id}/reject")
    public CaptureDto rejectCaptureStatus(@PathVariable Long id, @RequestParam(defaultValue = "all") String target)
            throws com.junkdrawer.model.common.InstanceNotFoundException {

        Capture capture = captureService.rejectStatuses(id, target);
        return captureConversor.toCaptureDto(capture);
    }

    private Capture.CaptureType parseCaptureType(String fileType) {
        if (fileType == null || fileType.isBlank()) {
            return null;
        }
        try {
            return Capture.CaptureType.valueOf(fileType.trim().toUpperCase());
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "fileType inválido. Valores: NOTE, LINK, AUDIO, IMAGE, DOCUMENT");
        }
    }
}

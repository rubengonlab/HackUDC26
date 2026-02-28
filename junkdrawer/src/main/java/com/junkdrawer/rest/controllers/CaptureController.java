package com.junkdrawer.rest.controllers;

import java.time.LocalDate;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
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

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;

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

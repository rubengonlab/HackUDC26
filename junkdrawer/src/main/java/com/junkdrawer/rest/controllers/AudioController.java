package com.junkdrawer.rest.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
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

import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.entities.Audio;
import com.junkdrawer.model.services.AudioService;
import com.junkdrawer.model.services.Block;
import com.junkdrawer.rest.dtos.AudioConversor;
import com.junkdrawer.rest.dtos.AudioDto;
import com.junkdrawer.rest.dtos.BlockDto;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;

@Tag(name = "Audio", description = "Operaciones para gestionar recursos de audio.")
@RestController
@CrossOrigin(origins="*")
@RequestMapping("/audio")
public class AudioController {

    @Autowired
    private AudioService audioService;

    @Autowired
    private AudioConversor audioConversor;

    @Operation(summary = "Crear audio", description = "Crea una captura AUDIO y guarda el archivo enviado.")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Audio creado",
                    content = @Content(schema = @Schema(implementation = AudioDto.class))),
            @ApiResponse(responseCode = "400", description = "Archivo invalido"),
            @ApiResponse(responseCode = "404", description = "Categoria no encontrada")
    })
    @PostMapping(consumes = "multipart/form-data")
    @ResponseStatus(HttpStatus.CREATED)
    public AudioDto create(
            @RequestPart MultipartFile file,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String contextText) throws InstanceNotFoundException {

        Audio audio = audioService.create(file, categoryId, contextText);
        return audioConversor.toAudioDto(audio);
    }

    @Operation(summary = "Actualizar audio", description = "Actualiza metadata de categoria/contexto del audio.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Audio actualizado",
                    content = @Content(schema = @Schema(implementation = AudioDto.class))),
            @ApiResponse(responseCode = "404", description = "Audio o categoria no encontrados")
    })
    @PutMapping("/{id}")
    public AudioDto update(
            @PathVariable Long id,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String contextText) throws InstanceNotFoundException {

        Audio audio = audioService.update(id, categoryId, contextText);
        return audioConversor.toAudioDto(audio);
    }

    @Operation(summary = "Eliminar audio", description = "Elimina entidad de audio y fichero fisico.")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Audio eliminado"),
            @ApiResponse(responseCode = "404", description = "Audio no encontrado")
    })
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) throws InstanceNotFoundException {
        audioService.delete(id);
    }

    @Operation(summary = "Obtener audio", description = "Obtiene un audio por id.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Audio encontrado",
                    content = @Content(schema = @Schema(implementation = AudioDto.class))),
            @ApiResponse(responseCode = "404", description = "Audio no encontrado")
    })
    @GetMapping("/{id}")
    public AudioDto getById(@PathVariable Long id) throws InstanceNotFoundException {
        Audio audio = audioService.getById(id);
        return audioConversor.toAudioDto(audio);
    }

    @Operation(summary = "Listar audios", description = "Listado paginado de audios.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Listado paginado")
    })
    @GetMapping
    public BlockDto<AudioDto> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Block<Audio> audios = audioService.getAll(page, size);
        return new BlockDto<>(audioConversor.toAudioDtos(audios.getItems()), audios.getExistMoreItems());
    }
}

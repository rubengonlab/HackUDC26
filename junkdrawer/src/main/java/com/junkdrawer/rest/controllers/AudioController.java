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
            @ApiResponse(responseCode = "400", description = "Archivo invalido")
    })
    @PostMapping(consumes = "multipart/form-data")
    @ResponseStatus(HttpStatus.CREATED)
    public AudioDto create(
            @RequestPart MultipartFile file,
            @RequestParam(required = false) String contextText) throws InstanceNotFoundException {

        Audio audio = audioService.create(file, contextText);
        return audioConversor.toAudioDto(audio, buildContentUrl(audio.getId()));
    }

    @Operation(summary = "Actualizar audio", description = "Actualiza metadata de categoria/contexto del audio.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Audio actualizado",
                    content = @Content(schema = @Schema(implementation = AudioDto.class))),
            @ApiResponse(responseCode = "404", description = "Audio no encontrado")
    })
    @PutMapping("/{id}")
    public AudioDto update(
            @PathVariable Long id,
            @RequestParam(required = false) String contextText) throws InstanceNotFoundException {

        Audio audio = audioService.update(id, contextText);
        return audioConversor.toAudioDto(audio, buildContentUrl(audio.getId()));
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
        return audioConversor.toAudioDto(audio, buildContentUrl(audio.getId()));
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
        return new BlockDto<>(
                audioConversor.toAudioDtos(audios.getItems(), audio -> buildContentUrl(audio.getId())),
                audios.getExistMoreItems());
    }

    @Operation(summary = "Contenido de audio", description = "Devuelve el binario del audio para reproducir/descargar desde frontend.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Contenido de audio"),
            @ApiResponse(responseCode = "404", description = "Audio no encontrado")
    })
    @GetMapping("/{id}/content")
    public ResponseEntity<Resource> getContent(@PathVariable Long id) throws InstanceNotFoundException {
        Audio audio = audioService.getById(id);
        Path path = Path.of(audio.getStoragePath());
        Resource resource = new FileSystemResource(path);
        if (!resource.exists()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Fichero de audio no encontrado");
        }

        MediaType mediaType = MediaType.APPLICATION_OCTET_STREAM;
        if (audio.getMimeType() != null) {
            try {
                mediaType = MediaType.parseMediaType(audio.getMimeType());
            } catch (Exception ignored) {
                mediaType = MediaType.APPLICATION_OCTET_STREAM;
            }
        }

        return ResponseEntity.ok()
                .contentType(mediaType)
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + audio.getOriginalFileName() + "\"")
                .body(resource);
    }

    private String buildContentUrl(Long audioId) {
        return "/audio/" + audioId + "/content";
    }
}

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
import com.junkdrawer.model.entities.Image;
import com.junkdrawer.model.services.Block;
import com.junkdrawer.model.services.ImageService;
import com.junkdrawer.rest.dtos.BlockDto;
import com.junkdrawer.rest.dtos.ImageConversor;
import com.junkdrawer.rest.dtos.ImageDto;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;

@Tag(name = "Image", description = "Operaciones para gestionar recursos de imagen.")
@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/image")
public class ImageController {

    @Autowired
    private ImageService imageService;

    @Autowired
    private ImageConversor imageConversor;

    @Operation(summary = "Subir imagen", description = "Crea una captura IMAGE y guarda la imagen validada.")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Imagen creada",
                    content = @Content(schema = @Schema(implementation = ImageDto.class))),
            @ApiResponse(responseCode = "400", description = "Archivo invalido")
    })
    @PostMapping(consumes = "multipart/form-data")
    @ResponseStatus(HttpStatus.CREATED)
    public ImageDto create(
            @RequestPart MultipartFile file,
            @RequestParam(required = false) String contextText,
            @RequestParam(required = false) Long categoryId) throws InstanceNotFoundException {

        Image image = imageService.create(file, contextText, categoryId);
        return imageConversor.toImageDto(image, buildContentUrl(image.getId()));
    }

    @Operation(summary = "Actualizar imagen", description = "Actualiza metadata de categoria/contexto de la imagen.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Imagen actualizada",
                    content = @Content(schema = @Schema(implementation = ImageDto.class))),
            @ApiResponse(responseCode = "404", description = "Imagen no encontrada")
    })
    @PutMapping("/{id}")
    public ImageDto update(
            @PathVariable Long id,
            @RequestParam(required = false) String contextText) throws InstanceNotFoundException {

        Image image = imageService.update(id, contextText);
        return imageConversor.toImageDto(image, buildContentUrl(image.getId()));
    }

    @Operation(summary = "Eliminar imagen", description = "Elimina entidad de imagen y fichero fisico.")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Imagen eliminada"),
            @ApiResponse(responseCode = "404", description = "Imagen no encontrada")
    })
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) throws InstanceNotFoundException {
        imageService.delete(id);
    }

    @Operation(summary = "Obtener imagen", description = "Obtiene una imagen por id.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Imagen encontrada",
                    content = @Content(schema = @Schema(implementation = ImageDto.class))),
            @ApiResponse(responseCode = "404", description = "Imagen no encontrada")
    })
    @GetMapping("/{id}")
    public ImageDto getById(@PathVariable Long id) throws InstanceNotFoundException {
        Image image = imageService.getById(id);
        return imageConversor.toImageDto(image, buildContentUrl(image.getId()));
    }

    @Operation(summary = "Listar imagenes", description = "Listado paginado de imagenes.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Listado paginado")
    })
    @GetMapping
    public BlockDto<ImageDto> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Block<Image> images = imageService.getAll(page, size);
        return new BlockDto<>(
                imageConversor.toImageDtos(images.getItems(), image -> buildContentUrl(image.getId())),
                images.getExistMoreItems());
    }

    @Operation(summary = "Contenido de imagen", description = "Devuelve el binario de la imagen para frontend.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Contenido de imagen"),
            @ApiResponse(responseCode = "404", description = "Imagen no encontrada")
    })
    @GetMapping("/{id}/content")
    public ResponseEntity<Resource> getContent(@PathVariable Long id) throws InstanceNotFoundException {
        Image image = imageService.getById(id);
        Path path = Path.of(image.getStoragePath());
        Resource resource = new FileSystemResource(path);
        if (!resource.exists()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Fichero de imagen no encontrado");
        }

        MediaType mediaType = MediaType.APPLICATION_OCTET_STREAM;
        if (image.getMimeType() != null) {
            try {
                mediaType = MediaType.parseMediaType(image.getMimeType());
            } catch (Exception ignored) {
                mediaType = MediaType.APPLICATION_OCTET_STREAM;
            }
        }

        return ResponseEntity.ok()
                .contentType(mediaType)
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + image.getOriginalFileName() + "\"")
                .body(resource);
    }

    private String buildContentUrl(Long imageId) {
        return "/image/" + imageId + "/content";
    }
}

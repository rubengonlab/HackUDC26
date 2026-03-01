package com.junkdrawer.rest.controllers;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.regex.Pattern;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.junkdrawer.model.common.DuplicateInstanceException;
import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.entities.Link;
import com.junkdrawer.model.entities.Note;
import com.junkdrawer.model.services.LinkService;
import com.junkdrawer.model.services.NoteService;
import com.junkdrawer.rest.dtos.CreateTextResourceParamsDto;
import com.junkdrawer.rest.dtos.TextResourceConversor;
import com.junkdrawer.rest.dtos.TextResourceDto;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

@Tag(name = "Texto", description = "Creacion de recursos de texto (nota o enlace).")
@RestController
@CrossOrigin(origins="*")
@RequestMapping("/text")
public class TextController {

    private static final Pattern STRICT_HTTP_URL_PATTERN = Pattern.compile(
            "^https?://[\\w.-]+(?::\\d+)?(?:/[\\w\\-._~:/?#\\[\\]@!$&'()*+,;=%]*)?$",
            Pattern.CASE_INSENSITIVE);

    @Autowired
    private NoteService noteService;

    @Autowired
    private LinkService linkService;

    @Autowired
    private TextResourceConversor textResourceConversor;

    @Operation(
            summary = "Crear recurso de texto",
            description = "Si content es URL valida crea LINK, si no crea NOTE.",
            requestBody = @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    required = true,
                    content = @Content(
                            schema = @Schema(implementation = CreateTextResourceParamsDto.class),
                            examples = @ExampleObject(value = """
                                    {
                                      "content": "Comprar leche y pan",
                                      "contextText": "Lista de compra"
                                    }
                                    """))))
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Recurso creado",
                    content = @Content(schema = @Schema(implementation = TextResourceDto.class))),
            @ApiResponse(responseCode = "400", description = "Datos invalidos o URL duplicada")
    })
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public TextResourceDto createTextResource(@Valid @RequestBody CreateTextResourceParamsDto params)
            throws DuplicateInstanceException, InstanceNotFoundException {

        if (isValidUrl(params.getContent())) {
            Link link = linkService.createLinkResource(params.getContent(), params.getContextText(), params.getCategoryId());
            return textResourceConversor.toTextResourceDto(link);
        }

        Note note = noteService.createNoteResource(
                params.getContent(),
                params.getContextText(),
                params.getCategoryId());
        return textResourceConversor.toTextResourceDto(note);
    }

    private boolean isValidUrl(String value) {
        if (value == null || value.isBlank()) {
            return false;
        }

        String trimmed = value.trim();
        if (!STRICT_HTTP_URL_PATTERN.matcher(trimmed).matches()) {
            return false;
        }

        try {
            URI uri = new URI(trimmed);
            return uri.getScheme() != null
                    && (uri.getScheme().equalsIgnoreCase("http") || uri.getScheme().equalsIgnoreCase("https"))
                    && uri.getHost() != null
                    && trimmed.equals(uri.toString());
        } catch (URISyntaxException exception) {
            return false;
        }
    }
}

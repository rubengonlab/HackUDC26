package com.junkdrawer.rest.dtos;

import org.springframework.stereotype.Component;

import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.entities.Link;
import com.junkdrawer.model.entities.Note;

@Component
public class TextResourceConversor {

    public TextResourceDto toTextResourceDto(Note note) {
        return fromNote(note);
    }

    public TextResourceDto toTextResourceDto(Link link) {
        return fromLink(link);
    }

    private TextResourceDto fromNote(Note note) {
        Capture capture = note.getCapture();
        TextResourceDto dto = baseFromCapture(capture);
        dto.setKind("NOTE");
        dto.setId(note.getId());
        dto.setTitle(note.getTitle());
        dto.setContent(note.getContent());
        return dto;
    }

    private TextResourceDto fromLink(Link link) {
        Capture capture = link.getCapture();
        TextResourceDto dto = baseFromCapture(capture);
        dto.setKind("LINK");
        dto.setId(link.getId());
        dto.setUrl(link.getUrl());
        dto.setOrigin(link.getOrigin());
        return dto;
    }

    private TextResourceDto baseFromCapture(Capture capture) {
        TextResourceDto dto = new TextResourceDto();
        dto.setCaptureId(capture.getId());
        dto.setCreatedAt(capture.getCreatedAt());
        dto.setCategoryStatus(capture.getCategoryStatus().name());
        dto.setContextText(capture.getContextText());
        dto.setCategoryId(capture.getCategory() != null ? capture.getCategory().getId() : null);
        return dto;
    }
}

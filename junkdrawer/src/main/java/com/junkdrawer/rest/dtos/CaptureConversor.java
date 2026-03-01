package com.junkdrawer.rest.dtos;

import java.util.List;

import org.springframework.stereotype.Component;

import com.junkdrawer.model.entities.Audio;
import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.entities.Document;
import com.junkdrawer.model.entities.Image;
import com.junkdrawer.model.entities.Link;
import com.junkdrawer.model.entities.Note;

@Component
public class CaptureConversor {

    public CaptureDto toCaptureDto(Capture capture) {
        CaptureDto dto = new CaptureDto();
        dto.setId(capture.getId());
        dto.setCreatedAt(capture.getCreatedAt());
        dto.setCaptureType(capture.getCaptureType().name());
        dto.setCategoryStatus(capture.getCategoryStatus().name());
        dto.setCategoryId(capture.getCategory() != null ? capture.getCategory().getId() : null);
        dto.setCategoryName(capture.getCategory() != null ? capture.getCategory().getName() : null);
        dto.setTitle(capture.getTitle());
        dto.setContextText(capture.getContextText());
        dto.setOrigin(capture.getOrigin());

        if (capture.getNote() != null) {
            dto.setNote(fromNote(capture.getNote()));
        }
        if (capture.getLink() != null) {
            dto.setLink(fromLink(capture.getLink()));
        }
        if (capture.getAudio() != null) {
            dto.setAudio(fromAudio(capture.getAudio()));
        }
        if (capture.getImage() != null) {
            dto.setImage(fromImage(capture.getImage()));
        }
        if (capture.getDocument() != null) {
            dto.setDocument(fromDocument(capture.getDocument()));
        }

        return dto;
    }

    public List<CaptureDto> toCaptureDtos(List<Capture> captures) {
        return captures.stream().map(this::toCaptureDto).toList();
    }

    private CaptureDto.NoteDataDto fromNote(Note note) {
        CaptureDto.NoteDataDto dto = new CaptureDto.NoteDataDto();
        dto.setId(note.getId());
        dto.setContent(note.getContent());
        dto.setReorderedText(note.getReorderedText());
        dto.setTextStatus(note.getTextStatus() != null ? note.getTextStatus().name() : null);
        return dto;
    }

    private CaptureDto.LinkDataDto fromLink(Link link) {
        CaptureDto.LinkDataDto dto = new CaptureDto.LinkDataDto();
        dto.setId(link.getId());
        dto.setUrl(link.getUrl());
        dto.setOrigin(link.getOrigin());
        return dto;
    }

    private CaptureDto.AudioDataDto fromAudio(Audio audio) {
        CaptureDto.AudioDataDto dto = new CaptureDto.AudioDataDto();
        dto.setId(audio.getId());
        dto.setFileName(audio.getFileName());
        dto.setOriginalFileName(audio.getOriginalFileName());
        dto.setMimeType(audio.getMimeType());
        dto.setSize(audio.getSize());
        dto.setStoragePath(audio.getStoragePath());
        dto.setContentUrl("/audio/" + audio.getId() + "/content");
        dto.setParsedText(audio.getParsedText());
        dto.setReorderedParsedText(audio.getReorderedParsedText());
        dto.setTextStatus(audio.getTextStatus() != null ? audio.getTextStatus().name() : null);
        return dto;
    }

    private CaptureDto.FileDataDto fromImage(Image image) {
        CaptureDto.FileDataDto dto = new CaptureDto.FileDataDto();
        dto.setId(image.getId());
        dto.setFileName(image.getFileName());
        dto.setOriginalFileName(image.getOriginalFileName());
        dto.setMimeType(image.getMimeType());
        dto.setSize(image.getSize());
        dto.setStoragePath(image.getStoragePath());
        dto.setParsedText(image.getParsedText());
        dto.setReorderedParsedText(image.getReorderedParsedText());
        dto.setTextStatus(image.getTextStatus() != null ? image.getTextStatus().name() : null);
        return dto;
    }

    private CaptureDto.FileDataDto fromDocument(Document document) {
        CaptureDto.FileDataDto dto = new CaptureDto.FileDataDto();
        dto.setId(document.getId());
        dto.setFileName(document.getFileName());
        dto.setOriginalFileName(document.getOriginalFileName());
        dto.setMimeType(document.getMimeType());
        dto.setSize(document.getSize());
        dto.setStoragePath(document.getStoragePath());
        dto.setParsedText(document.getParsedText());
        dto.setReorderedParsedText(document.getReorderedParsedText());
        dto.setTextStatus(document.getTextStatus() != null ? document.getTextStatus().name() : null);
        return dto;
    }
}

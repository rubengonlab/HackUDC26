package com.junkdrawer.rest.dtos;

import java.util.List;

import org.springframework.stereotype.Component;

import com.junkdrawer.model.entities.Audio;

@Component
public class AudioConversor {

    public AudioDto toAudioDto(Audio audio) {
        return new AudioDto(
                audio.getId(),
                audio.getCapture().getId(),
                audio.getFileName(),
                audio.getOriginalFileName(),
                audio.getMimeType(),
                audio.getSize(),
                audio.getStoragePath());
    }

    public List<AudioDto> toAudioDtos(List<Audio> audios) {
        return audios.stream()
                .map(this::toAudioDto)
                .toList();
    }
}

/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.rest.dtos;

import java.util.List;

import org.springframework.stereotype.Component;

import com.junkdrawer.model.entities.Audio;
import com.junkdrawer.model.entities.Capture;

@Component
public class AudioConversor {

    public AudioDto toAudioDto(Audio audio, String contentUrl) {
        Capture capture = audio.getCapture();
        return new AudioDto(
                audio.getId(),
                capture.getId(),
                audio.getFileName(),
                audio.getOriginalFileName(),
                audio.getMimeType(),
                audio.getSize(),
                audio.getStoragePath(),
                contentUrl,
                capture.getCreatedAt(),
                capture.getCategoryStatus().name(),
                capture.getCategory() != null ? capture.getCategory().getId() : null,
                capture.getTitle(),
                capture.getContextText(),
                audio.getParsedText(),
                audio.getReorderedParsedText(),
                audio.getTextStatus() != null ? audio.getTextStatus().name() : null);
    }

    public List<AudioDto> toAudioDtos(List<Audio> audios, java.util.function.Function<Audio, String> contentUrlBuilder) {
        return audios.stream()
                .map(audio -> toAudioDto(audio, contentUrlBuilder.apply(audio)))
                .toList();
    }
}

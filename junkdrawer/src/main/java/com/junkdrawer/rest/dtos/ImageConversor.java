/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.rest.dtos;

import java.util.List;

import org.springframework.stereotype.Component;

import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.entities.Image;

@Component
public class ImageConversor {

    public ImageDto toImageDto(Image image, String contentUrl) {
        Capture capture = image.getCapture();
        return new ImageDto(
                image.getId(),
                capture.getId(),
                image.getFileName(),
                image.getOriginalFileName(),
                image.getMimeType(),
                image.getSize(),
                image.getStoragePath(),
                contentUrl,
                capture.getCreatedAt(),
                capture.getCategoryStatus().name(),
                capture.getCategory() != null ? capture.getCategory().getId() : null,
                capture.getTitle(),
                capture.getContextText(),
                image.getParsedText(),
                image.getReorderedParsedText(),
                image.getTextStatus() != null ? image.getTextStatus().name() : null);
    }

    public List<ImageDto> toImageDtos(List<Image> images, java.util.function.Function<Image, String> contentUrlBuilder) {
        return images.stream()
                .map(image -> toImageDto(image, contentUrlBuilder.apply(image)))
                .toList();
    }
}

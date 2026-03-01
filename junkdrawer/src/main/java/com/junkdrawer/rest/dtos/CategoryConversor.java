/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.rest.dtos;

import java.util.List;

import org.springframework.stereotype.Component;

import com.junkdrawer.model.entities.Category;

@Component
public class CategoryConversor {

    public CategoryDto toCategoryDto(Category category) {
        return new CategoryDto(category.getId(), category.getName());
    }

    public List<CategoryDto> toCategoryDtos(List<Category> categories) {
        return categories.stream()
                .map(this::toCategoryDto)
                .toList();
    }
}

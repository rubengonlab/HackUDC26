/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.model.services;

import org.springframework.web.multipart.MultipartFile;

import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.entities.Audio;

public interface AudioService {

    Audio create(MultipartFile file, String contextText, Long categoryId) throws InstanceNotFoundException;

    Audio update(Long id, String contextText) throws InstanceNotFoundException;

    void delete(Long id) throws InstanceNotFoundException;

    Audio getById(Long id) throws InstanceNotFoundException;

    Block<Audio> getAll(int page, int size);
}

/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.model.services;

import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.entities.Note;

public interface NoteService {

    Note createNoteResource(String content, String contextText, Long categoryId)
            throws InstanceNotFoundException;

    Note createNote(String text, Long captureId) throws InstanceNotFoundException;

    Note getNote(Long id) throws InstanceNotFoundException;

    Note updateNote(Long id, String text, Long captureId) throws InstanceNotFoundException;

    void deleteNote(Long id) throws InstanceNotFoundException;

    Block<Note> getAll(int page, int size);
}

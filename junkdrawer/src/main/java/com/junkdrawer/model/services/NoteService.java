package com.junkdrawer.model.services;

import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.entities.Note;

public interface NoteService {

    Note createNote(String text, Long captureId) throws InstanceNotFoundException;

    Note getNote(Long id) throws InstanceNotFoundException;

    Note updateNote(Long id, String text, Long captureId) throws InstanceNotFoundException;

    void deleteNote(Long id) throws InstanceNotFoundException;
}

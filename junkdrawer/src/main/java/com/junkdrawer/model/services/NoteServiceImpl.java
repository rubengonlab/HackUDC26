package com.junkdrawer.model.services;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.daos.NoteDao;
import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.entities.Note;

@Service
@Transactional
public class NoteServiceImpl implements NoteService {

    @Autowired
    private NoteDao noteDao;

    @Autowired
    private PermissionChecker permissionChecker;

    @Override
    public Note createNote(String text, Long captureId) throws InstanceNotFoundException {
        Capture capture = permissionChecker.checkCaptureExists(captureId);

        Note note = new Note();
        note.setText(text);
        note.setCapture(capture);

        return noteDao.save(note);
    }

    @Override
    @Transactional(readOnly = true)
    public Note getNote(Long id) throws InstanceNotFoundException {
        return permissionChecker.checkNoteExists(id);
    }

    @Override
    public Note updateNote(Long id, String text, Long captureId) throws InstanceNotFoundException {
        Note note = permissionChecker.checkNoteExists(id);
        Capture capture = permissionChecker.checkCaptureExists(captureId);

        note.setText(text);
        note.setCapture(capture);

        return noteDao.save(note);
    }

    @Override
    public void deleteNote(Long id) throws InstanceNotFoundException {
        Note note = permissionChecker.checkNoteExists(id);
        noteDao.delete(note);
    }
}

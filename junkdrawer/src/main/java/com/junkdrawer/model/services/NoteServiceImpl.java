package com.junkdrawer.model.services;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.daos.CaptureDao;
import com.junkdrawer.model.daos.NoteDao;
import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.entities.Category;
import com.junkdrawer.model.entities.Note;

@Service
@Transactional
public class NoteServiceImpl implements NoteService {

    @Autowired
    private NoteDao noteDao;

    @Autowired
    private CaptureDao captureDao;

    @Autowired
    private PermissionChecker permissionChecker;

    @Override
    public Note createNoteResource(String title, String content, Long categoryId, String contextText)
            throws InstanceNotFoundException {
        Category category = null;
        if (categoryId != null) {
            category = permissionChecker.checkCategoryExists(categoryId);
        }

        Capture capture = new Capture();
        capture.setCaptureType(Capture.CaptureType.NOTE);
        capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
        capture.setCategory(category);
        capture.setContextText(contextText);
        capture = captureDao.save(capture);

        Note note = new Note();
        note.setCapture(capture);
        note.setTitle(title);
        note.setContent(content);

        return noteDao.save(note);
    }

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

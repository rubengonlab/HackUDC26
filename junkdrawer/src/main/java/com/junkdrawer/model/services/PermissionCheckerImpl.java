package com.junkdrawer.model.services;

import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.daos.AudioDao;
import com.junkdrawer.model.daos.CaptureDao;
import com.junkdrawer.model.daos.CategoryDao;
import com.junkdrawer.model.daos.NoteDao;
import com.junkdrawer.model.entities.Audio;
import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.entities.Category;
import com.junkdrawer.model.entities.Note;

@Service
@Transactional(readOnly = true)
public class PermissionCheckerImpl implements PermissionChecker {

    @Autowired
    private CategoryDao categoryDao;

    @Autowired
    private CaptureDao captureDao;

    @Autowired
    private NoteDao noteDao;

    @Autowired
    private AudioDao audioDao;

    @Override
    public Category checkCategoryExists(Long categoryId) throws InstanceNotFoundException {
        Optional<Category> optional = categoryDao.findById(categoryId);

        if (!optional.isPresent()) {
            throw new InstanceNotFoundException("project.entities.category", categoryId);
        }

        return optional.get();
    }

    @Override
    public Capture checkCaptureExists(Long captureId) throws InstanceNotFoundException {
        Optional<Capture> optional = captureDao.findById(captureId);

        if (!optional.isPresent()) {
            throw new InstanceNotFoundException("project.entities.capture", captureId);
        }

        return optional.get();
    }

    @Override
    public Note checkNoteExists(Long noteId) throws InstanceNotFoundException {
        Optional<Note> optional = noteDao.findById(noteId);

        if (!optional.isPresent()) {
            throw new InstanceNotFoundException("project.entities.note", noteId);
        }

        return optional.get();
    }

    @Override
    public Audio checkAudioExists(Long audioId) throws InstanceNotFoundException {
        Optional<Audio> optional = audioDao.findById(audioId);

        if (!optional.isPresent()) {
            throw new InstanceNotFoundException("project.entities.audio", audioId);
        }

        return optional.get();
    }
}

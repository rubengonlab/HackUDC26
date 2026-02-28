package com.junkdrawer.model.services;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.daos.CaptureDao;
import com.junkdrawer.model.daos.CategoryDao;
import com.junkdrawer.model.daos.NoteDao;
import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.entities.Category;
import com.junkdrawer.model.entities.Note;

@Service
@Transactional
public class NoteServiceImpl implements NoteService {

    private static final Logger logger = LoggerFactory.getLogger(NoteServiceImpl.class);
    private static final String NO_CATEGORY = "sin_categoria";

    @Autowired
    private NoteDao noteDao;

    @Autowired
    private CaptureDao captureDao;

    @Autowired
    private CategoryDao categoryDao;

    @Autowired
    private PermissionChecker permissionChecker;

    @Autowired
    private BedrockNovaService bedrockNovaService;

    @Override
    public Note createNoteResource(String content, String contextText)
            throws InstanceNotFoundException {
        Capture capture = new Capture();
        capture.setCaptureType(Capture.CaptureType.NOTE);
        capture.setCategoryStatus(Capture.CategoryStatus.PENDING);
        capture.setContextText(contextText);
        capture = captureDao.save(capture);

        Note note = new Note();
        note.setCapture(capture);
        note.setText(content);
        note.setTextStatus(Note.TextStatus.PENDING);

        note = noteDao.save(note);
        applySuggestedCategoryAndReorderedText(capture, note, content);

        return note;
    }

    private void applySuggestedCategoryAndReorderedText(Capture capture, Note note, String noteText) {
        List<Category> allCategories = categoryDao.findAllByOrderByNameAsc();
        if (allCategories.isEmpty()) {
            capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
            captureDao.save(capture);
            note.setTextStatus(Note.TextStatus.FAILED);
            noteDao.save(note);
            return;
        }

        List<String> categoryNames = allCategories.stream()
                .map(Category::getName)
                .collect(Collectors.toList());

        try {
            BedrockNovaService.NoteAiProcessingResult aiResult = bedrockNovaService.procesarNota(categoryNames, noteText);
            if (aiResult.title() != null && !aiResult.title().isBlank()) {
                capture.setTitle(aiResult.title().trim());
            }

            if (aiResult.reorderedText() != null && !aiResult.reorderedText().isBlank()) {
                note.setReorderedText(aiResult.reorderedText().trim());
                note.setTextStatus(Note.TextStatus.PROCESSED);
            } else {
                note.setTextStatus(Note.TextStatus.FAILED);
            }
            noteDao.save(note);

            String predictedCategory = aiResult.category();
            if (predictedCategory == null || predictedCategory.isBlank()) {
                capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
                captureDao.save(capture);
                return;
            }

            if (NO_CATEGORY.equalsIgnoreCase(predictedCategory.trim())) {
                capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
                captureDao.save(capture);
                return;
            }

            Optional<Category> matchedCategory = allCategories.stream()
                    .filter(category -> category.getName().equalsIgnoreCase(predictedCategory.trim()))
                    .findFirst();

            if (matchedCategory.isPresent()) {
                capture.setCategory(matchedCategory.get());
                captureDao.save(capture);
            } else {
                capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
                captureDao.save(capture);
                logger.warn("Categoría sugerida por modelo no encontrada: {}", predictedCategory);
            }
        } catch (Exception e) {
            capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
            captureDao.save(capture);
            note.setTextStatus(Note.TextStatus.FAILED);
            noteDao.save(note);
            logger.warn("No se pudo clasificar automáticamente la nota: {}", e.getMessage());
        }
    }

    @Override
    public Note createNote(String text, Long captureId) throws InstanceNotFoundException {
        Capture capture = permissionChecker.checkCaptureExists(captureId);

        Note note = new Note();
        note.setText(text);
        note.setTextStatus(Note.TextStatus.PENDING);
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
        note.setTextStatus(Note.TextStatus.PENDING);
        note.setReorderedText(null);
        note.setCapture(capture);

        return noteDao.save(note);
    }

    @Override
    public void deleteNote(Long id) throws InstanceNotFoundException {
        Note note = permissionChecker.checkNoteExists(id);
        noteDao.delete(note);
    }

    @Override
    @Transactional(readOnly = true)
    public Block<Note> getAll(int page, int size) {
        Slice<Note> slice = noteDao.findAll(PageRequest.of(page, size));
        return new Block<>(slice.getContent(), slice.hasNext());
    }
}

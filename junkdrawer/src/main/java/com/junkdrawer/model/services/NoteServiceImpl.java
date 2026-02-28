package com.junkdrawer.model.services;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
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
    public Note createNoteResource(String title, String content, Long categoryId, String contextText)
            throws InstanceNotFoundException {
        Category category = null;
        if (categoryId != null) {
            category = permissionChecker.checkCategoryExists(categoryId);
        }

        Capture capture = new Capture();
        capture.setCaptureType(Capture.CaptureType.NOTE);
        capture.setCategoryStatus(Capture.CategoryStatus.PENDING);
        capture.setCategory(category);
        capture.setContextText(contextText);
        capture = captureDao.save(capture);

        Note note = new Note();
        note.setCapture(capture);
        note.setTitle(title);
        note.setText(content);

        note = noteDao.save(note);
        applySuggestedCategory(capture, content);

        return note;
    }

    private void applySuggestedCategory(Capture capture, String noteText) {
        List<Category> allCategories = categoryDao.findAllByOrderByNameAsc();
        if (allCategories.isEmpty()) {
            capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
            captureDao.save(capture);
            return;
        }

        List<String> categoryNames = allCategories.stream()
                .map(Category::getName)
                .collect(Collectors.toList());

        try {
            String predictedCategory = bedrockNovaService.clasificarTexto(categoryNames, noteText);
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
            logger.warn("No se pudo clasificar automáticamente la nota: {}", e.getMessage());
        }
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

/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.model.services;

import java.time.LocalDateTime;
import java.time.LocalDate;
import java.util.List;

import org.springframework.data.domain.Slice;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.daos.CaptureDao;
import com.junkdrawer.model.entities.Audio;
import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.entities.Category;
import com.junkdrawer.model.entities.Image;
import com.junkdrawer.model.entities.Note;

@Service
@Transactional
public class CaptureServiceImpl implements CaptureService {

    @Autowired
    private CaptureDao captureDao;

    @Autowired
    private PermissionChecker permissionChecker;

    @Override
    public Capture createCapture(Capture.CaptureType captureType, Capture.CategoryStatus categoryStatus, Long categoryId)
            throws InstanceNotFoundException {

        Category category = null;
        if (categoryId != null) {
            category = permissionChecker.checkCategoryExists(categoryId);
        }

        Capture capture = new Capture();
        capture.setCaptureType(captureType);
        capture.setCategoryStatus(categoryStatus);
        capture.setCategory(category);
        capture.setCreatedAt(LocalDateTime.now().withNano(0));

        return captureDao.save(capture);
    }

    @Override
    @Transactional(readOnly = true)
    public Capture getCapture(Long id) throws InstanceNotFoundException {
        return permissionChecker.checkCaptureExists(id);
    }

    @Override
    public Capture updateCapture(Long id, Capture.CaptureType captureType, Capture.CategoryStatus categoryStatus, Long categoryId)
            throws InstanceNotFoundException {

        Capture capture = permissionChecker.checkCaptureExists(id);

        Category category = null;
        if (categoryId != null) {
            category = permissionChecker.checkCategoryExists(categoryId);
        }

        capture.setCaptureType(captureType);
        capture.setCategoryStatus(categoryStatus);
        capture.setCategory(category);

        return captureDao.save(capture);
    }

    @Override
    public void deleteCapture(Long id) throws InstanceNotFoundException {
        Capture capture = permissionChecker.checkCaptureExists(id);
        captureDao.delete(capture);
    }

    @Override
    @Transactional(readOnly = true)
    public Block<Capture> getCaptures(LocalDate dateFrom, LocalDate dateTo, Long categoryId,
            Capture.CaptureType captureType, int page, int size) {

        LocalDateTime createdFrom = dateFrom != null ? dateFrom.atStartOfDay() : null;
        LocalDateTime createdToExclusive = dateTo != null ? dateTo.plusDays(1).atStartOfDay() : null;

        Slice<Capture> slice = captureDao.getCaptures(createdFrom, createdToExclusive, categoryId, captureType, page, size);
        return new Block<>(slice.getContent(), slice.hasNext());
    }

    @Override
    public Capture patchCapture(Long captureId, Long categoryId, String title, String contextText, String reorderedText,
            String audioName, String imageName) throws InstanceNotFoundException {

        Capture capture = permissionChecker.checkCaptureExists(captureId);

        if (categoryId != null) {
            Category category = permissionChecker.checkCategoryExists(categoryId);
            capture.setCategory(category);
        }
        if (title != null) {
            capture.setTitle(title);
        }
        if (contextText != null) {
            capture.setContextText(contextText);
        }
        if (reorderedText != null) {
            applyReorderedText(capture, reorderedText);
        }
        if (audioName != null) {
            if (capture.getAudio() == null) {
                throw new IllegalArgumentException("La captura no es de tipo AUDIO");
            }
            capture.getAudio().setOriginalFileName(audioName);
        }
        if (imageName != null) {
            if (capture.getImage() == null) {
                throw new IllegalArgumentException("La captura no es de tipo IMAGE");
            }
            capture.getImage().setOriginalFileName(imageName);
        }

        return captureDao.save(capture);
    }

    @Override
    public Capture approveStatuses(Long captureId, String target) throws InstanceNotFoundException {
        Capture capture = permissionChecker.checkCaptureExists(captureId);
        StatusTarget statusTarget = parseStatusTarget(target);

        if (statusTarget == StatusTarget.ALL || statusTarget == StatusTarget.CATEGORY) {
            capture.setCategoryStatus(Capture.CategoryStatus.APPROVED);
        }
        if (statusTarget == StatusTarget.ALL || statusTarget == StatusTarget.TEXT) {
            approveTextStatus(capture);
        }

        return captureDao.save(capture);
    }

    @Override
    public Capture rejectStatuses(Long captureId, String target) throws InstanceNotFoundException {
        Capture capture = permissionChecker.checkCaptureExists(captureId);
        StatusTarget statusTarget = parseStatusTarget(target);

        if (statusTarget == StatusTarget.ALL || statusTarget == StatusTarget.CATEGORY) {
            capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
            capture.setCategory(null);
        }
        if (statusTarget == StatusTarget.ALL || statusTarget == StatusTarget.TEXT) {
            rejectTextStatus(capture);
        }

        return captureDao.save(capture);
    }

    @Override
    @Transactional(readOnly = true)
    public Block<Capture> getPendingCategoryCaptures(int page, int size) {
        Slice<Capture> slice = captureDao.getCapturesByCategoryStatus(Capture.CategoryStatus.PENDING, page, size);
        return new Block<>(slice.getContent(), slice.hasNext());
    }

    @Override
    @Transactional(readOnly = true)
    public List<Capture.CaptureType> getUsedCaptureTypes() {
        return captureDao.getUsedCaptureTypes();
    }

    @Override
    @Transactional(readOnly = true)
    public Block<LocalDate> getCaptureDays(int page, int size) {
        Slice<LocalDate> slice = captureDao.getCaptureDays(page, size);
        return new Block<>(slice.getContent(), slice.hasNext());
    }

    private void applyReorderedText(Capture capture, String reorderedText) {
        if (capture.getNote() != null) {
            Note note = capture.getNote();
            note.setReorderedText(reorderedText);
            note.setTextStatus(Note.TextStatus.PROCESSED);
            return;
        }
        if (capture.getAudio() != null) {
            Audio audio = capture.getAudio();
            audio.setReorderedParsedText(reorderedText);
            audio.setTextStatus(Audio.TextStatus.PROCESSED);
            return;
        }
        if (capture.getImage() != null) {
            Image image = capture.getImage();
            image.setReorderedParsedText(reorderedText);
            image.setTextStatus(Image.TextStatus.PROCESSED);
            return;
        }

        throw new IllegalArgumentException("La captura no tiene texto reordenado editable para su tipo");
    }

    private void approveTextStatus(Capture capture) {
        if (capture.getNote() != null) {
            capture.getNote().setTextStatus(Note.TextStatus.APPROVED);
            return;
        }
        if (capture.getAudio() != null) {
            capture.getAudio().setTextStatus(Audio.TextStatus.APPROVED);
            return;
        }
        if (capture.getImage() != null) {
            capture.getImage().setTextStatus(Image.TextStatus.APPROVED);
            return;
        }

        throw new IllegalArgumentException("La captura no soporta estado de texto");
    }

    private void rejectTextStatus(Capture capture) {
        if (capture.getNote() != null) {
            capture.getNote().setTextStatus(Note.TextStatus.FAILED);
            return;
        }
        if (capture.getAudio() != null) {
            capture.getAudio().setTextStatus(Audio.TextStatus.FAILED);
            return;
        }
        if (capture.getImage() != null) {
            capture.getImage().setTextStatus(Image.TextStatus.FAILED);
            return;
        }

        throw new IllegalArgumentException("La captura no soporta estado de texto");
    }

    private StatusTarget parseStatusTarget(String target) {
        if (target == null || target.isBlank()) {
            return StatusTarget.ALL;
        }

        return switch (target.trim().toLowerCase()) {
            case "all" -> StatusTarget.ALL;
            case "category" -> StatusTarget.CATEGORY;
            case "text" -> StatusTarget.TEXT;
            default -> throw new IllegalArgumentException("target invalido. Valores: all, category, text");
        };
    }

    private enum StatusTarget {
        ALL,
        CATEGORY,
        TEXT
    }
}

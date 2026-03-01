/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.model.services;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.daos.AudioDao;
import com.junkdrawer.model.daos.CaptureDao;
import com.junkdrawer.model.daos.CategoryDao;
import com.junkdrawer.model.entities.Audio;
import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.entities.Category;

@Service
@Transactional
public class AudioServiceImpl implements AudioService {

    private static final Logger logger = LoggerFactory.getLogger(AudioServiceImpl.class);
    private static final String NO_CATEGORY = "sin_categoria";

    @Autowired
    private AudioDao audioDao;

    @Autowired
    private CaptureDao captureDao;

    @Autowired
    private CategoryDao categoryDao;

    @Autowired
    private PermissionChecker permissionChecker;

    @Autowired
    private BedrockNovaService bedrockNovaService;

    @Autowired
    private WhisperTranscriptionService whisperTranscriptionService;

    @Value("${app.upload.base-path:uploads}")
    private String uploadBasePath;

    @Override
    public Audio create(MultipartFile file, String contextText, Long categoryId) throws InstanceNotFoundException {
        validateAudioFile(file);

        Category selectedCategory = null;
        if (categoryId != null) {
            selectedCategory = permissionChecker.checkCategoryExists(categoryId);
        }

        Capture capture = new Capture();
        capture.setCaptureType(Capture.CaptureType.AUDIO);
        capture.setCategoryStatus(selectedCategory != null ? Capture.CategoryStatus.APPROVED : Capture.CategoryStatus.PENDING);
        capture.setCategory(selectedCategory);
        capture.setContextText(contextText);
        capture = captureDao.save(capture);

        String fileName = buildFileName(file.getOriginalFilename());
        Path storageDirectory = Paths.get(uploadBasePath, "audio");
        Path destination = storageDirectory.resolve(fileName);

        try {
            Files.createDirectories(storageDirectory);
            Files.copy(file.getInputStream(), destination, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException exception) {
            throw new RuntimeException("No se pudo guardar el archivo de audio", exception);
        }

        Audio audio = new Audio();
        audio.setCapture(capture);
        audio.setFileName(fileName);
        audio.setOriginalFileName(file.getOriginalFilename());
        audio.setMimeType(file.getContentType());
        audio.setSize(file.getSize());
        audio.setStoragePath(destination.toString());
        audio.setTextStatus(Audio.TextStatus.PENDING);
        audio = audioDao.save(audio);

        processSuggestedCategoryAndTitleFromAudio(capture, audio, destination, contextText, selectedCategory != null);
        return audio;
    }

    @Override
    public Audio update(Long id, String contextText) throws InstanceNotFoundException {
        Audio audio = permissionChecker.checkAudioExists(id);
        Capture capture = audio.getCapture();
        capture.setContextText(contextText);
        captureDao.save(capture);
        return audio;
    }

    @Override
    public void delete(Long id) throws InstanceNotFoundException {
        Audio audio = permissionChecker.checkAudioExists(id);

        try {
            Files.deleteIfExists(Paths.get(audio.getStoragePath()));
        } catch (IOException exception) {
            throw new RuntimeException("No se pudo borrar el archivo de audio", exception);
        }

        Capture capture = audio.getCapture();
        audioDao.delete(audio);
        captureDao.delete(capture);
    }

    @Override
    @Transactional(readOnly = true)
    public Audio getById(Long id) throws InstanceNotFoundException {
        return permissionChecker.checkAudioExists(id);
    }

    @Override
    @Transactional(readOnly = true)
    public Block<Audio> getAll(int page, int size) {
        Slice<Audio> slice = audioDao.findAll(PageRequest.of(page, size));
        return new Block<>(slice.getContent(), slice.hasNext());
    }

    private void processSuggestedCategoryAndTitleFromAudio(Capture capture, Audio audio, Path audioPath, String contextText,
            boolean hasUserCategory) {
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
            String parsedText = whisperTranscriptionService.transcribe(audioPath)
                    .map(String::trim)
                    .filter(text -> !text.isBlank())
                    .orElse(null);

            audio.setParsedText(parsedText);

            if (parsedText == null) {
                audio.setTextStatus(Audio.TextStatus.FAILED);
                audio.setReorderedParsedText(null);
                audioDao.save(audio);
                capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
                captureDao.save(capture);
                logger.warn("Audio sin transcripcion disponible; no se puede clasificar por contenido");
                return;
            }

            String textForModel = buildTextForModel(parsedText, contextText);
            BedrockNovaService.AudioAiProcessingResult aiResult = bedrockNovaService
                    .procesarTranscripcionAudio(categoryNames, textForModel);

            if (aiResult.reorderedText() != null && !aiResult.reorderedText().isBlank()) {
                audio.setReorderedParsedText(aiResult.reorderedText().trim());
                audio.setTextStatus(Audio.TextStatus.PROCESSED);
            } else {
                audio.setReorderedParsedText(null);
                audio.setTextStatus(Audio.TextStatus.FAILED);
            }
            audioDao.save(audio);

            applyCategoryAndTitle(capture, allCategories, aiResult.category(), aiResult.title(), hasUserCategory);
        } catch (Exception exception) {
            audio.setTextStatus(Audio.TextStatus.FAILED);
            audioDao.save(audio);
            capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
            captureDao.save(capture);
            logger.warn("No se pudo clasificar automaticamente el audio: {}", exception.getMessage());
        }
    }

    private void applyCategoryAndTitle(Capture capture, List<Category> allCategories,
            String predictedCategory, String title, boolean hasUserCategory) {

        if (title != null && !title.isBlank()) {
            capture.setTitle(title.trim());
        }

        if (hasUserCategory) {
            captureDao.save(capture);
            return;
        }

        if (predictedCategory == null || predictedCategory.isBlank()
                || NO_CATEGORY.equalsIgnoreCase(predictedCategory.trim())) {
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
            logger.warn("Categoria sugerida por modelo no encontrada para audio: {}", predictedCategory);
        }
    }

    private void validateAudioFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("El archivo no puede estar vacio");
        }

        String mimeType = file.getContentType();
        if (mimeType == null || !mimeType.startsWith("audio/")) {
            throw new IllegalArgumentException("El archivo debe ser de tipo audio");
        }
    }

    private String buildFileName(String originalFileName) {
        String extension = "";
        if (originalFileName != null) {
            int index = originalFileName.lastIndexOf('.');
            if (index >= 0) {
                extension = originalFileName.substring(index);
            }
        }
        return UUID.randomUUID() + extension;
    }

    private String buildTextForModel(String parsedText, String contextText) {
        String normalizedParsed = parsedText != null ? parsedText.trim() : "";
        String normalizedContext = contextText != null ? contextText.trim() : "";

        if (normalizedContext.isBlank()) {
            return normalizedParsed;
        }
        if (normalizedParsed.isBlank()) {
            return normalizedContext;
        }

        return normalizedParsed + "\n\nContexto:\n" + normalizedContext;
    }
}

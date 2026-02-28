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

    @Value("${app.upload.base-path:uploads}")
    private String uploadBasePath;

    @Override
    public Audio create(MultipartFile file, String contextText) throws InstanceNotFoundException {
        validateAudioFile(file);

        Capture capture = new Capture();
        capture.setCaptureType(Capture.CaptureType.AUDIO);
        capture.setCategoryStatus(Capture.CategoryStatus.PENDING);
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
        audio = audioDao.save(audio);

        applySuggestedCategoryAndTitle(capture, normalizeContext(contextText));
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

    private void applySuggestedCategoryAndTitle(Capture capture, String textToClassify) {
        List<Category> allCategories = categoryDao.findAllByOrderByNameAsc();
        if (allCategories.isEmpty() || textToClassify.isBlank()) {
            capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
            captureDao.save(capture);
            if (textToClassify.isBlank()) {
                logger.warn("Audio sin transcripción/contexto; no se puede clasificar por contenido");
            }
            return;
        }

        List<String> categoryNames = allCategories.stream()
                .map(Category::getName)
                .collect(Collectors.toList());

        try {
            BedrockNovaService.AiProcessingResult aiResult = bedrockNovaService.procesarTexto(categoryNames, textToClassify);
            if (aiResult.title() != null && !aiResult.title().isBlank()) {
                capture.setTitle(aiResult.title().trim());
            }

            String predictedCategory = aiResult.category();
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
                logger.warn("Categoría sugerida por modelo no encontrada para audio: {}", predictedCategory);
            }
        } catch (Exception exception) {
            capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
            captureDao.save(capture);
            logger.warn("No se pudo clasificar automáticamente el audio: {}", exception.getMessage());
        }
    }

    private String normalizeContext(String contextText) {
        if (contextText == null) {
            return "";
        }
        return contextText.trim();
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
}

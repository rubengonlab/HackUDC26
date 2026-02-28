package com.junkdrawer.model.services;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

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
import com.junkdrawer.model.entities.Audio;
import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.entities.Category;

@Service
@Transactional
public class AudioServiceImpl implements AudioService {

    @Autowired
    private AudioDao audioDao;

    @Autowired
    private CaptureDao captureDao;

    @Autowired
    private PermissionChecker permissionChecker;

    @Value("${app.upload.base-path:uploads}")
    private String uploadBasePath;

    @Override
    public Audio create(MultipartFile file, Long categoryId, String contextText) throws InstanceNotFoundException {
        validateAudioFile(file);

        Category category = null;
        if (categoryId != null) {
            category = permissionChecker.checkCategoryExists(categoryId);
        }

        Capture capture = new Capture();
        capture.setCaptureType(Capture.CaptureType.AUDIO);
        capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
        capture.setCategory(category);
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

        return audioDao.save(audio);
    }

    @Override
    public Audio update(Long id, Long categoryId, String contextText) throws InstanceNotFoundException {
        Audio audio = permissionChecker.checkAudioExists(id);
        Capture capture = audio.getCapture();

        Category category = null;
        if (categoryId != null) {
            category = permissionChecker.checkCategoryExists(categoryId);
        }

        capture.setCategory(category);
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

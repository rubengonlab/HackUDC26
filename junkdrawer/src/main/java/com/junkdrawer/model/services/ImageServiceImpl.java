package com.junkdrawer.model.services;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.net.URLConnection;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

import javax.imageio.ImageIO;

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
import com.junkdrawer.model.daos.CaptureDao;
import com.junkdrawer.model.daos.CategoryDao;
import com.junkdrawer.model.daos.ImageDao;
import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.entities.Category;
import com.junkdrawer.model.entities.Image;

@Service
@Transactional
public class ImageServiceImpl implements ImageService {

    private static final Logger logger = LoggerFactory.getLogger(ImageServiceImpl.class);
    private static final String NO_CATEGORY = "sin_categoria";

    @Autowired
    private ImageDao imageDao;

    @Autowired
    private CaptureDao captureDao;

    @Autowired
    private CategoryDao categoryDao;

    @Autowired
    private PermissionChecker permissionChecker;

    @Autowired
    private BedrockNovaService bedrockNovaService;

    @Autowired
    private AzureVisionOcrService azureVisionOcrService;

    @Value("${app.upload.base-path:uploads}")
    private String uploadBasePath;

    @Value("${app.upload.image.max-bytes:10485760}")
    private long maxImageSizeBytes;

    @Override
    public Image create(MultipartFile file, String contextText) throws InstanceNotFoundException {
        ValidatedImage validatedImage = validateAndReadImage(file);

        Capture capture = new Capture();
        capture.setCaptureType(Capture.CaptureType.IMAGE);
        capture.setCategoryStatus(Capture.CategoryStatus.PENDING);
        capture.setContextText(contextText);
        capture = captureDao.save(capture);

        String fileName = buildFileName(file.getOriginalFilename(), validatedImage.mimeType());
        Path storageDirectory = Paths.get(uploadBasePath, "image");
        Path destination = storageDirectory.resolve(fileName);

        try {
            Files.createDirectories(storageDirectory);
            Files.write(destination, validatedImage.bytes());
        } catch (IOException exception) {
            throw new RuntimeException("No se pudo guardar el archivo de imagen", exception);
        }

        Image image = new Image();
        image.setCapture(capture);
        image.setFileName(fileName);
        image.setOriginalFileName(file.getOriginalFilename());
        image.setMimeType(validatedImage.mimeType());
        image.setSize(file.getSize());
        image.setStoragePath(destination.toString());
        image.setTextStatus(Image.TextStatus.PENDING);
        image = imageDao.save(image);

        processImageTextAndCategory(capture, image, validatedImage.bytes(), contextText);
        return image;
    }

    @Override
    public Image update(Long id, String contextText) throws InstanceNotFoundException {
        Image image = permissionChecker.checkImageExists(id);
        Capture capture = image.getCapture();
        capture.setContextText(contextText);
        captureDao.save(capture);
        return image;
    }

    @Override
    public void delete(Long id) throws InstanceNotFoundException {
        Image image = permissionChecker.checkImageExists(id);

        try {
            Files.deleteIfExists(Paths.get(image.getStoragePath()));
        } catch (IOException exception) {
            throw new RuntimeException("No se pudo borrar el archivo de imagen", exception);
        }

        Capture capture = image.getCapture();
        imageDao.delete(image);
        captureDao.delete(capture);
    }

    @Override
    @Transactional(readOnly = true)
    public Image getById(Long id) throws InstanceNotFoundException {
        return permissionChecker.checkImageExists(id);
    }

    @Override
    @Transactional(readOnly = true)
    public Block<Image> getAll(int page, int size) {
        Slice<Image> slice = imageDao.findAll(PageRequest.of(page, size));
        return new Block<>(slice.getContent(), slice.hasNext());
    }

    private void processImageTextAndCategory(Capture capture, Image image, byte[] imageBytes, String contextText) {
        List<Category> allCategories = categoryDao.findAllByOrderByNameAsc();
        if (allCategories.isEmpty()) {
            capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
            captureDao.save(capture);
            image.setTextStatus(Image.TextStatus.FAILED);
            imageDao.save(image);
            return;
        }

        List<String> categoryNames = allCategories.stream()
                .map(Category::getName)
                .collect(Collectors.toList());

        try {
            String parsedText = azureVisionOcrService.extractText(imageBytes)
                    .map(String::trim)
                    .filter(text -> !text.isBlank())
                    .orElseGet(() -> normalizeContext(contextText));

            image.setParsedText(parsedText != null && !parsedText.isBlank() ? parsedText : null);

            if (parsedText == null || parsedText.isBlank()) {
                image.setTextStatus(Image.TextStatus.FAILED);
                imageDao.save(image);
                capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
                captureDao.save(capture);
                logger.warn("Imagen sin texto OCR ni contexto; no se puede clasificar");
                return;
            }

            BedrockNovaService.NoteAiProcessingResult aiResult = bedrockNovaService.procesarNota(categoryNames, parsedText);

            if (aiResult.reorderedText() != null && !aiResult.reorderedText().isBlank()) {
                image.setReorderedParsedText(aiResult.reorderedText().trim());
                image.setTextStatus(Image.TextStatus.PROCESSED);
            } else {
                image.setReorderedParsedText(null);
                image.setTextStatus(Image.TextStatus.FAILED);
            }
            imageDao.save(image);

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
                logger.warn("Categoria sugerida por modelo no encontrada para imagen: {}", predictedCategory);
            }
        } catch (Exception exception) {
            capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
            captureDao.save(capture);
            image.setTextStatus(Image.TextStatus.FAILED);
            imageDao.save(image);
            logger.warn("No se pudo clasificar automaticamente la imagen: {}", exception.getMessage());
        }
    }

    private String normalizeContext(String contextText) {
        if (contextText == null) {
            return "";
        }
        return contextText.trim();
    }

    private ValidatedImage validateAndReadImage(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("El archivo no puede estar vacio");
        }

        if (file.getSize() > maxImageSizeBytes) {
            throw new IllegalArgumentException("La imagen excede el tamano maximo permitido");
        }

        String declaredMimeType = normalizeMimeType(file.getContentType());
        if (declaredMimeType == null || !declaredMimeType.startsWith("image/")) {
            throw new IllegalArgumentException("El archivo debe ser de tipo imagen");
        }

        byte[] bytes;
        try {
            bytes = file.getBytes();
        } catch (IOException exception) {
            throw new RuntimeException("No se pudo leer el archivo de imagen", exception);
        }

        if (bytes.length == 0) {
            throw new IllegalArgumentException("El archivo no puede estar vacio");
        }

        String detectedMimeType;
        try {
            detectedMimeType = normalizeMimeType(URLConnection.guessContentTypeFromStream(new ByteArrayInputStream(bytes)));
        } catch (IOException exception) {
            throw new RuntimeException("No se pudo detectar el tipo de la imagen", exception);
        }

        if (detectedMimeType == null || !detectedMimeType.startsWith("image/")) {
            throw new IllegalArgumentException("El contenido del archivo no corresponde a una imagen valida");
        }

        if (!areEquivalentImageMimeTypes(declaredMimeType, detectedMimeType)) {
            throw new IllegalArgumentException("El contenido de la imagen no coincide con el tipo MIME indicado");
        }

        BufferedImage bufferedImage;
        try {
            bufferedImage = ImageIO.read(new ByteArrayInputStream(bytes));
        } catch (IOException exception) {
            throw new RuntimeException("No se pudo procesar la imagen", exception);
        }

        if (bufferedImage == null || bufferedImage.getWidth() <= 0 || bufferedImage.getHeight() <= 0) {
            throw new IllegalArgumentException("La imagen esta corrupta o no es compatible");
        }

        return new ValidatedImage(bytes, detectedMimeType);
    }

    private String buildFileName(String originalFileName, String mimeType) {
        String extension = extractExtension(originalFileName);
        if (extension.isEmpty()) {
            extension = extensionFromMimeType(mimeType);
        }
        return UUID.randomUUID() + extension;
    }

    private String extractExtension(String originalFileName) {
        if (originalFileName == null) {
            return "";
        }

        String safeName = Paths.get(originalFileName).getFileName().toString();
        int index = safeName.lastIndexOf('.');
        if (index < 0 || index == safeName.length() - 1) {
            return "";
        }

        return safeName.substring(index).toLowerCase();
    }

    private String extensionFromMimeType(String mimeType) {
        return switch (normalizeMimeType(mimeType)) {
            case "image/jpeg" -> ".jpg";
            case "image/png" -> ".png";
            case "image/gif" -> ".gif";
            case "image/webp" -> ".webp";
            case "image/bmp" -> ".bmp";
            default -> "";
        };
    }

    private String normalizeMimeType(String mimeType) {
        if (mimeType == null) {
            return null;
        }
        int separator = mimeType.indexOf(';');
        String normalized = separator >= 0 ? mimeType.substring(0, separator) : mimeType;
        return normalized.trim().toLowerCase();
    }

    private boolean areEquivalentImageMimeTypes(String firstMimeType, String secondMimeType) {
        String normalizedFirst = canonicalizeImageMimeType(normalizeMimeType(firstMimeType));
        String normalizedSecond = canonicalizeImageMimeType(normalizeMimeType(secondMimeType));
        return normalizedFirst != null && normalizedFirst.equals(normalizedSecond);
    }

    private String canonicalizeImageMimeType(String mimeType) {
        if (mimeType == null) {
            return null;
        }

        return switch (mimeType) {
            case "image/jpg", "image/pjpeg" -> "image/jpeg";
            case "image/x-png" -> "image/png";
            default -> mimeType;
        };
    }

    private record ValidatedImage(byte[] bytes, String mimeType) {
    }
}

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
import com.junkdrawer.model.daos.CaptureDao;
import com.junkdrawer.model.daos.CategoryDao;
import com.junkdrawer.model.daos.DocumentDao;
import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.entities.Category;
import com.junkdrawer.model.entities.Document;

@Service
@Transactional
public class DocumentServiceImpl implements DocumentService {

    private static final Logger logger = LoggerFactory.getLogger(DocumentServiceImpl.class);
    private static final String NO_CATEGORY = "sin_categoria";

    @Autowired
    private DocumentDao documentDao;

    @Autowired
    private CaptureDao captureDao;

    @Autowired
    private CategoryDao categoryDao;

    @Autowired
    private PermissionChecker permissionChecker;

    @Autowired
    private BedrockNovaService bedrockNovaService;

    @Autowired
    private DocumentTextExtractionService documentTextExtractionService;

    @Value("${app.upload.base-path:uploads}")
    private String uploadBasePath;

    @Value("${app.upload.document.max-bytes:20971520}")
    private long maxDocumentSizeBytes;

    @Override
    public Document create(MultipartFile file, String contextText, Long categoryId) throws InstanceNotFoundException {
        validateDocument(file);

        Category selectedCategory = null;
        if (categoryId != null) {
            selectedCategory = permissionChecker.checkCategoryExists(categoryId);
        }

        Capture capture = new Capture();
        capture.setCaptureType(Capture.CaptureType.DOCUMENT);
        capture.setCategoryStatus(selectedCategory != null ? Capture.CategoryStatus.APPROVED : Capture.CategoryStatus.PENDING);
        capture.setCategory(selectedCategory);
        capture.setContextText(contextText);
        capture = captureDao.save(capture);

        String fileName = buildFileName(file.getOriginalFilename());
        Path storageDirectory = Paths.get(uploadBasePath, "document");
        Path destination = storageDirectory.resolve(fileName);
        byte[] fileBytes;
        try {
            fileBytes = file.getBytes();
            Files.createDirectories(storageDirectory);
            Files.copy(file.getInputStream(), destination, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException exception) {
            throw new RuntimeException("No se pudo guardar el archivo de documento", exception);
        }

        Document document = new Document();
        document.setCapture(capture);
        document.setFileName(fileName);
        document.setOriginalFileName(file.getOriginalFilename());
        document.setMimeType(file.getContentType());
        document.setSize(file.getSize());
        document.setStoragePath(destination.toString());
        document.setTextStatus(Document.TextStatus.PENDING);
        document = documentDao.save(document);

        processDocumentTextAndCategory(capture, document, fileBytes, contextText, selectedCategory != null);
        return document;
    }

    @Override
    public Document update(Long id, String contextText) throws InstanceNotFoundException {
        Document document = permissionChecker.checkDocumentExists(id);
        Capture capture = document.getCapture();
        capture.setContextText(contextText);
        captureDao.save(capture);
        return document;
    }

    @Override
    public void delete(Long id) throws InstanceNotFoundException {
        Document document = permissionChecker.checkDocumentExists(id);

        try {
            Files.deleteIfExists(Paths.get(document.getStoragePath()));
        } catch (IOException exception) {
            throw new RuntimeException("No se pudo borrar el archivo de documento", exception);
        }

        Capture capture = document.getCapture();
        documentDao.delete(document);
        captureDao.delete(capture);
    }

    @Override
    @Transactional(readOnly = true)
    public Document getById(Long id) throws InstanceNotFoundException {
        return permissionChecker.checkDocumentExists(id);
    }

    @Override
    @Transactional(readOnly = true)
    public Block<Document> getAll(int page, int size) {
        Slice<Document> slice = documentDao.findAll(PageRequest.of(page, size));
        return new Block<>(slice.getContent(), slice.hasNext());
    }

    private void processDocumentTextAndCategory(Capture capture, Document document, byte[] fileBytes, String contextText,
            boolean hasUserCategory) {

        List<Category> allCategories = categoryDao.findAllByOrderByNameAsc();
        if (allCategories.isEmpty()) {
            capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
            captureDao.save(capture);
            document.setTextStatus(Document.TextStatus.FAILED);
            documentDao.save(document);
            return;
        }

        List<String> categoryNames = allCategories.stream().map(Category::getName).collect(Collectors.toList());

        try {
            String parsedText = documentTextExtractionService
                    .extractText(fileBytes, document.getOriginalFileName(), document.getMimeType())
                    .orElseGet(() -> normalizeContext(contextText));

            if (parsedText != null && !parsedText.isBlank()) {
                document.setParsedText(parsedText);
            } else {
                document.setParsedText(null);
            }

            if (parsedText == null || parsedText.isBlank()) {
                document.setReorderedParsedText(null);
                document.setTextStatus(Document.TextStatus.FAILED);
                documentDao.save(document);
                capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
                captureDao.save(capture);
                logger.warn("Documento sin texto extraible ni contexto");
                return;
            }

            String textForModel = buildTextForModel(parsedText, contextText);
            BedrockNovaService.NoteAiProcessingResult aiResult = bedrockNovaService.procesarNota(categoryNames, textForModel);

            if (aiResult.reorderedText() != null && !aiResult.reorderedText().isBlank()) {
                document.setReorderedParsedText(aiResult.reorderedText().trim());
                document.setTextStatus(Document.TextStatus.PROCESSED);
            } else {
                document.setReorderedParsedText(null);
                document.setTextStatus(Document.TextStatus.FAILED);
            }
            documentDao.save(document);

            if (aiResult.title() != null && !aiResult.title().isBlank()) {
                capture.setTitle(aiResult.title().trim());
            }

            if (hasUserCategory) {
                captureDao.save(capture);
                return;
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
                logger.warn("Categoria sugerida por modelo no encontrada para documento: {}", predictedCategory);
            }
        } catch (Exception exception) {
            document.setTextStatus(Document.TextStatus.FAILED);
            documentDao.save(document);
            capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
            captureDao.save(capture);
            logger.warn("No se pudo procesar documento: {}", exception.getMessage());
        }
    }

    private void validateDocument(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("El archivo no puede estar vacio");
        }
        if (file.getSize() > maxDocumentSizeBytes) {
            throw new IllegalArgumentException("El documento excede el tamano maximo permitido");
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

    private String normalizeContext(String contextText) {
        if (contextText == null) {
            return "";
        }
        return contextText.trim();
    }

    private String buildTextForModel(String parsedText, String contextText) {
        String normalizedParsed = parsedText != null ? parsedText.trim() : "";
        String normalizedContext = normalizeContext(contextText);

        if (normalizedContext.isBlank()) {
            return normalizedParsed;
        }
        if (normalizedParsed.isBlank()) {
            return normalizedContext;
        }
        return normalizedParsed + "\n\nContexto:\n" + normalizedContext;
    }
}

package com.junkdrawer.model.services;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.junkdrawer.model.common.DuplicateInstanceException;
import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.daos.CaptureDao;
import com.junkdrawer.model.daos.CategoryDao;
import com.junkdrawer.model.daos.LinkDao;
import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.entities.Category;
import com.junkdrawer.model.entities.Link;

@Service
@Transactional
public class LinkServiceImpl implements LinkService {

    private static final Logger logger = LoggerFactory.getLogger(LinkServiceImpl.class);
    private static final String NO_CATEGORY = "sin_categoria";

    @Autowired
    private LinkDao linkDao;

    @Autowired
    private CaptureDao captureDao;

    @Autowired
    private CategoryDao categoryDao;

    @Autowired
    private BedrockNovaService bedrockNovaService;

    @Autowired
    private PermissionChecker permissionChecker;

    @Override
    public Link createLinkResource(String url, String contextText, Long categoryId)
            throws DuplicateInstanceException, InstanceNotFoundException {

        Optional<Link> optionalLink = linkDao.findByUrl(url);
        if (optionalLink.isPresent()) {
            throw new DuplicateInstanceException("project.entities.link", url);
        }

        Category selectedCategory = null;
        if (categoryId != null) {
            selectedCategory = permissionChecker.checkCategoryExists(categoryId);
        }

        String origin = detectOrigin(url);

        Capture capture = new Capture();
        capture.setCaptureType(Capture.CaptureType.LINK);
        capture.setCategoryStatus(selectedCategory != null ? Capture.CategoryStatus.APPROVED : Capture.CategoryStatus.PENDING);
        capture.setCategory(selectedCategory);
        capture.setContextText(contextText);
        capture.setOrigin(origin);
        capture = captureDao.save(capture);

        Link link = new Link();
        link.setCapture(capture);
        link.setUrl(url);
        link.setOrigin(origin);

        link = linkDao.save(link);

        applySuggestedCategoryAndTitle(capture, buildTextForClassification(url, contextText), selectedCategory != null);
        return link;
    }

    private String detectOrigin(String url) {
        try {
            String host = new URI(url).getHost();
            if (host == null) {
                return "unknown";
            }
            String normalizedHost = host.toLowerCase(Locale.ROOT);

            if (normalizedHost.contains("instagram")) {
                return "instagram";
            }
            if (normalizedHost.contains("youtube") || normalizedHost.contains("youtu.be")) {
                return "youtube";
            }
            if (normalizedHost.contains("tiktok")) {
                return "tiktok";
            }
            if (normalizedHost.contains("x.com") || normalizedHost.contains("twitter")) {
                return "twitter";
            }
            if (normalizedHost.contains("pinterest")) {
                return "pinterest";
            }

            return normalizedHost;
        } catch (URISyntaxException exception) {
            return "unknown";
        }
    }

    private String buildTextForClassification(String url, String contextText) {
        if (contextText != null && !contextText.isBlank()) {
            return contextText.trim();
        }
        return "URL: " + url;
    }

    private void applySuggestedCategoryAndTitle(Capture capture, String textToClassify, boolean hasUserCategory) {
        List<Category> allCategories = categoryDao.findAllByOrderByNameAsc();
        if (allCategories.isEmpty() || textToClassify.isBlank()) {
            capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
            captureDao.save(capture);
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
                logger.warn("Categoría sugerida por modelo no encontrada para link: {}", predictedCategory);
            }
        } catch (Exception exception) {
            capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
            captureDao.save(capture);
            logger.warn("No se pudo clasificar automáticamente el link: {}", exception.getMessage());
        }
    }
}

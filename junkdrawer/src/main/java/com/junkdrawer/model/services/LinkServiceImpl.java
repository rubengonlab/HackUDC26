package com.junkdrawer.model.services;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.Locale;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.junkdrawer.model.common.DuplicateInstanceException;
import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.daos.CaptureDao;
import com.junkdrawer.model.daos.LinkDao;
import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.entities.Category;
import com.junkdrawer.model.entities.Link;

@Service
@Transactional
public class LinkServiceImpl implements LinkService {

    @Autowired
    private LinkDao linkDao;

    @Autowired
    private CaptureDao captureDao;

    @Autowired
    private PermissionChecker permissionChecker;

    @Override
    public Link createLinkResource(String url, Long categoryId, String contextText)
            throws DuplicateInstanceException, InstanceNotFoundException {

        Optional<Link> optionalLink = linkDao.findByUrl(url);
        if (optionalLink.isPresent()) {
            throw new DuplicateInstanceException("project.entities.link", url);
        }

        Category category = null;
        if (categoryId != null) {
            category = permissionChecker.checkCategoryExists(categoryId);
        }

        String origin = detectOrigin(url);

        Capture capture = new Capture();
        capture.setCaptureType(Capture.CaptureType.LINK);
        capture.setCategoryStatus(Capture.CategoryStatus.UNCATEGORIZED);
        capture.setCategory(category);
        capture.setContextText(contextText);
        capture.setOrigin(origin);
        capture = captureDao.save(capture);

        Link link = new Link();
        link.setCapture(capture);
        link.setUrl(url);
        link.setOrigin(origin);

        return linkDao.save(link);
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
}

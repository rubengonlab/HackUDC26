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
import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.entities.Category;

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
}

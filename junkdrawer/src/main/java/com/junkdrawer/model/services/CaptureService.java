package com.junkdrawer.model.services;

import java.time.LocalDate;
import java.util.List;

import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.entities.Capture;

public interface CaptureService {

    Capture createCapture(Capture.CaptureType captureType, Capture.CategoryStatus categoryStatus, Long categoryId) throws InstanceNotFoundException;

    Capture getCapture(Long id) throws InstanceNotFoundException;

    Capture updateCapture(Long id, Capture.CaptureType captureType, Capture.CategoryStatus categoryStatus, Long categoryId) throws InstanceNotFoundException;

    void deleteCapture(Long id) throws InstanceNotFoundException;

    Block<Capture> getCaptures(LocalDate dateFrom, LocalDate dateTo, Long categoryId, Capture.CaptureType captureType,
            int page, int size);

    List<Capture.CaptureType> getUsedCaptureTypes();

    Block<LocalDate> getCaptureDays(int page, int size);
}

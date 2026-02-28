package com.junkdrawer.model.services;

import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.entities.Capture;

public interface CaptureService {

    Capture createCapture(Capture.CaptureType captureType, Capture.CategoryStatus categoryStatus, Long categoryId) throws InstanceNotFoundException;

    Capture getCapture(Long id) throws InstanceNotFoundException;

    Capture updateCapture(Long id, Capture.CaptureType captureType, Capture.CategoryStatus categoryStatus, Long categoryId) throws InstanceNotFoundException;

    void deleteCapture(Long id) throws InstanceNotFoundException;
}

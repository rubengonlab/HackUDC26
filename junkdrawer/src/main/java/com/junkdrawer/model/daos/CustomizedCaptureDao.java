package com.junkdrawer.model.daos;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.domain.Slice;

import com.junkdrawer.model.entities.Capture;

public interface CustomizedCaptureDao {

    Slice<Capture> getCaptures(LocalDateTime createdFrom, LocalDateTime createdToExclusive, Long categoryId,
            Capture.CaptureType captureType, int page, int size);

    List<Capture.CaptureType> getUsedCaptureTypes();

    Slice<LocalDate> getCaptureDays(int page, int size);
}

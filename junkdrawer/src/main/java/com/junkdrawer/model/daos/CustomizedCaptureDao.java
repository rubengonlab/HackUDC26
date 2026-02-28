package com.junkdrawer.model.daos;

import java.time.LocalDateTime;

import org.springframework.data.domain.Slice;

import com.junkdrawer.model.entities.Capture;

public interface CustomizedCaptureDao {

    Slice<Capture> getCaptures(LocalDateTime createdFrom, LocalDateTime createdToExclusive, Long categoryId,
            Capture.CaptureType captureType, int page, int size);
}

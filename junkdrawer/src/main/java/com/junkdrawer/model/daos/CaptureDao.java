package com.junkdrawer.model.daos;

import org.springframework.data.jpa.repository.JpaRepository;

import com.junkdrawer.model.entities.Capture;

public interface CaptureDao extends JpaRepository<Capture, Long> {
}

package com.junkdrawer.model.daos;

import org.springframework.data.jpa.repository.JpaRepository;

import com.junkdrawer.model.entities.Image;

public interface ImageDao extends JpaRepository<Image, Long> {
}

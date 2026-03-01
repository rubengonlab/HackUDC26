package com.junkdrawer.model.daos;

import org.springframework.data.jpa.repository.JpaRepository;

import com.junkdrawer.model.entities.Audio;

public interface AudioDao extends JpaRepository<Audio, Long> {
}

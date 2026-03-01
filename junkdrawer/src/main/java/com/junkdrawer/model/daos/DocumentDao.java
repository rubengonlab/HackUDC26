package com.junkdrawer.model.daos;

import org.springframework.data.jpa.repository.JpaRepository;

import com.junkdrawer.model.entities.Document;

public interface DocumentDao extends JpaRepository<Document, Long> {
}

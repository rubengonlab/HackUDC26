package com.junkdrawer.model.daos;

import org.springframework.data.jpa.repository.JpaRepository;

import com.junkdrawer.model.entities.Note;

public interface NoteDao extends JpaRepository<Note, Long> {
}

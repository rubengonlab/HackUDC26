package com.junkdrawer.model.daos;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.junkdrawer.model.entities.Link;

public interface LinkDao extends JpaRepository<Link, Long> {

    Optional<Link> findByUrl(String url);
}

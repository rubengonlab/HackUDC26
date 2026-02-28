package com.junkdrawer.model.daos;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.junkdrawer.model.entities.Category;

public interface CategoryDao extends JpaRepository<Category, Long> {

    boolean existsByName(String name);

    Optional<Category> findByName(String name);

    java.util.List<Category> findAllByOrderByNameAsc();
}

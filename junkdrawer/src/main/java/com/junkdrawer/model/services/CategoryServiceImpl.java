/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.model.services;

import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.junkdrawer.model.common.DuplicateInstanceException;
import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.daos.CategoryDao;
import com.junkdrawer.model.entities.Category;

@Service
@Transactional
public class CategoryServiceImpl implements CategoryService {

    @Autowired
    private CategoryDao categoryDao;

    @Autowired
    private PermissionChecker permissionChecker;

    @Override
    public void createCategory(String name) {
        Optional<Category> optional = categoryDao.findByName(name);

        if (!optional.isPresent()) {
            Category category = new Category(name);
            categoryDao.save(category);
        }
    }

    @Override
    @Transactional(readOnly = true)
    public Category getCategory(Long id) throws InstanceNotFoundException {
        return permissionChecker.checkCategoryExists(id);
    }

    @Override
    public Category updateCategory(Long id, String name) throws InstanceNotFoundException, DuplicateInstanceException {
        Category category = permissionChecker.checkCategoryExists(id);

        Optional<Category> optional = categoryDao.findByName(name);

        if (optional.isPresent() && !optional.get().getId().equals(id)) {
            throw new DuplicateInstanceException("project.entities.category", name);
        }

        category.setName(name);
        return categoryDao.save(category);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Category> getCategories() {
        return categoryDao.findAllByOrderByNameAsc();
    }

    @Override
    public void deleteCategory(Long id) throws InstanceNotFoundException {
        Category category = permissionChecker.checkCategoryExists(id);
        categoryDao.delete(category);
    }
}

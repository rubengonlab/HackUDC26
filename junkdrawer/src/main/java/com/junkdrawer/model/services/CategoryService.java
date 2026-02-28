package com.junkdrawer.model.services;

import java.util.List;

import com.junkdrawer.model.common.DuplicateInstanceException;
import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.entities.Category;

public interface CategoryService {

    Category createCategory(String name) throws DuplicateInstanceException;

    Category getCategory(Long id) throws InstanceNotFoundException;

    Category updateCategory(Long id, String name) throws InstanceNotFoundException, DuplicateInstanceException;

    List<Category> getCategories();

    void deleteCategory(Long id) throws InstanceNotFoundException;

}

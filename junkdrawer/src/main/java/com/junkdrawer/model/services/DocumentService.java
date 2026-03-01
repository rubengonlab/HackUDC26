package com.junkdrawer.model.services;

import org.springframework.web.multipart.MultipartFile;

import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.entities.Document;

public interface DocumentService {

    Document create(MultipartFile file, String contextText, Long categoryId) throws InstanceNotFoundException;

    Document update(Long id, String contextText) throws InstanceNotFoundException;

    void delete(Long id) throws InstanceNotFoundException;

    Document getById(Long id) throws InstanceNotFoundException;

    Block<Document> getAll(int page, int size);
}

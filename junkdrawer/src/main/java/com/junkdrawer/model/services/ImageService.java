package com.junkdrawer.model.services;

import org.springframework.web.multipart.MultipartFile;

import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.entities.Image;

public interface ImageService {

    Image create(MultipartFile file, String contextText) throws InstanceNotFoundException;

    Image update(Long id, String contextText) throws InstanceNotFoundException;

    void delete(Long id) throws InstanceNotFoundException;

    Image getById(Long id) throws InstanceNotFoundException;

    Block<Image> getAll(int page, int size);
}

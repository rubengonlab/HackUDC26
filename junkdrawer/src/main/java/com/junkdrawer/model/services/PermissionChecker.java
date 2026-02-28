package com.junkdrawer.model.services;

import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.entities.Capture;
import com.junkdrawer.model.entities.Category;
import com.junkdrawer.model.entities.Note;

public interface PermissionChecker {

    Category checkCategoryExists(Long categoryId) throws InstanceNotFoundException;

    Capture checkCaptureExists(Long captureId) throws InstanceNotFoundException;

    Note checkNoteExists(Long noteId) throws InstanceNotFoundException;
}

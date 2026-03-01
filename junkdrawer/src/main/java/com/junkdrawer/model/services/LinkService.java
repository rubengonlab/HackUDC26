/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.model.services;

import com.junkdrawer.model.common.DuplicateInstanceException;
import com.junkdrawer.model.common.InstanceNotFoundException;
import com.junkdrawer.model.entities.Link;

public interface LinkService {

    Link createLinkResource(String url, String contextText, Long categoryId)
            throws DuplicateInstanceException, InstanceNotFoundException;
}

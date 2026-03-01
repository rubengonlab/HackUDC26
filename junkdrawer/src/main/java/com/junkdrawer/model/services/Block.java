/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.model.services;

import java.util.List;

public class Block<T> {

    private List<T> items;
    private boolean existMoreItems;

    public Block(List<T> items, boolean existMoreItems) {
        this.items = items;
        this.existMoreItems = existMoreItems;
    }

    public List<T> getItems() {
        return items;
    }

    public boolean getExistMoreItems() {
        return existMoreItems;
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + (existMoreItems ? 1231 : 1237);
        result = prime * result + ((items == null) ? 0 : items.hashCode());
        return result;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (obj == null) {
            return false;
        }
        if (getClass() != obj.getClass()) {
            return false;
        }
        Block<?> other = (Block<?>) obj;
        if (existMoreItems != other.existMoreItems) {
            return false;
        }
        if (items == null) {
            return other.items == null;
        } else {
            return items.equals(other.items);
        }
    }
}

package com.junkdrawer.model.common;

public class InstanceNotFoundException extends InstanceException {

    public InstanceNotFoundException(String name, Object key) {
        super(name, key);
    }
}

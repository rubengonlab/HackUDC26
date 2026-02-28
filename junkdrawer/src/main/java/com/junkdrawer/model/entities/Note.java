package com.junkdrawer.model.entities;

import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;

@Entity
public class Note {
    private Long id;
    private String text;
    private Capture capture;

    public Note() {}

    public Note(String text, Capture capture) {
        this.text = text;
        this.capture = capture;
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long getId() {
        return id;
    }
    public void setId(Long id) {
        this.id = id;
    }

    public String getText() {
        return text;
    }
    public void setText(String text) {
        this.text = text;
    }

    @ManyToOne(optional=false, fetch=FetchType.LAZY)
    @JoinColumn(name="captureId")
    public Capture getCapture() {
        return capture;
    }
    public void setCapture(Capture capture) {
        this.capture = capture;
    }

}

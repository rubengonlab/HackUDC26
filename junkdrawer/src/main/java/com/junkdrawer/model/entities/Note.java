package com.junkdrawer.model.entities;

import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Transient;

@Entity
public class Note {
    private Long id;
    private String title;
    private String content;
    private Capture capture;

    public Note() {}

    public Note(String title, String content, Capture capture) {
        this.title = title;
        this.content = content;
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

    public String getTitle() {
        return title;
    }
    public void setTitle(String title) {
        this.title = title;
    }

    public String getContent() {
        return content;
    }
    public void setContent(String content) {
        this.content = content;
    }

    // Temporary compatibility with current service layer.
    @Transient
    public String getText() {
        return content;
    }
    public void setText(String text) {
        this.content = text;
    }

    @OneToOne(optional=false, fetch=FetchType.LAZY)
    @JoinColumn(name="captureId", unique=true)
    public Capture getCapture() {
        return capture;
    }
    public void setCapture(Capture capture) {
        this.capture = capture;
    }

}

package com.junkdrawer.model.entities;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Lob;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Transient;

@Entity
public class Note {

    public enum TextStatus {
        PENDING,
        PROCESSED,
        FAILED
    }

    private Long id;
    private String content;
    private String reorderedText;
    private TextStatus textStatus = TextStatus.PENDING;
    private Capture capture;

    public Note() {}

    public Note(String content, Capture capture) {
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

    @Lob
    public String getContent() {
        return content;
    }
    public void setContent(String content) {
        this.content = content;
    }

    @Lob
    public String getReorderedText() {
        return reorderedText;
    }

    public void setReorderedText(String reorderedText) {
        this.reorderedText = reorderedText;
    }

    @Enumerated(EnumType.STRING)
    public TextStatus getTextStatus() {
        return textStatus;
    }

    public void setTextStatus(TextStatus textStatus) {
        this.textStatus = textStatus;
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

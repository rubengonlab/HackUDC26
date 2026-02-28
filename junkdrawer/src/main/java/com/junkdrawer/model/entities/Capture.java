package com.junkdrawer.model.entities;

import java.time.LocalDateTime;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.PrePersist;

@Entity
public class Capture {

    public enum CaptureType {
        NOTE,
        LINK,
        AUDIO,
        IMAGE,
        DOCUMENT
    }

    public enum CategoryStatus {
        UNCATEGORIZED,
        PENDING,
        APPROVED
    }

    private Long id;
    private LocalDateTime createdAt;
    private CaptureType captureType;
    private CategoryStatus categoryStatus = CategoryStatus.UNCATEGORIZED;
    private Category category;
    private String contextText;
    private String origin;
    private Note note;
    private Link link;
    private Audio audio;
    private Image image;
    private Document document;

    public Capture() {}

    
    public Capture(LocalDateTime createdAt, CaptureType captureType, CategoryStatus categoryStatus, Category category) {
        this.createdAt = createdAt;
        this.captureType = captureType;
        this.categoryStatus = categoryStatus;
        this.category = category;
    }

    @PrePersist
    public void prePersist() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now().withNano(0);
        }
        if (categoryStatus == null) {
            categoryStatus = CategoryStatus.UNCATEGORIZED;
        }
    }
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long getId() {
        return id;
    }
    public void setId(Long id) {
        this.id = id;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    @Enumerated(EnumType.STRING)
    public CaptureType getCaptureType() {
        return captureType;
    }
    public void setCaptureType(CaptureType captureType) {
        this.captureType = captureType;
    }

    @Enumerated(EnumType.STRING)
    public CategoryStatus getCategoryStatus() {
        return categoryStatus;
    }
    public void setCategoryStatus(CategoryStatus categoryStatus) {
        this.categoryStatus = categoryStatus;
    }

    @ManyToOne(fetch=FetchType.LAZY)
    @JoinColumn(name="categoryId")
    public Category getCategory() {
        return category;
    }

    public void setCategory(Category category) {
        this.category = category;
    }

    public String getContextText() {
        return contextText;
    }

    public void setContextText(String contextText) {
        this.contextText = contextText;
    }

    public String getOrigin() {
        return origin;
    }

    public void setOrigin(String origin) {
        this.origin = origin;
    }

    @OneToOne(mappedBy = "capture", fetch = FetchType.LAZY)
    public Note getNote() {
        return note;
    }

    public void setNote(Note note) {
        this.note = note;
    }

    @OneToOne(mappedBy = "capture", fetch = FetchType.LAZY)
    public Link getLink() {
        return link;
    }

    public void setLink(Link link) {
        this.link = link;
    }

    @OneToOne(mappedBy = "capture", fetch = FetchType.LAZY)
    public Audio getAudio() {
        return audio;
    }

    public void setAudio(Audio audio) {
        this.audio = audio;
    }

    @OneToOne(mappedBy = "capture", fetch = FetchType.LAZY)
    public Image getImage() {
        return image;
    }

    public void setImage(Image image) {
        this.image = image;
    }

    @OneToOne(mappedBy = "capture", fetch = FetchType.LAZY)
    public Document getDocument() {
        return document;
    }

    public void setDocument(Document document) {
        this.document = document;
    }

}

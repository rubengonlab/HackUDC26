package com.junkdrawer.model.entities;

import java.time.LocalDateTime;

import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;

@Entity
public class Capture {

    public enum CaptureType {
        NOTE
    }

    public enum CategoryStatus {
        ACCEPTED,
        WITHOUT_CATEGORY
    }

    private Long id;
    private LocalDateTime createdAt;
    private CaptureType captureType;
    private CategoryStatus categoryStatus;
    private Category category;

    public Capture() {}

    
    public Capture(LocalDateTime createdAt, CaptureType captureType, CategoryStatus categoryStatus, Category category) {
        this.createdAt = createdAt;
        this.captureType = captureType;
        this.categoryStatus = categoryStatus;
        this.category = category;
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

    public CaptureType getCaptureType() {
        return captureType;
    }
    public void setCaptureType(CaptureType captureType) {
        this.captureType = captureType;
    }

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

}

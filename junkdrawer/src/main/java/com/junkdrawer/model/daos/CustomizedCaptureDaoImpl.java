/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
package com.junkdrawer.model.daos;

import java.sql.Date;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Slice;
import org.springframework.data.domain.SliceImpl;

import com.junkdrawer.model.entities.Capture;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import jakarta.persistence.TypedQuery;

public class CustomizedCaptureDaoImpl implements CustomizedCaptureDao {

    @PersistenceContext
    private EntityManager entityManager;

    @Override
    public Slice<Capture> getCaptures(LocalDateTime createdFrom, LocalDateTime createdToExclusive, Long categoryId,
            Capture.CaptureType captureType, int page, int size) {

        StringBuilder queryString = new StringBuilder();
        queryString.append("SELECT c ")
                .append("FROM Capture c ")
                .append("LEFT JOIN FETCH c.category cat ")
                .append("LEFT JOIN FETCH c.note n ")
                .append("LEFT JOIN FETCH c.link l ")
                .append("LEFT JOIN FETCH c.audio a ")
                .append("LEFT JOIN FETCH c.image i ")
                .append("LEFT JOIN FETCH c.document d ")
                .append("WHERE 1 = 1 ");

        if (createdFrom != null) {
            queryString.append("AND c.createdAt >= :createdFrom ");
        }
        if (createdToExclusive != null) {
            queryString.append("AND c.createdAt < :createdToExclusive ");
        }
        if (categoryId != null) {
            queryString.append("AND cat.id = :categoryId ");
            queryString.append("AND c.categoryStatus IN (:approvedStatus, :uncategorizedStatus) ");
        }
        if (captureType != null) {
            queryString.append("AND c.captureType = :captureType ");
        }

        queryString.append("ORDER BY c.createdAt DESC, c.id DESC");

        TypedQuery<Capture> query = entityManager.createQuery(queryString.toString(), Capture.class)
                .setFirstResult(page * size)
                .setMaxResults(size + 1);

        if (createdFrom != null) {
            query.setParameter("createdFrom", createdFrom);
        }
        if (createdToExclusive != null) {
            query.setParameter("createdToExclusive", createdToExclusive);
        }
        if (categoryId != null) {
            query.setParameter("categoryId", categoryId);
            query.setParameter("approvedStatus", Capture.CategoryStatus.APPROVED);
            query.setParameter("uncategorizedStatus", Capture.CategoryStatus.UNCATEGORIZED);
        }
        if (captureType != null) {
            query.setParameter("captureType", captureType);
        }

        List<Capture> items = query.getResultList();
        boolean hasNext = items.size() == (size + 1);
        if (hasNext) {
            items.remove(items.size() - 1);
        }

        return new SliceImpl<>(items, PageRequest.of(page, size), hasNext);
    }

    @Override
    public Slice<Capture> getCapturesByCategoryStatus(Capture.CategoryStatus categoryStatus, int page, int size) {
        TypedQuery<Capture> query = entityManager.createQuery(
                "SELECT c FROM Capture c "
                        + "LEFT JOIN FETCH c.category cat "
                        + "LEFT JOIN FETCH c.note n "
                        + "LEFT JOIN FETCH c.link l "
                        + "LEFT JOIN FETCH c.audio a "
                        + "LEFT JOIN FETCH c.image i "
                        + "LEFT JOIN FETCH c.document d "
                        + "WHERE c.categoryStatus = :categoryStatus "
                        + "ORDER BY c.createdAt DESC, c.id DESC",
                Capture.class)
                .setParameter("categoryStatus", categoryStatus)
                .setFirstResult(page * size)
                .setMaxResults(size + 1);

        List<Capture> items = query.getResultList();
        boolean hasNext = items.size() == (size + 1);
        if (hasNext) {
            items.remove(items.size() - 1);
        }

        return new SliceImpl<>(items, PageRequest.of(page, size), hasNext);
    }

    @Override
    public List<Capture.CaptureType> getUsedCaptureTypes() {
        TypedQuery<Capture.CaptureType> query = entityManager.createQuery(
                "SELECT DISTINCT c.captureType FROM Capture c ORDER BY c.captureType",
                Capture.CaptureType.class);

        return query.getResultList();
    }

    @Override
    public Slice<LocalDate> getCaptureDays(int page, int size) {
        Query query = entityManager.createNativeQuery(
                "SELECT DISTINCT CAST(createdAt AS DATE) AS captureDay "
                        + "FROM Capture "
                        + "ORDER BY captureDay DESC");

        query.setFirstResult(page * size);
        query.setMaxResults(size + 1);

        @SuppressWarnings("unchecked")
        List<Object> rawItems = query.getResultList();
        boolean hasNext = rawItems.size() == (size + 1);
        if (hasNext) {
            rawItems.remove(rawItems.size() - 1);
        }

        List<LocalDate> items = rawItems.stream()
                .map(this::toLocalDate)
                .toList();

        return new SliceImpl<>(items, PageRequest.of(page, size), hasNext);
    }

    private LocalDate toLocalDate(Object value) {
        if (value instanceof LocalDate localDate) {
            return localDate;
        }
        if (value instanceof Date date) {
            return date.toLocalDate();
        }
        return LocalDate.parse(value.toString());
    }
}

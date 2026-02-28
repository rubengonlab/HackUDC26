package com.junkdrawer.model.daos;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Slice;
import org.springframework.data.domain.SliceImpl;

import com.junkdrawer.model.entities.Capture;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
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
}

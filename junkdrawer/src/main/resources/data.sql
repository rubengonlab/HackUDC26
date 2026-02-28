INSERT INTO category (id, name) VALUES (1, 'Personal');
INSERT INTO category (id, name) VALUES (2, 'Trabajo');
INSERT INTO category (id, name) VALUES (3, 'Ideas');

INSERT INTO capture (id, createdAt, captureType, categoryStatus, categoryId)
VALUES (1, '2026-02-01 10:00:00', 'NOTE', 'UNCATEGORIZED', 1);
INSERT INTO capture (id, createdAt, captureType, categoryStatus, categoryId)
VALUES (2, '2026-02-02 11:30:00', 'NOTE', 'APPROVED', 2);
INSERT INTO capture (id, createdAt, captureType, categoryStatus, categoryId)
VALUES (3, '2026-02-03 09:15:00', 'NOTE', 'PENDING', NULL);

INSERT INTO note (id, title, content, captureId) VALUES (1, 'Compra', 'Comprar leche y pan', 1);
INSERT INTO note (id, title, content, captureId) VALUES (2, 'Demo', 'Preparar demo para cliente', 2);
INSERT INTO note (id, title, content, captureId) VALUES (3, 'Idea', 'Idea para nueva funcionalidad', 3);

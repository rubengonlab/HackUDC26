-- SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
-- SPDX-License-Identifier: MIT

INSERT INTO category (id, name) VALUES (1, 'Personal');
INSERT INTO category (id, name) VALUES (2, 'Trabajo');
INSERT INTO category (id, name) VALUES (3, 'Ideas');

INSERT INTO capture (id, createdAt, captureType, categoryStatus, title, categoryId)
VALUES (1, '2026-02-01 10:00:00', 'NOTE', 'UNCATEGORIZED', 'Compra', 1);
INSERT INTO capture (id, createdAt, captureType, categoryStatus, title, categoryId)
VALUES (2, '2026-02-02 11:30:00', 'NOTE', 'APPROVED', 'Demo', 2);
INSERT INTO capture (id, createdAt, captureType, categoryStatus, title, categoryId)
VALUES (3, '2026-02-03 09:15:00', 'NOTE', 'PENDING', 'Idea', NULL);

INSERT INTO note (id, content, captureId) VALUES (1, 'Comprar leche y pan', 1);
INSERT INTO note (id, content, captureId) VALUES (2, 'Preparar demo para cliente', 2);
INSERT INTO note (id, content, captureId) VALUES (3, 'Idea para nueva funcionalidad', 3);

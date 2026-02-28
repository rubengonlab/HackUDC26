INSERT INTO Category (id, name) VALUES (1, 'Personal');
INSERT INTO Category (id, name) VALUES (2, 'Trabajo');
INSERT INTO Category (id, name) VALUES (3, 'Ideas');

INSERT INTO Capture (id, createdAt, captureType, categoryStatus, categoryId)
VALUES (1, '2026-02-01 10:00:00', 0, 0, 1);
INSERT INTO Capture (id, createdAt, captureType, categoryStatus, categoryId)
VALUES (2, '2026-02-02 11:30:00', 0, 0, 2);
INSERT INTO Capture (id, createdAt, captureType, categoryStatus, categoryId)
VALUES (3, '2026-02-03 09:15:00', 0, 1, NULL);

INSERT INTO Note (id, text, captureId) VALUES (1, 'Comprar leche y pan', 1);
INSERT INTO Note (id, text, captureId) VALUES (2, 'Preparar demo para cliente', 2);
INSERT INTO Note (id, text, captureId) VALUES (3, 'Idea para nueva funcionalidad', 3);

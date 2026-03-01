# JunkDrawer Backend

Documento de referencia del backend actual de `junkdrawer` (estado real del código en este momento).

## 1. Arquitectura

El backend está organizado por capas:

- `model/entities`: modelo de dominio JPA.
- `model/daos`: repositorios Spring Data (`JpaRepository`).
- `model/services`: lógica de negocio y reglas de creación/validación.
- `rest/controllers`: endpoints HTTP.
- `rest/dtos` + conversores: contratos de entrada/salida.
- `rest/common`: manejo global de errores.

Stack principal:

- Spring Boot + Spring Web MVC
- Spring Data JPA
- H2
- Spring Validation
- Springdoc OpenAPI (Swagger UI)

## 2. Configuración de API

Propiedades relevantes en `application.properties`:

- `server.servlet.context-path=/junkdrawer`
- `springdoc.swagger-ui.path=/docs`
- `app.upload.base-path=uploads`

URLs útiles:

- Base API: `/junkdrawer`
- Swagger UI: `/junkdrawer/docs`

## 3. Modelo de dominio

### 3.1 Category

Representa una categoría funcional para clasificar capturas.

Campos:

- `id`
- `name`

### 3.2 Capture

Entidad base y transversal: todo recurso (nota, enlace, audio, imagen, documento) cuelga de una `Capture`.

Campos:

- `id`
- `createdAt` (autogenerado en `@PrePersist`)
- `captureType` (`NOTE | LINK | AUDIO | IMAGE | DOCUMENT`)
- `categoryStatus` (`UNCATEGORIZED | PENDING | APPROVED`)
- `category` (nullable)
- `contextText` (nullable)
- `origin` (string libre, útil para links)

### 3.3 Note

Texto libre escrito/pegado.

Campos:

- `id`
- `title`
- `content`
- `capture` (OneToOne obligatorio y único)

### 3.4 Link

Recurso de enlace.

Campos:

- `id`
- `url` (única)
- `origin` (string; dominio/plataforma)
- `capture` (OneToOne obligatorio y único)

### 3.5 Audio / Image / Document

Recursos de archivo con metadatos.

Campos comunes:

- `id`
- `capture` (OneToOne obligatorio y único)
- `fileName` (nombre interno)
- `originalFileName`
- `mimeType`
- `size`
- `storagePath`

Restricción actual:

- `Document.originalFileName` es único.

## 4. Relaciones

- `Category 1 --- N Capture` (opcional desde capture).
- `Capture 1 --- 1 Note` (opcional)
- `Capture 1 --- 1 Link` (opcional)
- `Capture 1 --- 1 Audio` (opcional)
- `Capture 1 --- 1 Image` (opcional)
- `Capture 1 --- 1 Document` (opcional)

Idea de diseño: `Capture` almacena metadatos comunes; cada subtipo almacena datos específicos.

## 5. Capa de acceso a datos (DAOs)

Repositorios actuales:

- `CategoryDao`
- `CaptureDao`
- `NoteDao`
- `LinkDao` (`findByUrl`)
- `AudioDao`

## 6. Servicios y reglas de negocio

### 6.1 PermissionChecker

Servicio de comprobación de existencia (patrón `check...Exists`) que centraliza `InstanceNotFoundException`:

- `checkCategoryExists`
- `checkCaptureExists`
- `checkNoteExists`
- `checkAudioExists`

### 6.2 CategoryService

CRUD de categorías con reglas:

- No permite duplicar nombre (`DuplicateInstanceException`).
- Listado ordenado por nombre.

### 6.3 CaptureService

CRUD básico de `Capture`.

### 6.4 NoteService

Funciones heredadas + creación de recurso `NOTE` completo:

- `createNoteResource(...)`: crea `Capture` tipo `NOTE` y luego `Note`.
- `categoryStatus` llega como parámetro (si null, fallback a `UNCATEGORIZED`).

### 6.5 LinkService

Creación de recurso `LINK`:

- valida URL duplicada por `url` (lanza `DuplicateInstanceException`).
- crea `Capture` tipo `LINK`.
- detecta `origin` por host (instagram, youtube, tiktok, twitter/x, pinterest o dominio).

### 6.6 AudioService

Gestión de audio con fichero físico:

- `create(file, categoryId, categoryStatus, contextText)`
  - valida no vacío y `mimeType` `audio/*`
  - crea `Capture` tipo `AUDIO`
  - guarda archivo en `uploads/audio`
  - crea `Audio`
- `update(...)`: solo metadata (`category`, `categoryStatus`, `contextText`)
- `delete(id)`: elimina entidad y fichero físico
- `getAll(page,size)`: paginado con `Block<T>` usando `Slice`

## 7. Controladores REST

### 7.1 CategoryController (`/categories`)

- `POST /categories`
- `GET /categories/{id}`
- `GET /categories`

### 7.2 AudioController (`/audio`)

- `POST /audio` (`multipart/form-data`, `file` + params opcionales)
- `PUT /audio/{id}`
- `DELETE /audio/{id}`
- `GET /audio/{id}`
- `GET /audio` (paginado vía `BlockDto`)

### 7.3 TextController (`/text`)

- `POST /text` endpoint común:
  - Si `content` es URL estricta `http/https` y el campo completo es solo URL -> crea `LINK` (vía `LinkService`)
  - Si no -> crea `NOTE` (vía `NoteService`)

Esto permite que frontend use un único endpoint de texto y backend resuelva el tipo de recurso.

## 8. DTOs clave

- `CreateCategoryParamsDto`, `CategoryDto`
- `CreateTextResourceParamsDto`, `TextResourceDto`
- `AudioDto`
- `BlockDto<T>` (items + `existMoreItems`)

Conversores:

- `CategoryConversor`
- `TextResourceConversor`
- `AudioConversor`

## 9. Manejo de errores

`CommonControllerAdvice` gestiona:

- `InstanceNotFoundException` -> `404`
- `DuplicateInstanceException` -> `400`
- `MethodArgumentNotValidException` -> `400` con errores de campo
- `HandlerMethodValidationException` -> `400`
- `PermissionException` -> `403`
- `IllegalArgumentException` -> `400`

Formato de error:

- `ErrorsDto` (`globalError` o `fieldErrors`)
- `FieldErrorDto`

## 10. Esquema y datos

- `schema.sql`: define `Category`, `Capture`, `Note`, `Link`, `Audio`, `Image`, `Document` + índices.
- `data.sql`: datos semilla para arranque local.

## 11. Estado funcional actual

Implementado y operativo:

- Categorías
- Texto (nota/enlace por endpoint común)
- Audio

Estructura base ya preparada en modelo para:

- Image
- Document
- más endpoints/servicios de texto (update/get/delete/paginación) si se amplían en siguientes iteraciones.

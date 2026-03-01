# 📝 Changelog

Todos los cambios notables de este proyecto se documentan en este fichero.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y este proyecto sigue [Versionado Semántico](https://semver.org/lang/es/).

---

## [0.1.0] - 2026-03-01

### Añadido

- **Backend**: API REST con Spring Boot 4 y Java 17.
  - Entidades: Capture, Note, Link, Audio, Image, Document, Category.
  - CRUD completo de capturas y categorías.
  - Transcripción de audio con Whisper (faster-whisper-server).
  - Extracción de texto de imágenes con Azure Vision OCR.
  - Extracción de texto de documentos.
  - Clasificación automática con AWS Bedrock Nova.
  - Swagger UI en `/junkdrawer/docs`.
- **Mobile App**: Aplicación Flutter para Android.
  - Autenticación local.
  - Gestión de categorías con sincronización al backend.
  - Captura de notas, audios, imágenes y documentos.
  - Pantalla de elementos pendientes de categorización.
  - Compartir contenido desde otras apps.
- **Browser Extension**: Extensión Chrome (Manifest V3).
  - Captura de notas de texto desde el navegador.
  - Grabación de audio desde el navegador.
  - Menú contextual para captura rápida.
- **Infraestructura**: Docker Compose para backend + Whisper API.
- **Documentación**: README, BACKEND.md, guías de integración y configuración.
- **Licencia**: MIT License con cabecera en todos los ficheros de código.


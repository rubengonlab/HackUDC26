# 🗄️ Kelea — Junk Drawer (Cajón Digital Inteligente)

**Kelea** es un cajón digital inteligente que permite capturar cualquier tipo de información —notas, enlaces, audios, imágenes y documentos— y organizarla de forma estructurada mediante categorías, facilitando su consulta y relación posterior.

El proyecto está compuesto por tres módulos principales:

| Módulo | Tecnología | Descripción |
|--------|-----------|-------------|
| **Backend** | Spring Boot 4 + Java 17 | API REST con persistencia H2, transcripción de audio (Whisper), OCR (Azure Vision) y clasificación IA (AWS Bedrock Nova) |
| **Mobile App** | Flutter 3 + Dart | Aplicación móvil Android para capturar y gestionar notas, audios, imágenes y documentos |
| **Browser Extension** | Chrome Extension (Manifest V3) | Extensión de navegador para capturar notas y audios directamente desde Chrome |

---

## 📋 Requisitos previos

- **Docker** y **Docker Compose** (para ejecutar backend + Whisper)
- **Java 17** y **Maven 3.9+** (si ejecutas el backend sin Docker)
- **Flutter SDK ≥ 3.10.8** (para la app móvil)
- **Google Chrome** (para la extensión de navegador)

---

## 🚀 Ejecución rápida con Docker Compose

La forma más sencilla de levantar el backend y el servicio de transcripción Whisper:

```bash
# Desde la raíz del proyecto
cd HackUDC25

# Crea un fichero .env con las variables de entorno necesarias (ver sección Configuración)
cp .env.example .env  # o créalo manualmente

# Levanta los servicios
docker compose up -d --build
```

Esto arranca:

- **Backend** en `http://localhost:8080/junkdrawer`
  - Swagger UI: `http://localhost:8080/junkdrawer/docs`
- **Whisper API** (transcripción audio-a-texto) en la red interna Docker

---

## ⚙️ Ejecución manual (sin Docker)

### Backend

```bash
cd backend
mvn clean spring-boot:run
```

El backend arrancará en `http://localhost:8080/junkdrawer`.

### Mobile App (Flutter)

```bash
cd mobile-app

# Instalar dependencias
flutter pub get

# Configurar la IP del backend (ver sección Configuración)
# Editar lib/services/api_service.dart con la IP de tu máquina

# Ejecutar en dispositivo/emulador Android
flutter run
```

### Browser Extension

1. Abre **Google Chrome** y navega a `chrome://extensions/`.
2. Activa el **Modo desarrollador** (esquina superior derecha).
3. Haz clic en **Cargar descomprimida** y selecciona la carpeta `browser-extension/`.
4. La extensión aparecerá en la barra de herramientas de Chrome.

---

## 🔧 Configuración

### Variables de entorno del backend

Crea un fichero `.env` en la raíz del proyecto con las variables necesarias para los servicios externos (AWS Bedrock, Azure Vision, etc.). Consulta `backend/src/main/resources/application.properties` para ver todas las propiedades disponibles.

### Conexión móvil → backend

Edita `mobile-app/lib/services/api_service.dart` y actualiza la URL base con la IP de tu máquina:

```dart
// Reemplaza con tu IP local
static const String baseUrl = 'http://TU_IP:8080/junkdrawer';
```

Para obtener tu IP en Windows:
```bash
ipconfig
```

---

## 🏗️ Arquitectura

```
┌──────────────────────┐   ┌──────────────────────┐
│   Flutter App        │   │  Browser Extension   │
│   (Android)          │   │  (Chrome)            │
└─────────┬────────────┘   └─────────┬────────────┘
          │          HTTP             │
          └────────────┬──────────────┘
                       ↓
          ┌────────────────────────┐
          │  Spring Boot Backend   │
          │  /junkdrawer           │
          │  ┌──────────────────┐  │
          │  │ REST Controllers │  │
          │  │ Services         │  │
          │  │ JPA / H2         │  │
          │  └──────────────────┘  │
          └────────────┬───────────┘
                       │
          ┌────────────┼───────────────┐
          ↓            ↓               ↓
   ┌────────────┐ ┌──────────┐ ┌────────────────┐
   │ Whisper API│ │ Azure    │ │ AWS Bedrock    │
   │ (Audio→Txt)│ │ Vision   │ │ Nova (IA)      │
   └────────────┘ │ (OCR)    │ └────────────────┘
                  └──────────┘
```

### Modelo de datos

El backend gestiona los siguientes tipos de captura:

- **Note** — Texto libre escrito o pegado
- **Link** — Enlace web con origen
- **Audio** — Archivo de audio con transcripción automática
- **Image** — Imagen con extracción OCR
- **Document** — Documento con extracción de texto

Cada captura se clasifica con **categorías** y un estado (`UNCATEGORIZED`, `PENDING`, `APPROVED`).

---

## 📁 Estructura del proyecto

```
code/
├── junkdrawer/                 # API REST (Spring Boot + Java 17)
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/
├── notes_app/              # App móvil (Flutter)
│   ├── pubspec.yaml
│   └── lib/
├── extension/       # Extensión Chrome (Manifest V3)
│   ├── manifest.json
│   ├── popup.html/js
│   └── background.js
├── docs/                    # Documentación técnica
├── docker-compose.yml       # Orquestación de servicios
└── README.md
```

---

## 📖 Documentación adicional

- [`backend/BACKEND.md`](junkdrawer/BACKEND.md) — Referencia completa del backend (endpoints, modelo, servicios)
- [`docs/RESUMEN_EJECUTIVO.md`](docs/RESUMEN_EJECUTIVO.md) — Resumen ejecutivo de la integración frontend-backend
- [`docs/SETUP_CONEXION_API.md`](docs/SETUP_CONEXION_API.md) — Guía paso a paso de conexión con la API
- [`docs/IMPLEMENTACION_API_CATEGORIAS.md`](docs/IMPLEMENTACION_API_CATEGORIAS.md) — Detalles de la implementación de categorías

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Consulta la [guía de contribución](CONTRIBUTING.md) para conocer el flujo de trabajo, estilo de código y cómo enviar un Pull Request.

Este proyecto se adhiere a un [Código de Conducta](CODE_OF_CONDUCT.md).

---

## 📝 Changelog

Consulta el [CHANGELOG](CHANGELOG.md) para ver el historial de cambios.

---

## 📄 Licencia

Este proyecto está licenciado bajo la [Licencia MIT](LICENSE).

Copyright (c) 2026 Rubén González Laballós


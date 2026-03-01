# 🤝 Contribuir a Kelea

¡Gracias por tu interés en contribuir a **Kelea**! Todas las contribuciones son bienvenidas: código, documentación, reportes de errores, sugerencias, etc.

---

## 📋 Tabla de contenidos

- [Código de conducta](#código-de-conducta)
- [¿Cómo puedo contribuir?](#cómo-puedo-contribuir)
- [Configuración del entorno de desarrollo](#configuración-del-entorno-de-desarrollo)
- [Flujo de trabajo con Git](#flujo-de-trabajo-con-git)
- [Estilo de código](#estilo-de-código)
- [Reportar errores](#reportar-errores)
- [Proponer mejoras](#proponer-mejoras)

---

## Código de conducta

Este proyecto se adhiere a un [Código de Conducta](CODE_OF_CONDUCT.md). Al participar, se espera que respetes estas normas.

---

## ¿Cómo puedo contribuir?

### 🐛 Reportar errores

1. Asegúrate de que el error no ha sido reportado previamente buscando en los [Issues](../../issues).
2. Abre un nuevo issue describiendo:
   - Pasos para reproducir el error.
   - Comportamiento esperado vs. comportamiento obtenido.
   - Capturas de pantalla si es posible.
   - Tu entorno (SO, versión de Java/Flutter, navegador, etc.).

### 💡 Proponer mejoras

1. Abre un issue con la etiqueta `enhancement`.
2. Describe la mejora con el mayor detalle posible.
3. Si puedes, incluye mockups o ejemplos.

### 🔧 Enviar código

1. Haz fork del repositorio.
2. Crea una rama para tu contribución.
3. Realiza tus cambios siguiendo las guías de estilo.
4. Envía un Pull Request.

---

## Configuración del entorno de desarrollo

### Requisitos

- **Java 17** + **Maven 3.9+**
- **Flutter SDK ≥ 3.10.8**
- **Docker** y **Docker Compose**
- **Google Chrome** (para la extensión)

### Pasos

```bash
# 1. Clona tu fork
git clone https://github.com/rubengonlab/HackUDC.git
cd HackUDC

# 2. Backend
cd backend
mvn clean install
mvn spring-boot:run

# 3. Mobile App
cd ../mobile-app
flutter pub get
flutter run

# 4. Browser Extension
# Carga la carpeta browser-extension/ en chrome://extensions/
```

---

## Flujo de trabajo con Git

1. **Crea una rama** desde `main`:
   ```bash
   git checkout -b feature/mi-mejora
   ```

2. **Nomenclatura de ramas**:
   - `feature/descripcion` — Nueva funcionalidad
   - `fix/descripcion` — Corrección de error
   - `docs/descripcion` — Cambios en documentación
   - `refactor/descripcion` — Refactorización de código

3. **Commits**: usa mensajes descriptivos en español o inglés:
   ```
   feat: añadir endpoint de búsqueda de capturas
   fix: corregir timeout en transcripción de audio
   docs: actualizar instrucciones de instalación
   ```

4. **Pull Request**:
   - Describe qué cambia y por qué.
   - Referencia el issue relacionado si existe (ej: `Closes #12`).
   - Asegúrate de que los tests pasan.

---

## Estilo de código

### Java (Backend)

- Sigue las convenciones estándar de Java.
- Usa la estructura de capas existente: `entities`, `daos`, `services`, `controllers`, `dtos`.
- Incluye la cabecera de licencia MIT en cada fichero nuevo.

### Dart (Mobile App)

- Sigue las [guías de estilo de Dart](https://dart.dev/effective-dart/style).
- Ejecuta `flutter analyze` antes de enviar cambios.
- Incluye la cabecera de licencia MIT en cada fichero nuevo.

### JavaScript (Browser Extension)

- Usa ES6+.
- Incluye la cabecera de licencia MIT en cada fichero nuevo.

---

## 📄 Licencia

Al contribuir a este proyecto, aceptas que tus contribuciones serán licenciadas bajo la [Licencia MIT](LICENSE).




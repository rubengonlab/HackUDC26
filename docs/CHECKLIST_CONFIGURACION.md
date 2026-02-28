# ✅ Checklist de Configuración - Backend Frontend

## 🔧 Pre-requisitos del Sistema

- [ ] Servidor Spring Boot instalado y configurado
- [ ] Flutter SDK instalado y actualizado
- [ ] Git configurado
- [ ] IP del servidor conocida

## 🛠️ Configuración Inicial

### Backend (Spring Boot)

- [ ] Clonar/descargar el proyecto `junkdrawer`
- [ ] Navegar a la carpeta: `cd junkdrawer`
- [ ] Compilar el proyecto: `mvn clean install`
- [ ] Verificar que la carpeta `src/main/java/com/junkdrawer/` existe
- [ ] Verificar que existen los controllers:
  - [ ] `CategoryController.java`
  - [ ] `TextController.java`
  - [ ] `AudioController.java`
- [ ] Verificar puerto 8080 está disponible: `netstat -ano | findstr :8080`
- [ ] Iniciar servidor: `mvn spring-boot:run`
- [ ] Verificar en navegador: `http://localhost:8080/junkdrawer/categories`
  - Debe retornar un JSON vacío: `[]`

### Frontend (Flutter - Paso 1: Obtener IP del Servidor)

**En Windows PowerShell (donde corre el servidor):**
```powershell
ipconfig
```
**Buscar**: IPv4 Address en tu conexión activa (ej: `192.168.1.100`)

**En Terminal Terminal (MacOS/Linux)**:
```bash
ifconfig
```

**O usar hostname:**
```bash
hostname -I
```

### Frontend (Flutter - Paso 2: Actualizar URL)

**Archivo**: `notes_app/lib/services/api_service.dart`

- [ ] Abrir el archivo en tu editor
- [ ] Ir a la línea 6
- [ ] Cambiar: `static const String _baseUrl = 'http://192.168.1.100:8080/junkdrawer';`
- [ ] Reemplazar `192.168.1.100` por tu IP real
- [ ] Guardar archivo
- [ ] Ejemplo: `static const String _baseUrl = 'http://10.0.0.5:8080/junkdrawer';`

### Frontend (Flutter - Paso 3: Instalar Dependencias)

**En la carpeta del proyecto Flutter:**
```bash
cd notes_app
flutter pub get
```

- [ ] Ejecutar comando anterior
- [ ] Verificar que `http` se instala correctamente
- [ ] No debería haber errores

## 🧪 Pruebas de Conectividad

### Test 1: Alcanzar el Servidor desde tu Máquina con Flutter

**Desde PowerShell (máquina con Flutter):**
```powershell
ping 192.168.1.100  # Cambiar por tu IP
```
- [ ] Debería recibir respuestas (0% pérdida)

### Test 2: Ver si el Servidor está Respondiendo

```bash
curl http://192.168.1.100:8080/junkdrawer/categories
```
O en navegador: `http://192.168.1.100:8080/junkdrawer/categories`

- [ ] Debería mostrar `[]` (lista vacía de categorías)

### Test 3: Crear una Categoría desde Backend

```bash
curl -X POST http://192.168.1.100:8080/junkdrawer/categories \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Test\"}"
```

- [ ] Debería retornar 201 (Created) con datos de la categoría

## 📱 Pruebas en la App Flutter

### Test 4: Crear Categoría Personalizada

- [ ] Ejecutar app: `flutter run`
- [ ] Ir a pantalla "Mis Categorías"
- [ ] Presionar botón "+"
- [ ] Ingresar nombre (ej: "Test Categ")
- [ ] Presionar "Crear"
- [ ] ✅ Si funciona:
  - Categoría aparece en "Mis Categorías"
  - Se selecciona automáticamente
  - Diálogo se cierra
- [ ] ❌ Si falla:
  - Ver mensaje de error
  - Verificar URL en `api_service.dart`
  - Verificar que servidor está corriendo
  - Ver logs: `flutter logs`

### Test 5: Sincronizar Categorías

- [ ] En pantalla "Mis Categorías"
- [ ] Seleccionar varias categorías
- [ ] Presionar "Continuar"
- [ ] ✅ Si funciona:
  - Botón muestra "Cargando..."
  - Se navega a pantalla de notas
  - No hay mensaje de error
- [ ] ❌ Si falla:
  - Ver mensaje de error visible
  - Reintentar
  - Revisar backend

### Test 6: Categoría Duplicada

- [ ] Crear una categoría personalizada (ej: "Duplic")
- [ ] Crear otra con el mismo nombre
- [ ] ✅ Debería mostrar error de duplicada
- [ ] Hacer click en "Continuar"
- [ ] ✅ La categoría duplicada se ignora automáticamente

## 🐛 Debugging si hay Problemas

### Problema: "Connection refused" o timeout

**Causas posibles:**
1. Servidor no está corriendo
2. IP es incorrecta
3. Puerto 8080 está bloqueado

**Soluciones:**
- [ ] Verificar que `mvn spring-boot:run` está activo
- [ ] Verificar IP correcta con `ipconfig`
- [ ] Verificar puerto: `netstat -ano | findstr :8080`
- [ ] Permitir en firewall si es necesario

### Problema: App se congela o es muy lenta

**Causas posibles:**
1. Timeout demasiado corto
2. Servidor muy lento
3. Mucha latencia de red

**Soluciones:**
- [ ] Aumentar timeout en `api_service.dart` línea 19:
  ```dart
  .timeout(const Duration(seconds: 60),
  ```
- [ ] Revisar velocidad del servidor
- [ ] Revisar latencia de red

### Problema: Error 400 Bad Request

**Causas posibles:**
1. Nombre vacío
2. Nombre muy largo
3. Backend rechaza datos

**Soluciones:**
- [ ] Verificar que maxLength es 15 en `categories_screen.dart`
- [ ] Ver mensaje exacto de error en la app
- [ ] Ver logs del servidor: `mvn spring-boot:run`

### Ver Logs Detallados

**Flutter:**
```bash
flutter logs
```

**Backend (en otra terminal):**
```bash
mvn spring-boot:run
```

- [ ] Buscar errores HTTP
- [ ] Buscar excepciones Java
- [ ] Buscar mensajes de conexión

## ✅ Verificación Final

- [ ] Servidor corriendo en `http://IP:8080/junkdrawer`
- [ ] URL actualizada en `api_service.dart`
- [ ] `flutter pub get` ejecutado sin errores
- [ ] `flutter analyze` sin issues
- [ ] Conexión alcanza servidor (ping OK)
- [ ] Servidor responde (curl OK)
- [ ] App crea categorías sin error
- [ ] App sincroniza categorías sin error
- [ ] Navega a pantalla de notas al presionar Continuar

## 🎉 Cuándo Todo Esté Funcionando

Si pasaste todos los tests, ¡la integración está completa! 🎊

Puedes:
- [ ] Crear categorías personalizadas
- [ ] Ver que se registran en el backend
- [ ] Sincronizar múltiples categorías
- [ ] Manejar errores de conexión gracefully
- [ ] Continuar a la siguiente pantalla

## 📞 Si Aún Hay Problemas

1. Verificar todos los pasos de este checklist
2. Ver archivo: `SETUP_CONEXION_API.md`
3. Ver archivo: `IMPLEMENTACION_API_CATEGORIAS.md`
4. Revisar logs de Flutter: `flutter logs`
5. Revisar logs del servidor Spring Boot
6. Asegurar que ambas máquinas están en la misma red

---

**Documento**: `CHECKLIST_CONFIGURACION.md`
**Última actualización**: 2026-02-28
**Estado**: Completado ✅


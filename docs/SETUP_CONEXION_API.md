# 🚀 Guía de Configuración - Conexión Backend Frontend

## ⚙️ Pasos de Configuración

### 1. Obtener la IP del Servidor Backend

#### En Windows (donde corre Spring Boot):
```powershell
ipconfig
```
Busca la línea `IPv4 Address` en la sección de tu conexión de red. Ejemplo: `192.168.1.100`

#### En Linux/Mac:
```bash
ifconfig
```
o
```bash
hostname -I
```

### 2. Actualizar la URL en el Código

**Archivo**: `notes_app/lib/services/api_service.dart`

Cambiar la línea 6:
```dart
// Antes:
static const String _baseUrl = 'http://192.168.1.100:8080/junkdrawer';

// Después (con tu IP):
static const String _baseUrl = 'http://TU_IP_AQUI:8080/junkdrawer';
```

### 3. Asegurar que el Backend está Ejecutándose

```bash
cd junkdrawer
mvn spring-boot:run
```

El servidor debe estar disponible en: `http://TU_IP:8080/junkdrawer`

Verificar en el navegador: `http://TU_IP:8080/junkdrawer/categories`

### 4. Ejecutar la Aplicación Flutter

```bash
cd notes_app
flutter pub get  # Si ya no lo has hecho
flutter run
```

## 📱 Prueba de Funcionalidad

### Crear una Categoría Personalizada:
1. En la pantalla "Mis Categorías", presiona el botón "+"
2. Ingresa un nombre (máximo 15 caracteres)
3. Presiona "Crear"
4. Verifica que:
   - La categoría aparece en "Mis Categorías"
   - Se selecciona automáticamente
   - El mensaje de error (si lo hay) es claro

### Sincronizar Categorías:
1. Selecciona una o más categorías
2. Presiona "Continuar"
3. Verifica que:
   - El botón muestra "Cargando..."
   - Las categorías personalizadas se envían al backend
   - Se navega a la pantalla de notas si todo es exitoso
   - Se muestra un mensaje de error si falla

## 🔍 Debugging

### Ver Logs en Flutter:
```bash
flutter logs
```

### Monitorear Peticiones HTTP:
En `api_service.dart`, puedes agregar prints:
```dart
print('Enviando: $categoryName');
print('Response: ${response.statusCode} - ${response.body}');
```

### Verificar Conectividad:
```bash
# Desde tu PC, verifica que puedas alcanzar el servidor:
ping TU_IP
curl http://TU_IP:8080/junkdrawer/categories
```

## ⚠️ Problemas Comunes

### Error: "Connection refused"
- **Solución**: El servidor no está corriendo o la IP es incorrecta
- Verifica que `mvn spring-boot:run` esté ejecutándose
- Verifica la IP correcta en `api_service.dart`

### Error: "Connection timeout"
- **Solución**: El servidor está lento o muy lejos
- Aumenta el timeout en `api_service.dart` (línea 19):
  ```dart
  .timeout(const Duration(seconds: 60), // Aumentar a 60
  ```

### Categoría duplicada
- **Comportamiento**: Se ignora automáticamente durante la sincronización
- **Nota**: Si creas una categoría con el mismo nombre dos veces, la segunda será duplicada en el backend

### La app no navega después de presionar "Continuar"
- **Verificar**: 
  - ¿Hay mensaje de error visible?
  - ¿El servidor está respondiendo?
  - ¿Las categorías se están creando en el backend?

## 📊 Flujo de Datos

```
Usuario selecciona categorías
         ↓
Presiona "Continuar"
         ↓
CategoriesProvider.syncSelectedCategoriesToBackend()
         ↓
Para cada categoría personalizada:
  ApiService.createCategory(nombre)
         ↓
  POST /categories con JSON: {"name": "..."}
         ↓
Backend crea y retorna categoría (201)
         ↓
Si todas son exitosas: navega a /notes
Si alguna falla: muestra error y permite reintentar
```

## 🛠️ Arquitectura de Servicios

### ApiService (lib/services/api_service.dart)
- Maneja todas las peticiones HTTP
- Gestiona excepciones
- Convierte respuestas JSON

### CategoriesProvider (lib/providers/categories_provider.dart)
- Gestiona estado local de categorías
- Coordina con ApiService
- Notifica cambios a la UI

### CategoriesScreen (lib/screens/categories/categories_screen.dart)
- Muestra categorías
- Permite seleccionar categorías
- Permite crear categorías personalizadas
- Sincroniza con backend antes de continuar

## 📝 Endpoints del Backend

### POST /junkdrawer/categories
**Crear categoría**
```json
Request:
{
  "name": "Mi Categoría"
}

Response (201):
{
  "id": 1,
  "name": "Mi Categoría"
}

Response (400):
{
  "message": "Categoría duplicada"
}
```

### GET /junkdrawer/categories
**Listar categorías**
```json
Response (200):
[
  {"id": 1, "name": "Categoría 1"},
  {"id": 2, "name": "Categoría 2"}
]
```

### GET /junkdrawer/categories/{id}
**Obtener categoría por ID**
```json
Response (200):
{
  "id": 1,
  "name": "Categoría 1"
}

Response (404):
{
  "message": "Categoría no encontrada"
}
```


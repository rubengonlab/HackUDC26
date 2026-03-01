# Implementación de Conexión Frontend-Backend - Categorías

## Resumen de Cambios

Se ha implementado la integración completa entre el frontend (Flutter) y el backend (Spring Boot) para la gestión de categorías.

## Cambios Realizados

### 1. **Instalación de Dependencias**
- ✅ Agregado package `http: ^1.1.0` al `pubspec.yaml` para hacer peticiones HTTP
- ✅ Ejecutado `flutter pub get` para descargar las dependencias

### 2. **Creación del Servicio de API** (`lib/services/api_service.dart`)
Se creó un servicio centralizado que maneja la comunicación con el backend:

#### Endpoints Implementados:
- **POST `/categories`** - Crear una nueva categoría
- **GET `/categories`** - Obtener lista de todas las categorías
- **GET `/categories/{id}`** - Obtener una categoría específica por ID

#### Excepciones Personalizadas:
- `TimeoutException` - Conexión tardó demasiado
- `NetworkException` - Error de conexión a internet
- `BadRequestException` - Error de validación o categoría duplicada (400)
- `ServerException` - Error en el servidor (5xx)
- `NotFoundException` - Categoría no encontrada (404)

#### Características:
- Timeout de 30 segundos por defecto
- Manejo robusto de errores HTTP
- Mensajes de error descriptivos para el usuario

### 3. **Actualización del CategoriesProvider** (`lib/providers/categories_provider.dart`)

#### Nuevas Propiedades:
- `_isLoading` - Indica si se está creando una categoría
- `_isSyncingCategories` - Indica si se están sincronizando categorías con el backend

#### Métodos Modificados:
- **`addCustomCategory()`** - Ahora:
  - Envía la categoría al backend antes de agregarla localmente
  - Maneja excepciones y muestra errores al usuario
  - Muestra estado "Creando..." mientras se procesa

#### Nuevos Métodos:
- **`syncSelectedCategoriesToBackend()`** - Sincroniza todas las categorías seleccionadas:
  - Envía cada categoría personalizada seleccionada al servidor (una por una)
  - Ignora categorías duplicadas automáticamente
  - Maneja excepciones de red, timeout y servidor
  - Retorna `true` si es exitoso, `false` si hay errores

### 4. **Actualización de la Pantalla de Categorías** (`lib/screens/categories/categories_screen.dart`)

#### Cambios en el Diálogo de Crear Categoría:
- Agregado estado "Creando..." en el botón
- El botón se deshabilita mientras se procesa la solicitud
- Mostrado mensaje de error de manera clara

#### Cambios en el Botón Continuar:
- Ahora llama a `syncSelectedCategoriesToBackend()` antes de navegar
- Muestra estado "Cargando..." mientras se sincroniza
- Solo navega si la sincronización es exitosa
- Muestra errores en la pantalla para que el usuario sepa qué salió mal

#### Nuevo Mensaje de Error:
- Agregado contenedor para mostrar errores de sincronización
- Visible debajo de las categorías personalizadas
- Con estilos consistentes con el design de Kelea

## Flujo de Uso

### Crear Categoría Personalizada:
1. Usuario hace clic en el botón "+"
2. Ingresa nombre (máximo 15 caracteres)
3. Presiona "Crear"
4. La app envía la categoría al backend
5. Si es exitoso, se agrega a la lista local y se selecciona automáticamente
6. Si falla, muestra el error específico

### Continuar a Notas:
1. Usuario selecciona una o más categorías
2. Presiona "Continuar"
3. La app sincroniza todas las categorías seleccionadas con el backend
4. Solo envía categorías personalizadas (no las predeterminadas)
5. Ignora automáticamente categorías duplicadas
6. Si es exitoso, navega a la pantalla de notas
7. Si falla, muestra el error y permite reintentar

## Manejo de Errores

### Errores Posibles:
1. **Timeout** - "La conexión tardó demasiado. Verifica tu conexión a internet."
2. **Sin conexión** - "Error de conexión: [descripción]"
3. **Categoría duplicada** - Se ignora automáticamente durante la sincronización
4. **Error del servidor** - "Error al crear la categoría. Código: [código HTTP]"
5. **Validación fallida** - Mostrado el mensaje del servidor

## Configuración del Servidor

### URL Base del Servidor:
En `lib/services/api_service.dart`, línea 4:
```dart
static const String _baseUrl = 'http://192.168.1.100:8080/junkdrawer';
```

**IMPORTANTE**: Cambiar `192.168.1.100` por la IP real de tu servidor si es diferente.

## Próximos Pasos Recomendados

1. Verificar que el servidor esté corriendo en el puerto 8080
2. Cambiar la URL del servidor a la IP correcta
3. Testear la creación de categorías
4. Testear la sincronización de múltiples categorías
5. Validar el manejo de errores de conexión

## Arquitectura

```
┌─────────────────────────────────────┐
│     Flutter App (Frontend)          │
├─────────────────────────────────────┤
│                                     │
│  CategoriesScreen                   │
│       ↓                             │
│  CategoriesProvider                 │
│       ↓                             │
│  ApiService                         │
│       ↓                             │
│  HTTP Client                        │
└─────────────────────────────────────┘
           ↓ (HTTP)
┌─────────────────────────────────────┐
│    Spring Boot (Backend)            │
├─────────────────────────────────────┤
│                                     │
│  CategoryController                 │
│       ↓                             │
│  CategoryService                    │
│       ↓                             │
│  Database                           │
└─────────────────────────────────────┘
```


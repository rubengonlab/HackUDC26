import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // Configurar aquí la URL base del servidor
  static const String _baseUrl = 'http://10.20.29.99:8080/junkdrawer';

  // ---------------------------------------------------------------------------
  // Helper: decodifica el body solo si no está vacío. Devuelve null si vacío.
  // Lanza ServerException si el body no es JSON válido.
  // ---------------------------------------------------------------------------
  static dynamic _safeDecodeBody(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      throw ServerException(
        'Respuesta inesperada del servidor (código ${response.statusCode}). '
        'Contacta con soporte si el problema persiste.',
      );
    }
  }

  // Crear una categoría
  static Future<Map<String, dynamic>?> createCategory(String categoryName) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': categoryName}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
          'La conexión tardó demasiado. Verifica tu conexión a internet.',
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // El servidor puede devolver el objeto creado o cuerpo vacío — ambos son válidos
        final decoded = _safeDecodeBody(response);
        return decoded as Map<String, dynamic>?;
      } else if (response.statusCode == 400) {
        final decoded = _safeDecodeBody(response);
        final message = (decoded is Map ? decoded['message'] : null)
            ?? 'Datos inválidos. Revisa el nombre de la categoría.';
        throw BadRequestException(message as String);
      } else if (response.statusCode == 409) {
        // Conflict: categoría duplicada
        throw BadRequestException('La categoría ya existe en el servidor.');
      } else {
        throw ServerException(
          'Error del servidor al crear la categoría (código ${response.statusCode}).',
        );
      }
    } on TimeoutException {
      rethrow;
    } on BadRequestException {
      rethrow;
    } on ServerException {
      rethrow;
    } on http.ClientException catch (e) {
      throw NetworkException(
        'No se pudo conectar al servidor. Verifica tu red. (${e.message})',
      );
    } catch (e) {
      throw NetworkException('Error inesperado de red: ${e.toString()}');
    }
  }

  // Obtener todas las categorías
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
          'La conexión tardó demasiado. Verifica tu conexión a internet.',
        ),
      );

      if (response.statusCode == 200) {
        final decoded = _safeDecodeBody(response);
        if (decoded == null) return [];
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
        throw ServerException('Formato de respuesta inesperado del servidor.');
      } else {
        throw ServerException(
          'Error al obtener categorías (código ${response.statusCode}).',
        );
      }
    } on TimeoutException {
      rethrow;
    } on ServerException {
      rethrow;
    } on http.ClientException catch (e) {
      throw NetworkException(
        'No se pudo conectar al servidor. Verifica tu red. (${e.message})',
      );
    } catch (e) {
      throw NetworkException('Error inesperado de red: ${e.toString()}');
    }
  }

  // Obtener una categoría por ID
  static Future<Map<String, dynamic>> getCategoryById(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/categories/$categoryId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
          'La conexión tardó demasiado. Verifica tu conexión a internet.',
        ),
      );

      if (response.statusCode == 200) {
        final decoded = _safeDecodeBody(response);
        if (decoded is Map<String, dynamic>) return decoded;
        throw ServerException('Formato de respuesta inesperado del servidor.');
      } else if (response.statusCode == 404) {
        throw NotFoundException('Categoría no encontrada.');
      } else {
        throw ServerException(
          'Error al obtener la categoría (código ${response.statusCode}).',
        );
      }
    } on TimeoutException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } on ServerException {
      rethrow;
    } on http.ClientException catch (e) {
      throw NetworkException(
        'No se pudo conectar al servidor. Verifica tu red. (${e.message})',
      );
    } catch (e) {
      throw NetworkException('Error inesperado de red: ${e.toString()}');
    }
  }
}

// Excepciones personalizadas
class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => message;
}

class BadRequestException implements Exception {
  final String message;
  const BadRequestException(this.message);

  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  const ServerException(this.message);

  @override
  String toString() => message;
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException(this.message);

  @override
  String toString() => message;
}

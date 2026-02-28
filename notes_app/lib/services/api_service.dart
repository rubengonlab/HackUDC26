import 'package:http/http.dart' as http;
import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:io';

class ApiService {
  static const String _baseUrl = 'http://10.20.29.99:8080/junkdrawer';
  static const _kTimeout = Duration(seconds: 30);
  static const _kTimeoutAudio = Duration(seconds: 60);

  static dynamic _safeDecodeBody(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      throw ServerException(
          'Respuesta inesperada del servidor (código ${response.statusCode}).');
    }
  }

  // ── POST /categories ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> createCategory(String categoryName) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/categories'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'name': categoryName}),
          )
          .timeout(_kTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _safeDecodeBody(response) as Map<String, dynamic>?;
      } else if (response.statusCode == 400) {
        final d = _safeDecodeBody(response);
        final msg = (d is Map ? d['message'] : null)
            ?? 'Datos inválidos. Revisa el nombre de la categoría.';
        throw BadRequestException(msg as String);
      } else if (response.statusCode == 409) {
        throw BadRequestException('La categoría ya existe en el servidor.');
      } else {
        throw ServerException('Error del servidor (código ${response.statusCode}).');
      }
    } on TimeoutException {
      throw NetworkException('La conexión tardó demasiado. Verifica tu internet.');
    } on http.ClientException catch (e) {
      throw NetworkException('Sin conexión al servidor. (${e.message})');
    } on BadRequestException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Error inesperado: ${e.toString()}');
    }
  }

  // ── POST /text ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createTextNote({
    required String content,
    String? title,
    int? categoryId,
    String? contextText,
  }) async {
    try {
      final body = <String, dynamic>{'content': content};
      if (title != null && title.isNotEmpty) body['title'] = title;
      if (categoryId != null) body['categoryId'] = categoryId;
      if (contextText != null && contextText.isNotEmpty) body['contextText'] = contextText;

      final response = await http
          .post(
            Uri.parse('$_baseUrl/text'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_kTimeout);

      if (response.statusCode == 201) {
        return _safeDecodeBody(response) as Map<String, dynamic>? ?? {};
      } else if (response.statusCode == 400) {
        final d = _safeDecodeBody(response);
        final msg = (d is Map ? d['message'] : null)
            ?? 'El contenido no puede estar vacío.';
        throw BadRequestException(msg as String);
      } else if (response.statusCode == 404) {
        throw NotFoundException('La categoría seleccionada no existe.');
      } else if (response.statusCode == 409) {
        throw DuplicateException('Ya existe una nota con ese contenido.');
      } else {
        throw ServerException('Error del servidor (código ${response.statusCode}).');
      }
    } on TimeoutException {
      throw NetworkException('La conexión tardó demasiado. Verifica tu internet.');
    } on http.ClientException catch (e) {
      throw NetworkException('Sin conexión al servidor. (${e.message})');
    } on BadRequestException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } on DuplicateException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Error inesperado: ${e.toString()}');
    }
  }

  // ── POST /audio ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createAudio({
    required File audioFile,
    int? categoryId,
    String? contextText,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/audio'));
      request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));
      if (categoryId != null) request.fields['categoryId'] = categoryId.toString();
      if (contextText != null && contextText.isNotEmpty) {
        request.fields['contextText'] = contextText;
      }

      final streamed = await request.send().timeout(_kTimeoutAudio);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201) {
        return _safeDecodeBody(response) as Map<String, dynamic>? ?? {};
      } else if (response.statusCode == 400) {
        final d = _safeDecodeBody(response);
        final msg = (d is Map ? d['message'] : null) ?? 'Archivo de audio no válido.';
        throw BadRequestException(msg as String);
      } else if (response.statusCode == 404) {
        throw NotFoundException('La categoría seleccionada no existe.');
      } else {
        throw ServerException('Error del servidor (código ${response.statusCode}).');
      }
    } on TimeoutException {
      throw NetworkException('La subida tardó demasiado. Verifica tu internet.');
    } on http.ClientException catch (e) {
      throw NetworkException('Sin conexión al servidor. (${e.message})');
    } on BadRequestException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Error inesperado: ${e.toString()}');
    }
  }

  // ── GET /categories ─────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/categories'),
              headers: {'Content-Type': 'application/json'})
          .timeout(_kTimeout);

      if (response.statusCode == 200) {
        final decoded = _safeDecodeBody(response);
        if (decoded == null) return [];
        if (decoded is List) return decoded.cast<Map<String, dynamic>>();
        throw ServerException('Formato de respuesta inesperado.');
      } else {
        throw ServerException(
            'Error al obtener categorías (código ${response.statusCode}).');
      }
    } on TimeoutException {
      throw NetworkException('La conexión tardó demasiado.');
    } on http.ClientException catch (e) {
      throw NetworkException('Sin conexión al servidor. (${e.message})');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Error inesperado: ${e.toString()}');
    }
  }

  // ── GET /audio ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getAudios({int page = 0, int size = 100}) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/audio?page=$page&size=$size'),
              headers: {'Content-Type': 'application/json'})
          .timeout(_kTimeout);

      if (response.statusCode == 200) {
        final decoded = _safeDecodeBody(response);
        if (decoded is Map<String, dynamic>) return decoded;
        throw ServerException('Formato de respuesta inesperado.');
      } else {
        throw ServerException(
            'Error al obtener audios (código ${response.statusCode}).');
      }
    } on TimeoutException {
      throw NetworkException('La conexión tardó demasiado.');
    } on http.ClientException catch (e) {
      throw NetworkException('Sin conexión al servidor. (${e.message})');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Error inesperado: ${e.toString()}');
    }
  }

  // ── GET /categories/:id ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getCategoryById(int categoryId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/categories/$categoryId'),
              headers: {'Content-Type': 'application/json'})
          .timeout(_kTimeout);

      if (response.statusCode == 200) {
        final decoded = _safeDecodeBody(response);
        if (decoded is Map<String, dynamic>) return decoded;
        throw ServerException('Formato de respuesta inesperado.');
      } else if (response.statusCode == 404) {
        throw NotFoundException('Categoría no encontrada.');
      } else {
        throw ServerException(
            'Error al obtener la categoría (código ${response.statusCode}).');
      }
    } on TimeoutException {
      throw NetworkException('La conexión tardó demasiado.');
    } on http.ClientException catch (e) {
      throw NetworkException('Sin conexión al servidor. (${e.message})');
    } on NotFoundException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Error inesperado: ${e.toString()}');
    }
  }
}

// ── Excepciones personalizadas ────────────────────────────────────────────────
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

class DuplicateException implements Exception {
  final String message;
  const DuplicateException(this.message);
  @override
  String toString() => message;
}

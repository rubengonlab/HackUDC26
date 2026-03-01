import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  /// Extrae el mensaje de error del body del backend.
  /// El backend usa ErrorsDto con campo "globalError" (o "message" como fallback).
  /// También soporta el formato de error genérico de Spring Boot (campo "error").
  static String? _errorMsg(dynamic decoded, [String? fallback]) {
    if (decoded is Map) {
      final msg = decoded['globalError'] ?? decoded['message'] ?? decoded['error'];
      return msg as String? ?? fallback;
    }
    return fallback;
  }
  // POST /categories
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
        throw BadRequestException(_errorMsg(d, 'Datos inválidos.')!);
      } else if (response.statusCode == 409) {
        throw BadRequestException('La categoría ya existe en el servidor.');
      } else {
        throw ServerException('Error del servidor (código ${response.statusCode}).');
      }
    } on TimeoutException {
      throw NetworkException('La conexión tardó demasiado. Verifica tu internet.');
    } on http.ClientException catch (e) {
      throw NetworkException('Sin conexión al servidor. (${e.message})');
    } on BadRequestException { rethrow; } on ServerException { rethrow; } catch (e) {
      throw NetworkException('Error inesperado: ${e.toString()}');
    }
  }
  // POST /text
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
          .post(Uri.parse('$_baseUrl/text'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(_kTimeout);
      if (response.statusCode == 201) {
        return _safeDecodeBody(response) as Map<String, dynamic>? ?? {};
      } else if (response.statusCode == 400) {
        final d = _safeDecodeBody(response);
        throw BadRequestException((d is Map ? (d['globalError'] ?? d['message']) : null) ?? 'El contenido no puede estar vacío.');
      } else if (response.statusCode == 404) {
        final d = _safeDecodeBody(response);
        throw NotFoundException((d is Map ? (d['globalError'] ?? d['message']) : null) ?? 'La categoría seleccionada no existe.');
      } else if (response.statusCode == 409) {
        throw DuplicateException('Ya existe una nota con ese contenido.');
      } else {
        throw ServerException('Error del servidor (código ${response.statusCode}).');
      }
    } on TimeoutException { throw NetworkException('La conexión tardó demasiado. Verifica tu internet.');
    } on http.ClientException catch (e) { throw NetworkException('Sin conexión. (${e.message})');
    } on BadRequestException { rethrow; } on NotFoundException { rethrow; } on DuplicateException { rethrow;
    } on ServerException { rethrow; } catch (e) { throw NetworkException('Error inesperado: ${e.toString()}'); }
  }
  // POST /audio
  static Future<Map<String, dynamic>> createAudio({
    required File audioFile,
    int? categoryId,
    String? contextText,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/audio'));
      final audioMime = _mimeTypeFromPath(audioFile.path, defaultMime: 'audio/m4a');
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
        contentType: MediaType.parse(audioMime),
      ));
      if (categoryId != null) request.fields['categoryId'] = categoryId.toString();
      if (contextText != null && contextText.isNotEmpty) request.fields['contextText'] = contextText;
      final streamed = await request.send().timeout(_kTimeoutAudio);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 201) {
        return _safeDecodeBody(response) as Map<String, dynamic>? ?? {};
      } else if (response.statusCode == 400) {
        final d = _safeDecodeBody(response);
        throw BadRequestException((d is Map ? (d['globalError'] ?? d['message']) : null) ?? 'Archivo de audio no válido.');
      } else if (response.statusCode == 404) {
        final d = _safeDecodeBody(response);
        throw NotFoundException((d is Map ? (d['globalError'] ?? d['message']) : null) ?? 'La categoría seleccionada no existe.');
      } else {
        throw ServerException('Error del servidor (código ${response.statusCode}).');
      }
    } on TimeoutException { throw NetworkException('La subida tardó demasiado.');
    } on http.ClientException catch (e) { throw NetworkException('Sin conexión. (${e.message})');
    } on BadRequestException { rethrow; } on NotFoundException { rethrow; } on ServerException { rethrow;
    } catch (e) { throw NetworkException('Error inesperado: ${e.toString()}'); }
  }
  // POST /image
  static Future<Map<String, dynamic>> createImage({
    required File imageFile,
    String? contextText,
    int? categoryId,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/image'));
      final imageMime = _mimeTypeFromPath(imageFile.path, defaultMime: 'image/jpeg');
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType.parse(imageMime),
      ));
      if (contextText != null && contextText.isNotEmpty) request.fields['contextText'] = contextText;
      if (categoryId != null) request.fields['categoryId'] = categoryId.toString();
      final streamed = await request.send().timeout(_kTimeoutAudio);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 201) {
        return _safeDecodeBody(response) as Map<String, dynamic>? ?? {};
      } else if (response.statusCode == 400) {
        final d = _safeDecodeBody(response);
        throw BadRequestException((d is Map ? (d['globalError'] ?? d['message']) : null) ?? 'Archivo de imagen no válido.');
      } else if (response.statusCode == 404) {
        final d = _safeDecodeBody(response);
        throw NotFoundException((d is Map ? (d['globalError'] ?? d['message']) : null) ?? 'La categoría seleccionada no existe.');
      } else {
        throw ServerException('Error del servidor (código ${response.statusCode}).');
      }
    } on TimeoutException { throw NetworkException('La subida tardó demasiado.');
    } on http.ClientException catch (e) { throw NetworkException('Sin conexión. (${e.message})');
    } on BadRequestException { rethrow; } on NotFoundException { rethrow; } on ServerException { rethrow;
    } catch (e) { throw NetworkException('Error inesperado: ${e.toString()}'); }
  }
  // GET /categories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories')).timeout(_kTimeout);
      if (response.statusCode == 200) {
        final decoded = _safeDecodeBody(response);
        if (decoded == null) return [];
        if (decoded is List) return decoded.cast<Map<String, dynamic>>();
        throw ServerException('Formato de respuesta inesperado.');
      } else {
        throw ServerException('Error al obtener categorías (código ${response.statusCode}).');
      }
    } on TimeoutException { throw NetworkException('La conexión tardó demasiado.');
    } on http.ClientException catch (e) { throw NetworkException('Sin conexión. (${e.message})');
    } on ServerException { rethrow; } catch (e) { throw NetworkException('Error inesperado: ${e.toString()}'); }
  }
  // GET /captures
  static Future<Map<String, dynamic>> getCaptures({
    String? date, int? categoryId, String? fileType, int page = 0, int size = 50,
  }) async {
    try {
      final params = <String, String>{'page': '$page', 'size': '$size'};
      if (date != null) params['date'] = date;
      if (categoryId != null) params['categoryId'] = '$categoryId';
      if (fileType != null && fileType.isNotEmpty) params['fileType'] = fileType;
      final uri = Uri.parse('$_baseUrl/captures').replace(queryParameters: params);
      final response = await http.get(uri).timeout(_kTimeout);
      if (response.statusCode == 200) {
        final decoded = _safeDecodeBody(response);
        if (decoded is Map<String, dynamic>) return decoded;
        throw ServerException('Formato de respuesta inesperado.');
      } else if (response.statusCode == 400) {
        final d = _safeDecodeBody(response);
        throw BadRequestException((d is Map ? d['message'] : null) ?? 'Filtro inválido.');
      } else {
        throw ServerException('Error al obtener capturas (código ${response.statusCode}).');
      }
    } on TimeoutException { throw NetworkException('La conexión tardó demasiado.');
    } on http.ClientException catch (e) { throw NetworkException('Sin conexión. (${e.message})');
    } on BadRequestException { rethrow; } on ServerException { rethrow;
    } catch (e) { throw NetworkException('Error inesperado: ${e.toString()}'); }
  }
  // GET /captures/types
  static Future<List<String>> getUsedCaptureTypes() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/captures/types')).timeout(_kTimeout);
      if (response.statusCode == 200) {
        final decoded = _safeDecodeBody(response);
        if (decoded is List) return decoded.cast<String>();
        return [];
      } else {
        throw ServerException('Error al obtener tipos (código ${response.statusCode}).');
      }
    } on TimeoutException { throw NetworkException('La conexión tardó demasiado.');
    } on http.ClientException catch (e) { throw NetworkException('Sin conexión. (${e.message})');
    } on ServerException { rethrow; } catch (e) { throw NetworkException('Error inesperado: ${e.toString()}'); }
  }
  // GET /captures/days
  static Future<Map<String, dynamic>> getCaptureDays({int page = 0, int size = 30}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/captures/days?page=$page&size=$size')).timeout(_kTimeout);
      if (response.statusCode == 200) {
        final decoded = _safeDecodeBody(response);
        if (decoded is Map<String, dynamic>) return decoded;
        throw ServerException('Formato de respuesta inesperado.');
      } else {
        throw ServerException('Error al obtener días (código ${response.statusCode}).');
      }
    } on TimeoutException { throw NetworkException('La conexión tardó demasiado.');
    } on http.ClientException catch (e) { throw NetworkException('Sin conexión. (${e.message})');
    } on ServerException { rethrow; } catch (e) { throw NetworkException('Error inesperado: ${e.toString()}'); }
  }
  // GET /categories/:id
  static Future<Map<String, dynamic>> getCategoryById(int categoryId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories/$categoryId')).timeout(_kTimeout);
      if (response.statusCode == 200) {
        final decoded = _safeDecodeBody(response);
        if (decoded is Map<String, dynamic>) return decoded;
        throw ServerException('Formato de respuesta inesperado.');
      } else if (response.statusCode == 404) {
        throw NotFoundException('Categoría no encontrada.');
      } else {
        throw ServerException('Error al obtener la categoría (código ${response.statusCode}).');
      }
    } on TimeoutException { throw NetworkException('La conexión tardó demasiado.');
    } on http.ClientException catch (e) { throw NetworkException('Sin conexión. (${e.message})');
    } on NotFoundException { rethrow; } on ServerException { rethrow;
    } catch (e) { throw NetworkException('Error inesperado: ${e.toString()}'); }
  }
  // POST /document
  static Future<Map<String, dynamic>> createDocument({
    required File documentFile,
    String? contextText,
    int? categoryId,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/document'));
      final docMime = _mimeTypeFromPath(documentFile.path, defaultMime: 'application/octet-stream');
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        documentFile.path,
        contentType: MediaType.parse(docMime),
      ));
      if (contextText != null && contextText.isNotEmpty) request.fields['contextText'] = contextText;
      if (categoryId != null) request.fields['categoryId'] = categoryId.toString();
      final streamed = await request.send().timeout(_kTimeoutAudio);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 201) {
        return _safeDecodeBody(response) as Map<String, dynamic>? ?? {};
      } else {
        // Para cualquier error, intentamos leer el mensaje real del servidor
        dynamic d;
        try { d = _safeDecodeBody(response); } catch (_) { d = null; }
        final serverMsg = _errorMsg(d);
        if (response.statusCode == 400) {
          throw BadRequestException(serverMsg ?? 'Archivo de documento no válido.');
        } else if (response.statusCode == 404) {
          throw NotFoundException(serverMsg ?? 'Recurso no encontrado (código 404).');
        } else if (response.statusCode == 409) {
          throw DuplicateException(serverMsg ?? 'Ya existe un documento con ese nombre de archivo.');
        } else if (response.statusCode == 413) {
          throw BadRequestException('El archivo es demasiado grande para el servidor.');
        } else if (response.statusCode == 500) {
          throw ServerException(serverMsg ?? 'Error interno del servidor al procesar el documento.');
        } else {
          throw ServerException(serverMsg ?? 'Error del servidor (código ${response.statusCode}).');
        }
      }
    } on TimeoutException { throw NetworkException('La subida tardó demasiado.');
    } on http.ClientException catch (e) { throw NetworkException('Sin conexión. (${e.message})');
    } on BadRequestException { rethrow; } on NotFoundException { rethrow; } on ServerException { rethrow;
    } catch (e) { throw NetworkException('Error inesperado: ${e.toString()}'); }
  }

  // GET /captures/pending-category  →  capturas pendientes de revisar por el usuario
  // El backend marca como UNCATEGORIZED cuando la IA no puede asignar categoría,
  // y como PENDING mientras está procesando. Mostramos ambas (todo lo que no sea APPROVED).
  static Future<Map<String, dynamic>> getPendingCaptures({int page = 0, int size = 50}) async {
    try {
      // Usamos el endpoint general que devuelve TODAS las capturas
      final uri = Uri.parse('$_baseUrl/captures')
          .replace(queryParameters: {'page': '$page', 'size': '$size'});
      final response = await http.get(uri).timeout(_kTimeout);
      if (response.statusCode == 200) {
        final decoded = _safeDecodeBody(response);
        if (decoded is! Map<String, dynamic>) {
          throw ServerException('Formato de respuesta inesperado.');
        }
        // Filtramos en cliente: solo las que NO están aprobadas
        final allItems = (decoded['items'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .where((item) {
              final status = (item['categoryStatus'] as String? ?? '').toUpperCase();
              return status != 'APPROVED';
            })
            .toList();
        return {
          'items': allItems,
          'existMoreItems': decoded['existMoreItems'] ?? false,
        };
      } else {
        throw ServerException('Error al obtener capturas pendientes (código ${response.statusCode}).');
      }
    } on TimeoutException { throw NetworkException('La conexión tardó demasiado.');
    } on http.ClientException catch (e) { throw NetworkException('Sin conexión. (${e.message})');
    } on ServerException { rethrow; } catch (e) { throw NetworkException('Error inesperado: ${e.toString()}'); }
  }

  // PATCH /captures/{id}
  static Future<Map<String, dynamic>> patchCapture(
    int captureId, {
    int? categoryId,
    String? title,
    String? contextText,
    String? reorderedText,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (categoryId != null) body['categoryId'] = categoryId;
      if (title != null) body['title'] = title;
      if (contextText != null) body['contextText'] = contextText;
      if (reorderedText != null) body['reorderedText'] = reorderedText;
      final response = await http
          .patch(Uri.parse('$_baseUrl/captures/$captureId'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(_kTimeout);
      if (response.statusCode == 200) {
        return _safeDecodeBody(response) as Map<String, dynamic>? ?? {};
      } else if (response.statusCode == 404) {
        throw NotFoundException('Captura no encontrada.');
      } else {
        throw ServerException('Error del servidor (código ${response.statusCode}).');
      }
    } on TimeoutException { throw NetworkException('La conexión tardó demasiado.');
    } on http.ClientException catch (e) { throw NetworkException('Sin conexión. (${e.message})');
    } on NotFoundException { rethrow; } on ServerException { rethrow;
    } catch (e) { throw NetworkException('Error inesperado: ${e.toString()}'); }
  }

  // POST /captures/{id}/approve?target=all|category|text
  static Future<void> approveCapture(int captureId, {String target = 'all'}) async {
    try {
      final uri = Uri.parse('$_baseUrl/captures/$captureId/approve')
          .replace(queryParameters: {'target': target});
      final response = await http.post(uri).timeout(_kTimeout);
      if (response.statusCode != 200) {
        throw ServerException('Error al aprobar (código ${response.statusCode}).');
      }
    } on TimeoutException { throw NetworkException('La conexión tardó demasiado.');
    } on http.ClientException catch (e) { throw NetworkException('Sin conexión. (${e.message})');
    } on ServerException { rethrow; } catch (e) { throw NetworkException('Error inesperado: ${e.toString()}'); }
  }

  // POST /captures/{id}/reject?target=all|category|text
  static Future<void> rejectCapture(int captureId, {String target = 'all'}) async {
    try {
      final uri = Uri.parse('$_baseUrl/captures/$captureId/reject')
          .replace(queryParameters: {'target': target});
      final response = await http.post(uri).timeout(_kTimeout);
      if (response.statusCode != 200) {
        throw ServerException('Error al rechazar (código ${response.statusCode}).');
      }
    } on TimeoutException { throw NetworkException('La conexión tardó demasiado.');
    } on http.ClientException catch (e) { throw NetworkException('Sin conexión. (${e.message})');
    } on ServerException { rethrow; } catch (e) { throw NetworkException('Error inesperado: ${e.toString()}'); }
  }

  // Utilidad: infiere MIME type desde la extensión del archivo
  static String _mimeTypeFromPath(String path, {required String defaultMime}) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      // Imágenes
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      // Audio
      case 'm4a':
        return 'audio/m4a';
      case 'mp4':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      case '3gp':
        return 'audio/3gpp';
      case 'webm':
        return 'audio/webm';
      // Documentos
      case 'pdf':
        return 'application/pdf';
      case 'txt':
      case 'md':
      case 'log':
      case 'csv':
        return 'text/plain';
      case 'html':
      case 'htm':
        return 'text/html';
      case 'css':
        return 'text/css';
      case 'js':
      case 'mjs':
        return 'application/javascript';
      case 'ts':
        return 'application/typescript';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'yaml':
      case 'yml':
        return 'application/yaml';
      case 'dart':
      case 'py':
      case 'java':
      case 'kt':
      case 'swift':
      case 'cpp':
      case 'c':
      case 'h':
      case 'sh':
      case 'bat':
      case 'sql':
        return 'text/plain';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'zip':
        return 'application/zip';
      default:
        return defaultMime;
    }
  }
}
// Excepciones personalizadas
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  @override String toString() => message;
}
class BadRequestException implements Exception {
  final String message;
  const BadRequestException(this.message);
  @override String toString() => message;
}
class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
  @override String toString() => message;
}
class NotFoundException implements Exception {
  final String message;
  const NotFoundException(this.message);
  @override String toString() => message;
}
class DuplicateException implements Exception {
  final String message;
  const DuplicateException(this.message);
  @override String toString() => message;
}

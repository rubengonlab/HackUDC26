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
        final msg = (d is Map ? d['message'] : null) ?? 'Datos inválidos.';
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
        throw BadRequestException((d is Map ? d['message'] : null) ?? 'El contenido no puede estar vacío.');
      } else if (response.statusCode == 404) {
        throw NotFoundException('La categoría seleccionada no existe.');
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
        throw BadRequestException((d is Map ? d['message'] : null) ?? 'Archivo de audio no válido.');
      } else if (response.statusCode == 404) {
        throw NotFoundException('La categoría seleccionada no existe.');
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
      final streamed = await request.send().timeout(_kTimeoutAudio);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 201) {
        return _safeDecodeBody(response) as Map<String, dynamic>? ?? {};
      } else if (response.statusCode == 400) {
        final d = _safeDecodeBody(response);
        throw BadRequestException((d is Map ? d['message'] : null) ?? 'Archivo de imagen no válido.');
      } else {
        throw ServerException('Error del servidor (código ${response.statusCode}).');
      }
    } on TimeoutException { throw NetworkException('La subida tardó demasiado.');
    } on http.ClientException catch (e) { throw NetworkException('Sin conexión. (${e.message})');
    } on BadRequestException { rethrow; } on ServerException { rethrow;
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
  // GET /captures/pending-category
  static Future<Map<String, dynamic>> getPendingCaptures({int page = 0, int size = 50}) async {
    try {
      final uri = Uri.parse('$_baseUrl/captures/pending-category')
          .replace(queryParameters: {'page': '$page', 'size': '$size'});
      final response = await http.get(uri).timeout(_kTimeout);
      if (response.statusCode == 200) {
        final decoded = _safeDecodeBody(response);
        if (decoded is Map<String, dynamic>) return decoded;
        throw ServerException('Formato de respuesta inesperado.');
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

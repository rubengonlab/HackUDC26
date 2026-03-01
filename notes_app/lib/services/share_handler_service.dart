import 'dart:io';
import 'package:flutter/services.dart';

/// Servicio que gestiona el contenido compartido desde otras apps.
/// Soporta texto/URLs (Instagram, TikTok, YouTube...) e imágenes (galería, etc.)
class ShareHandlerService {
  static const _channel = MethodChannel('com.junkdrawer/share_handler');

  /// Callback para URL/texto compartido mientras la app está abierta.
  static Function(String url)? onSharedUrl;

  /// Callback para imagen compartida mientras la app está abierta.
  static Function(File imageFile)? onSharedImage;

  /// Inicializa el listener para shares recibidos con la app en primer plano.
  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedUrl') {
        final url = call.arguments as String?;
        if (url != null && url.isNotEmpty) onSharedUrl?.call(url);
      } else if (call.method == 'onSharedImageUri') {
        final uri = call.arguments as String?;
        if (uri != null && uri.isNotEmpty) {
          final file = await _resolveImageUri(uri);
          if (file != null) onSharedImage?.call(file);
        }
      }
    });
  }

  /// URL/texto compartido al abrir la app desde un share (app estaba cerrada).
  static Future<String?> getInitialSharedUrl() async {
    try {
      final url = await _channel.invokeMethod<String>('getSharedUrl');
      return (url != null && url.isNotEmpty) ? url : null;
    } catch (_) {
      return null;
    }
  }

  /// Imagen compartida al abrir la app desde un share (app estaba cerrada).
  static Future<File?> getInitialSharedImage() async {
    try {
      final uri = await _channel.invokeMethod<String>('getSharedImageUri');
      if (uri == null || uri.isEmpty) return null;
      return _resolveImageUri(uri);
    } catch (_) {
      return null;
    }
  }

  /// Convierte un content:// URI de Android en un File copiándolo al caché.
  static Future<File?> _resolveImageUri(String uriString) async {
    try {
      // Pedimos al nativo que copie el content URI a un archivo temporal
      final path = await _channel.invokeMethod<String>(
        'copyUriToCache',
        {'uri': uriString},
      );
      if (path == null || path.isEmpty) return null;
      return File(path);
    } catch (_) {
      return null;
    }
  }
}


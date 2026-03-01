import 'package:flutter/services.dart';

/// Servicio que gestiona los enlaces compartidos desde otras apps (Instagram,
/// TikTok, YouTube, etc.) a través del canal nativo com.junkdrawer/share_handler.
class ShareHandlerService {
  static const _channel = MethodChannel('com.junkdrawer/share_handler');

  /// Callback que se invoca cuando llega un enlace mientras la app ya está abierta.
  static Function(String url)? onSharedUrl;

  /// Inicializa el listener para cuando la app ya está en primer plano.
  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedUrl') {
        final url = call.arguments as String?;
        if (url != null && url.isNotEmpty) {
          onSharedUrl?.call(url);
        }
      }
    });
  }

  /// Consulta si hay una URL compartida pendiente (app abierta desde Share).
  /// Devuelve null si no hay ninguna.
  static Future<String?> getInitialSharedUrl() async {
    try {
      final url = await _channel.invokeMethod<String>('getSharedUrl');
      return (url != null && url.isNotEmpty) ? url : null;
    } catch (_) {
      return null;
    }
  }
}


import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../services/index.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Punto de entrada
// ─────────────────────────────────────────────────────────────────────────────
/// [onSaved] recibe true si la nota se guardó con categoría (aprobada), false si quedó pendiente.
void showNewNoteSheet(BuildContext context, {void Function(bool approved)? onSaved}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NewNoteSheet(onSaved: onSaved),
  );
}

/// Abre directamente el sheet en modo texto con [sharedUrl] prellenado.
void showSharedUrlSheet(BuildContext context, String sharedUrl, {void Function(bool approved)? onSaved}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NewNoteSheet(initialSharedUrl: sharedUrl, onSaved: onSaved),
  );
}

/// Abre directamente el sheet en modo imagen con [sharedFile] prellenado.
void showSharedImageSheet(BuildContext context, File sharedFile, {void Function(bool approved)? onSaved}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NewNoteSheet(initialSharedImage: sharedFile, onSaved: onSaved),
  );
}

class _NewNoteSheet extends StatefulWidget {
  const _NewNoteSheet({this.initialSharedUrl, this.initialSharedImage, this.onSaved});
  final String? initialSharedUrl;
  final File? initialSharedImage;
  final void Function(bool approved)? onSaved;
  @override
  State<_NewNoteSheet> createState() => _NewNoteSheetState();
}

enum _SheetMode { picker, text, audio, image }

class _NewNoteSheetState extends State<_NewNoteSheet> {
  late _SheetMode _mode;

  @override
  void initState() {
    super.initState();
    if (widget.initialSharedImage != null) {
      _mode = _SheetMode.image;
    } else if (widget.initialSharedUrl != null) {
      _mode = _SheetMode.text;
    } else {
      _mode = _SheetMode.picker;
    }
  }

  void _handleSaved(bool approved) {
    Navigator.of(context).pop();
    widget.onSaved?.call(approved);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: switch (_mode) {
        _SheetMode.picker => _PickerView(
            key: const ValueKey('picker'),
            onText: () => setState(() => _mode = _SheetMode.text),
            onAudio: () => setState(() => _mode = _SheetMode.audio),
            onImage: () => setState(() => _mode = _SheetMode.image),
          ),
        _SheetMode.text => _TextNoteView(
            key: const ValueKey('text'),
            onBack: () => setState(() => _mode = _SheetMode.picker),
            onSaved: _handleSaved,
            initialContent: widget.initialSharedUrl,
          ),
        _SheetMode.audio => _AudioNoteView(
            key: const ValueKey('audio'),
            onBack: () => setState(() => _mode = _SheetMode.picker),
            onSaved: _handleSaved,
          ),
        _SheetMode.image => _ImageNoteView(
            key: const ValueKey('image'),
            onBack: () => setState(() => _mode = _SheetMode.picker),
            onSaved: _handleSaved,
            initialFile: widget.initialSharedImage,
          ),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vista 1: selector de tipo
// ─────────────────────────────────────────────────────────────────────────────
class _PickerView extends StatelessWidget {
  const _PickerView({
    super.key,
    required this.onText,
    required this.onAudio,
    required this.onImage,
  });
  final VoidCallback onText;
  final VoidCallback onAudio;
  final VoidCallback onImage;

  static const _kBg = Color(0xFF1A1F4D);
  static const _kPrimary = Color(0xFFFF5856);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Nueva nota',
              style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('¿Cómo quieres capturar tu idea?',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _TypeButton(
                  emoji: '📝',
                  label: 'Escribir',
                  sublabel: 'Nota o enlace',
                  color: const Color(0xFF4C9FE0),
                  onTap: onText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeButton(
                  emoji: '🎙️',
                  label: 'Grabar voz',
                  sublabel: 'Audio',
                  color: _kPrimary,
                  onTap: onAudio,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeButton(
                  emoji: '🖼️',
                  label: 'Imagen',
                  sublabel: 'Foto o galería',
                  color: const Color(0xFF56C288),
                  onTap: onImage,
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF252B5C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Text(sublabel,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vista 2: nota de texto
// ─────────────────────────────────────────────────────────────────────────────
class _TextNoteView extends StatefulWidget {
  const _TextNoteView({super.key, required this.onBack, required this.onSaved, this.initialContent});
  final VoidCallback onBack;
  final void Function(bool approved) onSaved;
  final String? initialContent;
  @override
  State<_TextNoteView> createState() => _TextNoteViewState();
}

class _TextNoteViewState extends State<_TextNoteView> {
  static const _kBg = Color(0xFF1A1F4D);
  static const _kPrimary = Color(0xFFFF5856);

  final _titleCtrl = TextEditingController();
  late final TextEditingController _contentCtrl;
  String? _selectedCategoryId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _contentCtrl = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext ctx) async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      setState(() => _error = 'El contenido no puede estar vacío.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final catId = int.tryParse(_selectedCategoryId ?? '');
      await ApiService.createTextNote(
        content: content,
        title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        categoryId: catId,
      );
      if (ctx.mounted) ctx.read<NotesProvider>().loadNotes();
      widget.onSaved(catId != null); // approved si se eligió categoría
    } on BadRequestException catch (e) {
      setState(() => _error = e.message);
    } on NotFoundException catch (e) {
      setState(() => _error = e.message);
    } on DuplicateException catch (e) {
      setState(() => _error = e.message);
    } on NetworkException catch (e) {
      setState(() => _error = e.message);
    } on ServerException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Error inesperado. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoriesProvider>().getAllCategories();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20, 12, 20,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle + navegación
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white.withValues(alpha: 0.6), size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Nota de texto',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),

            // Título (opcional)
            _InputField(
              controller: _titleCtrl,
              hint: 'Título (opcional)',
              maxLines: 1,
            ),
            const SizedBox(height: 12),

            // Contenido (obligatorio)
            _InputField(
              controller: _contentCtrl,
              hint: 'Escribe tu nota o pega un enlace...',
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 12),

            // Selector de categoría
            _CategorySelector(
              categories: categories,
              selectedId: _selectedCategoryId,
              onChanged: (id) => setState(() => _selectedCategoryId = id),
            ),

            // Error
            if (_error != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: _error!),
            ],

            const SizedBox(height: 20),

            // Botón guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : () => _save(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  disabledBackgroundColor: _kPrimary.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Guardar nota',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vista 3: grabación de audio con paquete record
// ─────────────────────────────────────────────────────────────────────────────
class _AudioNoteView extends StatefulWidget {
  const _AudioNoteView({super.key, required this.onBack, required this.onSaved});
  final VoidCallback onBack;
  final void Function(bool approved) onSaved;
  @override
  State<_AudioNoteView> createState() => _AudioNoteViewState();
}

enum _RecordState { idle, recording, recorded, uploading }

class _AudioNoteViewState extends State<_AudioNoteView> {
  static const _kBg = Color(0xFF1A1F4D);
  static const _kPrimary = Color(0xFFFF5856);

  static const _channel = MethodChannel('com.junkdrawer/audio_recorder');

  _RecordState _state = _RecordState.idle;
  String? _recordedPath;
  String? _selectedCategoryId;
  String? _error;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    if (_state == _RecordState.recording) {
      _channel.invokeMethod('stop').catchError((_) {});
    }
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() => _error = null);
    try {
      final path = await _channel.invokeMethod<String>('start');
      if (path == null || path.isEmpty) {
        setState(() => _error = 'No se pudo iniciar la grabación.');
        return;
      }
      _elapsed = Duration.zero;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
      setState(() => _state = _RecordState.recording);
    } on PlatformException catch (e) {
      setState(() => _error = _mapPlatformError(e));
    } catch (e) {
      setState(() => _error = 'No se pudo iniciar la grabación: ${e.toString()}');
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    try {
      final path = await _channel.invokeMethod<String>('stop');
      if (path == null || path.isEmpty) {
        setState(() { _state = _RecordState.idle; _error = 'No se guardó el audio.'; });
        return;
      }
      setState(() { _recordedPath = path; _state = _RecordState.recorded; });
    } on PlatformException catch (e) {
      setState(() { _state = _RecordState.idle; _error = _mapPlatformError(e); });
    } catch (e) {
      setState(() { _state = _RecordState.idle; _error = 'Error al detener la grabación.'; });
    }
  }

  Future<void> _discardRecording() async {
    if (_recordedPath != null) {
      try { await File(_recordedPath!).delete(); } catch (_) {}
    }
    setState(() {
      _recordedPath = null;
      _state = _RecordState.idle;
      _elapsed = Duration.zero;
      _error = null;
    });
  }

  Future<void> _upload(BuildContext ctx) async {
    if (_recordedPath == null) return;
    setState(() { _state = _RecordState.uploading; _error = null; });
    try {
      final catId = int.tryParse(_selectedCategoryId ?? '');
      await ApiService.createAudio(audioFile: File(_recordedPath!), categoryId: catId);
      if (ctx.mounted) ctx.read<NotesProvider>().loadNotes();
      widget.onSaved(catId != null); // approved si se eligió categoría
    } on BadRequestException catch (e) {
      setState(() { _error = e.message; _state = _RecordState.recorded; });
    } on NotFoundException catch (e) {
      setState(() { _error = e.message; _state = _RecordState.recorded; });
    } on NetworkException catch (e) {
      setState(() { _error = e.message; _state = _RecordState.recorded; });
    } on ServerException catch (e) {
      setState(() { _error = e.message; _state = _RecordState.recorded; });
    } catch (e) {
      setState(() { _error = 'Error inesperado. Inténtalo de nuevo.'; _state = _RecordState.recorded; });
    }
  }

  String _mapPlatformError(PlatformException e) {
    switch (e.code) {
      case 'PERMISSION_DENIED': return 'Se necesita permiso de micrófono. Actívalo en Ajustes.';
      case 'RECORDER_ERROR': return 'Error del grabador: ${e.message}';
      default: return e.message ?? 'Error desconocido al grabar.';
    }
  }

  String _formatElapsed() {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoriesProvider>().getAllCategories();
    final isRecording = _state == _RecordState.recording;
    final isRecorded = _state == _RecordState.recorded;
    final isUploading = _state == _RecordState.uploading;

    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20,
          24 + MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Cabecera
          Row(
            children: [
              GestureDetector(
                onTap: isRecording ? null : widget.onBack,
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: isRecording
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.6),
                    size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Nota de voz',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 28),

          // Área central de grabación
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFF252B5C),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isRecording
                    ? _kPrimary.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.07),
              ),
            ),
            child: Column(
              children: [
                // Botón principal (iniciar / detener)
                GestureDetector(
                  onTap: isUploading
                      ? null
                      : isRecording
                          ? _stopRecording
                          : isRecorded
                              ? null
                              : _startRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: isRecorded
                          ? Colors.white.withValues(alpha: 0.08)
                          : _kPrimary.withValues(alpha: isRecording ? 1.0 : 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isRecorded
                            ? Colors.white.withValues(alpha: 0.15)
                            : _kPrimary,
                        width: 2,
                      ),
                      boxShadow: isRecording
                          ? [BoxShadow(
                              color: _kPrimary.withValues(alpha: 0.4),
                              blurRadius: 20, spreadRadius: 4)]
                          : [],
                    ),
                    child: Icon(
                      isRecording
                          ? Icons.stop_rounded
                          : isRecorded
                              ? Icons.check_rounded
                              : Icons.mic_rounded,
                      color: isRecorded
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Estado / cronómetro
                Text(
                  isUploading
                      ? 'Subiendo...'
                      : isRecording
                          ? _formatElapsed()
                          : isRecorded
                              ? 'Grabación lista  ✓'
                              : 'Toca para grabar',
                  style: TextStyle(
                    color: isRecording
                        ? _kPrimary
                        : Colors.white.withValues(alpha: 0.6),
                    fontSize: 15,
                    fontWeight:
                        isRecording ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),

                // Ondas animadas durante grabación
                if (isRecording)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) => _WaveBar(index: i)),
                    ),
                  ),
              ],
            ),
          ),

          // Botón descartar (solo si hay grabación)
          if (isRecorded) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: isUploading ? null : _discardRecording,
              icon: Icon(Icons.delete_outline,
                  size: 18, color: Colors.white.withValues(alpha: 0.45)),
              label: Text('Descartar y grabar de nuevo',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13)),
            ),
          ],

          const SizedBox(height: 16),

          // Selector de categoría
          _CategorySelector(
            categories: categories,
            selectedId: _selectedCategoryId,
            onChanged: (id) => setState(() => _selectedCategoryId = id),
          ),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _error!),
          ],

          const SizedBox(height: 20),

          // Botón guardar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isRecorded && !isUploading ? () => _upload(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                disabledBackgroundColor: _kPrimary.withValues(alpha: 0.25),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: isUploading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Text('Guardar nota de voz',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vista 4: subida de imagen (cámara o galería)
// ─────────────────────────────────────────────────────────────────────────────
class _ImageNoteView extends StatefulWidget {
  const _ImageNoteView({super.key, required this.onBack, required this.onSaved, this.initialFile});
  final VoidCallback onBack;
  final void Function(bool approved) onSaved;
  final File? initialFile;
  @override
  State<_ImageNoteView> createState() => _ImageNoteViewState();
}

class _ImageNoteViewState extends State<_ImageNoteView> {
  static const _kBg = Color(0xFF1A1F4D);
  static const _kGreen = Color(0xFF56C288);

  File? _pickedFile;
  final _contextCtrl = TextEditingController();
  String? _selectedCategoryId;
  bool _uploading = false;
  String? _error;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialFile != null) {
      _pickedFile = widget.initialFile;
    }
  }

  @override
  void dispose() {
    _contextCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _error = null);
    try {
      final xfile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (xfile != null) {
        setState(() => _pickedFile = File(xfile.path));
      }
    } catch (e) {
      setState(() => _error =
          'No se pudo acceder a ${source == ImageSource.camera ? 'la cámara' : 'la galería'}: ${e.toString()}');
    }
  }

  Future<void> _upload(BuildContext ctx) async {
    if (_pickedFile == null) return;
    setState(() { _uploading = true; _error = null; });
    try {
      final catId = int.tryParse(_selectedCategoryId ?? '');
      await ApiService.createImage(
        imageFile: _pickedFile!,
        contextText: _contextCtrl.text.trim().isEmpty ? null : _contextCtrl.text.trim(),
        categoryId: catId,
      );
      if (ctx.mounted) ctx.read<NotesProvider>().loadNotes();
      widget.onSaved(catId != null); // approved si se eligió categoría
    } on BadRequestException catch (e) {
      setState(() { _error = e.message; _uploading = false; });
    } on NetworkException catch (e) {
      setState(() { _error = e.message; _uploading = false; });
    } on ServerException catch (e) {
      setState(() { _error = e.message; _uploading = false; });
    } catch (e) {
      setState(() { _error = 'Error inesperado. Inténtalo de nuevo.'; _uploading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoriesProvider>().getAllCategories();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20, 12, 20,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: _uploading ? null : widget.onBack,
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white.withValues(alpha: 0.6), size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Nota de imagen',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),

            // Área de previsualización o selector
            if (_pickedFile == null)
              Row(
                children: [
                  Expanded(
                    child: _ImageSourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Cámara',
                      color: _kGreen,
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ImageSourceButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Galería',
                      color: const Color(0xFF4C9FE0),
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              )
            else
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _pickedFile!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: _uploading
                          ? null
                          : () => setState(() => _pickedFile = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 14),
            _CategorySelector(
              categories: categories,
              selectedId: _selectedCategoryId,
              onChanged: (id) => setState(() => _selectedCategoryId = id),
            ),
            const SizedBox(height: 12),
            _InputField(
              controller: _contextCtrl,
              hint: 'Descripción o contexto (opcional)',
              maxLines: 2,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _pickedFile != null && !_uploading ? () => _upload(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  disabledBackgroundColor: _kGreen.withValues(alpha: 0.25),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _uploading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Guardar imagen',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: const Color(0xFF252B5C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets compartidos
// ─────────────────────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.minLines,
  });
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: const Color(0xFFFF5856),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF252B5C),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFFF5856), width: 1.5),
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.categories,
    required this.selectedId,
    required this.onChanged,
  });
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  static const _kPrimary = Color(0xFFFF5856);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Categoría (opcional)',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Opción "Sin categoría"
              _CatChip(
                label: 'Sin categoría',
                isSelected: selectedId == null,
                color: Colors.white.withValues(alpha: 0.2),
                onTap: () => onChanged(null),
              ),
              ...categories.map((cat) => _CatChip(
                    label: cat.name,
                    isSelected: selectedId == cat.id,
                    color: _parseColor(cat.color),
                    onTap: () => onChanged(cat.id),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Color _parseColor(String c) {
    final hex = c.replaceAll('#', '');
    if (hex.length == 8) return Color(int.parse(hex, radix: 16));
    if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    return _kPrimary;
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.85)
              : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;
  static const _kPrimary = Color(0xFFFF5856);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _kPrimary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: _kPrimary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// Barra de onda animada para la grabación
class _WaveBar extends StatefulWidget {
  const _WaveBar({required this.index});
  final int index;
  @override
  State<_WaveBar> createState() => _WaveBarState();
}

class _WaveBarState extends State<_WaveBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + widget.index * 80),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 4, end: 20)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Container(
        width: 4,
        height: _anim.value,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5856),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}


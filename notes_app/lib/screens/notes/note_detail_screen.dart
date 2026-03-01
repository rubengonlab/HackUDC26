/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
import 'dart:typed_data';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../models/index.dart';

class NoteDetailScreen extends StatelessWidget {
  const NoteDetailScreen({super.key, required this.note});
  final Note note;

  static const _kBg      = Color(0xFF1A1F4D);
  static const _kSurface = Color(0xFF252B5C);
  static const _kPrimary = Color(0xFFFF5856);

  static const _typeColors = {
    NoteType.text:     Color(0xFF4C9FE0),
    NoteType.audio:    Color(0xFFFF5856),
    NoteType.image:    Color(0xFF56C288),
    NoteType.link:     Color(0xFFFFB347),
    NoteType.document: Color(0xFF9B8EA8),
  };

  Color get _accent => _typeColors[note.type] ?? _kPrimary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Text(Note.typeEmoji(note.type), style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                note.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(note: note, accent: _accent),
            const SizedBox(height: 20),
            switch (note.type) {
              NoteType.image    => _ImageContent(note: note, accent: _accent),
              NoteType.audio    => _AudioContent(note: note, accent: _accent),
              NoteType.link     => _LinkContent(note: note, accent: _accent),
              NoteType.text     => _TextContent(note: note, accent: _accent),
              NoteType.document => _DocumentContent(note: note, accent: _accent),
            },
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de cabecera: título, fecha, categoría, contexto
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.note, required this.accent});
  final Note note;
  final Color accent;

  String _formatDate(DateTime d) {
    const months = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month]} ${d.year} · $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252B5C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            note.title,
            style: const TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, height: 1.3),
          ),
          const SizedBox(height: 10),
          // Fecha
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 13, color: Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 5),
              Text(_formatDate(note.createdAt),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
            ],
          ),
          // Categoría
          if (note.categoryName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.folder_rounded, size: 13, color: accent),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Text(note.categoryName!,
                      style: TextStyle(
                          color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
          // Contexto
          if (note.contextText != null && note.contextText!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.label_outline_rounded, size: 14,
                    color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(note.contextText!,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 13, height: 1.5, fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEXTO
// ─────────────────────────────────────────────────────────────────────────────
class _TextContent extends StatelessWidget {
  const _TextContent({required this.note, required this.accent});
  final Note note;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final hasReordered = note.reorderedText?.trim().isNotEmpty ?? false;
    final original = note.preview ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasReordered) ...[
          _SectionLabel(label: 'Reformulado por IA', icon: Icons.auto_awesome_rounded, color: accent),
          const SizedBox(height: 8),
          _TextBox(text: note.reorderedText!, accent: accent),
          if (original.isNotEmpty) const SizedBox(height: 20),
        ],
        if (original.isNotEmpty) ...[
          _SectionLabel(
              label: 'Contenido original',
              icon: Icons.notes_rounded,
              color: hasReordered ? Colors.white.withValues(alpha: 0.4) : accent),
          const SizedBox(height: 8),
          _TextBox(
              text: original,
              accent: hasReordered ? Colors.white.withValues(alpha: 0.35) : accent,
              dimmed: hasReordered),
        ],
        if (!hasReordered && original.isEmpty) _EmptyContent(accent: accent),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUDIO — reproductor nativo + transcripción
// ─────────────────────────────────────────────────────────────────────────────
class _AudioContent extends StatefulWidget {
  const _AudioContent({required this.note, required this.accent});
  final Note note;
  final Color accent;
  @override
  State<_AudioContent> createState() => _AudioContentState();
}

class _AudioContentState extends State<_AudioContent> {
  static const _channel = MethodChannel('com.junkdrawer/audio_recorder');
  static const _baseUrl  = 'http://10.20.29.99:8080/junkdrawer';

  // idle → loading (descargando) → playing → idle
  bool _playing  = false;
  bool _loading  = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler((call) async {
      if (!mounted) return;
      switch (call.method) {
        case 'onPlaybackStarted':
          setState(() { _playing = true; _loading = false; });
          break;
        case 'onPlaybackCompleted':
          setState(() { _playing = false; _loading = false; });
          break;
      }
    });
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _stopPlayback();
      return;
    }
    if (_loading) return; // evitar doble tap mientras carga
    if (widget.note.contentUrl == null) {
      setState(() => _error = 'URL de audio no disponible');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final url = '$_baseUrl${widget.note.contentUrl}';
      // El nativo devuelve success en cuanto lanza la descarga en background.
      // El estado _playing se activa cuando llega onPlaybackStarted.
      await _channel.invokeMethod('playUrl', {'url': url});
    } on PlatformException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message ?? 'Error al reproducir'; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'No se pudo reproducir el audio'; });
    }
  }

  Future<void> _stopPlayback() async {
    try { await _channel.invokeMethod('stopPlayback'); } catch (_) {}
    if (mounted) setState(() { _playing = false; _loading = false; });
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    if (_playing || _loading) _channel.invokeMethod('stopPlayback').catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final hasReordered = note.reorderedText?.trim().isNotEmpty ?? false;
    final original = note.preview ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Reproductor ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: widget.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.accent.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(
            children: [
              // Botón play/stop
              GestureDetector(
                onTap: (_loading) ? null : _togglePlay,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: _playing
                        ? widget.accent
                        : widget.accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: _loading
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                              color: widget.accent, strokeWidth: 2.5))
                      : Icon(
                          _playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                          color: _playing ? Colors.white : widget.accent,
                          size: 30),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loading  ? 'Descargando audio…'  :
                      _playing  ? 'Reproduciendo…' : 'Nota de voz',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _loading  ? 'Puede tardar unos segundos'  :
                      _playing  ? 'Toca para detener'           : 'Toca para reproducir',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 4),
                      Text(_error!,
                          style: const TextStyle(color: Color(0xFFFF5856), fontSize: 12)),
                    ],
                  ],
                ),
              ),
              Icon(Icons.mic_rounded, color: widget.accent.withValues(alpha: 0.5), size: 22),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Transcripción reformulada por IA arriba ───────────────────────
        if (hasReordered) ...[
          _SectionLabel(
              label: 'Reformulada por IA', icon: Icons.auto_awesome_rounded, color: widget.accent),
          const SizedBox(height: 8),
          _TextBox(text: note.reorderedText!, accent: widget.accent),
          if (original.isNotEmpty) const SizedBox(height: 20),
        ],

        // ── Transcripción original abajo ──────────────────────────────────
        if (original.isNotEmpty) ...[
          _SectionLabel(
              label: 'Transcripción original',
              icon: Icons.record_voice_over_rounded,
              color: hasReordered ? Colors.white.withValues(alpha: 0.4) : widget.accent),
          const SizedBox(height: 8),
          _TextBox(
              text: original,
              accent: hasReordered ? Colors.white.withValues(alpha: 0.35) : widget.accent,
              dimmed: hasReordered),
        ],

        if (!hasReordered && original.isEmpty)
          _EmptyContent(accent: widget.accent, message: 'Transcripción no disponible todavía'),
      ],
    );
  }

  Note get note => widget.note;
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGEN — visor + texto OCR
// ─────────────────────────────────────────────────────────────────────────────
class _ImageContent extends StatefulWidget {
  const _ImageContent({required this.note, required this.accent});
  final Note note;
  final Color accent;
  @override
  State<_ImageContent> createState() => _ImageContentState();
}

class _ImageContentState extends State<_ImageContent> {
  Uint8List? _imageBytes;
  bool _loading = true;
  String? _error;

  static const _baseUrl = 'http://10.20.29.99:8080/junkdrawer';

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (widget.note.contentUrl == null) {
      setState(() { _loading = false; _error = 'URL de imagen no disponible'; });
      return;
    }
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl${widget.note.contentUrl}'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        setState(() { _imageBytes = response.bodyBytes; _loading = false; });
      } else {
        setState(() { _loading = false; _error = 'Error ${response.statusCode}'; });
      }
    } catch (e) {
      setState(() { _loading = false; _error = 'No se pudo cargar la imagen'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final hasOcr = note.preview?.trim().isNotEmpty ?? false;
    final hasReordered = note.reorderedText?.trim().isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Imagen ────────────────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 200, maxHeight: 420),
            color: const Color(0xFF252B5C),
            child: _loading
                ? Center(child: CircularProgressIndicator(color: widget.accent))
                : _error != null
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.broken_image_rounded,
                              size: 48, color: Colors.white.withValues(alpha: 0.3)),
                          const SizedBox(height: 8),
                          Text(_error!,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
                        ]))
                    : Image.memory(_imageBytes!, fit: BoxFit.contain),
          ),
        ),

        // ── Texto IA arriba ───────────────────────────────────────────────
        if (hasReordered) ...[
          const SizedBox(height: 20),
          _SectionLabel(
              label: 'Análisis por IA', icon: Icons.auto_awesome_rounded, color: widget.accent),
          const SizedBox(height: 8),
          _TextBox(text: note.reorderedText!, accent: widget.accent),
        ],

        // ── Texto OCR original abajo ──────────────────────────────────────
        if (hasOcr) ...[
          const SizedBox(height: 20),
          _SectionLabel(
              label: 'Texto detectado (OCR)',
              icon: Icons.text_fields_rounded,
              color: hasReordered ? Colors.white.withValues(alpha: 0.4) : widget.accent),
          const SizedBox(height: 8),
          _TextBox(
              text: note.preview!,
              accent: hasReordered ? Colors.white.withValues(alpha: 0.35) : widget.accent,
              dimmed: hasReordered),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENLACE
// ─────────────────────────────────────────────────────────────────────────────
class _LinkContent extends StatelessWidget {
  const _LinkContent({required this.note, required this.accent});
  final Note note;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final urlText = note.url ?? note.preview ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icono
        Center(
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.35), width: 2),
            ),
            child: Icon(Icons.link_rounded, color: accent, size: 36),
          ),
        ),
        const SizedBox(height: 20),
        // URL con botón copiar
        _SectionLabel(label: 'URL', icon: Icons.open_in_new_rounded, color: accent),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF252B5C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(urlText,
                    style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: accent)),
              ),
              IconButton(
                icon: Icon(Icons.copy_rounded, size: 18, color: accent.withValues(alpha: 0.6)),
                tooltip: 'Copiar URL',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: urlText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('URL copiada'), duration: Duration(seconds: 2)));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DOCUMENTO — info del archivo + texto IA + extraído
// ─────────────────────────────────────────────────────────────────────────────
class _DocumentContent extends StatelessWidget {
  const _DocumentContent({required this.note, required this.accent});
  final Note note;
  final Color accent;

  String _docEmoji(String? n) {
    if (n == null) return '📄';
    final ext = n.split('.').last.toLowerCase();
    if (ext == 'pdf') return '📕';
    if (['js','ts','dart','py','java','kt','swift','cpp','c','h'].contains(ext)) return '💻';
    if (['json','xml','yaml','yml','toml'].contains(ext)) return '⚙️';
    if (['md','txt','csv','log'].contains(ext)) return '📃';
    if (['doc','docx','odt'].contains(ext)) return '📝';
    if (['xls','xlsx','ods'].contains(ext)) return '📊';
    return '📄';
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final fileName = note.title;
    final original  = note.preview ?? '';
    final hasReordered = note.reorderedText?.trim().isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tarjeta de archivo ────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.3), width: 2),
          ),
          child: Row(
            children: [
              Text(_docEmoji(fileName), style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    if (note.durationSeconds != null && note.durationSeconds! > 0) ...[
                      const SizedBox(height: 4),
                      Text(_formatSize(note.durationSeconds),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                    ],
                  ],
                ),
              ),
              Icon(Icons.insert_drive_file_rounded, color: accent, size: 28),
            ],
          ),
        ),

        // ── IA arriba ─────────────────────────────────────────────────────
        if (hasReordered) ...[
          const SizedBox(height: 20),
          _SectionLabel(
              label: 'Reformulado por IA', icon: Icons.auto_awesome_rounded, color: accent),
          const SizedBox(height: 8),
          _TextBox(text: note.reorderedText!, accent: accent),
        ],

        // ── Texto extraído abajo ──────────────────────────────────────────
        if (original.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionLabel(
              label: 'Contenido extraído',
              icon: Icons.text_snippet_rounded,
              color: hasReordered ? Colors.white.withValues(alpha: 0.4) : accent),
          const SizedBox(height: 8),
          _TextBox(
              text: original,
              accent: hasReordered ? Colors.white.withValues(alpha: 0.35) : accent,
              dimmed: hasReordered),
        ],

        if (original.isEmpty && !hasReordered && note.contextText == null)
          _EmptyContent(accent: accent, message: 'Sin contenido extraído'),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets comunes
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label.toUpperCase(),
            style: TextStyle(
                color: color, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      ],
    );
  }
}

class _TextBox extends StatelessWidget {
  const _TextBox({required this.text, required this.accent, this.dimmed = false});
  final String text;
  final Color accent;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dimmed
            ? Colors.white.withValues(alpha: 0.04)
            : accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dimmed
              ? Colors.white.withValues(alpha: 0.1)
              : accent.withValues(alpha: 0.2),
        ),
      ),
      child: Text(text,
          style: TextStyle(
              color: dimmed
                  ? Colors.white.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.9),
              fontSize: 14, height: 1.6)),
    );
  }
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent({required this.accent, this.message});
  final Color accent;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty_rounded,
                size: 40, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 10),
            Text(message ?? 'Sin contenido disponible',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}







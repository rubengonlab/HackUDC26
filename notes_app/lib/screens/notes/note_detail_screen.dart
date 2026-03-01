import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/index.dart';

class NoteDetailScreen extends StatelessWidget {
  const NoteDetailScreen({super.key, required this.note});
  final Note note;

  static const _kPrimary = Color(0xFFFF5856);

  static const _typeColors = {
    NoteType.text:  Color(0xFF4C9FE0),
    NoteType.audio: Color(0xFFFF5856),
    NoteType.image: Color(0xFF56C288),
    NoteType.link:  Color(0xFFFFB347),
  };

  Color get _accent => _typeColors[note.type] ?? _kPrimary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F4D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F4D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Text(Note.typeEmoji(note.type),
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                note.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17),
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
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadatos: fecha + categoría
            _MetaRow(note: note, accent: _accent),
            const SizedBox(height: 20),

            // Contenido principal según tipo
            switch (note.type) {
              NoteType.image => _ImageContent(note: note, accent: _accent),
              NoteType.audio => _AudioContent(note: note, accent: _accent),
              NoteType.link  => _LinkContent(note: note, accent: _accent),
              NoteType.text  => _TextContent(note: note, accent: _accent),
            },
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fila de metadatos (fecha, categoría)
// ─────────────────────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.note, required this.accent});
  final Note note;
  final Color accent;

  String _formatDate(DateTime d) {
    const months = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${d.day} ${months[d.month]} ${d.year}  '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.schedule_rounded,
            size: 13, color: Colors.white.withValues(alpha: 0.4)),
        const SizedBox(width: 5),
        Text(_formatDate(note.createdAt),
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
        if (note.categoryName != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_rounded, size: 11, color: accent),
                const SizedBox(width: 4),
                Text(note.categoryName!,
                    style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contenido: TEXTO / NOTA
// ─────────────────────────────────────────────────────────────────────────────
class _TextContent extends StatelessWidget {
  const _TextContent({required this.note, required this.accent});
  final Note note;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final hasReordered = note.reorderedText != null &&
        note.reorderedText!.trim().isNotEmpty;
    final original = note.preview ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Texto reformulado por IA (principal)
        if (hasReordered) ...[
          _SectionLabel(label: 'Reformulado por IA', icon: Icons.auto_awesome_rounded, color: accent),
          const SizedBox(height: 8),
          _TextBox(text: note.reorderedText!, accent: accent),
          const SizedBox(height: 20),
          _SectionLabel(label: 'Original', icon: Icons.notes_rounded,
              color: Colors.white.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          _TextBox(
              text: original,
              accent: Colors.white.withValues(alpha: 0.35),
              dimmed: true),
        ] else if (original.isNotEmpty) ...[
          _SectionLabel(label: 'Contenido', icon: Icons.notes_rounded, color: accent),
          const SizedBox(height: 8),
          _TextBox(text: original, accent: accent),
        ] else
          _EmptyContent(accent: accent),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contenido: AUDIO
// ─────────────────────────────────────────────────────────────────────────────
class _AudioContent extends StatelessWidget {
  const _AudioContent({required this.note, required this.accent});
  final Note note;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final hasReordered = note.reorderedText != null &&
        note.reorderedText!.trim().isNotEmpty;
    final original = note.preview ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icono decorativo de audio
        Center(
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.35), width: 2),
            ),
            child: Icon(Icons.mic_rounded, color: accent, size: 38),
          ),
        ),
        const SizedBox(height: 20),

        if (hasReordered) ...[
          _SectionLabel(label: 'Transcripción reformulada', icon: Icons.auto_awesome_rounded, color: accent),
          const SizedBox(height: 8),
          _TextBox(text: note.reorderedText!, accent: accent),
          const SizedBox(height: 20),
        ],
        if (original.isNotEmpty) ...[
          _SectionLabel(
              label: hasReordered ? 'Transcripción original' : 'Transcripción',
              icon: Icons.record_voice_over_rounded,
              color: hasReordered
                  ? Colors.white.withValues(alpha: 0.4)
                  : accent),
          const SizedBox(height: 8),
          _TextBox(
              text: original,
              accent: hasReordered
                  ? Colors.white.withValues(alpha: 0.35)
                  : accent,
              dimmed: hasReordered),
        ],
        if (!hasReordered && original.isEmpty)
          _EmptyContent(accent: accent, message: 'Transcripción no disponible todavía'),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contenido: IMAGEN
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 200, maxHeight: 380),
            color: const Color(0xFF252B5C),
            child: _loading
                ? Center(child: CircularProgressIndicator(color: widget.accent))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image_rounded,
                                size: 48,
                                color: Colors.white.withValues(alpha: 0.3)),
                            const SizedBox(height: 8),
                            Text(_error!,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 13)),
                          ],
                        ),
                      )
                    : Image.memory(_imageBytes!, fit: BoxFit.contain),
          ),
        ),

        // Contexto si existe
        if (widget.note.contextText != null &&
            widget.note.contextText!.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionLabel(label: 'Contexto', icon: Icons.label_outline_rounded,
              color: widget.accent),
          const SizedBox(height: 8),
          _TextBox(text: widget.note.contextText!, accent: widget.accent),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contenido: ENLACE
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
        _SectionLabel(label: 'URL', icon: Icons.open_in_new_rounded, color: accent),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF252B5C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Text(urlText,
              style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: accent)),
        ),
        if (note.contextText != null &&
            note.contextText!.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionLabel(label: 'Notas', icon: Icons.notes_rounded, color: accent),
          const SizedBox(height: 8),
          _TextBox(text: note.contextText!, accent: accent),
        ],
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
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8)),
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
              fontSize: 14,
              height: 1.6)),
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







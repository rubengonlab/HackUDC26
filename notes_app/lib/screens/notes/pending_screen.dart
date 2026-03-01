import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../services/index.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Colores globales
// ─────────────────────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF1A1F4D);
const _kSurface = Color(0xFF252B5C);
const _kPrimary = Color(0xFFFF5856);
const _kGreen   = Color(0xFF56C288);
const _kBaseUrl = 'http://10.20.29.99:8080/junkdrawer';

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla principal de pendientes
// ─────────────────────────────────────────────────────────────────────────────
class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});
  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.getPendingCaptures(size: 100);
      final items = (result['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _removeItem(int captureId) {
    setState(() => _items.removeWhere((i) {
      final id = i['id'];
      if (id == null) return false;
      if (id is int) return id == captureId;
      if (id is num) return id.toInt() == captureId;
      return false;
    }));
    if (mounted) context.read<NotesProvider>().loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Pendientes de aprobar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
        ),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _load,
              tooltip: 'Actualizar',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: _kPrimary,
                  backgroundColor: _kSurface,
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          // Necesario para que pull-to-refresh funcione en lista vacía
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            _EmptyView(),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                          itemCount: _items.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => _PendingCard(
                            json: _items[i],
                            onDone: _removeItem,
                          ),
                        ),
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de captura pendiente
// ─────────────────────────────────────────────────────────────────────────────
class _PendingCard extends StatefulWidget {
  const _PendingCard({required this.json, required this.onDone});
  final Map<String, dynamic> json;
  final void Function(int captureId) onDone;
  @override
  State<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<_PendingCard> {
  late final int _captureId;
  late final String _type;

  // Campos editables
  late int? _selectedCategoryId;
  late final TextEditingController _reorderedCtrl;
  bool _useReordered = true;
  bool _saving = false;
  String? _error;
  bool _expanded = false;

  /// Casteo seguro: acepta int, num, String o null
  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  @override
  void initState() {
    super.initState();
    _captureId = _toInt(widget.json['id']) ?? 0;
    _type = (widget.json['captureType'] as String? ?? 'NOTE').toUpperCase();
    _selectedCategoryId = _toInt(widget.json['categoryId']);

    final reordered = _extractReorderedText();
    _reorderedCtrl = TextEditingController(text: reordered ?? '');
    _useReordered = reordered != null && reordered.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _reorderedCtrl.dispose();
    super.dispose();
  }

  // ── Helpers de extracción de datos ──────────────────────────────────────

  /// Texto reformulado por IA según el tipo de captura
  String? _extractReorderedText() {
    switch (_type) {
      case 'NOTE':
        return widget.json['note']?['reorderedText'] as String?;
      case 'AUDIO':
        return widget.json['audio']?['reorderedParsedText'] as String?;
      case 'IMAGE':
        return widget.json['image']?['reorderedParsedText'] as String?;
      default:
        return null;
    }
  }

  /// Texto original (transcripción / contenido / URL) según tipo
  String? _extractOriginalText() {
    switch (_type) {
      case 'NOTE':
        return widget.json['note']?['content'] as String?;
      case 'AUDIO':
        return widget.json['audio']?['parsedText'] as String?;
      case 'IMAGE':
        return widget.json['image']?['parsedText'] as String?;
      case 'LINK':
        return widget.json['link']?['url'] as String?;
      default:
        return widget.json['contextText'] as String?;
    }
  }

  String get _title {
    final t = widget.json['title'] as String?;
    if (t != null && t.trim().isNotEmpty) return t;
    switch (_type) {
      case 'AUDIO': return widget.json['audio']?['originalFileName'] as String? ?? 'Audio';
      case 'IMAGE': return widget.json['image']?['originalFileName'] as String? ?? 'Imagen';
      case 'LINK':  return widget.json['link']?['url'] as String? ?? 'Enlace';
      case 'NOTE':
        final content = widget.json['note']?['content'] as String? ?? '';
        final first = content.split('\n').first;
        return first.isNotEmpty ? first : 'Nota';
      default: return 'Captura';
    }
  }

  String get _typeEmoji {
    switch (_type) {
      case 'AUDIO':    return '🎙️';
      case 'IMAGE':    return '🖼️';
      case 'LINK':     return '🔗';
      case 'NOTE':     return '📝';
      case 'DOCUMENT': return '📄';
      default:         return '📌';
    }
  }

  Color get _accent {
    switch (_type) {
      case 'AUDIO':    return _kPrimary;
      case 'IMAGE':    return _kGreen;
      case 'LINK':     return const Color(0xFFFFB347);
      case 'NOTE':     return const Color(0xFF4C9FE0);
      default:         return const Color(0xFF9B8EA8);
    }
  }

  // ── Acciones ────────────────────────────────────────────────────────────
  Future<void> _approve(BuildContext ctx) async {
    setState(() { _saving = true; _error = null; });
    try {
      final reorderedFinal = _reorderedCtrl.text.trim();
      final originalReordered = _extractReorderedText() ?? '';

      // 1. Actualizar reorderedText si fue editado
      if (reorderedFinal != originalReordered && reorderedFinal.isNotEmpty) {
        await ApiService.patchCapture(_captureId, reorderedText: reorderedFinal);
      }

      // 2. Actualizar categoría si cambió
      final originalCategoryId = _toInt(widget.json['categoryId']);
      if (_selectedCategoryId != originalCategoryId) {
        await ApiService.patchCapture(_captureId, categoryId: _selectedCategoryId);
      }

      // 3. Aprobar según lo que el usuario eligió
      final hasReordered = reorderedFinal.isNotEmpty;
      if (hasReordered && _useReordered) {
        await ApiService.approveCapture(_captureId, target: 'all');
      } else if (hasReordered && !_useReordered) {
        await ApiService.approveCapture(_captureId, target: 'category');
        await ApiService.rejectCapture(_captureId, target: 'text');
      } else {
        await ApiService.approveCapture(_captureId, target: 'category');
      }

      widget.onDone(_captureId);
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  Future<void> _reject(BuildContext ctx) async {
    setState(() { _saving = true; _error = null; });
    try {
      await ApiService.rejectCapture(_captureId, target: 'all');
      widget.onDone(_captureId);
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoriesProvider>().getAllCategories();
    final suggestedCatName = widget.json['categoryName'] as String?;
    final originalText = _extractOriginalText();
    final reorderedText = _extractReorderedText();
    final hasReorderedField = reorderedText != null && reorderedText.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera: emoji + título + tipo + flecha ────────────────────
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(child: Text(_typeEmoji, style: const TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_title,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 2),
                        if (suggestedCatName != null)
                          Row(children: [
                            Icon(Icons.auto_awesome_rounded, size: 11, color: _accent),
                            const SizedBox(width: 4),
                            Text('IA sugiere: $suggestedCatName',
                                style: TextStyle(color: _accent, fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ])
                        else
                          Text('Sin categoría sugerida',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenido expandible ────────────────────────────────────────
          if (_expanded) ...[
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Imagen si es IMAGE
                  if (_type == 'IMAGE') ...[
                    _ImagePreview(json: widget.json),
                    const SizedBox(height: 14),
                  ],

                  // Categoría desplegable
                  _SectionLabel('Categoría', Icons.folder_rounded, _accent),
                  const SizedBox(height: 6),
                  _CategoryDropdown(
                    categories: categories,
                    selectedId: _selectedCategoryId,
                    onChanged: (id) => setState(() => _selectedCategoryId = id),
                  ),
                  const SizedBox(height: 14),

                  // Contexto (si existe)
                  if (widget.json['contextText'] != null &&
                      (widget.json['contextText'] as String).trim().isNotEmpty) ...[
                    _SectionLabel('Contexto', Icons.label_outline_rounded,
                        Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(height: 6),
                    _TextBlock(
                        text: widget.json['contextText'] as String,
                        accent: Colors.white.withValues(alpha: 0.35)),
                    const SizedBox(height: 14),
                  ],

                  // Texto original
                  if (originalText != null && originalText.trim().isNotEmpty) ...[
                    _SectionLabel(
                      _type == 'LINK' ? 'URL' : 'Texto original',
                      _type == 'LINK' ? Icons.link_rounded : Icons.notes_rounded,
                      Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 6),
                    _TextBlock(text: originalText, accent: Colors.white.withValues(alpha: 0.35)),
                    const SizedBox(height: 14),
                  ],

                  // Texto reformulado por IA (editable) + selector original/reformulado
                  if (hasReorderedField) ...[
                    Row(
                      children: [
                        Expanded(child: _SectionLabel(
                            'Reformulado por IA', Icons.auto_awesome_rounded, _accent)),
                        // Toggle: usar reformulado o usar original
                        _ToggleChip(
                          label: _useReordered ? 'Usar este' : 'Usar original',
                          active: _useReordered,
                          color: _accent,
                          onTap: () => setState(() => _useReordered = !_useReordered),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Campo editable
                    Container(
                      decoration: BoxDecoration(
                        color: _useReordered
                            ? _accent.withValues(alpha: 0.07)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _useReordered
                              ? _accent.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: TextField(
                        controller: _reorderedCtrl,
                        enabled: _useReordered,
                        maxLines: null,
                        style: TextStyle(
                          color: _useReordered
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.3),
                          fontSize: 13, height: 1.6,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(12),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          hintText: 'Sin texto reformulado',
                          hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.25),
                              fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Error
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(color: _kPrimary, fontSize: 12)),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),

            // ── Botones Aprobar / Rechazar ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              child: Row(
                children: [
                  // Rechazar
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _reject(context),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: BorderSide(color: _kPrimary.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Aprobar
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : () => _approve(context),
                      icon: _saving
                          ? const SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_rounded, size: 16),
                      label: Text(_saving ? 'Guardando...' : 'Aprobar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _kGreen.withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview de imagen
// ─────────────────────────────────────────────────────────────────────────────
class _ImagePreview extends StatefulWidget {
  const _ImagePreview({required this.json});
  final Map<String, dynamic> json;
  @override
  State<_ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<_ImagePreview> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final imageId = widget.json['image']?['id'];
    if (imageId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final r = await http.get(Uri.parse('$_kBaseUrl/image/$imageId/content'))
          .timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        setState(() { _bytes = r.bodyBytes; _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 160,
        width: double.infinity,
        color: Colors.white.withValues(alpha: 0.05),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2))
            : _bytes != null
                ? Image.memory(_bytes!, fit: BoxFit.cover)
                : Center(child: Icon(Icons.broken_image_rounded,
                    size: 36, color: Colors.white.withValues(alpha: 0.2))),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown de categoría
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.selectedId,
    required this.onChanged,
  });
  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedId,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E2456),
          hint: Text('SIN CATEGORÍA',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12, letterSpacing: 0.5)),
          style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 0.5),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white.withValues(alpha: 0.4)),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text('SIN CATEGORÍA',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12, letterSpacing: 0.5)),
            ),
            ...categories.map((cat) => DropdownMenuItem<int?>(
              value: int.tryParse(cat.id),
              child: Text(cat.name.toUpperCase(),
                  style: const TextStyle(color: Colors.white,
                      fontSize: 12, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
            )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets pequeños
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 6),
      Text(label.toUpperCase(),
          style: TextStyle(color: color, fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    ],
  );
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.text, required this.accent});
  final String text;
  final Color accent;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    ),
    child: Text(text,
        style: TextStyle(color: accent, fontSize: 13, height: 1.55)),
  );
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.label, required this.active,
      required this.color, required this.onTap});
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? color : Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: TextStyle(
              color: active ? color : Colors.white.withValues(alpha: 0.4),
              fontSize: 11, fontWeight: FontWeight.w600)),
    ),
  );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
            color: _kGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.check_circle_outline_rounded,
            size: 36, color: _kGreen),
      ),
      const SizedBox(height: 16),
      const Text('¡Todo al día!',
          style: TextStyle(color: Colors.white, fontSize: 16,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text('No hay capturas pendientes de aprobar',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.45),
              fontSize: 13)),
    ]),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off_rounded, size: 40, color: _kPrimary),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Reintentar'),
        style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    ]),
  );
}





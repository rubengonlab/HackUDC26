import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
enum GroupBy { category, type, date }
class NotesProvider extends ChangeNotifier {
  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;
  final List<GroupBy> _groupingOrder = [GroupBy.category];
  List<Note> get allNotes => List.unmodifiable(_notes);
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<GroupBy> get groupingOrder => List.unmodifiable(_groupingOrder);
  Set<GroupBy> get activeGroupings => _groupingOrder.toSet();
  void toggleGrouping(GroupBy g) {
    if (_groupingOrder.contains(g)) {
      if (_groupingOrder.length > 1) _groupingOrder.remove(g);
    } else {
      _groupingOrder.add(g);
    }
    notifyListeners();
  }
  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await ApiService.getAudios(page: 0, size: 200);
      final items = result['items'] as List<dynamic>? ?? [];
      _notes = items
          .map((e) => Note.fromAudioJson(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  List<FolderNode> buildFolderTree(List<Category> userCategories) {
    return _buildLevel(_notes, _groupingOrder, 0, userCategories);
  }
  List<FolderNode> _buildLevel(
    List<Note> notes,
    List<GroupBy> order,
    int depth,
    List<Category> userCategories,
  ) {
    if (depth >= order.length) return [];
    final groupBy = order[depth];
    final Map<String, List<Note>> groups = {};
    for (final note in notes) {
      final key = _keyFor(note, groupBy);
      groups.putIfAbsent(key, () => []).add(note);
    }
    return groups.entries.map((e) {
      final children = _buildLevel(e.value, order, depth + 1, userCategories);
      return FolderNode(
        key: e.key,
        label: _labelFor(e.key, groupBy, userCategories),
        groupBy: groupBy,
        notes: children.isEmpty ? e.value : [],
        children: children,
        totalNotes: e.value.length,
        color: _colorFor(e.key, groupBy, userCategories),
      );
    }).toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }
  String _keyFor(Note note, GroupBy g) {
    switch (g) {
      case GroupBy.category:
        return note.categoryId ?? '_uncategorized';
      case GroupBy.type:
        return note.type.name;
      case GroupBy.date:
        final d = note.createdAt;
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
  }
  String _labelFor(String key, GroupBy g, List<Category> cats) {
    switch (g) {
      case GroupBy.category:
        if (key == '_uncategorized') return 'Sin categoria';
        try {
          return cats.firstWhere((c) => c.id == key).name;
        } catch (_) {
          return key;
        }
      case GroupBy.type:
        final type = NoteType.values.firstWhere(
          (t) => t.name == key,
          orElse: () => NoteType.text,
        );
        return '${Note.typeEmoji(type)} ${Note.typeLabel(type)}';
      case GroupBy.date:
        final parts = key.split('-');
        final d = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        return _formatDateLabel(d);
    }
  }
  String _formatDateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return 'Hace $diff dias';
    const months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
  Color? _colorFor(String key, GroupBy g, List<Category> cats) {
    if (g != GroupBy.category) return null;
    if (key == '_uncategorized') return const Color(0xFF6B7280);
    try {
      return _parseColor(cats.firstWhere((c) => c.id == key).color);
    } catch (_) {
      return null;
    }
  }
  Color _parseColor(String colorString) {
    final hex = colorString.replaceAll('#', '');
    if (hex.length == 8) return Color(int.parse(hex, radix: 16));
    if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    return const Color(0xFFFF5856);
  }
}
class FolderNode {
  final String key;
  final String label;
  final GroupBy groupBy;
  final List<Note> notes;
  final List<FolderNode> children;
  final int totalNotes;
  final Color? color;
  const FolderNode({
    required this.key,
    required this.label,
    required this.groupBy,
    required this.notes,
    required this.children,
    required this.totalNotes,
    this.color,
  });
  bool get isLeaf => children.isEmpty;
}

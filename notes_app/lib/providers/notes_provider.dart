/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';

enum GroupBy { category, type, date }

class NotesProvider extends ChangeNotifier {
  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;
  final List<GroupBy> _groupingOrder = [GroupBy.category];

  // Filtros activos
  String? _activeFileType;   // NOTE, LINK, AUDIO, IMAGE, DOCUMENT — null = todos
  int? _activeCategoryId;    // null = todas
  String? _activeDate;       // yyyy-MM-dd — null = todas

  // Tipos y fechas disponibles (cargados desde el back)
  List<String> _availableTypes = [];
  List<String> _availableDays = [];
  bool _isLoadingFilters = false;

  // Conteo de capturas pendientes de aprobar (para badge de campana)
  int _pendingCount = 0;

  // ── Getters ──────────────────────────────────────────────────────────────
  List<Note> get allNotes => List.unmodifiable(_notes);
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<GroupBy> get groupingOrder => List.unmodifiable(_groupingOrder);
  Set<GroupBy> get activeGroupings => _groupingOrder.toSet();

  String? get activeFileType => _activeFileType;
  int? get activeCategoryId => _activeCategoryId;
  String? get activeDate => _activeDate;
  List<String> get availableTypes => List.unmodifiable(_availableTypes);
  List<String> get availableDays => List.unmodifiable(_availableDays);
  bool get isLoadingFilters => _isLoadingFilters;
  bool get hasActiveFilters =>
      _activeFileType != null || _activeCategoryId != null || _activeDate != null;
  int get pendingCount => _pendingCount;

  // ── Agrupación ────────────────────────────────────────────────────────────
  void toggleGrouping(GroupBy g) {
    if (_groupingOrder.contains(g)) {
      if (_groupingOrder.length > 1) _groupingOrder.remove(g);
    } else {
      _groupingOrder.add(g);
    }
    notifyListeners();
  }

  // ── Filtros ───────────────────────────────────────────────────────────────
  void setFileTypeFilter(String? fileType) {
    _activeFileType = fileType;
    loadNotes();
  }

  void setCategoryFilter(int? categoryId) {
    _activeCategoryId = categoryId;
    loadNotes();
  }

  void setDateFilter(String? date) {
    _activeDate = date;
    loadNotes();
  }

  void clearFilters() {
    _activeFileType = null;
    _activeCategoryId = null;
    _activeDate = null;
    loadNotes();
  }

  // ── Carga principal desde /captures ──────────────────────────────────────
  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await ApiService.getCaptures(
        date: _activeDate,
        categoryId: _activeCategoryId,
        fileType: _activeFileType,
        page: 0,
        size: 200,
      );
      final items = result['items'] as List<dynamic>? ?? [];
      final all = items
          .map((e) => Note.fromCaptureJson(e as Map<String, dynamic>))
          .toList();
      _notes = _activeCategoryId != null
          ? all
          : all.where((n) => n.categoryStatus == CategoryStatus.approved).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    // Actualizar badge sin bloquear la UI
    refreshPendingCount();
  }

  // ── Recarga solo el conteo de pendientes (badge campana) ─────────────────
  Future<void> refreshPendingCount({bool withDelay = false}) async {
    // Si viene de una creación nueva, esperamos a que el back procese IA/OCR
    if (withDelay) await Future.delayed(const Duration(seconds: 4));
    try {
      final result = await ApiService.getPendingCaptures(size: 100);
      final items = result['items'] as List<dynamic>? ?? [];
      _pendingCount = items.length;
      notifyListeners();
    } catch (_) {
      // Silencioso: el badge simplemente no se actualiza
    }
  }

  // ── Carga de metadatos de filtros (tipos usados + días disponibles) ───────
  Future<void> loadFilterMetadata() async {
    _isLoadingFilters = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        ApiService.getUsedCaptureTypes(),
        ApiService.getCaptureDays(page: 0, size: 60),
      ]);
      _availableTypes = results[0] as List<String>;
      final daysResult = results[1] as Map<String, dynamic>;
      final rawDays = daysResult['items'] as List<dynamic>? ?? [];
      _availableDays = rawDays.map((d) => d.toString()).toList();
    } catch (_) {
      // Silencioso: si falla, simplemente no hay filtros de metadatos
    } finally {
      _isLoadingFilters = false;
      notifyListeners();
    }
  }

  // ── Árbol de carpetas ─────────────────────────────────────────────────────
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
        if (key == '_uncategorized') return 'Sin categoría';
        try {
          return cats.firstWhere((c) => c.id == key).name;
        } catch (_) {
          return key;
        }
      case GroupBy.type:
        const labels = {
          'audio': '🎙️ Audio',
          'text': '📝 Texto',
          'image': '🖼️ Imagen',
          'link': '🔗 Enlace',
        };
        return labels[key] ?? key;
      case GroupBy.date:
        final parts = key.split('-');
        if (parts.length < 3) return key;
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
    if (diff < 7) return 'Hace $diff días';
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

import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';

class CategoriesProvider extends ChangeNotifier {
  // Paleta de colores para asignar a categorías del backend (sin color propio)
  static const List<String> _palette = [
    '#FFFF5856', // rojo coral Kelea
    '#FF4C9FE0', // azul cielo
    '#FF56C288', // verde menta
    '#FFFFC107', // ámbar
    '#FFE040FB', // morado
    '#FFFF7043', // naranja
    '#FF26C6DA', // cian
    '#FFEF5350', // rojo vivo
    '#FF66BB6A', // verde hoja
    '#FFAB47BC', // lila
  ];

  // ── Categorías cargadas desde el backend ─────────────────────────────────
  final List<Category> _backendCategories = [];
  bool _isLoadingCategories = false;

  // ── Categorías por defecto (pantalla de selección inicial) ───────────────
  static final List<Category> _defaultCategories = [
    Category(id: 'work',      name: '💼 Trabajo',         color: '#FFFF5856', isDefault: true),
    Category(id: 'hobbies',   name: '🎮 Pasatiempos',      color: '#FF4C9FE0', isDefault: true),
    Category(id: 'learning',  name: '📚 Aprendizaje',      color: '#FF56C288', isDefault: true),
    Category(id: 'projects',  name: '🚀 Proyectos',        color: '#FFFFC107', isDefault: true),
    Category(id: 'health',    name: '💪 Salud & Bienestar', color: '#FFE040FB', isDefault: true),
    Category(id: 'family',    name: '👨‍👩‍👧‍👦 Familia',         color: '#FFFF7043', isDefault: true),
    Category(id: 'shopping',  name: '🛍️ Compras & Regalos', color: '#FF26C6DA', isDefault: true),
    Category(id: 'food',      name: '🍽️ Comida',            color: '#FFEF5350', isDefault: true),
    Category(id: 'finances',  name: '💰 Finanzas',          color: '#FF66BB6A', isDefault: true),
    Category(id: 'trips',     name: '✈️ Viajes',            color: '#FFAB47BC', isDefault: true),
  ];

  final List<Category> _defaultCategories$ = List.unmodifiable(_defaultCategories);
  final List<Category> _customCategories = [];
  List<String> _selectedCategoryIds = [];
  String _newCategoryName = '';
  bool _showAddDialog = false;
  String? _error;
  bool _isLoading = false;
  bool _isSyncingCategories = false;

  // ── Getters ─────────────────────────────────────────────────────────────────
  List<Category> get defaultCategories => _defaultCategories$;
  List<Category> get customCategories => _customCategories;
  List<String> get selectedCategoryIds => _selectedCategoryIds;
  String get newCategoryName => _newCategoryName;
  bool get showAddDialog => _showAddDialog;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isSyncingCategories => _isSyncingCategories;
  bool get isLoadingCategories => _isLoadingCategories;

  /// Devuelve las categorías reales del backend si ya se cargaron;
  /// si no, devuelve las locales (default + custom) como fallback.
  List<Category> getAllCategories() {
    if (_backendCategories.isNotEmpty) return List.unmodifiable(_backendCategories);
    return [..._defaultCategories$, ..._customCategories];
  }

  List<Category> getSelectedCategories() => getAllCategories()
      .where((cat) => _selectedCategoryIds.contains(cat.id))
      .toList();

  // ── Carga de categorías desde el backend ─────────────────────────────────
  /// Llama a GET /categories y reemplaza la lista local con la del servidor.
  Future<void> loadFromBackend() async {
    if (_isLoadingCategories) return;
    _isLoadingCategories = true;
    notifyListeners();

    try {
      final raw = await ApiService.getCategories();
      _backendCategories.clear();
      for (int i = 0; i < raw.length; i++) {
        final item = raw[i];
        final id = item['id']?.toString() ?? 'cat_$i';
        final name = item['name'] as String? ?? 'Categoría';
        final color = _palette[i % _palette.length];
        _backendCategories.add(Category(id: id, name: name, color: color));
      }
    } catch (_) {
      // Si falla, seguimos con las locales silenciosamente
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  void toggleCategorySelection(String categoryId) {
    if (_selectedCategoryIds.contains(categoryId)) {
      _selectedCategoryIds.remove(categoryId);
    } else {
      _selectedCategoryIds.add(categoryId);
    }
    notifyListeners();
  }

  void showAddCategoryDialog() {
    _showAddDialog = true;
    _newCategoryName = '';
    _error = null;
    notifyListeners();
  }

  void hideAddCategoryDialog() {
    _showAddDialog = false;
    _newCategoryName = '';
    _error = null;
    notifyListeners();
  }

  void updateNewCategoryName(String name) {
    _newCategoryName = name;
    _error = null;
    notifyListeners();
  }

  Future<void> addCustomCategory() async {
    if (_newCategoryName.trim().isEmpty) {
      _error = 'El nombre de la categoría no puede estar vacío';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Intentar enviar al backend
      await ApiService.createCategory(_newCategoryName.trim());

      // Si es exitoso, agregar a la lista local
      final newCategory = Category(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: _newCategoryName.trim(),
        color: _generateRandomColor(),
        isDefault: false,
      );

      _customCategories.add(newCategory);
      _selectedCategoryIds.add(newCategory.id);
      _newCategoryName = '';
      _showAddDialog = false;
      _error = null;
      _isLoading = false;
      notifyListeners();
    } on BadRequestException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } on TimeoutException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } on NetworkException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } on ServerException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error inesperado: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  void deleteCustomCategory(String categoryId) {
    _customCategories.removeWhere((cat) => cat.id == categoryId);
    _selectedCategoryIds.remove(categoryId);
    notifyListeners();
  }

  void setSelectedCategories(List<String> categoryIds) {
    _selectedCategoryIds = categoryIds;
    notifyListeners();
  }

  void clearAllSelections() {
    _selectedCategoryIds.clear();
    notifyListeners();
  }

  String _generateRandomColor() {
    return '#FFFF5856'; // Rojo coral Kelea - Color del botón
  }


  /// Sincroniza las categorías seleccionadas con el backend.
  /// Envía los IDs/nombres de todas las categorías seleccionadas al servidor.
  Future<bool> syncSelectedCategoriesToBackend() async {
    _isSyncingCategories = true;
    _error = null;
    notifyListeners();

    try {
      final selectedCategories = getSelectedCategories();

      if (selectedCategories.isEmpty) {
        _error = 'Selecciona al menos una categoría';
        _isSyncingCategories = false;
        notifyListeners();
        return false;
      }

      // Enviar cada categoría seleccionada al backend (default y personalizadas)
      for (final category in selectedCategories) {
        try {
          await ApiService.createCategory(category.name);
        } on BadRequestException catch (e) {
          // Si la categoría ya existe en el servidor, continuamos con la siguiente
          if (e.message.toLowerCase().contains('duplicada') ||
              e.message.toLowerCase().contains('existe') ||
              e.message.toLowerCase().contains('duplicate') ||
              e.message.toLowerCase().contains('already')) {
            continue;
          }
          _error = e.message;
          _isSyncingCategories = false;
          notifyListeners();
          return false;
        } on TimeoutException catch (e) {
          _error = e.message;
          _isSyncingCategories = false;
          notifyListeners();
          return false;
        } on NetworkException catch (e) {
          _error = e.message;
          _isSyncingCategories = false;
          notifyListeners();
          return false;
        } on ServerException catch (e) {
          _error = e.message;
          _isSyncingCategories = false;
          notifyListeners();
          return false;
        }
      }

      _isSyncingCategories = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error inesperado: ${e.toString()}';
      _isSyncingCategories = false;
      notifyListeners();
      return false;
    }
  }
}


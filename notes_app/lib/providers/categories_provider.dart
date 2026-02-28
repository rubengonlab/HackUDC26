import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';

class CategoriesProvider extends ChangeNotifier {
  static final List<Category> _defaultCategories = [
    Category(
      id: 'work',
      name: '💼 Trabajo',
      color: '#FFFF5856',
      isDefault: true,
    ),
    Category(
      id: 'hobbies',
      name: '🎮 Pasatiempos',
      color: '#FFFF5856',
      isDefault: true,
    ),
    Category(
      id: 'learning',
      name: '📚 Aprendizaje',
      color: '#FFFF5856',
      isDefault: true,
    ),
    Category(
      id: 'projects',
      name: '🚀 Proyectos',
      color: '#FFFF5856',
      isDefault: true,
    ),
    Category(
      id: 'health',
      name: '💪 Salud & Bienestar',
      color: '#FFFF5856',
      isDefault: true,
    ),
    Category(
      id: 'family',
      name: '👨‍ Familia',
      color: '#FFFF5856',
      isDefault: true,
    ),
    Category(
      id: 'shopping',
      name: '🛍️ Compras & Regalos',
      color: '#FFFF5856',
      isDefault: true,
    ),
    Category(
      id: 'food',
      name: '🍽️ Comida',
      color: '#FFFF5856',
      isDefault: true,
    ),
    Category(
      id: 'finances',
      name: '💰 Finanzas',
      color: '#FFFF5856',
      isDefault: true,
    ),
    Category(
      id: 'trips',
      name: '✈️ Viajes',
      color: '#FFFF5856',
      isDefault: true,
    ),
  ];

  final List<Category> _defaultCategories$ = List.unmodifiable(_defaultCategories);
  final List<Category> _customCategories = [];
  List<String> _selectedCategoryIds = [];
  String _newCategoryName = '';
  bool _showAddDialog = false;
  String? _error;
  bool _isLoading = false;
  bool _isSyncingCategories = false;

  // Getters
  List<Category> get defaultCategories => _defaultCategories$;
  List<Category> get customCategories => _customCategories;
  List<String> get selectedCategoryIds => _selectedCategoryIds;
  String get newCategoryName => _newCategoryName;
  bool get showAddDialog => _showAddDialog;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isSyncingCategories => _isSyncingCategories;

  List<Category> getAllCategories() =>
      [..._defaultCategories$, ..._customCategories];

  List<Category> getSelectedCategories() => getAllCategories()
      .where((cat) => _selectedCategoryIds.contains(cat.id))
      .toList();

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


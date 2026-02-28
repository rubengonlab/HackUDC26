import 'package:flutter/material.dart';
import '../models/index.dart';

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
      name: '👨‍👩‍👧‍👦 Familia',
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

  final List<Category> _defaultCategories$ = _defaultCategories;
  final List<Category> _customCategories = [];
  List<String> _selectedCategoryIds = [];
  String _newCategoryName = '';
  bool _showAddDialog = false;
  String? _error;

  // Getters
  List<Category> get defaultCategories => _defaultCategories$;
  List<Category> get customCategories => _customCategories;
  List<String> get selectedCategoryIds => _selectedCategoryIds;
  String get newCategoryName => _newCategoryName;
  bool get showAddDialog => _showAddDialog;
  String? get error => _error;

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

  void addCustomCategory() {
    if (_newCategoryName.trim().isEmpty) {
      _error = 'El nombre de la categoría no puede estar vacío';
      notifyListeners();
      return;
    }

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
    notifyListeners();
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
}


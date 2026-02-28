import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../widgets/categories/index.dart';
import '../../widgets/common/index.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F4D), // Azul oscuro Kelea
      appBar: AppBar(
        title: const Text(
          'Mis Categorías',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1A1F4D),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCategoryDialog(context);
        },
        backgroundColor: const Color(0xFFFF5856), // Rojo coral Kelea
        tooltip: 'Agregar categoría',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<CategoriesProvider>(
        builder: (context, categoriesProvider, _) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instrucción con estilo Kelea
                  Text(
                    'Selecciona al menos una categoría para continuar',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),

                  const SizedBox(height: 24),

                  // Sección de categorías predeterminadas
                  _buildCategorySection(
                    title: 'Categorías Principales',
                    categories: categoriesProvider.defaultCategories,
                    provider: categoriesProvider,
                    isDeletable: false,
                  ),

                  const SizedBox(height: 32),

                  // Sección de categorías personalizadas
                  if (categoriesProvider.customCategories.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategorySection(
                          title: 'Mis Categorías',
                          categories: categoriesProvider.customCategories,
                          provider: categoriesProvider,
                          isDeletable: true,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),

                  // Botón de continuar con estilo Kelea
                  CustomButton(
                    text: 'Continuar',
                    onPressed: categoriesProvider.selectedCategoryIds.isEmpty
                        ? null
                        : () {
                            context.push('/notes');
                          },
                    isPrimary: true,
                    isEnabled:
                        categoriesProvider.selectedCategoryIds.isNotEmpty,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required List<Category> categories,
    required CategoriesProvider provider,
    required bool isDeletable,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFFFF5856), // Rojo coral para títulos
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: categories.map((category) {
            return CategoryChip(
              category: category,
              isSelected:
                  provider.selectedCategoryIds.contains(category.id),
              onTap: () {
                provider.toggleCategorySelection(category.id);
              },
              isDeletable: isDeletable,
              onDelete: () {
                provider.deleteCustomCategory(category.id);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Consumer<CategoriesProvider>(
          builder: (context, categoriesProvider, _) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1F4D), // Fondo azul oscuro
              title: Text(
                'Nueva Categoría',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              content: TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nombre de categoría',
                  labelStyle: const TextStyle(
                    color: Color(0xFFFF5856),
                    fontWeight: FontWeight.w500,
                  ),
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF5856),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF5856),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF5856),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  categoriesProvider.updateNewCategoryName(value);
                },
              ),
              // Mostrar error si existe
              actions: [
                if (categoriesProvider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5856).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: const Border.fromBorderSide(
                          BorderSide(color: Color(0xFFFF5856), width: 1),
                        ),
                      ),
                      child: Text(
                        categoriesProvider.error!,
                        style: const TextStyle(
                          color: Color(0xFFFF5856),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    categoriesProvider.hideAddCategoryDialog();
                  },
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5856),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    categoriesProvider.addCustomCategory();
                    if (context.mounted && categoriesProvider.error == null) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}




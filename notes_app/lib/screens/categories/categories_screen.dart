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
      floatingActionButton: Consumer<CategoriesProvider>(
        builder: (context, categoriesProvider, _) {
          return FloatingActionButton(
            onPressed: categoriesProvider.isSyncingCategories
                ? null
                : () => _showAddCategoryDialog(context),
            backgroundColor: categoriesProvider.isSyncingCategories
                ? const Color(0xFFFF5856).withValues(alpha: 0.4)
                : const Color(0xFFFF5856),
            tooltip: 'Agregar categoría',
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
      body: Consumer<CategoriesProvider>(
        builder: (context, categoriesProvider, _) {
          return Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
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
                        title: 'Categorías Sugeridas',
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
                        onPressed: () async {
                          if (categoriesProvider.selectedCategoryIds.isEmpty ||
                              categoriesProvider.isSyncingCategories) {
                            return;
                          }

                          final success = await categoriesProvider
                              .syncSelectedCategoriesToBackend();

                          if (!context.mounted) return;

                          if (success) {
                            context.push('/notes');
                          } else if (categoriesProvider.error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  categoriesProvider.error!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: const Color(0xFFFF5856),
                                duration: const Duration(seconds: 5),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        },
                        isPrimary: true,
                        isLoading: categoriesProvider.isSyncingCategories,
                        isEnabled: categoriesProvider.selectedCategoryIds.isNotEmpty,
                        width: double.infinity,
                      ),
                    ],
                  ),
                ),
              ),
              // Overlay de carga mientras se sincronizan categorías
              if (categoriesProvider.isSyncingCategories)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFFF5856)),
                        SizedBox(height: 16),
                        Text(
                          'Guardando categorías...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 12,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
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
          },
        ),
      ],
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    context.read<CategoriesProvider>().hideAddCategoryDialog();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AddCategoryDialog(),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget stateful dedicado al diálogo: gestiona el controller con su propio
// ciclo de vida, evitando dispose manuales y el crash de dependents.isEmpty
// ---------------------------------------------------------------------------
class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog();

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit(CategoriesProvider provider) async {
    if (provider.isLoading) return;
    await provider.addCustomCategory();
    if (!mounted) return;
    if (provider.error == null) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoriesProvider>(
      builder: (context, provider, _) {
        return PopScope(
          canPop: !provider.isLoading,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1A1F4D),
            title: Text(
              'Nueva Categoría',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    maxLength: 15,
                    maxLines: 1,
                    autofocus: true,
                    enabled: !provider.isLoading,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(provider),
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
                      counterStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                      errorText: provider.error,
                      errorStyle: const TextStyle(color: Color(0xFFFF5856)),
                    ),
                    onChanged: provider.updateNewCategoryName,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: provider.isLoading
                    ? null
                    : () {
                        provider.hideAddCategoryDialog();
                        Navigator.pop(context);
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
                  disabledBackgroundColor: const Color(0xFFFF5856),
                  disabledForegroundColor: Colors.white,
                ),
                onPressed: provider.isLoading ? () {} : () => _submit(provider),
                child: provider.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Crear'),
              ),
            ],
          ),
        );
      },
    );
  }
}




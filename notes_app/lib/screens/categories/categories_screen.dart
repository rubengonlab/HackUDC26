/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
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
  static const _kPrimary = Color(0xFFFF5856);
  static const _kBg = Color(0xFF1A1F4D);
  static const _kSurface = Color(0xFF252B5C);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesProvider>().loadFromBackend();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        // Sin título: el encabezado vive dentro del body para más impacto visual
        title: const SizedBox.shrink(),
      ),
      body: Consumer<CategoriesProvider>(
        builder: (context, categoriesProvider, _) {
          final selectedCount = categoriesProvider.selectedCategoryIds.length;

          return Stack(
            children: [
              // ── Layout principal: encabezado + scroll + barra inferior ──
              Column(
                children: [
                  // Encabezado fijo
                  _buildHeader(selectedCount),

                  // Zona scrollable con las categorías
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        // ── Categorías sugeridas ──────────────────────────
                        SliverToBoxAdapter(
                          child: _buildSectionTitle(
                            icon: Icons.auto_awesome,
                            title: 'Sugeridas',
                            subtitle: 'Elige las que mejor describan tus notas',
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: _buildCategoryGrid(
                            categories: categoriesProvider.defaultCategories,
                            provider: categoriesProvider,
                            isDeletable: false,
                          ),
                        ),

                        // ── Categorías personalizadas ─────────────────────
                        if (categoriesProvider.customCategories.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: _buildSectionTitle(
                              icon: Icons.edit_note,
                              title: 'Creadas por ti',
                              subtitle: 'Tus categorías personalizadas',
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: _buildCategoryGrid(
                              categories: categoriesProvider.customCategories,
                              provider: categoriesProvider,
                              isDeletable: true,
                            ),
                          ),
                        ],

                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      ],
                    ),
                  ),

                  // ── Barra inferior fija ───────────────────────────────────
                  _buildBottomBar(context, categoriesProvider, selectedCount),
                ],
              ),

              // ── Overlay de carga ──────────────────────────────────────────
              if (categoriesProvider.isSyncingCategories)
                Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: _kPrimary),
                        SizedBox(height: 16),
                        Text(
                          'Guardando tus categorías…',
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

  // ── Encabezado ─────────────────────────────────────────────────────────────
  Widget _buildHeader(int selectedCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🗂️', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Organiza tus notas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'con categorías',
                      style: TextStyle(
                        color: _kPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Cada nota que crees se clasificará automáticamente en las categorías que elijas ahora. Puedes cambiarlas cuando quieras.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          // Contador de selección
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selectedCount > 0
                  ? _kPrimary.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: selectedCount > 0
                    ? _kPrimary.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selectedCount > 0 ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16,
                  color: selectedCount > 0 ? _kPrimary : Colors.white38,
                ),
                const SizedBox(width: 8),
                Text(
                  selectedCount == 0
                      ? 'Ninguna seleccionada aún'
                      : selectedCount == 1
                          ? '1 categoría seleccionada'
                          : '$selectedCount categorías seleccionadas',
                  style: TextStyle(
                    color: selectedCount > 0 ? _kPrimary : Colors.white38,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Título de sección ───────────────────────────────────────────────────────
  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Icon(icon, color: _kPrimary, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Grid de categorías como Sliver ──────────────────────────────────────────
  Widget _buildCategoryGrid({
    required List<Category> categories,
    required CategoriesProvider provider,
    required bool isDeletable,
  }) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final category = categories[index];
          return CategoryChip(
            category: category,
            isSelected: provider.selectedCategoryIds.contains(category.id),
            onTap: () => provider.toggleCategorySelection(category.id),
            isDeletable: isDeletable,
            onDelete: () => provider.deleteCustomCategory(category.id),
          );
        },
        childCount: categories.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
    );
  }

  // ── Barra inferior fija ─────────────────────────────────────────────────────
  Widget _buildBottomBar(
    BuildContext context,
    CategoriesProvider categoriesProvider,
    int selectedCount,
  ) {
    final canContinue =
        selectedCount > 0 && !categoriesProvider.isSyncingCategories;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: _kBg,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Botón principal "Continuar" — ocupa todo el espacio disponible
                Expanded(
                  child: CustomButton(
                    text: canContinue
                        ? 'Empezar con $selectedCount ${selectedCount == 1 ? 'categoría' : 'categorías'} →'
                        : 'Selecciona una categoría',
                    onPressed: () async {
                      if (!canContinue) return;
                      final success =
                          await categoriesProvider.syncSelectedCategoriesToBackend();
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
                                  fontWeight: FontWeight.w500),
                            ),
                            backgroundColor: _kPrimary,
                            duration: const Duration(seconds: 5),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                    isPrimary: true,
                    isLoading: categoriesProvider.isSyncingCategories,
                    isEnabled: canContinue,
                  ),
                ),

                const SizedBox(width: 12),

                // Botón "Nueva categoría" — abajo a la derecha, tamaño fijo
                FloatingActionButton(
                  heroTag: 'add_category_fab',
                  onPressed: categoriesProvider.isSyncingCategories
                      ? null
                      : () => _showAddCategoryDialog(context),
                  backgroundColor: categoriesProvider.isSyncingCategories
                      ? _kPrimary.withValues(alpha: 0.4)
                      : _kSurface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: _kPrimary.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  tooltip: 'Nueva categoría',
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),

            // Aviso debajo cuando no hay selección
            if (selectedCount == 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Selecciona al menos una categoría para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
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




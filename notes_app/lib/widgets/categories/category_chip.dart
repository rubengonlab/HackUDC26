import 'package:flutter/material.dart';
import '../../models/index.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDeletable;
  final VoidCallback? onDelete;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.isDeletable = false,
    this.onDelete,
  });

  Color _parseColor(String colorString) {
    final String colorStr =
        colorString.replaceAll('#', '').replaceAll('FF', '');
    return Color(int.parse('FF$colorStr', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(category.color);
    final backgroundColor = color;
    final textColor = Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            // Contenido principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Nombre de la categoría en mayúsculas
                  Text(
                    category.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                  // Checkmark si está seleccionado
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            // Botón de eliminar si es deletable
            if (isDeletable && !category.isDefault)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: backgroundColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


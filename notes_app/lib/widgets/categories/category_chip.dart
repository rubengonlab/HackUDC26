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
    final backgroundColor =
        isSelected ? color : color.withValues(alpha: 0.2);
    final textColor = isSelected ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.check, size: 18, color: textColor),
              ),
            Text(
              category.name,
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isDeletable && !category.isDefault)
              GestureDetector(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: textColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


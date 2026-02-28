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
    final String hex = colorString.replaceAll('#', '');
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    } else if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return const Color(0xFFFF5856);
  }

  /// Extrae el emoji inicial del nombre si existe (ej: "💼 Trabajo" → "💼")
  String? _extractEmoji(String name) {
    final runes = name.runes.toList();
    if (runes.isNotEmpty) {
      final firstChar = String.fromCharCode(runes[0]);
      // Los emojis tienen codepoint > 127
      if (runes[0] > 127) return firstChar;
    }
    return null;
  }

  /// Elimina el emoji y el espacio al inicio del nombre
  String _cleanName(String name) {
    final runes = name.runes.toList();
    if (runes.isNotEmpty && runes[0] > 127) {
      // Salta el emoji (puede ocupar 2 codepoints para emojis compuestos)
      int skip = 1;
      if (runes.length > 1 && runes[1] == 0x200D) skip = 3; // ZWJ sequences
      final stripped = String.fromCharCodes(runes.skip(skip)).trimLeft();
      return stripped;
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _parseColor(category.color);
    final emoji = _extractEmoji(category.name);
    final cleanName = _cleanName(category.name);

    // No seleccionado: fondo oscuro semitransparente
    // Seleccionado: fondo sólido con accentColor
    final bgColor = isSelected
        ? accentColor
        : const Color(0xFF1A1F4D);

    final borderColor = isSelected
        ? Colors.white.withValues(alpha: 0.9)
        : accentColor.withValues(alpha: 0.5);

    return AnimatedScale(
      scale: isSelected ? 1.04 : 1.0,
      duration: const Duration(milliseconds: 180),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1.5),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.45),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              // Contenido principal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    // Emoji en círculo
                    if (emoji != null)
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 17)),
                        ),
                      ),
                    if (emoji != null) const SizedBox(width: 8),
                    // Nombre
                    Expanded(
                      child: Text(
                        cleanName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.75),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Check en esquina superior derecha cuando está seleccionado
              if (isSelected)
                Positioned(
                  top: 5,
                  right: isDeletable ? 22 : 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 12,
                      color: accentColor,
                    ),
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
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        Icons.close,
                        size: 11,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

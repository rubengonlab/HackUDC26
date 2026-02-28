import 'package:flutter/material.dart';

class AppTheme {
  // Colores de Kelea - Azul oscuro y Rojo Coral
  static const Color _primaryColor = Color(0xFF1A1F4D);    // Azul oscuro Kelea
  static const Color _accentColor = Color(0xFFFF5856);     // Rojo coral Kelea
  static const Color _backgroundColor = Color(0xFFF8F9FB); // Blanco muy suave
  static const Color _surfaceColor = Color(0xFFFFFFFF);    // Blanco puro
  static const Color _borderColor = Color(0xFFE8EDF2);     // Gris muy claro
  static const Color _textColor = Color(0xFF1A1F4D);       // Texto en azul oscuro
  static const Color _textSecondary = Color(0xFF6B7280);   // Gris medio
  static const Color _errorColor = Color(0xFFFF5856);      // Rojo coral para errores

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: _primaryColor,
      secondary: _accentColor,
      tertiary: _accentColor,
      error: _errorColor,
      surface: _surfaceColor,
      outline: _borderColor,
    ),
    scaffoldBackgroundColor: _backgroundColor,

    // AppBar minimalista
    appBarTheme: AppBarTheme(
      backgroundColor: _surfaceColor,
      foregroundColor: _textColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: _textColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),

    // Botones elegantes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: _borderColor, width: 1),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Inputs elegantes
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(
        color: _textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: _textSecondary.withValues(alpha: 0.6),
        fontSize: 14,
      ),
    ),

    // FAB minimalista
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Cards elegantes
    cardTheme: CardThemeData(
      color: _surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _borderColor, width: 1),
      ),
    ),

    // Tipografía minimalista
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: _textColor,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: _textColor,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _textColor,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _textColor,
        letterSpacing: 0.25,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _textColor,
        letterSpacing: 0.15,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: _textColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _textColor,
        height: 1.43,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _textSecondary,
        letterSpacing: 0.4,
      ),
    ),
  );
}


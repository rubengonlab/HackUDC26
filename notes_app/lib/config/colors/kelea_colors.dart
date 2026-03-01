/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
// Constantes de Colores Kelea para usar en la aplicación
// Coloca este archivo en lib/config/colors/kelea_colors.dart

import 'package:flutter/material.dart';

class KeleaColors {
  // Colores primarios
  static const Color primaryBlue = Color(0xFF1A1F4D);    // Azul oscuro Kelea
  static const Color accentRed = Color(0xFFFF5856);      // Rojo coral Kelea

  // Colores neutros
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8F9FB);
  static const Color borderLight = Color(0xFFE8EDF2);
  static const Color textSecondary = Color(0xFF6B7280);

  // Gradientes (opcionales)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, accentRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Paleta extendida para estados
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}

// Ejemplos de uso:
/*
// Usar en Text
Text(
  'Hola',
  style: TextStyle(color: KeleaColors.primaryBlue),
)

// Usar en Container
Container(
  color: KeleaColors.accentRed,
  child: ...,
)

// Usar en Icon
Icon(
  Icons.home,
  color: KeleaColors.accentRed,
)

// Usar gradiente
Container(
  decoration: BoxDecoration(
    gradient: KeleaColors.primaryGradient,
  ),
)
*/


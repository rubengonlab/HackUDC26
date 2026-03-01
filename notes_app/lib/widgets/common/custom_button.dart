/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final bool isEnabled;
  final double? width;
  final double? height;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.isEnabled = true,
    this.width,
    this.height,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Cuando isLoading=true: pasamos un callback vacío (no null) para que el botón
    // mantenga su color activo y muestre el spinner. La guard dentro de onPressed
    // del llamador ya previene la doble ejecución.
    // Cuando !isEnabled: null para mostrar el estado deshabilitado.
    VoidCallback? resolvedOnPressed;
    if (!isEnabled) {
      resolvedOnPressed = null;
    } else if (isLoading) {
      resolvedOnPressed = () {}; // bloqueado visualmente por el spinner
    } else {
      resolvedOnPressed = onPressed;
    }

    final button = isPrimary
        ? ElevatedButton(
            onPressed: resolvedOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5856),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFFF5856).withValues(alpha: 0.5),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _buildButtonContent(),
          )
        : OutlinedButton(
            onPressed: resolvedOnPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF5856),
              disabledForegroundColor: const Color(0xFFFF5856).withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide(
                color: const Color(0xFFFF5856),
                width: 1.5,
              ),
            ),
            child: _buildButtonContent(),
          );

    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: isPrimary ? Colors.white : const Color(0xFFFF5856),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}


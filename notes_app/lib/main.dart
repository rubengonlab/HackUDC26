/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme/index.dart';
import 'config/routes/index.dart';
import 'providers/index.dart';

// Instancias globales de los providers
final authProvider = AuthProvider();
final categoriesProvider = CategoriesProvider();
final notesProvider = NotesProvider();

void main() {
  // Bloquear la orientación a solo Portrait (sin permitir rotación inversa)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: categoriesProvider),
        ChangeNotifierProvider.value(value: notesProvider),
      ],
      child: MaterialApp.router(
        title: 'Reciclador de Ideas',
        theme: AppTheme.lightTheme,
        routerConfig: createRouter(authProvider),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}


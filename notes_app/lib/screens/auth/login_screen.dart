/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/index.dart';
import '../../widgets/common/index.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late FocusNode _usernameFocus;
  late FocusNode _passwordFocus;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _usernameFocus = FocusNode();
    _passwordFocus = FocusNode();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _doLogin(AuthProvider authProvider) async {
    if (authProvider.isLoading) return;
    FocusScope.of(context).unfocus();
    await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );
  }

  InputDecoration _fieldDecoration({required String label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(
        color: Color(0xFF1A1F4D),
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: const Color(0xFF1A1F4D).withValues(alpha: 0.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFF5856), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFF5856), width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFF5856), width: 2.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F4D),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Logo
                    Center(
                      child: Image.asset(
                        'assets/images/LoginIcon.png',
                        width: 220,
                        height: 147,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(height: 60),

                    Text(
                      '¡Bienvenido!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Inicia sesión para acceder a tus notas',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),

                    const SizedBox(height: 48),

                    // Campo usuario
                    TextField(
                      controller: _usernameController,
                      focusNode: _usernameFocus,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !authProvider.isLoading,
                      onSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_passwordFocus),
                      decoration: _fieldDecoration(
                        label: 'Usuario',
                        hint: 'tu@usuario.com',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Campo contraseña
                    TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      enabled: !authProvider.isLoading,
                      onSubmitted: (_) => _doLogin(authProvider),
                      decoration: _fieldDecoration(
                        label: 'Contraseña',
                        hint: '••••••••',
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Mensaje de error
                    if (authProvider.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5856).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: const Border.fromBorderSide(
                            BorderSide(color: Color(0xFFFF5856), width: 1),
                          ),
                        ),
                        child: Text(
                          authProvider.error!,
                          style: const TextStyle(
                            color: Color(0xFFFF5856),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Botón de login (el spinner lo gestiona isLoading en CustomButton)
                    CustomButton(
                      text: 'Iniciar Sesión',
                      onPressed: () => _doLogin(authProvider),
                      isLoading: authProvider.isLoading,
                      width: double.infinity,
                    ),

                    const SizedBox(height: 40),

                    Center(
                      child: Text(
                        'MVP Demo: cualquier usuario y contraseña',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}


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

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F4D), // Azul oscuro Kelea
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
                    // Espaciador superior
                    const SizedBox(height: 40),

                    // Logo de Kelea
                    Center(
                      child: Image.asset(
                        'assets/images/Designer.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Título
                    Text(
                      'Kelea Notes',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                    ),

                    const SizedBox(height: 12),

                    // Subtítulo
                    Text(
                      'Inicia sesión para acceder a tus notas',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),

                    const SizedBox(height: 48),

                    // Username Field con borde rojo y relleno blanco
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Usuario',
                        hintText: 'tu@usuario.com',
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
                          borderSide: const BorderSide(
                            color: Color(0xFFFF5856),
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF5856),
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF5856),
                            width: 2.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Password Field con borde rojo y relleno blanco
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        hintText: '••••••••',
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
                          borderSide: const BorderSide(
                            color: Color(0xFFFF5856),
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF5856),
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF5856),
                            width: 2.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Error Message
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

                    // Login Button
                    CustomButton(
                      text: authProvider.isLoading ? 'Cargando...' : 'Iniciar Sesión',
                      onPressed: () async {
                        await authProvider.login(
                          _usernameController.text,
                          _passwordController.text,
                        );
                      },
                      isLoading: authProvider.isLoading,
                      width: double.infinity,
                    ),

                    const SizedBox(height: 40),

                    // Info text
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


// fichier: lib/admin/admin_login_page.dart

import 'package:flutter/material.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      // --- Simulation du Backend ---
      // Dans une vraie application, vous feriez un appel HTTP ici.
      // On simule une attente de 1 seconde.
      await Future.delayed(const Duration(seconds: 1));

      // On prétend que le login a réussi et que le backend nous a renvoyé un token et un rôle.
      final fakeToken = 'admin-token-12345';
      final fakeRole = 'admin'; // ou 'super_admin'

      if (!mounted) return;

      // On navigue vers la page principale de l'admin en passant le token et le rôle.
      Navigator.pushReplacementNamed(
        context,
        '/admin/shell',
        arguments: {'token': fakeToken, 'role': fakeRole},
      );
      // --- Fin de la simulation ---

      setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accès Administrateur"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', height: 80),
                const SizedBox(height: 24),
                const Text(
                  'Bienvenue, Administrateur',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Veuillez vous connecter pour continuer.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez entrer un email';
                    if (!value.endsWith('@tibu.ma')) return 'L\'email doit se terminer par @tibu.ma';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez entrer un mot de passe';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: const Color(0xFF3575D3),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _login,
                        child: const Text('Se connecter'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
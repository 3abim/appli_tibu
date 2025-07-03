// main.dart

// --- IMPORTS CORRIGÉS ---
import 'package:appli_tibu/collaborateur_login_page.dart';
import 'package:flutter/material.dart';
import 'package:appli_tibu/collaborateur_dashboard.dart';
import 'package:appli_tibu/collaborateur_progress_page.dart';
import 'package:appli_tibu/settings_page.dart';
import 'package:appli_tibu/notifications_page.dart';
import 'package:appli_tibu/compte_page.dart';
import 'package:appli_tibu/admin_login_page.dart';
import 'package:appli_tibu/admin_shell_page.dart';
// Make sure that the file 'lib/admin/admin_shell_page.dart' exists and contains a class named 'AdminShellPage'

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Pour enlever la bannière "DEBUG"
      title: 'Step Up',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3575D3)),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0057B8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        // --- ROUTES PUBLIQUES ---
        '/': (context) => const WelcomePage(),
        '/register': (context) => const CollaborateurLoginPage(),
        '/admin-login': (context) => const AdminLoginPage(),

        // --- ROUTES COLLABORATEUR (privées) ---
        '/dashboard': (context) {
          final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final token = arguments?['token'] ?? '';
          return CollaborateurDashboard(token: token);
        },
        '/notifications': (context) => const NotificationsPage(),
        '/compte': (context) {
          final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ComptePage(
            nom: arguments['nom'],
            email: arguments['email'],
            entreprise: arguments['entreprise'],
          );
        },
        '/progress': (context) {
          final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return CollaborateurProgressPage(
            token: arguments['token'],
            nom: arguments['nom'],
            email: arguments['email'],
            entreprise: arguments['entreprise'],
            objectifPas: 10000,
            objectifCalories: 400,
            objectifDistance: 7.0,
          );
        },
        '/settings': (context) {
          final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return SettingsPage(
            token: arguments['token'],
            nom: arguments['nom'],
            email: arguments['email'],
            entreprise: arguments['entreprise'],
          );
        },

        // --- ROUTES ADMIN (privées) ---
        '/admin/shell': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return AdminShellPage(
            token: args['token'] ?? '',
            role: args['role'] ?? 'admin',
          );
        },
      },
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/welcome.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.3)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Chaque mouvement est un pas vers la réussite.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text('Commencer', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/admin-login');
                  },
                  child: const Text(
                    "Accès administrateur",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'collaborateur_login_page.dart';
import 'collaborateur_dashboard.dart';
import 'admin_login_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_shell_page.dart';
import 'settings_page.dart'; 
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Appli Tibu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3575D3)),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0057B8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/login': (context) => const CollaborateurLoginPage(),
        '/admin-login': (context) => const AdminLoginPage(),
        
        // Route Dashboard Collaborateur
        '/dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          
          // Gestion flexible des arguments
          String? token;
          if (args is Map<String, dynamic>) {
            token = args['token'] ?? (args['user'] as Map<String, dynamic>?)?['token'];
          }
          
          if (token != null) {
            return CollaborateurDashboard(token: token);
          }
          
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Session invalide", style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false),
                    child: const Text("Se reconnecter"),
                  ),
                ],
              ),
            ),
          );
        },
        
        // Route Admin
        '/admin/shell': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          return AdminShellPage(
            token: args['token'] ?? '',
            role: args['role'] ?? 'admin',
          );
        },
        
        // Routes supplémentaires conservées
        '/notifications': (context) => const NotificationsPage(),
        '/compte': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          return ComptePage(
            nom: args['nom'] ?? 'Non défini',
            email: args['email'] ?? '',
            entreprise: args['entreprise'] ?? '',
          );
        },
        '/progress': (context) => const CollaborateurProgressPage(),
        '/settings': (context) {
          // 1. On récupère les arguments
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

          return SettingsPage(
            token: args['token'] ?? '',
            nom: args['nom'] ?? 'Non défini',
            email: args['email'] ?? '',
            entreprise: args['entreprise'] ?? '',
          );
        },

      },
    );
  }
}

// Pages conservées inchangées
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Notifications")),
    body: const Center(child: Text("Page des notifications")),
  );
}

class ComptePage extends StatelessWidget {
  final String nom;
  final String email;
  final String entreprise;
  
  const ComptePage({
    super.key,
    required this.nom,
    required this.email,
    required this.entreprise,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Mon Compte")),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Nom: $nom", style: const TextStyle(fontSize: 18)),
          Text("Email: $email", style: const TextStyle(fontSize: 18)),
          Text("Entreprise: $entreprise", style: const TextStyle(fontSize: 18)),
        ],
      ),
    ),
  );
}

class CollaborateurProgressPage extends StatelessWidget {
  const CollaborateurProgressPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Mes Progrès")),
    body: const Center(child: Text("Page des progrès")),
  );
}

// Page d'accueil inchangée
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/welcome.png', fit: BoxFit.cover),
          Container(color: Colors.black.withAlpha(77)),
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
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Commencer', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/admin-login'),
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
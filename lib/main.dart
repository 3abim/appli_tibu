import 'package:appli_tibu/collaborateur_login_page.dart';
import 'package:flutter/material.dart';
import 'admin_login_page.dart';
import 'package:appli_tibu/collaborateur_dashboard.dart'; // Supposons que c'est le bon chemin
import 'package:appli_tibu/collaborateur_progress_page.dart';
import 'package:appli_tibu/settings_page.dart';
import 'package:appli_tibu/notifications_page.dart';
import 'package:appli_tibu/compte_page.dart';

// 2. FONCTION MAIN
void main() {
  runApp(const MyApp()); // On lance le widget principal MyApp
}

// 3. WIDGET PRINCIPAL DE L'APPLICATION
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Up',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3575D3)), // J'ai mis votre bleu
        useMaterial3: true,
        // Style global pour les boutons pour correspondre à votre design
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0057B8), // Votre couleur bleue principale
            foregroundColor: Colors.white, // Texte en blanc
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      // On commence sur la page de bienvenue
      initialRoute: '/',
      
      // 4. GESTION DES ROUTES (C'EST LA CORRECTION LA PLUS IMPORTANTE)
      // C'est ici qu'on définit comment naviguer entre les pages.
      routes: {
        '/': (context) => const WelcomePage(),
        '/register': (context) => const CollaborateurLoginPage(),
        '/admin-login': (context) => const AdminLoginPage(),
        
        // --- ROUTE DASHBOARD ---
        '/dashboard': (context) {
          // On récupère le token passé depuis la page de login
          final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final token = arguments?['token'] ?? ''; // Sécurité pour éviter le null
          return CollaborateurDashboard(token: token);
        },
        
        // --- ROUTE NOTIFICATIONS ---
        '/notifications': (context) => const NotificationsPage(),
        
        // --- ROUTE COMPTE ---
        '/compte': (context) {
          // On récupère les informations de l'utilisateur passées en argument
          final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ComptePage(
            nom: arguments['nom'],
            email: arguments['email'],
            entreprise: arguments['entreprise'],
          );
        },

        // --- ROUTE PROGRÈS ---
        '/progress': (context) {
  // On récupère les informations de l'utilisateur
  final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  
  // ET MAINTENANT ON LES UTILISE !
  return CollaborateurProgressPage(
    // On passe les vraies infos
    nom: arguments['nom'],
    email: arguments['email'],
    entreprise: arguments['entreprise'],

    // On peut garder les objectifs en dur pour le moment
    objectifPas: 10000,
    objectifCalories: 400,
    objectifDistance: 7.0,
  );
},

        // --- ROUTE RÉGLAGES ---
        '/settings': (context) {
          // On récupère les infos de l'utilisateur
          final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          // On les passe à la page SettingsPage qui en a besoin pour le bouton "Compte"
          return SettingsPage(
            nom: arguments['nom'],
            email: arguments['email'],
            entreprise: arguments['entreprise'],
          );
        },
      },
    );
  }
}

// 5. PAGE DE BIENVENUE (WelcomePage)
// Ce widget est correct, je le garde tel quel.
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
                  // Le style est maintenant défini dans le thème global
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
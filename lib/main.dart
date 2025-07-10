import 'package:flutter/material.dart';
import 'collaborateur_login_page.dart';
import 'collaborateur_dashboard.dart';
import 'admin_login_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_shell_page.dart';
import 'settings_page.dart';
import 'collaborateur_progress_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
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
        
        '/dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String? token;
          if (args is Map<String, dynamic>) {
            token = args['token'];
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
        
        '/admin/shell': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          return AdminShellPage(
            token: args['token'] ?? '',
            role: args['role'] ?? 'admin',
          );
        },
        
        '/notifications': (context) => const NotificationsPage(),
        '/compte': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          return ComptePage(
            nom: args['nom'] ?? 'Non défini',
            email: args['email'] ?? '',
            entreprise: args['entreprise'] ?? '',
          );
        },

        '/progress': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          return CollaborateurProgressPage(
            token: args['token'] ?? '',
            nom: args['nom'] ?? 'Non défini',
            email: args['email'] ?? '',
            entreprise: args['entreprise'] ?? '',
          );
        },

        '/settings': (context) {
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

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Notifications")),
    body: const Center(child: Text("Page des notifications")),
  );
}

class ComptePage extends StatefulWidget {
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
  State<ComptePage> createState() => _ComptePageState();
}

class _ComptePageState extends State<ComptePage> {
  late TextEditingController _nomController;
  late TextEditingController _emailController;
  late TextEditingController _entrepriseController;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.nom);
    _emailController = TextEditingController(text: widget.email);
    _entrepriseController = TextEditingController(text: widget.entreprise);
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _entrepriseController.dispose();
    super.dispose();
  }

  void _save() {
    // Ajoute ici la logique d'enregistrement (API, local, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modifications enregistrées !')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Mon Compte"),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
      automaticallyImplyLeading: false,
    ),
    body: Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFF0057B8),
                  child: Text(
                    _nomController.text.isNotEmpty
                        ? _nomController.text[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _entrepriseController,
                decoration: const InputDecoration(
                  labelText: 'Entreprise',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _launchInstagram() async {
    final Uri url = Uri.parse('https://www.instagram.com/tibuafrica');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/welcome.png', fit: BoxFit.cover),
        Container(color: Colors.black.withAlpha(77)),
        Column(
          children: [
            // Mets l'image tibu.png en haut
            const SizedBox(height: 48),
            Image.asset(
              'assets/tibu.png',
              height: 120,
            ),
            const Spacer(),
            // Contenu centralisé
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Chaque mouvement est un pas vers la réussite.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
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
            const Spacer(),
          ],
        ),
        // Icône Instagram en bas à gauche (ou à droite)
        Positioned(
          left: 24,
          bottom: 24,
          child: GestureDetector(
            onTap: _launchInstagram,
            child: Image.asset(
              'assets/instagram.png',
              height: 28,
            ),
          ),
        ),
      ],
    ),
  );
  }
}
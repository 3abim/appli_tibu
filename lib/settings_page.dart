import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Ajout de l'import http
import 'dart:convert'; // Ajout de l'import pour jsonEncode/jsonDecode

class SettingsPage extends StatefulWidget {
  final String token;
  final String nom;
  final String email;
  final String entreprise;

  const SettingsPage({
    super.key,
    required this.token,
    required this.nom,
    required this.email,
    required this.entreprise,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  // Les controllers pour les champs de texte
  late TextEditingController _pasQuotidienController;
  late TextEditingController _pasHebdomadaireController;
  late TextEditingController _pasMensuelController;
  late TextEditingController _caloriesController;
  late TextEditingController _distanceController;

  // Variables pour gérer l'état de chargement et les erreurs
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialisation des controllers. Un pour chaque champ.
    _pasQuotidienController = TextEditingController();
    _pasHebdomadaireController = TextEditingController();
    _pasMensuelController = TextEditingController();
    _caloriesController = TextEditingController();
    _distanceController = TextEditingController();

    // On charge les objectifs depuis le serveur au lieu de SharedPreferences
    _loadObjectivesFromServer();
  }

  // NOUVELLE FONCTION pour charger les données depuis le serveur
  Future<void> _loadObjectivesFromServer() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://10.0.2.2:9091/api/objectifs');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pasQuotidienController.text = (data['pasQuotidien'] ?? 0).toString();
          _pasHebdomadaireController.text = (data['pasHebdomadaire'] ?? 0).toString();
          _pasMensuelController.text = (data['pasMensuel'] ?? 0).toString();
          _caloriesController.text = (data['calories'] ?? 0).toString();
          _distanceController.text = (data['distanceKm'] ?? 0.0).toString();
        });
      } else {
        // Gérer l'erreur si le serveur ne répond pas correctement
        _showErrorDialog("Erreur de chargement", "Impossible de récupérer vos objectifs. Code: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("Erreur de connexion", "Vérifiez votre connexion internet et réessayez. Détails: ${e.toString()}");
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // FONCTION MISE À JOUR pour sauvegarder les données sur le serveur
  Future<void> _saveObjectives() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final body = jsonEncode({
        'pasQuotidien': int.parse(_pasQuotidienController.text),
        'pasHebdomadaire': int.parse(_pasHebdomadaireController.text),
        'pasMensuel': int.parse(_pasMensuelController.text),
        'calories': int.parse(_caloriesController.text),
        'distanceKm': double.parse(_distanceController.text),
      });

      try {
        final url = Uri.parse('http://10.0.2.2:9091/api/objectifs');
        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
          body: body,
        );

        if (response.statusCode == 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Objectifs sauvegardés avec succès !'), backgroundColor: Colors.green),
          );
        } else if (response.statusCode == 400) {
          final errorData = jsonDecode(response.body);
          final errors = (errorData['errors'] as List).join('\n');
          _showErrorDialog("Données invalides", errors);
        } else {
          _showErrorDialog("Erreur de sauvegarde", "Le serveur a répondu avec le code ${response.statusCode}.");
        }
      } catch (e) {
        _showErrorDialog("Erreur de connexion", "Impossible de contacter le serveur. Détails: ${e.toString()}");
      } finally {
        if(mounted) setState(() => _isLoading = false);
      }
    }
  }

  // Fonction pour réinitialiser les champs en rechargeant depuis le serveur
  void _resetObjectives() {
    _loadObjectivesFromServer();
  }

  // Fonction utilitaire pour afficher les erreurs
  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pasQuotidienController.dispose();
    _pasHebdomadaireController.dispose();
    _pasMensuelController.dispose();
    _caloriesController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Paramètres des objectifs',
          style: TextStyle(color: Color(0xFF3575D3), fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          Image.asset('assets/logo.png', height: 70),
          const SizedBox(width: 16),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
              Positioned(
                right: 8, top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                  child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Text(widget.nom.isNotEmpty ? widget.nom[0] : '?', style: const TextStyle(color: Colors.black)),
            ),
            onSelected: (value) {
              if (value == 'account') {
                Navigator.pushNamed(
                  context,
                  '/compte',
                  arguments: {
                    'nom': widget.nom,
                    'email': widget.email,
                    'entreprise': widget.entreprise,
                  },
                );
              } else if (value == 'logout') {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'account',
                child: Text('Compte'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Se déconnecter'),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Objectifs de pas",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pasQuotidienController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Pas quotidiens",
                        helperText: "Recommandé : 8,000 - 12,000 pas",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Entrez un objectif" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pasHebdomadaireController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Pas hebdomadaires",
                        helperText: "Recommandé : 56,000 - 84,000 pas",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Entrez un objectif" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pasMensuelController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Pas mensuels",
                        helperText: "Recommandé : 240,000 - 360,000 pas",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Entrez un objectif" : null,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Autres objectifs quotidiens",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Calories à brûler (kcal)",
                        helperText: "Recommandé : 300 - 500 kcal",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Entrez un objectif" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _distanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Distance à parcourir (km)",
                        helperText: "Recommandé : 5 - 10 km",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Entrez un objectif" : null,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text("Sauvegarder les objectifs", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0057B8),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _saveObjectives,
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text("Réinitialiser"),
                          onPressed: _resetObjectives,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: const Color(0xFF3575D3),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(
              context,
              '/dashboard',
              arguments: {'token': widget.token},
            );
          } else if (index == 1) {
            Navigator.pushReplacementNamed(
              context,
              '/progress',
              arguments: {
                'token': widget.token,
                'nom': widget.nom,
                'email': widget.email,
                'entreprise': widget.entreprise,
              },
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Progrès"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Réglages"),
        ],
      ),
    );
  }
}
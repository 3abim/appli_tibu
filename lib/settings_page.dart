import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late TextEditingController _pasQuotidienController;
  late TextEditingController _caloriesController;
  late TextEditingController _distanceController;

  @override
  void initState() {
    super.initState();
    _pasQuotidienController = TextEditingController();
    _caloriesController = TextEditingController();
    _distanceController = TextEditingController();
    _loadObjectives();
  }

  Future<void> _loadObjectives() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pasQuotidienController.text = (prefs.getInt('objectifPas') ?? 10000).toString();
      _caloriesController.text = (prefs.getInt('objectifCalories') ?? 400).toString();
      _distanceController.text = (prefs.getDouble('objectifDistance') ?? 7.0).toString();
    });
  }

  Future<void> _saveObjectives() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('objectifPas', int.parse(_pasQuotidienController.text));
      await prefs.setInt('objectifCalories', int.parse(_caloriesController.text));
      await prefs.setDouble('objectifDistance', double.parse(_distanceController.text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Objectifs sauvegardés !')),
      );
    }
  }

  void _resetObjectives() {
    setState(() {
      _pasQuotidienController.text = '10000';
      _caloriesController.text = '400';
      _distanceController.text = '7';
    });
  }

  @override
  void dispose() {
    _pasQuotidienController.dispose();
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
          Image.asset('assets/logo.png', height: 40),
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
          // DANS LE FICHIER `settings_page.dart`
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
      body: SingleChildScrollView(
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
                        backgroundColor: const Color(0xFF0057B8), // Pantone 2935C
                        foregroundColor: Colors.white, // Texte en blanc
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
        currentIndex: 2, // Réglages = 2
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
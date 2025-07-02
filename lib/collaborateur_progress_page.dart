// collaborateur_progress_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CollaborateurProgressPage extends StatefulWidget {
  final int objectifPas;
  final int objectifCalories;
  final double objectifDistance;
  final String nom;
  final String email;
  final String entreprise;

  const CollaborateurProgressPage({
    super.key,
    required this.objectifPas,
    required this.objectifCalories,
    required this.objectifDistance,
    required this.nom,
    required this.email,
    required this.entreprise,
  });

  @override
  State<CollaborateurProgressPage> createState() => _CollaborateurProgressPageState();
}

class _CollaborateurProgressPageState extends State<CollaborateurProgressPage> {
  int pas = 0;
  double distance = 0.0;
  int calories = 0;
  StreamSubscription<StepCount>? _stepCountStream;

  late int objectifPas;
  late int objectifCalories;
  late double objectifDistance;

  @override
  void initState() {
    super.initState();
    objectifPas = widget.objectifPas;
    objectifCalories = widget.objectifCalories;
    objectifDistance = widget.objectifDistance;
    _initPedometer();
    loadObjectives();
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    super.dispose();
  }

  void _initPedometer() {
    _stepCountStream = Pedometer.stepCountStream.listen(
      (StepCount event) {
        if (!mounted) return;
        setState(() {
          pas = event.steps;
          distance = _calculateDistance(pas);
          calories = _calculateCalories(pas);
        });
      },
      onError: (error) {},
      cancelOnError: true,
    );
  }

  double _calculateDistance(int steps) {
    return (steps * 0.0008);
  }

  int _calculateCalories(int steps) {
    return (steps * 0.04).round();
  }

  void loadObjectives() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      objectifPas = prefs.getInt('objectifPas') ?? objectifPas;
      objectifCalories = prefs.getInt('objectifCalories') ?? objectifCalories;
      objectifDistance = prefs.getDouble('objectifDistance') ?? objectifDistance;
    });
  }

  @override
  Widget build(BuildContext context) {
    double percentPas = objectifPas > 0 ? (pas / objectifPas).clamp(0.0, 1.0) : 0.0;
    double percentCalories = objectifCalories > 0 ? (calories / objectifCalories).clamp(0.0, 1.0) : 0.0;
    double percentDistance = objectifDistance > 0 ? (distance / objectifDistance).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Progrès', style: TextStyle(color: Color(0xFF3575D3), fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.grey[200],
              // --- CORRECTION : On utilise `widget.nom` pour accéder à la vraie donnée
              child: Text(widget.nom.isNotEmpty ? widget.nom[0] : '?', style: const TextStyle(color: Colors.black)),
            ),
            onSelected: (value) {
              if (value == 'account') {
                Navigator.pushNamed(
                  context,
                  '/compte',
                  arguments: {
                    // --- CORRECTION : On passe les vraies données à la page compte
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Votre progression", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Suivez vos objectifs et vos accomplissements", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          Row(
            children: [
              _ProgressTab("Aujourd'hui", true),
              _ProgressTab("Cette semaine", false),
              _ProgressTab("Ce mois", false),
            ],
          ),
          const SizedBox(height: 16),
          _ProgressCard(
            icon: Icons.adjust,
            iconColor: Colors.blue,
            title: "Pas quotidiens",
            value: pas.toString(),
            objectif: objectifPas.toString(),
            percent: percentPas,
            unite: "pas",
            reste: "${(objectifPas - pas) >= 0 ? objectifPas - pas : 0} pas restants",
          ),
          _ProgressCard(
            icon: Icons.trending_up,
            iconColor: Colors.orange,
            title: "Calories brûlées",
            value: calories.toString(),
            objectif: objectifCalories.toString(),
            percent: percentCalories,
            unite: "kcal",
            reste: "${(objectifCalories - calories) >= 0 ? objectifCalories - calories : 0} kcal restants",
          ),
          _ProgressCard(
            icon: Icons.calendar_today,
            iconColor: Colors.green,
            title: "Distance parcourue",
            value: distance.toStringAsFixed(2),
            objectif: objectifDistance.toStringAsFixed(1),
            percent: percentDistance,
            unite: "km",
            reste: "${((objectifDistance - distance) >= 0 ? objectifDistance - distance : 0).toStringAsFixed(2)} km restants",
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Progrès = 1
        selectedItemColor: const Color(0xFF3575D3),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            // Le dashboard récupère ses propres infos via le token, donc pas besoin d'arguments ici
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            // Déjà sur Progrès
          } else if (index == 2) {
            // --- CORRECTION : On passe les arguments à la page settings
            Navigator.pushReplacementNamed(
              context,
              '/settings',
              arguments: {
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

class _ProgressTab extends StatelessWidget {
  final String label;
  final bool selected;
  const _ProgressTab(this.label, this.selected);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String objectif;
  final double percent;
  final String unite;
  final String reste;

  const _ProgressCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.objectif,
    required this.percent,
    required this.unite,
    required this.reste,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text("/ $objectif $unite", style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey[200],
              color: Colors.black,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${(percent * 100).toStringAsFixed(0)}% de l'objectif", style: const TextStyle(color: Colors.grey)),
                Text(reste, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
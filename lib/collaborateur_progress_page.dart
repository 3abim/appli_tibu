// collaborateur_progress_page.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

class CollaborateurProgressPage extends StatefulWidget {
  final String token;
  final String nom;
  final String email;
  final String entreprise;
  final int objectifPas;
  final int objectifCalories;
  final double objectifDistance;

  const CollaborateurProgressPage({
    super.key,
    required this.token,
    required this.nom,
    required this.email,
    required this.entreprise,
    required this.objectifPas,
    required this.objectifCalories,
    required this.objectifDistance,
  });

  @override
  State<CollaborateurProgressPage> createState() => _CollaborateurProgressPageState();
}

class _CollaborateurProgressPageState extends State<CollaborateurProgressPage> {
  int _progressTabIndex = 0;
  bool _isLoading = false;

  int pas = 0;
  double distance = 0.0;
  int calories = 0;

  late int objectifPas;
  late int objectifCalories;
  late double objectifDistance;

  StreamSubscription<StepCount>? _stepCountStream;

  @override
  void initState() {
    super.initState();
    objectifPas = widget.objectifPas;
    objectifCalories = widget.objectifCalories;
    objectifDistance = widget.objectifDistance;
    _fetchProgressData();
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    super.dispose();
  }

  void _initPedometerForToday() {
    _stepCountStream?.cancel();
    if (_progressTabIndex == 0) {
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
  }

  Future<void> _fetchProgressData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    if (_progressTabIndex == 0) {
      _initPedometerForToday();
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _stepCountStream?.cancel();

    String period = "semaine";
    if (_progressTabIndex == 2) period = "mois";

    final url = Uri.parse('http://10.0.2.2:9091/api/collaborateur/progress?periode=$period');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          pas = data['pas_total'] ?? 0;
          distance = (data['distance_totale'] ?? 0.0).toDouble();
          calories = data['calories_totales'] ?? 0;
          objectifPas = data['objectif_pas'] ?? widget.objectifPas * 7;
          objectifCalories = data['objectif_calories'] ?? widget.objectifCalories * 7;
          objectifDistance = (data['objectif_distance'] ?? widget.objectifDistance * 7).toDouble();
        });
      }
    } catch (e) {
      // Gérer l'erreur
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _calculateDistance(int steps) => (steps * 0.0008);
  int _calculateCalories(int steps) => (steps * 0.04).round();

  @override
  Widget build(BuildContext context) {
    double percentPas = objectifPas > 0 ? (pas / objectifPas).clamp(0.0, 1.0) : 0.0;
    double percentCalories = objectifCalories > 0 ? (calories / objectifCalories).clamp(0.0, 1.0) : 0.0;
    double percentDistance = objectifDistance > 0 ? (distance / objectifDistance).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      // --- VOTRE APPBAR EST DE RETOUR ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Progrès', style: TextStyle(color: Color(0xFF3575D3), fontWeight: FontWeight.bold)),
        actions: [
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
                    'token': widget.token,
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProgressTab(
                "Aujourd'hui",
                _progressTabIndex == 0,
                onTap: () {
                  setState(() { _progressTabIndex = 0; });
                  _fetchProgressData();
                },
              ),
              _ProgressTab(
                "Cette semaine",
                _progressTabIndex == 1,
                onTap: () {
                  setState(() { _progressTabIndex = 1; });
                  _fetchProgressData();
                },
              ),
              _ProgressTab(
                "Ce mois",
                _progressTabIndex == 2,
                onTap: () {
                  setState(() { _progressTabIndex = 2; });
                  _fetchProgressData();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
          else
            Column(
              children: [
                _ProgressCard(
                  icon: Icons.adjust,
                  iconColor: Colors.blue,
                  title: _progressTabIndex == 0 ? "Pas quotidiens" : "Total de pas",
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
            )
        ],
      ),
      // --- VOTRE BOTTOMNAVBAR EST DE RETOUR ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: const Color(0xFF3575D3),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(
              context,
              '/dashboard',
              arguments: {'token': widget.token},
            );
          } else if (index == 2) {
            Navigator.pushReplacementNamed(
              context,
              '/settings',
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

class _ProgressTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ProgressTab(this.label, this.selected, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.withAlpha(50) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.blue : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.blue : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
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
    super.key,
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text("/ $objectif $unite", style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey[200],
              color: iconColor,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${(percent * 100).toStringAsFixed(0)}% de l'objectif", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(reste, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
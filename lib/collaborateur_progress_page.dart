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

  const CollaborateurProgressPage({
    super.key,
    required this.token,
    required this.nom,
    required this.email,
    required this.entreprise,
  });

  @override
  State<CollaborateurProgressPage> createState() => _CollaborateurProgressPageState();
}

class _CollaborateurProgressPageState extends State<CollaborateurProgressPage> {
  int _progressTabIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  int pas = 0;
  double distance = 0.0;
  int calories = 0;

  int objectifPas = 10000;
  int objectifCalories = 400;
  double objectifDistance = 7.0;

  StreamSubscription<StepCount>? _stepCountStream;

  @override
  void initState() {
    super.initState();
    _fetchDataForCurrentTab();
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    super.dispose();
  }

  Future<void> _fetchDataForCurrentTab() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_progressTabIndex == 0) {
        await _fetchCurrentObjectives();
        _initPedometerForToday();
      } else {
        _stepCountStream?.cancel();
        String period = (_progressTabIndex == 1) ? "semaine" : "mois";
        await _fetchAggregatedProgress(period);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Une erreur est survenue : ${e.toString().replaceAll("Exception: ", "")}";
      });
    } finally {
      if (!mounted) return;
      // On ne met _isLoading à false que si le podomètre n'a pas déjà affiché une erreur
      if (_errorMessage == null || !_errorMessage!.contains("podomètre")) {
          setState(() {
            _isLoading = false;
          });
      }
    }
  }

  Future<void> _fetchCurrentObjectives() async {
    final url = Uri.parse('http://192.168.11.140:9091/api/objectifs');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() {
        objectifPas = data['pasQuotidien'] ?? 10000;
        objectifCalories = data['calories'] ?? 400;
        objectifDistance = (data['distanceKm'] ?? 7.0).toDouble();
      });
    } else {
      throw Exception("Impossible de charger les objectifs personnels.");
    }
  }

  void _initPedometerForToday() {
    pas = 0; // Réinitialiser les pas pour la vue "Aujourd'hui"
    _stepCountStream?.cancel();
    _stepCountStream = Pedometer.stepCountStream.listen(
      (StepCount event) {
        if (!mounted) return;
        setState(() {
          // MODIFIÉ : On efface le message d'erreur dès qu'on reçoit des données valides
          if (_errorMessage != null) {
            _errorMessage = null;
          }
          if (_isLoading) {
            _isLoading = false;
          }
          pas = event.steps;
          distance = _calculateDistance(pas);
          calories = _calculateCalories(pas);
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = "Le podomètre n'est pas disponible sur cet appareil.";
          _isLoading = false; // On arrête le chargement pour afficher l'erreur
        });
      },
      // MODIFIÉ : Le paramètre cancelOnError est retiré (par défaut à false)
      // pour permettre à l'écoute de continuer même après une erreur.
      // cancelOnError: true, // CETTE LIGNE EST LE PROBLÈME, ON LA SUPPRIME
    );
  }

  Future<void> _fetchAggregatedProgress(String period) async {
    final url = Uri.parse('http://192.168.11.140:9091/api/progress?periode=$period');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() {
        pas = data['pas_total'] ?? 0;
        distance = (data['distance_totale'] ?? 0.0).toDouble();
        calories = data['calories_totales'] ?? 0;
        objectifPas = data['objectif_pas'] ?? 0;
        objectifCalories = data['objectif_calories'] ?? 0;
        objectifDistance = (data['objectif_distance'] ?? 0.0).toDouble();
      });
    } else {
      throw Exception("Impossible de charger la progression pour la période '$period'.");
    }
  }

  double _calculateDistance(int steps) => (steps * 0.00075);
  int _calculateCalories(int steps) => (steps * 0.04).round();

  @override
  Widget build(BuildContext context) {
    double percentPas = objectifPas > 0 ? (pas / objectifPas).clamp(0.0, 1.0) : 0.0;
    double percentCalories = objectifCalories > 0 ? (calories / objectifCalories).clamp(0.0, 1.0) : 0.0;
    double percentDistance = objectifDistance > 0 ? (distance / objectifDistance).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Votre progression', style: TextStyle(color: Color(0xFF3575D3), fontWeight: FontWeight.bold)),
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
          : _errorMessage != null
              ? Center( // AJOUTÉ : Un affichage plus complet pour l'erreur
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
                         const SizedBox(height: 20),
                         // AJOUTÉ : Le bouton pour permettre une nouvelle tentative
                         if (_errorMessage!.contains("podomètre"))
                          ElevatedButton.icon(
                            icon: Icon(Icons.refresh),
                            label: Text("Réessayer"),
                            onPressed: _initPedometerForToday,
                          )
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text("Suivez vos objectifs et vos accomplissements", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                         child:
                        _ProgressTab(
                          "Aujourd'hui",
                          _progressTabIndex == 0,
                          onTap: () {
                            if (_progressTabIndex != 0) {
                              setState(() => _progressTabIndex = 0);
                              _fetchDataForCurrentTab();
                            }
                          },
                        ),
                        ),
                        Expanded(
                          child:
                        _ProgressTab(
                          "Cette semaine",
                          _progressTabIndex == 1,
                          onTap: () {
                            if (_progressTabIndex != 1) {
                              setState(() => _progressTabIndex = 1);
                              _fetchDataForCurrentTab();
                            }
                          },
                        ),
                    ),
                    Expanded(
                       child:
                        _ProgressTab(
                          "Ce mois",
                          _progressTabIndex == 2,
                          onTap: () {
                            if (_progressTabIndex != 2) {
                              setState(() => _progressTabIndex = 2);
                              _fetchDataForCurrentTab();
                            }
                          },
                        ),
                    ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _ProgressCard(
                      icon: Icons.directions_walk,
                      iconColor: Colors.blue,
                      title: "Pas",
                      value: pas.toString(),
                      objectif: objectifPas.toString(),
                      percent: percentPas,
                      unite: "pas",
                      reste: "${(objectifPas - pas) >= 0 ? (objectifPas - pas) : 0} restants",
                    ),
                    _ProgressCard(
                      icon: Icons.local_fire_department,
                      iconColor: Colors.orange,
                      title: "Calories brûlées",
                      value: calories.toString(),
                      objectif: objectifCalories.toString(),
                      percent: percentCalories,
                      unite: "kcal",
                      reste: "${(objectifCalories - calories) >= 0 ? (objectifCalories - calories) : 0} restantes",
                    ),
                    _ProgressCard(
                      icon: Icons.map_outlined,
                      iconColor: Colors.green,
                      title: "Distance parcourue",
                      value: distance.toStringAsFixed(2),
                      objectif: objectifDistance.toStringAsFixed(1),
                      percent: percentDistance,
                      unite: "km",
                      reste: "${((objectifDistance - distance) >= 0 ? objectifDistance - distance : 0.0).toStringAsFixed(2)} restants",
                    ),
                  ],
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: const Color(0xFF3575D3),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard', arguments: {'token': widget.token});
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/settings', arguments: {
              'token': widget.token,
              'nom': widget.nom,
              'email': widget.email,
              'entreprise': widget.entreprise,
            });
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

// Les classes _ProgressTab et _ProgressCard restent inchangées...
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
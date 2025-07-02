import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedometer/pedometer.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CollaborateurDashboard extends StatefulWidget {
  final String token;

  const CollaborateurDashboard({super.key, required this.token});

  @override
  State<CollaborateurDashboard> createState() => _CollaborateurDashboardState();
}

class _CollaborateurDashboardState extends State<CollaborateurDashboard> {
  String nom = "";
  String email = "";
  String entreprise = "";
  int pas = 0;
  int objectif = 0;
  double euros = 0.0;
  int classement = 0;
  List<Map<String, dynamic>> classementList = [];
  int objectifPerso = 10000;

  int classementTabIndex = 0; // 0 = aujourd'hui, 1 = semaine, 2 = mois

  StreamSubscription<StepCount>? _stepCountStream;

  bool isLoadingClassement = false;

  @override
  void initState() {
    super.initState();
    _initPedometer();
    _fetchCollaborateurData();
    _loadObjectifPerso();
    _fetchClassement(); // Ajouté pour charger le classement du jour au démarrage
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    super.dispose();
  }

  void _initPedometer() {
    _stepCountStream = Pedometer.stepCountStream.listen(
      (StepCount event) {
        setState(() {
          pas = event.steps;
        });
      },
      onError: (error) {},
      cancelOnError: true,
    );
  }

  Future<void> _fetchCollaborateurData() async {
    final url = Uri.parse('http://10.0.2.2:9090/api/collaborateur/dashboard');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        nom = data['nom'] ?? '';
        email = data['email'] ?? '';
        entreprise = data['entreprise'] ?? '';
        objectifPerso = data['objectifPerso'] ?? 0;
        euros = (data['euros'] ?? 0).toDouble();
        classement = data['classement'] ?? 0;
        if (data['pas'] != null) pas = data['pas'];
      });
    }
  }

  Future<void> _loadObjectifPerso() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      objectifPerso = prefs.getInt('objectifPas') ?? objectif;
    });
  }

  Future<void> _fetchClassement() async {
    setState(() {
      isLoadingClassement = true;
      classementList = []; // Vide la liste pour effet immédiat
    });
    String period = "jour";
    if (classementTabIndex == 1) period = "semaine";
    if (classementTabIndex == 2) period = "mois";
    final url = Uri.parse('http://10.0.2.2:9090/api/collaborateur/classement?periode=$period');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        classementList = List<Map<String, dynamic>>.from(data['classementList'] ?? []);
        classement = data['classement'] ?? 0;
        isLoadingClassement = false;
      });
    } else {
      setState(() {
        isLoadingClassement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Step Up', style: TextStyle(color: Color(0xFF3575D3), fontWeight: FontWeight.bold)),
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
                    GestureDetector(
            onTap: () {
              // Navigation vers la page Compte
              Navigator.pushNamed(
                context,
                '/compte',
                arguments: {
                  'nom': nom,
                  'email': email,
                  'entreprise': entreprise,
                },
              );
            },
            child: CircleAvatar(child: Text(nom.isNotEmpty ? nom[0] : '?')),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bonjour
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5FAFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bonjour, $nom 👋", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("Voici votre activité d'aujourd'hui", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Vos pas aujourd'hui
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: pantone2935C,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Vos pas aujourd'hui", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text("Objectif quotidien: $objectifPerso pas", style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                Center(
                  child: CircularPercentIndicator(
                    radius: 80,
                    lineWidth: 12,
                    percent: objectifPerso > 0 ? (pas / objectifPerso).clamp(0.0, 1.0) : 0.0,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("$pas", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        const Text("pas"),
                        Text("${objectifPerso > 0 ? ((pas / objectifPerso) * 100).toStringAsFixed(0) : 0}% de l'objectif", style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                    progressColor: Colors.green,
                    backgroundColor: Colors.grey[200]!,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Vos gains
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: pantone368C,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Vos gains", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const Text("1000 pas = 1€", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text("€", style: TextStyle(fontSize: 32, color: Colors.white)),
                    Text(euros.toStringAsFixed(2), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (pas % 1000) / 1000,
                  backgroundColor: Colors.white24,
                  color: Colors.black,
                ),
                const SizedBox(height: 4),
                Text(
                  "Encore ${1000 - (pas % 1000)} pas pour gagner 1€ supplémentaire",
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Classement des marcheurs
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: pantone130C,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Classement des marcheurs", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text("Votre position: #$classement", style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ClassementTab(
                      "Aujourd'hui",
                      classementTabIndex == 0,
                      onTap: () {
                        print('Onglet Aujourd\'hui cliqué');
                        setState(() {
                          classementTabIndex = 0;
                        });
                        _fetchClassement();
                      },
                    ),
                    _ClassementTab(
                      "Cette semaine",
                      classementTabIndex == 1,
                      onTap: () {
                        print('Onglet Cette semaine cliqué');
                        setState(() {
                          classementTabIndex = 1;
                        });
                        _fetchClassement();
                      },
                    ),
                    _ClassementTab(
                      "Ce mois",
                      classementTabIndex == 2,
                      onTap: () {
                        print('Onglet Ce mois cliqué');
                        setState(() {
                          classementTabIndex = 2;
                        });
                        _fetchClassement();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isLoadingClassement)
                  const Center(child: CircularProgressIndicator())
                else
                  ...classementList.map((item) => _ClassementItem(
                    nom: item["nom"] ?? "",
                    entreprise: item["entreprise"] ?? "",
                    pas: item["pas"] ?? 0,
                    isUser: (item["nom"] ?? "").toString().toLowerCase().contains(nom.toLowerCase()),
                    rang: item["rang"] ?? 0,
                  )),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              print('Test bouton cliqué');
            },
            child: const Text('Test bouton'),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF3575D3),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushNamed(
              context,
              '/progress',
              arguments: {
                'nom': nom,
                'email': email,
                'entreprise': entreprise,
              },
            );
           } else if (index == 2) {
            // On passe les données à la page des réglages
            Navigator.pushReplacementNamed(
              context,
              '/settings',
              arguments: {
                'nom': nom,
                'email': email,
                'entreprise': entreprise,
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

class _ClassementTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ClassementTab(this.label, this.selected, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ClassementItem extends StatelessWidget {
  final String nom;
  final String entreprise;
  final int pas;
  final bool isUser;
  final int rang;

  const _ClassementItem({
    required this.nom,
    required this.entreprise,
    required this.pas,
    required this.isUser,
    required this.rang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser ? Colors.white.withOpacity(0.7) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isUser ? Border.all(color: Colors.purple.shade100) : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isUser ? Colors.purple : Colors.grey[300],
            child: Text(nom.isNotEmpty ? nom[0] : '?'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom, style: TextStyle(fontWeight: isUser ? FontWeight.bold : FontWeight.normal, color: isUser ? Colors.purple : Colors.black)),
                Text(entreprise, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Text(
            pas.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 4),
          const Text("pas"),
        ],
      ),
    );
  }
}

// Pantone 2935C (bleu) : #0057B8
const pantone2935C = Color(0xFF0057B8);
// Pantone 368C (vert) : #39B54A
const pantone368C = Color(0xFF39B54A);
// Pantone 130C (orange) : #F2A900
const pantone130C = Color(0xFFF2A900);
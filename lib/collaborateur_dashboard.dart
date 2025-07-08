import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const pantone2935C = Color(0xFF0057B8);
const pantone368C = Color(0xFF39B54A);
const pantone130C = Color(0xFFF2A900);

class CollaborateurDashboard extends StatefulWidget {
  final String token;
  
  const CollaborateurDashboard({super.key, required this.token});

  @override
  State<CollaborateurDashboard> createState() => _CollaborateurDashboardState();
}

class _CollaborateurDashboardState extends State<CollaborateurDashboard> {
  bool _isLoading = true;
  String _errorMessage = '';
  
  String nom = "Chargement...";
  String email = "";
  String entreprise = "";
  int pas = 0;
  double euros = 0.0;
  int classement = 0;
  int objectifPerso = 10000;
  int classementTabIndex = 0;
  List<Map<String, dynamic>> classementList = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await Future.wait([
        _fetchUserData(),
        _fetchClassement(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchUserData() async {
    final url = Uri.parse('http://10.0.2.2:9091/api/collaborateur/dashboard');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  setState(() {
    nom = data['nom'] as String? ?? 'Non défini';
    email = data['email'] as String? ?? '';
    entreprise = data['entreprise'] as String?
      ?? data['organisation'] as String?
      ?? data['company'] as String?
      ?? '';
  pas = (data['pasAujourdHui'] as num?)?.toInt() ?? 0;
  euros = (data['eurosGagnes'] as num?)?.toDouble() ?? 0.0;
  classement = (data['classement'] as num?)?.toInt() ?? 0;
});

  } else {
    throw Exception('Erreur ${response.statusCode}: ${response.body}');
  }
}

  Future<void> _fetchClassement() async {
    final periods = ['jour', 'semaine', 'mois'];
    final period = periods[classementTabIndex];
    
    final url = Uri.parse('http://10.0.2.2:9091/api/collaborateur/classement?periode=$period');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      print(data); // Ajoute cette ligne pour voir les clés disponibles
      setState(() {
        classementList = List<Map<String, dynamic>>.from(data);
      });
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  void _changeClassementPeriod(int index) {
    setState(() {
      classementTabIndex = index;
      _fetchClassement();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadDashboardData,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Image.asset('assets/logo.png', height: 90),
        actions: [
          // Notifications
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                  child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
          // Compte
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Text(
                nom.isNotEmpty ? nom[0] : '?',
                style: const TextStyle(color: Colors.black),
              ),
            ),
            onSelected: (value) {
              if (value == 'account') {
                Navigator.pushNamed(
                  context,
                  '/compte',
                  arguments: {
                    'nom': nom,
                    'email': email,
                    'entreprise': entreprise,
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
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 16),
              _buildStepsCard(),
              const SizedBox(height: 16),
              _buildEarningsCard(),
              const SizedBox(height: 16),
              _buildRankingCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Progrès'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
        ],
        currentIndex: 0,
        onTap: (index) {
          // Navigation à implémenter
        },
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bonjour, $nom 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Entreprise: $entreprise', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsCard() {
    final progress = objectifPerso > 0 ? (pas / objectifPerso).clamp(0.0, 1.0) : 0.0;
    
    return Card(
  color: const Color(0xFF0057B8), // <-- couleur bleue
  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            const Text(
              'Vos pas aujourd\'hui',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Objectif: $objectifPerso pas', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Center(
              child: CircularPercentIndicator(
                radius: 80,
                lineWidth: 12,
                percent: progress,
                center: Text('$pas', style: const TextStyle(fontSize: 32, color: Colors.white)),
                progressColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
    final remainingSteps = 1000 - (pas % 1000);
    
    return Card(
      color: pantone368C,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vos gains', style: TextStyle(color: Colors.white, fontSize: 18)),
            const Text('1000 pas = 1€', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('€', style: TextStyle(fontSize: 32, color: Colors.white)),
                Text(euros.toStringAsFixed(2), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (pas % 1000) / 1000,
              backgroundColor: Colors.white.withOpacity(0.2),
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text('Encore $remainingSteps pas pour 1€ supplémentaire', style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingCard() {
    return Card(
      color: pantone130C,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Classement', style: TextStyle(color: Colors.white, fontSize: 18)),
            Text('Votre position: #$classement', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPeriodTab('Aujourd\'hui', 0),
                _buildPeriodTab('Semaine', 1),
                _buildPeriodTab('Mois', 2),
              ],
            ),
            const SizedBox(height: 8),
            ...classementList.map((item) => _buildRankingItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String label, int index) {
    final isSelected = classementTabIndex == index;
    
    return GestureDetector(
      onTap: () => _changeClassementPeriod(index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRankingItem(Map<String, dynamic> item) {
    final isCurrentUser = item['nom'] == nom;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isCurrentUser ? Colors.amber : Colors.grey[300],
            child: Text(item['rang'].toString(), style: const TextStyle(color: Colors.black)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nom'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['entreprise'] ?? item['organisation'] ?? item['company'] ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item['pas']} pas',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
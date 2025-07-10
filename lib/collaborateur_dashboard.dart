import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:pedometer/pedometer.dart';

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

  StreamSubscription<StepCount>? _stepCountStream;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _initPedometer();
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  void _initPedometer() {
    _stepCountStream = Pedometer.stepCountStream.listen(
      (StepCount event) {
        if (!mounted) return;
        
        setState(() {
          pas = event.steps;
          euros = (pas / 1000).floor().toDouble();
        });

        if (_debounce?.isActive ?? false) _debounce!.cancel();
        _debounce = Timer(const Duration(seconds: 15), () {
          _sendStepsToBackend(pas);
        });
      },
      onError: (error) {
        if (mounted) {
          print("Erreur Pedometer: $error");
        }
      },
      cancelOnError: true,
    );
  }

  Future<void> _sendStepsToBackend(int steps) async {
    try {
      final url = Uri.parse('http://192.168.11.140:9091/api/pas/update');
      await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'nombreDePas': steps}),
      );
      print('Pas ($steps) envoyés au backend avec succès.');
    } catch (e) {
      print('Erreur lors de l\'envoi des pas: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
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
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de chargement: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchUserData() async {
    final url = Uri.parse('http://192.168.11.140:9091/api/collaborateur/dashboard');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          nom = data['nom'] as String? ?? 'Non défini';
          email = data['email'] as String? ?? '';
          entreprise = data['entreprise'] as String? ?? data['organisation'] as String? ?? '';
          pas = (data['pasAujourdHui'] as num?)?.toInt() ?? 0;
          euros = (data['eurosGagnes'] as num?)?.toDouble() ?? 0.0;
          classement = (data['classement'] as num?)?.toInt() ?? 0;
          objectifPerso = (data['objectifPasQuotidien'] as num?)?.toInt() ?? 10000;
        });
      }
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> _fetchClassement() async {
    final periods = ['jour', 'semaine', 'mois'];
    final period = periods[classementTabIndex];
    
    final url = Uri.parse('http://192.168.11.140:9091/api/collaborateur/classement?periode=$period');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      if (mounted) {
        setState(() {
          classementList = List<Map<String, dynamic>>.from(data);
        });
      }
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  void _changeClassementPeriod(int index) {
    if (mounted) {
      setState(() {
        classementTabIndex = index;
      });
      _fetchClassement();
    }
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
              Text(_errorMessage, textAlign: TextAlign.center),
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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Image.asset('assets/logo.png', height: 40),
        actions: [
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
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Text(
                nom.isNotEmpty ? nom[0].toUpperCase() : '?',
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
        currentIndex: 0,
        selectedItemColor: const Color(0xFF3575D3),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/progress', arguments: {
              'token': widget.token,
              'nom': nom,
              'email': email,
              'entreprise': entreprise,
            });
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/settings', arguments: {
              'token': widget.token,
              'nom': nom,
              'email': email,
              'entreprise': entreprise,
            });
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Progrès'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bonjour, $nom', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Entreprise: $entreprise', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const Text('👋', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsCard() {
    final progress = objectifPerso > 0 ? (pas / objectifPerso).clamp(0.0, 1.0) : 0.0;
    
    return Card(
      color: pantone2935C,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vos pas aujourd\'hui', style: const TextStyle(color: Colors.white, fontSize: 18)),
            Text('Objectif: $objectifPerso pas', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Center(
              child: CircularPercentIndicator(
                radius: 60,
                lineWidth: 10,
                percent: progress,
                center: Text('$pas', style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                progressColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.3),
                circularStrokeCap: CircularStrokeCap.round,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vos gains', style: const TextStyle(color: Colors.white, fontSize: 18)),
            const Text('1000 pas = 1€', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Text('€${euros.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (pas % 1000) / 1000,
              backgroundColor: Colors.white.withOpacity(0.3),
              color: Colors.white,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Classement', style: const TextStyle(color: Colors.white, fontSize: 18)),
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
            ...classementList.take(3).map((item) => _buildRankingItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String label, int index) {
    final isSelected = classementTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeClassementPeriod(index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankingItem(Map<String, dynamic> item) {
    final isCurrentUser = item['nom'] == nom;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.white.withOpacity(0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text('${item['rang']}.', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(item['nom'] ?? '', style: const TextStyle(color: Colors.white, overflow: TextOverflow.ellipsis))),
          Text('${item['pas']} pas', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'services/pedometer_service.dart';

const pantone2935C = Color(0xFF0057B8);
const pantone368C = Color(0xFF39B54A);
const pantone130C = Color(0xFFF2A900);
const pantone187C = Color(0xFFAD1D2A); // Couleur pour la carte des écoles

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
  int classement = 0;
  int objectifPerso = 10000;
  int classementTabIndex = 0;
  List<Map<String, dynamic>> classementList = [];
  List<Map<String, dynamic>> ecolesBeneficiaires = []; // Renommage pour plus de clarté

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _logout() async {
    await PedometerService().stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Future<void> _loadAllData() async {
    if (mounted && !_isLoading) setState(() => _isLoading = true);
    _errorMessage = '';

    try {
      await Future.wait([
        _fetchDashboardData(),
        _fetchClassement('jour'),
        _fetchEcoles(),
      ]);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Erreur de chargement des données: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDashboardData() async {
    final response = await http.get(
      Uri.parse('http://192.168.11.158:9091/api/collaborateur/dashboard'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    ).timeout(const Duration(seconds: 10));

    if (!mounted) return;
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        nom = data['nom'] ?? "Inconnu";
        email = data['email'] ?? "";
        entreprise = data['organisation'] ?? "";
        objectifPerso = (data['objectifPasQuotidien'] as num?)?.toInt() ?? 10000;
        classement = data['classement'] ?? 0;
      });
    } else {
      throw Exception("Erreur serveur (dashboard): ${response.statusCode}");
    }
  }

  Future<void> _fetchClassement(String period) async {
    final response = await http.get(
      Uri.parse('http://192.168.11.158:9091/api/collaborateur/classement?periode=$period'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (mounted) setState(() => classementList = List<Map<String, dynamic>>.from(data));
    } else {
      // Gérer l'erreur silencieusement pour ne pas bloquer l'UI
    }
  }

  Future<void> _fetchEcoles() async {
    final response = await http.get(
      Uri.parse('http://192.168.11.158:9091/api/ecoles-beneficiaires'), // Correction de l'URL
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (mounted) setState(() => ecolesBeneficiaires = List<Map<String, dynamic>>.from(data));
    } else {
      // Gérer l'erreur silencieusement
    }
  }
  
  void _changeClassementPeriod(int index) {
    if (_isLoading) return;
    setState(() => classementTabIndex = index);
    String period;
    switch (index) {
      case 1: period = 'semaine'; break;
      case 2: period = 'mois'; break;
      default: period = 'jour';
    }
    _fetchClassement(period);
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _loadAllData, child: const Text('Réessayer')),
            ]),
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
        title: Image.asset('assets/logo.png', height: 90),
        actions: [
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.notifications_none), onPressed: () => Navigator.pushNamed(context, '/notifications')),
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
              child: Text(nom.isNotEmpty ? nom[0].toUpperCase() : '?', style: const TextStyle(color: Colors.black)),
            ),
            onSelected: (value) {
              if (value == 'account') Navigator.pushNamed(context, '/compte', arguments: {'nom': nom, 'email': email, 'entreprise': entreprise});
              else if (value == 'logout') _logout();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'account', child: Text('Compte')),
              const PopupMenuItem(value: 'logout', child: Text('Se déconnecter')),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 16),
              ValueListenableBuilder<int>(
                valueListenable: PedometerService().totalStepsToday,
                builder: (context, currentSteps, child) => _buildStepsCard(currentSteps),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<int>(
                valueListenable: PedometerService().totalStepsToday,
                builder: (context, currentSteps, child) => _buildEarningsCard(currentSteps),
              ),
              const SizedBox(height: 16),
              _buildRankingCard(),
              const SizedBox(height: 16),
              _buildEcolesCard(),
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
          if (index == 1) Navigator.pushReplacementNamed(context, '/progress', arguments: {'token': widget.token, 'nom': nom, 'email': email, 'entreprise': entreprise});
          else if (index == 2) Navigator.pushReplacementNamed(context, '/settings', arguments: {'token': widget.token, 'nom': nom, 'email': email, 'entreprise': entreprise});
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Progrès'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() => Card(
    elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bonjour, $nom', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Entreprise: $entreprise', style: const TextStyle(color: Colors.grey)),
        ])),
        const Text('👋', style: TextStyle(fontSize: 24)),
      ]),
    ),
  );

  Widget _buildStepsCard(int currentSteps) {
    final progress = objectifPerso > 0 ? (currentSteps / objectifPerso).clamp(0.0, 1.0) : 0.0;
    return Card(
      color: pantone2935C, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Vos pas aujourd\'hui', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Objectif: $objectifPerso pas', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Center(child: CircularPercentIndicator(
            radius: 60, lineWidth: 10, percent: progress,
            center: _SmoothCounter(count: currentSteps, style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
            progressColor: Colors.white, backgroundColor: Colors.white.withOpacity(0.3), circularStrokeCap: CircularStrokeCap.round,
          )),
        ]),
      ),
    );
  }

 Widget _buildEarningsCard(int currentSteps) {
    double currentEuros = (currentSteps / 1000).floor().toDouble();
    final remainingSteps = 1000 - (currentSteps % 1000);
    return Card(
      color: pantone368C, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Vos gains', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('1000 pas = 1€', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Text('€ ${currentEuros.toStringAsFixed(0)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (currentSteps % 1000) / 1000, backgroundColor: Colors.white.withOpacity(0.3), color: Colors.white, minHeight: 6, borderRadius: BorderRadius.circular(3)),
          const SizedBox(height: 8),
          Text('Encore $remainingSteps pas pour le prochain euro', style: const TextStyle(color: Colors.white)),
        ]),
      ),
    );
  }

  Widget _buildRankingCard() => Card(
    color: pantone130C, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Classement de votre organisation', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text('Votre position: #$classement', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        Row(children: [
          _buildPeriodTab('Aujourd\'hui', 0),
          _buildPeriodTab('Semaine', 1),
          _buildPeriodTab('Mois', 2),
        ]),
        const SizedBox(height: 12),
        if (classementList.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text("Aucun classement disponible.", style: TextStyle(color: Colors.white70))))
        else ...classementList.take(3).map((item) => _buildRankingItem(item)),
      ]),
    ),
  );

  Widget _buildEcolesCard() {
    return Card(
      color: pantone187C,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Écoles bénéficiaires",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            if (ecolesBeneficiaires.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("Aucune distribution de fonds pour le moment.", style: TextStyle(color: Colors.white70)),
                ),
              )
            else
              Column(
                children: ecolesBeneficiaires.map((ecole) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          ecole['nom'] ?? 'Nom inconnu',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "${(ecole['montant'] as num?)?.toStringAsFixed(2) ?? '0.00'} €",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String label, int index) => Expanded(
    child: GestureDetector(
      onTap: () => _changeClassementPeriod(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: classementTabIndex == index ? Colors.white : Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: classementTabIndex == index ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
      ),
    ),
  );

  Widget _buildRankingItem(Map<String, dynamic> item) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: (item['nom'] == nom) ? Colors.white.withOpacity(0.3) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Text('${item['rang']}.', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      const SizedBox(width: 8),
      Expanded(child: Text(item['nom'] ?? '', style: const TextStyle(color: Colors.white, overflow: TextOverflow.ellipsis))),
      Text('${item['pas']} pas', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ]),
  );
}

class _SmoothCounter extends StatelessWidget {
  final int count;
  final TextStyle style;
  const _SmoothCounter({required this.count, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: count.toDouble(), end: count.toDouble()),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Text(
          value.toInt().toString(),
          style: style,
        );
      },
    );
  }
}
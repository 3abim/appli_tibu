// FICHIER COMPLET ET CORRIGÉ
import 'package:flutter/material.dart';
import 'services/api_service.dart'; // IMPORTANT: L'import du service API
import 'dart:convert'; // IMPORTANT: Pour décoder le JSON

class AdminDashboardPage extends StatefulWidget {
  final String token;
  const AdminDashboardPage({super.key, required this.token});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // --- NOUVEAU: Gestion de l'état et des données dynamiques ---
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  // --- Données qui restent pour l'instant statiques (à lier au backend plus tard) ---
  int _classementTabIndex = 0;
  final List<Map<String, dynamic>> _companyRanking = [
    // TODO: Remplacer cette liste par un appel API
    {'name': 'Tibu Inc.', 'steps': 8765432, 'logo': 'assets/logo.png'},
    {'name': 'Innovate Corp.', 'steps': 2456789, 'logo': 'assets/logo.png'},
    {'name': 'HealthFirst Ltd.', 'steps': 1321669, 'logo': 'assets/logo.png'},
  ];

  @override
  void initState() {
    super.initState();
    // --- NOUVEAU: Appel à l'API au chargement de la page ---
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    // Assurer que le widget est toujours monté avant de modifier l'état
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getAdminDashboardStats();
      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _stats = jsonDecode(response.body);
          });
        } else {
          setState(() {
            _errorMessage = "Erreur lors du chargement des données (${response.statusCode}).";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Impossible de joindre le serveur. Veuillez réessayer.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _convertStepsToMoney() {
    // Utilise les données dynamiques si disponibles
    final double totalEuros = _stats?['totalEuros']?.toDouble() ?? 0.0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conversion Effectuée'),
        content: Text(
            'Les pas ont été convertis en ${totalEuros.toStringAsFixed(2)}€ pour les écoles.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- NOUVEAU: Gérer l'affichage en fonction de l'état (chargement, erreur, succès) ---
    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _fetchDashboardData, child: const Text("Réessayer")),
              ],
            ),
          ),
        ),
      );
    }
    
    // --- MODIFIÉ: Utilisation des données dynamiques de l'API ---
    final int totalSteps = _stats?['totalSteps']?.toInt() ?? 0;
    final double totalEuros = _stats?['totalEuros']?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total des Pas (toutes entreprises)',
                    value: totalSteps.toString(), // Donnée dynamique
                    icon: Icons.directions_walk,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Total des Gains Générés',
                    value: '€${totalEuros.toStringAsFixed(2)}', // Donnée dynamique
                    icon: Icons.euro,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.swap_horiz, color: Colors.white),
              label: const Text('Convertir les Pas en Argent', style: TextStyle(color: Colors.white)),
              onPressed: _convertStepsToMoney,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF0057B8),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Classement des Entreprises',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildRankingTab('Jour', 0),
                const SizedBox(width: 8),
                _buildRankingTab('Semaine', 1),
                const SizedBox(width: 8),
                _buildRankingTab('Mois', 2),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _companyRanking.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final company = _companyRanking[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(company['logo']),
                    ),
                  ),
                  title: Text(company['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text(
                    '${company['steps']} pas',
                    style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // --- NOUVEAU: Extraction de l'AppBar pour éviter la duplication de code ---
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Dashboard Admin'),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF3575D3),
      elevation: 1,
    );
  }

  Widget _buildRankingTab(String text, int index) {
    final bool isSelected = _classementTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _classementTabIndex = index;
          // TODO: Appeler l'API pour mettre à jour le classement
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3575D3) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
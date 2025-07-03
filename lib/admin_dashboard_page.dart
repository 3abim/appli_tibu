// fichier: lib/admin_dashboard_page.dart

import 'package:flutter/material.dart';

class AdminDashboardPage extends StatefulWidget {
  final String token;
  const AdminDashboardPage({super.key, required this.token});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // --- Données Mockées (factices) ---
  int _totalSteps = 12543890;
  double _totalEuros = 12543.89;
  int _classementTabIndex = 0; // 0=Jour, 1=Semaine, 2=Mois

  // Fausse liste d'entreprises
  final List<Map<String, dynamic>> _companyRanking = [
    {'name': 'Tibu Inc.', 'steps': 8765432, 'logo': 'assets/logo.png'},
    {'name': 'Innovate Corp.', 'steps': 2456789, 'logo': 'assets/logo.png'},
    {'name': 'HealthFirst Ltd.', 'steps': 1321669, 'logo': 'assets/logo.png'},
  ];
  // --- Fin des données mockées ---

  void _convertStepsToMoney() {
    // Dans une vraie application, cela déclencherait une action backend.
    // Ici, on affiche juste une confirmation.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conversion Effectuée'),
        content: Text(
            'Les pas ont été convertis en ${_totalEuros.toStringAsFixed(2)}€ pour les écoles.'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3575D3),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Section des Statistiques ---
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total des Pas (toutes entreprises)',
                  value: _totalSteps.toString(),
                  icon: Icons.directions_walk,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Total des Gains Générés',
                  value: '€${_totalEuros.toStringAsFixed(2)}',
                  icon: Icons.euro,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Bouton d'Action ---
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

          // --- Section du Classement des Entreprises ---
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
          // Affichage de la liste des entreprises
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(), // pour ne pas scroller dans une ListView
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
    );
  }

  // Widget pour construire les onglets du classement
  Widget _buildRankingTab(String text, int index) {
    final bool isSelected = _classementTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _classementTabIndex = index;
          // Ici, vous appelleriez une fonction pour rafraîchir les données
          // ex: _fetchCompanyRanking(period: text.toLowerCase());
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

  // Widget pour construire les cartes de statistiques
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
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'dart:convert';

class AdminDashboardPage extends StatefulWidget {
  final String token;
  const AdminDashboardPage({super.key, required this.token});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _stats;
  List<dynamic> _companyRanking = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _classementTabIndex = 0; // 0: jour, 1: semaine, 2: mois

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }
  
  Future<void> _fetchAllData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _fetchDashboardStats(),
        _fetchClassement(),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst("Exception: ", ""));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchDashboardStats() async {
    _stats = await _apiService.getAdminDashboardStats();
  }

  Future<void> _fetchClassement() async {
    final periods = ['jour', 'semaine', 'mois'];
    _companyRanking = await _apiService.getOrganisationClassement(periods[_classementTabIndex]);
  }

  Future<void> _convertStepsToMoney() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation de Conversion'),
        content: const Text('Cette action est irréversible et réinitialisera les pas de tous les utilisateurs. Continuer ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _apiService.convertSteps();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversion effectuée avec succès !'), backgroundColor: Colors.green),
      );
      await _fetchAllData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _onRankingTabTapped(int index) {
    if (_isLoading) return;
    setState(() {
      _classementTabIndex = index;
      _isLoading = true; 
    });
    _fetchClassement().catchError((e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    }).whenComplete(() {
      if (mounted) setState(() => _isLoading = false);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Dashboard Admin'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3575D3),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildDashboardView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _fetchAllData, child: const Text("Réessayer")),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDashboardView() {
    final int totalSteps = _stats?['totalSteps']?.toInt() ?? 0;
    final double totalEuros = _stats?['totalEuros']?.toDouble() ?? 0.0;

    return RefreshIndicator(
      onRefresh: _fetchAllData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(title: 'Total des Pas', value: totalSteps.toString(), icon: Icons.directions_walk, color: Colors.blue.shade700)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(title: 'Gains Générés', value: '€${totalEuros.toStringAsFixed(2)}', icon: Icons.euro, color: Colors.green.shade700)),
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
          Text('Classement des Entreprises', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
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
          _companyRanking.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(child: Text("Aucune donnée de pas pour cette période.", style: TextStyle(color: Colors.grey))),
              )
            : ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _companyRanking.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final company = _companyRanking[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      child: Text(
                        (company['organisationName'] as String).isNotEmpty ? (company['organisationName'] as String)[0] : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(company['organisationName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(
                      '${company['totalSteps']} pas',
                      style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }

  Widget _buildRankingTab(String text, int index) {
    final bool isSelected = _classementTabIndex == index;
    return GestureDetector(
      onTap: () => _onRankingTabTapped(index),
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
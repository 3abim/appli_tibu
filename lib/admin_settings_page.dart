// fichier: lib/admin_settings_page.dart

import 'package:flutter/material.dart';

class AdminSettingsPage extends StatefulWidget {
  final String token;
  final String role;
  const AdminSettingsPage({super.key, required this.token, required this.role});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _notificationController = TextEditingController();

  void _sendNotification() {
    if (_notificationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez écrire un message avant d\'envoyer.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // --- Logique pour envoyer la notification (simulation) ---
    print('Notification envoyée: "${_notificationController.text}"');
    
    // Afficher une confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification envoyée avec succès !'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Vider le champ de texte
    _notificationController.clear();
  }

  void _exportReport(String reportType) {
    // --- Logique pour exporter un rapport (simulation) ---
    print('Exportation du rapport: "$reportType"');
    
    // Afficher une confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exportation du rapport "$reportType" en cours...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  void dispose() {
    _notificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres & Outils'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3575D3),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Section Envoyer une Notification ---
          _buildSectionCard(
            title: 'Envoyer une Notification',
            icon: Icons.campaign,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Le message sera envoyé à tous les collaborateurs.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notificationController,
                  decoration: const InputDecoration(
                    labelText: 'Votre message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text('Envoyer', style: TextStyle(color: Colors.white)),
                    onPressed: _sendNotification,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF3575D3),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- Section Export de Rapports ---
          _buildSectionCard(
            title: 'Export de Rapports',
            icon: Icons.download,
            content: Column(
              children: [
                const Text(
                  'Générez des rapports au format CSV ou PDF.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.people, color: Colors.blue),
                  title: const Text('Rapport des Utilisateurs'),
                  subtitle: const Text('Activité, classement, etc.'),
                  trailing: const Icon(Icons.file_download_outlined),
                  onTap: () => _exportReport('Utilisateurs'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.school, color: Colors.green),
                  title: const Text('Rapport des Écoles'),
                  subtitle: const Text('Gains distribués, participation.'),
                  trailing: const Icon(Icons.file_download_outlined),
                  onTap: () => _exportReport('Écoles'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour construire les cartes de section
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF3575D3), size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            content,
          ],
        ),
      ),
    );
  }
}
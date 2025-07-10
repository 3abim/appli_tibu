import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

// Assurez-vous que le chemin relatif vers votre service est correct
import '../services/api_service.dart';

class AdminSettingsPage extends StatefulWidget {
  final String token;
  final String role;
  const AdminSettingsPage({super.key, required this.token, required this.role});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _notificationController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isDownloading = false;

  @override
  void dispose() {
    _notificationController.dispose();
    super.dispose();
  }

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
    // TODO: Connecter à l'API
    print('Notification envoyée: "${_notificationController.text}"');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification envoyée avec succès !'),
        backgroundColor: Colors.green,
      ),
    );
    _notificationController.clear();
  }

  Future<void> _exportReport(String reportType) async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Génération du rapport "$reportType" en cours...')),
    );

    try {
      final Uint8List fileData;
      final String fileName;

      if (reportType == 'Utilisateurs') {
        fileData = await _apiService.exportUsersReport();
        fileName = 'rapport_utilisateurs_${DateTime.now().millisecondsSinceEpoch}.pdf';
      } else {
        fileData = await _apiService.exportSchoolsReport();
        fileName = 'rapport_ecoles_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(fileData);
      final result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
        throw Exception('Impossible d\'ouvrir le fichier: ${result.message}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
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
                  trailing: _isDownloading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.file_download_outlined),
                  onTap: () => _exportReport('Utilisateurs'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.school, color: Colors.green),
                  title: const Text('Rapport des Écoles'),
                  subtitle: const Text('Gains distribués, participation.'),
                  trailing: _isDownloading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.file_download_outlined),
                  onTap: () => _exportReport('Écoles'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
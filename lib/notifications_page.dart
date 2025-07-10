import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pour formater les dates

// Assurez-vous que le chemin vers votre ApiService est correct
// Si cette page est dans lib/collaborateur/ et le service dans lib/services/
// le chemin '../services/api_service.dart' est correct.
import '../services/api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // Permet de recharger les données (pour le bouton "Réessayer" et le RefreshIndicator)
  Future<void> _loadNotifications() async {
    setState(() {
      _notificationsFuture = _apiService.getNotifications();
    });
  }

  // Fonction utilitaire pour formater la date de manière lisible
  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy à HH:mm', 'fr_FR').format(date);
    } catch (e) {
      // Si la date est invalide, on retourne une chaîne vide ou un message d'erreur
      return 'Date invalide';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 1.0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          // Cas 1: Chargement des données en cours
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Cas 2: Une erreur s'est produite (réseau, serveur, etc.)
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString().replaceFirst("Exception: ", ""),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      onPressed: _loadNotifications,
                    ),
                  ],
                ),
              ),
            );
          }

          // Cas 3: Les données sont arrivées, mais la liste est vide
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune notification',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Cas 4: On a des notifications, on les affiche dans une liste
          return RefreshIndicator(
            onRefresh: _loadNotifications,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(indent: 72, endIndent: 16, height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index] as Map<String, dynamic>;
                return ListTile(
                  leading: const Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.campaign, color: Colors.white, size: 20),
                    ),
                  ),
                  title: Text(notification['message'] ?? 'Message non disponible'),
                  subtitle: Text(
                    _formatDate(notification['createdAt'] ?? ''),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  isThreeLine: false, // S'assure que le layout est compact
                );
              },
            ),
          );
        },
      ),
    );
  }
}
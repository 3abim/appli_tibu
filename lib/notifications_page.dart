import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // On utilise un Future pour gérer l'état de la requête (chargement, erreur, succès)
  late Future<List<dynamic>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    // On lance le chargement des notifications dès que la page est créée
    _loadNotifications();
  }

  // Permet de recharger les données (utilisé pour le bouton "Réessayer" et le RefreshIndicator)
  void _loadNotifications() {
    setState(() {
      _notificationsFuture = _fetchNotificationsFromServer();
    });
  }

  // La fonction qui fait l'appel API
  Future<List<dynamic>> _fetchNotificationsFromServer() async {
    // Récupérer le token stocké
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Session invalide. Veuillez vous reconnecter.');
    }

    // N'oubliez pas de mettre votre IP ici
    final url = Uri.parse('http://192.168.11.114:9091/api/notifications');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // Si le serveur répond OK, on décode le JSON et on le retourne
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erreur de connexion. Vérifiez votre connexion internet.');
    }
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return 'Date inconnue';
    try {
      final date = DateTime.parse(isoDate);

      return DateFormat('dd MMM yyyy à HH:mm', 'fr_FR').format(date);
    } catch (e) {
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
            return RefreshIndicator(
              onRefresh: () async => _loadNotifications(),
              child: ListView( // On utilise un ListView pour que RefreshIndicator fonctionne
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Aucune notification pour le moment',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadNotifications(),
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
                );
              },
            ),
          );
        },
      ),
    );
  }
}
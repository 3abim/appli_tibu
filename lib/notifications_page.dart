import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Notifications statiques (exemple)
    final notifications = [
      "Bienvenue sur Step Up !",
      "Nouvelle fonctionnalité : personnalisez vos objectifs.",
      "Bravo, vous avez atteint 80% de votre objectif aujourd'hui !",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: notifications.isEmpty
          ? const Center(child: Text("Aucune notification"))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(notifications[index]),
              ),
            ),
    );
  }
}
import 'package:flutter/material.dart';

class ComptePage extends StatelessWidget {
  final String nom;
  final String email;
  final String entreprise;

  const ComptePage({
    super.key,
    required this.nom,
    required this.email,
    required this.entreprise,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Compte'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.account_circle, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 24),
            Text("Nom : $nom", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            Text("Email : $email", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text("Entreprise : $entreprise", style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
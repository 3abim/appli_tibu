import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CollaborateurLoginPage extends StatefulWidget {
  const CollaborateurLoginPage({super.key});

  @override
  State<CollaborateurLoginPage> createState() => _CollaborateurLoginPageState();
}

class _CollaborateurLoginPageState extends State<CollaborateurLoginPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Image.asset(
                'assets/logo.png',
                height: 140,
              ),
              const SizedBox(height: 8),
              const Text(
                "Bienvenue",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Connectez-vous ou créez un compte",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const TabBar(
                labelColor: Colors.black,
                tabs: [
                  Tab(text: "Connexion"),
                  Tab(text: "Inscription"),
                ],
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    _ConnexionForm(),
                    _InscriptionForm(),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnexionForm extends StatelessWidget {
  const _ConnexionForm();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const TextField(
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
                  Checkbox(value: false, onChanged: null),
                  Text("Se souvenir de moi"),
                ],
              ),
              Text(
                "Mot de passe oublié ?",
                style: TextStyle(
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Action de connexion
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0057B8),
              foregroundColor: Colors.white,
            ),
            child: const Text("Se connecter"),
          ),
        ],
      ),
    );
  }
}

class _InscriptionForm extends StatefulWidget {
  const _InscriptionForm();

  @override
  State<_InscriptionForm> createState() => _InscriptionFormState();
}

class _InscriptionFormState extends State<_InscriptionForm> {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _organisationController = TextEditingController();
  final _emailController = TextEditingController();
  final _mdpController = TextEditingController();
  final _confirmMdpController = TextEditingController();

  Future<void> _registerCollaborateur() async {
    if (_mdpController.text != _confirmMdpController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Les mots de passe ne correspondent pas")),
      );
      return;
    }

    final url = Uri.parse('http://10.0.2.2:9090/api/collaborateurs/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "nom": _nomController.text,
        "prenom": _prenomController.text,
        "organisation": _organisationController.text,
        "email": _emailController.text,
        "motDePasse": _mdpController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inscription réussie")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          TextField(
            controller: _nomController,
            decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _prenomController,
            decoration: const InputDecoration(labelText: 'Prénom', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _organisationController,
            decoration: const InputDecoration(labelText: 'Organisation', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mdpController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmMdpController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirmer mot de passe', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _registerCollaborateur,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0057B8),
              foregroundColor: Colors.white,
            ),
            child: const Text("S’inscrire"),
          ),
        ],
      ),
    );
  }
}

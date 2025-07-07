import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

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
              Image.asset('assets/logo.png', height: 140),
              const SizedBox(height: 8),
              const Text("Bienvenue", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text("Connectez-vous ou créez un compte", style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 16),
              const TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF3575D3),
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

class _ConnexionForm extends StatefulWidget {
  const _ConnexionForm();

  @override
  State<_ConnexionForm> createState() => _ConnexionFormState();
}

class _ConnexionFormState extends State<_ConnexionForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final url = Uri.parse('http://10.0.2.2:9091/api/auth/login');
      print('Tentative de connexion à: $url');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        }),
      ).timeout(const Duration(seconds: 10));
      
      print('Réponse reçue - Status: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['token'] != null) {
          Navigator.pushReplacementNamed(
            context,
            '/dashboard',
            arguments: {'token': responseData['token']},
          );
        } else {
          throw Exception('Token manquant dans la réponse');
        }
      } else {
        String errorMessage = "Email ou mot de passe incorrect";
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['message'] ?? errorMessage;
          } catch (e) {
            errorMessage = "Erreur du serveur (${response.statusCode})";
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Timeout: Le serveur ne répond pas")),
      );
    } on SocketException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur de réseau: Vérifiez votre connexion")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}")),
      );
      print('Erreur de connexion: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Veuillez entrer un email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Veuillez entrer un mot de passe';
              return null;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: const Color(0xFF0057B8),
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Text("Se connecter"),
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
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _organisationController = TextEditingController();
  final _emailController = TextEditingController();
  final _mdpController = TextEditingController();
  final _confirmMdpController = TextEditingController();
  bool _isRegistering = false;

  Future<void> _registerCollaborateur() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mdpController.text != _confirmMdpController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Les mots de passe ne correspondent pas")),
      );
      return;
    }
    
    setState(() => _isRegistering = true);

    try {
      final url = Uri.parse('http://10.0.2.2:9091/api/auth/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "nom": _nomController.text.trim(),
          "prenom": _prenomController.text.trim(),
          "organisation": _organisationController.text.trim(),
          "email": _emailController.text.trim(),
          "password": _mdpController.text,
        }),
      );

      if (!mounted) return;
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Inscription réussie ! Connectez-vous maintenant."),
            backgroundColor: Colors.green,
          ),
        );
        // Revenir à l'onglet de connexion
        DefaultTabController.of(context).animateTo(0);
      } else {
        String errorMessage = "Erreur lors de l'inscription";
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['message'] ?? errorMessage;
          } catch (e) {
            errorMessage = "Erreur du serveur (${response.statusCode})";
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Veuillez entrer votre nom';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _prenomController,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Veuillez entrer votre prénom';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _organisationController,
              decoration: const InputDecoration(
                labelText: 'Organisation',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Veuillez entrer votre organisation';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Veuillez entrer un email';
                if (!value.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mdpController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Veuillez entrer un mot de passe';
                if (value.length < 6) return 'Minimum 6 caractères';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmMdpController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer mot de passe',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != _mdpController.text) return 'Les mots de passe ne correspondent pas';
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isRegistering ? null : _registerCollaborateur,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF0057B8),
                foregroundColor: Colors.white,
              ),
              child: _isRegistering
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text("S'inscrire"),
            ),
          ],
        ),
      ),
    );
  }
}
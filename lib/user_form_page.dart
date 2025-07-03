// fichier: lib/admin/user_form_page.dart

import 'package:flutter/material.dart';

class UserFormPage extends StatefulWidget {
  // On passe l'utilisateur à modifier. Si c'est null, on est en mode "Ajout".
  final Map<String, String>? user;

  const UserFormPage({super.key, this.user});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _companyController;
  late TextEditingController _passwordController;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    // On pré-remplit les champs si on est en mode "Modification"
    _nameController = TextEditingController(text: widget.user?['name']);
    _emailController = TextEditingController(text: widget.user?['email']);
    _companyController = TextEditingController(text: widget.user?['company']);
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      // On crée un nouvel objet utilisateur avec les données du formulaire
      final newUser = {
        'name': _nameController.text,
        'email': _emailController.text,
        'company': _companyController.text,
      };

      // On renvoie l'utilisateur créé/modifié à la page précédente
      Navigator.of(context).pop(newUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier l\'utilisateur' : 'Ajouter un utilisateur'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3575D3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom complet'),
                validator: (value) => value!.isEmpty ? 'Le nom est requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'L\'email est requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'Entreprise'),
                validator: (value) => value!.isEmpty ? 'L\'entreprise est requise' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  // On affiche une info si on modifie un utilisateur
                  hintText: _isEditing ? 'Laisser vide pour ne pas changer' : null,
                ),
                obscureText: true,
                // Le mot de passe n'est requis que lors de la création
                validator: (value) => !_isEditing && value!.isEmpty ? 'Le mot de passe est requis' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF3575D3),
                  foregroundColor: Colors.white,
                ),
                child: Text(_isEditing ? 'Sauvegarder' : 'Créer l\'utilisateur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
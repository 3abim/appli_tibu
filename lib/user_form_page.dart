import 'package:appli_tibu/services/api_service.dart'; 
import 'package:flutter/material.dart';

class UserFormPage extends StatefulWidget {
  final Map<String, dynamic>? user; 
  const UserFormPage({super.key, this.user});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  // Les variables et fonctions doivent être DANS la classe State
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false; // <<<--- VARIABLE AJOUTÉE

  final ApiService _apiService = ApiService(); // <<<--- INSTANCE DÉPLACÉE ICI

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user?['prenom']);
    _lastNameController = TextEditingController(text: widget.user?['nom']);
    _emailController = TextEditingController(text: widget.user?['email']);
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // La fonction de soumission doit être DANS la classe State
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final Map<String, dynamic> userData = {
        'prenom': _firstNameController.text,
        'nom': _lastNameController.text,
        'email': _emailController.text,
      };
      if (_passwordController.text.isNotEmpty) {
        userData['password'] = _passwordController.text;
      }

      try {
        if (_isEditing) {
          await _apiService.updateAdmin(widget.user!['id'], userData);
        } else {
          await _apiService.createAdmin(userData);
        }
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${e.toString()}'))
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier l\'administrateur' : 'Ajouter un administrateur'),
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
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Prénom'),
                validator: (value) => value!.isEmpty ? 'Le prénom est requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Nom'),
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
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  hintText: _isEditing ? 'Laisser vide pour ne pas changer' : null,
                ),
                obscureText: true,
                validator: (value) => !_isEditing && value!.isEmpty ? 'Le mot de passe est requis' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF3575D3),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : Text(_isEditing ? 'Sauvegarder' : 'Créer l\'administrateur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
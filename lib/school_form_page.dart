import 'package:appli_tibu/services/api_service.dart'; // <<<--- IMPORT AJOUTÉ
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SchoolFormPage extends StatefulWidget {
  final Map<String, dynamic>? school;
  const SchoolFormPage({super.key, this.school});

  @override
  State<SchoolFormPage> createState() => _SchoolFormPageState();
}

class _SchoolFormPageState extends State<SchoolFormPage> {
  // Les variables et fonctions doivent être DANS la classe State
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _budgetController;
  bool _isLoading = false; // <<<--- VARIABLE AJOUTÉE

  final ApiService _apiService = ApiService(); // <<<--- INSTANCE DÉPLACÉE ICI

  bool get _isEditing => widget.school != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.school?['nom'] ?? '');
    _cityController = TextEditingController(text: widget.school?['ville'] ?? '');
    // On utilise budgetEuros qui vient du DTO
    final budget = widget.school?['budgetEuros'] as num?;
    _budgetController = TextEditingController(text: budget?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  // La fonction de soumission doit être DANS la classe State
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final schoolData = {
        'nom': _nameController.text,
        'ville': _cityController.text,
        'budgetEuros': double.parse(_budgetController.text),
      };

      try {
        if (_isEditing) {
          await _apiService.updateEcole(widget.school!['id'], schoolData);
        } else {
          await _apiService.createEcole(schoolData);
        }
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
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
        title: Text(_isEditing ? 'Modifier l\'école' : 'Ajouter une école'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3575D3),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom de l\'école'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Ville'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une ville';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Budget',
                  suffixText: '€', 
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un budget';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                   if (double.parse(value) < 0) {
                     return 'Le budget ne peut pas être négatif';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm, // Désactive le bouton pdt le chargement
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3575D3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : Text(
                        _isEditing ? 'Enregistrer les modifications' : 'Ajouter l\'école',
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
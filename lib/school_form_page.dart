import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import pour le filtrage des entrées numériques

class SchoolFormPage extends StatefulWidget {
  final Map<String, dynamic>? school;

  const SchoolFormPage({super.key, this.school});

  @override
  State<SchoolFormPage> createState() => _SchoolFormPageState();
}

class _SchoolFormPageState extends State<SchoolFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  // --- NOUVEAU : On ajoute un controller pour le budget ---
  late TextEditingController _budgetController;

  bool get _isEditing => widget.school != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.school?['name'] ?? '');
    _cityController = TextEditingController(text: widget.school?['city'] ?? '');
    
    // --- NOUVEAU : On initialise le controller du budget ---
    // On convertit le double en String pour le champ de texte.
    // Si c'est une nouvelle école, on laisse le champ vide.
    _budgetController = TextEditingController(
        text: _isEditing ? widget.school!['gains'].toString() : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    // --- NOUVEAU : On n'oublie pas de disposer le nouveau controller ---
    _budgetController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // --- MODIFIÉ : On récupère la valeur du budget depuis le controller ---
      final newSchoolData = {
        'name': _nameController.text,
        'city': _cityController.text,
        // On reconvertit le texte en double. Le validateur garantit que c'est possible.
        'gains': double.parse(_budgetController.text), 
      };

      Navigator.of(context).pop(newSchoolData);
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
              // --- NOUVEAU : Champ de formulaire pour le budget ---
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Budget bénéficié',
                  suffixText: '€', 
                ),
                // On s'assure que le clavier est de type numérique
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                // On filtre pour n'autoriser que les chiffres et le point décimal
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
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3575D3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
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
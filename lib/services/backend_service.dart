import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> submitRegistration({
  required String nom,
  required String prenom,
  required String organisation,
  required String email,
  required String password,
  required String confirmPassword,
}) async {
  print('>>> FLUTTER DEBUG: Début de submitRegistration.');
  if (password != confirmPassword) {
    return;
  }

  final url = Uri.parse('http://192.168.11.140:9091/api/auth/register');
  print('>>> FLUTTER DEBUG: URL cible: $url'); 
  final Map<String, dynamic> data = {
    'nom': nom,
    'email': email,
    'password': password,
    'pas': 0,
    'objectif': 10000,
    'euros': 0.0,
    'classement': 0,
    'entreprise': organisation,
  };
  print('>>> FLUTTER DEBUG: Corps de la requête JSON envoyé: ${jsonEncode(data)}');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  print('>>> FLUTTER DEBUG: Statut HTTP reçu: ${response.statusCode}'); // POINT 5
    print('>>> FLUTTER DEBUG: Corps de la réponse HTTP: ${response.body}');
    if (response.statusCode == 201) {
       print('>>> FLUTTER DEBUG: Inscription réussie !');
    } else {
      print('>>> FLUTTER DEBUG: Erreur du backend (code ${response.statusCode}).');
      String errorMessage = "Erreur lors de l'inscription.";
      try {
        final Map<String, dynamic> errorResponse = jsonDecode(response.body);
        if (errorResponse.containsKey('message')) {
          errorMessage = errorResponse['message'];
        } else if (errorResponse.containsKey('password')) {
          errorMessage = errorResponse['password'];
        } else if (errorResponse.containsKey('email')) {
          errorMessage = errorResponse['email'];
        }
      } catch (e) {
      }
    }
  } catch (e) {
     print('>>> FLUTTER DEBUG: Erreur réseau ou exception inattendue: $e');
  }
   print('>>> FLUTTER DEBUG: Fin de submitRegistration.');
}

Future<void> sendStepsToBackend(String email, int steps) async {
  final url = Uri.parse('http://192.168.11.140:9091/api/steps/update');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'steps': steps,
    }),
  );

  if (response.statusCode == 200) {
    print('Pas envoyés avec succès');
  } else {
    print('Erreur envoi pas: ${response.body}');
  }
}
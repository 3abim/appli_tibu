import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendStepsToBackend(String email, int steps) async {
final url = Uri.parse('http://10.0.2.2:9090/api/steps/update');

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

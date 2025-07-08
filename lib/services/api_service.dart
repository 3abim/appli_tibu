import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = Platform.isAndroid 
      ? 'http://10.0.2.2:9091' 
      : 'http://localhost:9091';
  String? _token;

  // Gestion centralisée des erreurs
  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return jsonDecode(response.body);
      case 400:
        throw BadRequestException(response.body);
      case 401:
      case 403:
        throw UnauthorizedException('Accès refusé');
      case 404:
        throw NotFoundException('Endpoint non trouvé');
      case 500:
        throw ServerException('Erreur serveur');
      default:
        throw FetchDataException('Erreur inconnue: ${response.statusCode}');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
     await _loadToken();
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<void> _loadToken() async {
    if (_token != null) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // --- AUTHENTICATION ---
  Future<dynamic> login(String email, String password) async {
  final uri = Uri.parse('$_baseUrl/api/auth/login');
  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json; charset=utf-8'},
    body: jsonEncode({'email': email, 'password': password}),
  );

  if (response.statusCode == 200) {
    return json.decode(utf8.decode(response.bodyBytes)); // Gestion UTF-8
  } else {
    throw Exception('Échec de la connexion');
  }
}

Future<dynamic> loginAdmin(String email, String password) async {
    final uri = Uri.parse('$_baseUrl/api/auth/admin/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      // On sauvegarde le token directement après une connexion réussie
      await _saveToken(data['token']);
      return data;
    } else {
      // Lance une exception avec le message du serveur s'il existe
      final errorBody = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['message'] ?? 'Échec de la connexion admin');
    }
  }
  Future<dynamic> getAdminDashboardStats() async {
  await _loadToken();
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/admin/dashboard-stats'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  } catch (e) {
    rethrow;
  }
} 

  Future<dynamic> register({
    required String nom,
    required String prenom,
    required String organisation,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'nom': nom,
          'prenom': prenom,
          'organisation': organisation,
          'email': email,
          'password': password,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // --- COLLABORATEUR ENDPOINTS ---
  Future<dynamic> updateSteps(int steps) async {
    await _loadToken();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/steps'),
        headers: await _getHeaders(),
        body: jsonEncode({'steps': steps}),
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getDashboardStats() async {
    await _loadToken();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/collaborateur/dashboard'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // --- ADMIN ENDPOINTS ---
  Future<dynamic> getAllUsers() async {
    await _loadToken();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/admin/users'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
}

// Classes d'exception personnalisées
class AppException implements Exception {
  final String message;
  AppException(this.message);
  
  @override
  String toString() => message;
}

class BadRequestException extends AppException {
  BadRequestException(String message) : super(message);
}

class UnauthorizedException extends AppException {
  UnauthorizedException(String message) : super(message);
}

class NotFoundException extends AppException {
  NotFoundException(String message) : super(message);
}

class ServerException extends AppException {
  ServerException(String message) : super(message);
}

class FetchDataException extends AppException {
  FetchDataException(String message) : super(message);
}
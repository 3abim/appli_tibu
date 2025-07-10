import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http; 
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = 'http://192.168.11.140:9091';
  String? _token;

  // Gestion centralisée des erreurs
  dynamic _handleResponse(http.Response response) {
    // Décode le corps une seule fois pour éviter les erreurs
    final dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      // Si le corps est vide ou invalide, on se base sur le statut
      if (response.statusCode >= 200 && response.statusCode < 300) return null;
      throw FetchDataException('Erreur de communication avec le serveur (Status ${response.statusCode})');
    }

    switch (response.statusCode) {
      case 200:
      case 201:
        return body;
      case 204: // No Content
        return null; // Pas de corps à retourner
      case 400:
        throw BadRequestException(body['message'] ?? 'Requête invalide');
      case 401:
      case 403:
        throw UnauthorizedException('Accès refusé. Veuillez vous reconnecter.');
      case 404:
        throw NotFoundException('La ressource demandée n\'a pas été trouvée.');
      case 500:
        throw ServerException(body['message'] ?? 'Erreur interne du serveur.');
      default:
        throw FetchDataException('Erreur inconnue: ${response.statusCode}');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
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
    final data = _handleResponse(response);
    await _saveToken(data['token']);
    return data;
  }

  Future<dynamic> loginAdmin(String email, String password) async {
    print('>>> DANS ApiService: Méthode loginAdmin appelée.');
    final uri = Uri.parse('$_baseUrl/api/auth/admin/login');
    print('>>> URL FINALE CONSTRUITE: ${uri.toString()}');
    try { 
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'email': email, 'password': password}),
       ).timeout(const Duration(seconds: 15));
       print('>>> RÉPONSE BRUTE DU SERVEUR: Status ${response.statusCode}, Body: ${response.body}');
    
    final data = _handleResponse(response);
    await _saveToken(data['token']);
    return data;
  } catch (e) {
      print('>>> ERREUR RÉSEAU OU TIMEOUT: ${e.toString()}');
      throw FetchDataException('Erreur lors de la connexion admin: $e');
    }
  }

Future<dynamic> getAdminDashboardStats() async {
    final uri = Uri.parse('$_baseUrl/api/admin/dashboard/stats');
    final response = await http.get(uri, headers: await _getHeaders());
    return _handleResponse(response);
  } 

  Future<List<dynamic>> getOrganisationClassement(String periode) async {
    final uri = Uri.parse('$_baseUrl/api/admin/dashboard/classement?periode=$periode');
    final response = await http.get(uri, headers: await _getHeaders());
    return _handleResponse(response);
  }

  Future<void> convertSteps() async {
    final uri = Uri.parse('$_baseUrl/api/admin/dashboard/convert');
    final response = await http.post(uri, headers: await _getHeaders());
    _handleResponse(response);
  }
  // --- GESTION ADMINS ---
  Future<List<dynamic>> getAdmins() async {
    final uri = Uri.parse('$_baseUrl/api/management/admins');
    final response = await http.get(uri, headers: await _getHeaders());
    return _handleResponse(response);
  }

  Future<dynamic> createAdmin(Map<String, dynamic> adminData) async {
    final uri = Uri.parse('$_baseUrl/api/management/admins');
    final response = await http.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(adminData),
    );
    return _handleResponse(response);
  }

  Future<dynamic> updateAdmin(String id, Map<String, dynamic> adminData) async {
    final uri = Uri.parse('$_baseUrl/api/management/admins/$id');
    final response = await http.put(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(adminData),
    );
    return _handleResponse(response);
  }

  Future<void> deleteAdmin(String id) async {
    final uri = Uri.parse('$_baseUrl/api/management/admins/$id');
    final response = await http.delete(uri, headers: await _getHeaders());
    _handleResponse(response); // Gère les erreurs de statut
  }

  // --- GESTION ECOLES ---
  Future<List<dynamic>> getEcoles() async {
    final uri = Uri.parse('$_baseUrl/api/management/ecoles');
    final response = await http.get(uri, headers: await _getHeaders());
    return _handleResponse(response);
  }

  Future<dynamic> createEcole(Map<String, dynamic> ecoleData) async {
    final uri = Uri.parse('$_baseUrl/api/management/ecoles');
    final response = await http.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(ecoleData),
    );
    return _handleResponse(response);
  }

  Future<dynamic> updateEcole(String id, Map<String, dynamic> ecoleData) async {
    final uri = Uri.parse('$_baseUrl/api/management/ecoles/$id');
    final response = await http.put(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(ecoleData),
    );
    return _handleResponse(response);
  }

  Future<void> deleteEcole(String id) async {
    final uri = Uri.parse('$_baseUrl/api/management/ecoles/$id');
    final response = await http.delete(uri, headers: await _getHeaders());
    _handleResponse(response); // Gère les erreurs de statut
  }

  
  Future<Uint8List> exportUsersReport() async {
    final uri = Uri.parse('$_baseUrl/api/admin/tools/reports/users');
    final headers = <String, String>{};
    await _loadToken(); // Charge le token
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download users report');
    }
  }

 Future<Uint8List> exportSchoolsReport() async {
    final uri = Uri.parse('$_baseUrl/api/admin/tools/reports/schools');
    final headers = <String, String>{};
    await _loadToken(); // Charge le token
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download schools report');
    }
  }

  Future<List<dynamic>> getNotifications() async {
    final uri = Uri.parse('$_baseUrl/api/notifications');
    final response = await http.get(uri, headers: await _getHeaders());
    return _handleResponse(response);
  }
}

// Dans la classe ApiService, à la suite des autres méthodes


// Classes d'exception personnalisées (elles doivent être en dehors de la classe ApiService)
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
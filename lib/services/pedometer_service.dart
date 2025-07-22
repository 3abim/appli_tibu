import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:http/http.dart' as http;

class PedometerService {
  static final PedometerService _instance = PedometerService._internal();
  factory PedometerService() => _instance;
  PedometerService._internal();

  final ValueNotifier<int> totalStepsToday = ValueNotifier<int>(0);

  String? _apiToken;
  int _serverSteps = 0;
  int _pedometerOffset = 0;
  StreamSubscription<StepCount>? _stepSubscription;
  Timer? _syncTimer;
  bool _isInitialized = false;

  Future<void> initialize(String token) async {
    if (_isInitialized) return;
    print("PedometerService: Initialisation...");
    _apiToken = token;
    _isInitialized = true;

    await _fetchInitialSteps();
    _startPedometerListener();
    _startSyncTimer();
  }

   Future<void> stop() async {
    print("PedometerService: Arrêt demandé...");
    _stepSubscription?.cancel();
    _syncTimer?.cancel();
    _stepSubscription = null;
    _syncTimer = null;
    
    await _syncStepsToServer(); 

    _isInitialized = false;
    _apiToken = null;
    totalStepsToday.value = 0;
    _serverSteps = 0;
    _pedometerOffset = 0;
    print("PedometerService: Services arrêtés.");
  }

  Future<void> _fetchInitialSteps() async {
    if (_apiToken == null) return;
    try {
      final url = Uri.parse('http://192.168.11.158:9091/api/collaborateur/dashboard');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $_apiToken'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _serverSteps = (data['pasAujourdHui'] as num?)?.toInt() ?? 0;
        totalStepsToday.value = _serverSteps;
        print("PedometerService: Pas initiaux du serveur: $_serverSteps");
      }
    } catch (e) {
      print("PedometerService: Erreur de récupération des pas initiaux: $e");
    }
  }

  void _startPedometerListener() {
    _stepSubscription?.cancel();
    _stepSubscription = Pedometer.stepCountStream.listen(
      (StepCount event) {
        if (!_isInitialized) return;
        
        if (_pedometerOffset == 0 || event.steps < _pedometerOffset) {
          print("PedometerService: Réinitialisation de l'offset du podomètre.");
          _pedometerOffset = event.steps;
          // On recalcule les pas déjà enregistrés pour la session
          _serverSteps = totalStepsToday.value;
        }

        int sessionSteps = event.steps - _pedometerOffset;
        if (sessionSteps < 0) sessionSteps = 0;

        totalStepsToday.value = _serverSteps + sessionSteps;
      },
      onError: (error) {
        print("PedometerService: Erreur du capteur: $error");
      },
    );
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) => _syncStepsToServer());
  }

  Future<void> _syncStepsToServer() async {
    if (!_isInitialized || _apiToken == null || totalStepsToday.value <= _serverSteps) return;
    
    print("PedometerService: Synchronisation de ${totalStepsToday.value} pas.");
    try {
      final url = Uri.parse('http://192.168.11.158:9091/api/pas/update');
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $_apiToken', 'Content-Type': 'application/json'},
        body: jsonEncode({'pas': totalStepsToday.value}),
      );
      if (response.statusCode == 200) {
        _serverSteps = totalStepsToday.value;
      }
    } catch (e) {
      print("PedometerService: Erreur de synchronisation: $e");
    }
  }
}
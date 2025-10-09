// lib/auth_providers.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _token;
  String? get token => _token;

  String? _username;
  String? get username => _username;

  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadUserFromStorage(); // Automatically try to log in when the app starts
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(username, password);

      if (response['success'] == true && response.containsKey('token')) {
        // --- SAVE THE USER DATA ---
        final prefs = await SharedPreferences.getInstance();
        _token = response['token'];
        _username = response['user']['username'];
        final authScheme = response['authScheme'] as String?;

        await prefs.setString('authToken', _token!);
        await prefs.setString('username', _username!);
        if (authScheme != null) {
          await prefs.setString('authScheme', authScheme);
        }

        // Set the token in the ApiService for all future requests
        _apiService.setAuthToken(_token!, scheme: authScheme);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'An unknown error occurred';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('authToken');
    final storedUsername = prefs.getString('username');
    final storedScheme = prefs.getString('authScheme');

    if (storedToken != null && storedUsername != null) {
      _token = storedToken;
      _username = storedUsername;
      _apiService.setAuthToken(
        _token!,
        scheme: storedScheme,
      ); // Configure ApiService for authenticated requests
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('username');
    _token = null;
    _username = null;
    // You might want to clear the token in ApiService as well
    // _apiService.setAuthToken(null);
    notifyListeners();
  }

  Future<bool> reportIncident(Map<String, dynamic> incidentDetails) async {
    if (!isAuthenticated) {
      _errorMessage = "You must be logged in to report an incident.";
      notifyListeners();
      return false;
    }

    try {
      await _apiService.postIncident(incidentDetails);
      return true;
    } catch (e) {
      final message = e.toString();
      _errorMessage = message;
      // If credentials missing/expired, force logout so LoginScreen shows again
      if (message.contains('401') ||
          message.contains('Authentication credentials were not provided')) {
        await logout();
      }
      notifyListeners();
      print(e); // For debugging purposes
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getIncidents() async {
    if (!isAuthenticated) {
      _errorMessage = "You must be logged in to view incidents.";
      notifyListeners();
      return [];
    }

    try {
      final incidents = await _apiService.getIncidents();
      return incidents;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      print(e); // For debugging purposes
      return [];
    }
  }

  // Blockchain UUID methods
  Future<Map<String, dynamic>> generateUUID() async {
    if (!isAuthenticated) {
      _errorMessage = "You must be logged in to generate UUIDs.";
      notifyListeners();
      return {'success': false, 'message': 'Not authenticated'};
    }

    try {
      final response = await _apiService.generateUUID();
      return response;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      print(e); // For debugging purposes
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getLatestUUID() async {
    if (!isAuthenticated) {
      _errorMessage = "You must be logged in to view UUIDs.";
      notifyListeners();
      return {'success': false, 'message': 'Not authenticated'};
    }

    try {
      final response = await _apiService.getLatestUUID();
      return response;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      print(e); // For debugging purposes
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getUserUUIDs() async {
    if (!isAuthenticated) {
      _errorMessage = "You must be logged in to view UUIDs.";
      notifyListeners();
      return {'success': false, 'message': 'Not authenticated'};
    }

    try {
      final response = await _apiService.getUserUUIDs();
      return response;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      print(e); // For debugging purposes
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyUUID(String uuidValue) async {
    if (!isAuthenticated) {
      _errorMessage = "You must be logged in to verify UUIDs.";
      notifyListeners();
      return {'success': false, 'message': 'Not authenticated'};
    }

    try {
      final response = await _apiService.verifyUUID(uuidValue);
      return response;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      print(e); // For debugging purposes
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyBlock(int blockId) async {
    if (!isAuthenticated) {
      _errorMessage = "You must be logged in to verify blocks.";
      notifyListeners();
      return {'success': false, 'message': 'Not authenticated'};
    }

    try {
      final response = await _apiService.verifyBlock(blockId);
      return response;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      print(e); // For debugging purposes
      return {'success': false, 'message': e.toString()};
    }
  }
}

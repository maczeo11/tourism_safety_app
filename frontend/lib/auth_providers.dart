import 'package:flutter/material.dart';
import 'api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(username, password);

      // Your LoginView returns 'success': true upon a successful login
      if (response['success'] == true) {
        // Here you would typically save the user data or token
        // For now, we'll just return true
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Handles cases like 'Invalid credentials' from your backend
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
}
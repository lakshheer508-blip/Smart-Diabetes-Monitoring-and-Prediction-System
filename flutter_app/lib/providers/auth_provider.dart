import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String _errorMessage = '';

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  AuthProvider() {
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token != null && token != 'demo_token' && token.isNotEmpty) {
        _isAuthenticated = true;
      } else {
        // Clean up invalid tokens
        await prefs.remove('jwt_token');
        _isAuthenticated = false;
      }
    } catch (e) {
      print("SharedPreferences Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _errorMessage = '';
    final result = await ApiService.login(email, password);
    
    if (result != null && result['access_token'] != null) {
      _isAuthenticated = true;
      _errorMessage = '';
      notifyListeners();
      return true;
    } else {
      _errorMessage = result?['error'] ?? 'Invalid email or password';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _errorMessage = '';
    final result = await ApiService.register(name, email, password);
    
    if (result['success'] == true) {
      // Auto-login after registration
      return login(email, password);
    } else {
      _errorMessage = result['error'] ?? 'Registration failed';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    _isAuthenticated = false;
    _errorMessage = '';
    notifyListeners();
  }
}

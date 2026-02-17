import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../config/constants.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;

  Future<void> initialize() async {
    await _apiService.initialize();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Mock login for demo purposes
      await Future.delayed(const Duration(seconds: 1));
      
      if (email.isEmpty || password.isEmpty) {
        _error = 'Email and password are required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create a mock token and user
      _token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
      await _apiService.setToken(_token!);
      _user = User(
        id: 'user_123',
        name: email.split('@')[0],
        email: email,
        role: 'user',
        isActive: true,
        createdAt: DateTime.now(),
      );
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Mock registration for demo purposes
      await Future.delayed(const Duration(seconds: 1));
      
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        _error = 'All fields are required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!email.contains('@')) {
        _error = 'Please enter a valid email';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.length < 6) {
        _error = 'Password must be at least 6 characters';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create a mock token and user
      _token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
      await _apiService.setToken(_token!);
      _user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        role: 'user',
        isActive: true,
        createdAt: DateTime.now(),
      );
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    await _apiService.clearToken();
    notifyListeners();
  }

  Future<void> getProfile() async {
    try {
      final response = await _apiService.get(AppConstants.getUserEndpoint);
      _user = User.fromJson(response);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

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

    if (email.isEmpty || password.isEmpty) {
      _error = 'Email and password are required';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // shortcut when working against mock backend
    if (AppConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 300));
      _token = 'mock-token';
      _user = User(
        id: '1',
        name: 'Mock User',
        email: email,
        isActive: true,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      final response = await _apiService.post(
        AppConstants.loginEndpoint,
        data: {'email': email, 'password': password},
        requiresAuth: false,
      );

      // expect response to contain token and user
      if (response is Map<String, dynamic>) {
        _token = response['token'] ?? response['accessToken'];
        if (_token != null) {
          await _apiService.setToken(_token!);
        }
        final userData = response['user'] ?? response;
        _user = User.fromJson(userData as Map<String, dynamic>);
      }

      _isLoading = false;
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

    // mock branch
    if (AppConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 300));
      _token = 'mock-token';
      _user = User(
        id: '1',
        name: name,
        email: email,
        isActive: true,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      final response = await _apiService.post(
        AppConstants.registerEndpoint,
        data: {'name': name, 'email': email, 'password': password},
        requiresAuth: false,
      );
      if (response is Map<String, dynamic>) {
        _token = response['token'] ?? response['accessToken'];
        if (_token != null) {
          await _apiService.setToken(_token!);
        }
        final userData = response['user'] ?? response;
        _user = User.fromJson(userData as Map<String, dynamic>);
      }
      _isLoading = false;
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
    if (AppConstants.useMockApi) {
      // leave existing mock user as-is
      return;
    }

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

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _isLoading = true;
    notifyListeners();

    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      _user = await _authService.getCurrentUser();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final success = await _authService.login(email, password);
      if (success) {
        _user = await _authService.getCurrentUser();
        notifyListeners();
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final success = await _authService.register(name, email, password);
      if (success) {
        _user = await _authService.getCurrentUser();
        notifyListeners();
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
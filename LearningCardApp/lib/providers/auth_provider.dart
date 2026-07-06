import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? user;
  bool isLoading = false;
  bool isInitialized = false;
  String? errorMessage;

  bool get isAuthenticated => user != null;

  Future<void> tryAutoLogin() async {
    if (isInitialized) return;
    isLoading = true;
    notifyListeners();
    try {
      user = await _authService.getProfile();
    } catch (_) {
      user = null;
    } finally {
      isLoading = false;
      isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _authService.login(email: email, password: password);
      user = result['user'] as UserModel;
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      await _authService.register(name: name, email: email, password: password);
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    user = null;
    notifyListeners();
  }
}
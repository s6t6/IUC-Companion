import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final user = await _apiService.login(email, password);
    
    if (user != null) {
      _currentUser = user;
    }
    
    _isLoading = false;
    notifyListeners();
    return user != null;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
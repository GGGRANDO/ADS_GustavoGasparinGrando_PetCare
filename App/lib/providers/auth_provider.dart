import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _usuario;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get usuario => _usuario;
  bool get isLoggedIn => _usuario != null;
  bool get loading => _loading;
  String? get error => _error;

  AuthProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('usuario');
    if (raw != null) {
      _usuario = jsonDecode(raw) as Map<String, dynamic>;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String senha) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.login(email, senha);
      _usuario = data['usuario'] as Map<String, dynamic>;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _usuario = null;
    notifyListeners();
  }
}

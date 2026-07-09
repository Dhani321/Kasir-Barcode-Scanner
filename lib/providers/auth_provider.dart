import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.role == 'admin';

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await AuthService.login(username, password);
      _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    if (await AuthService.isLoggedIn()) {
      _user = await AuthService.me();
      notifyListeners();
    }
  }

  String _parseError(dynamic e) {
    try {
      final resp = (e as dynamic).response;
      if (resp != null && resp.data is Map) {
        return resp.data['message'] ?? 'Terjadi kesalahan.';
      }
    } catch (_) {}
    return 'Tidak dapat terhubung ke server. Pastikan server berjalan.';
  }
}

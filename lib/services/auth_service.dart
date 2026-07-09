import '../services/api_client.dart';
import '../models/user.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final resp = await ApiClient.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    final data = resp.data as Map<String, dynamic>;
    await ApiClient.setToken(data['token'] as String);
    return data;
  }

  static Future<void> logout() async {
    try {
      await ApiClient.post('/auth/logout');
    } catch (_) {}
    await ApiClient.clearToken();
  }

  static Future<AppUser?> me() async {
    try {
      final resp = await ApiClient.get('/auth/me');
      return AppUser.fromJson(resp.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isLoggedIn() => ApiClient.hasToken();
}

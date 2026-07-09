import '../services/api_client.dart';

class UserService {
  static Future<List<dynamic>> getUsers({String? role, String? search}) async {
    final resp = await ApiClient.get('/users', params: {
      if (role != null) 'role': role,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return resp.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final resp = await ApiClient.post('/users', data: data);
    return resp.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async {
    final resp = await ApiClient.put('/users/$id', data: data);
    return resp.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> toggleActive(int id) async {
    final resp = await ApiClient.patch('/users/$id/toggle-active');
    return resp.data as Map<String, dynamic>;
  }

  static Future<void> deleteUser(int id) async {
    await ApiClient.delete('/users/$id');
  }
}

class ReportService {
  static Future<Map<String, dynamic>> getSalesReport({
    String? dateFrom,
    String? dateTo,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final resp = await ApiClient.get('/reports/sales', params: {
      'date_from': dateFrom ?? today,
      'date_to': dateTo ?? today,
    });
    return resp.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final resp = await ApiClient.get('/reports/dashboard');
    return resp.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getShiftReport(int shiftId) async {
    final resp = await ApiClient.get('/reports/shift/$shiftId');
    return resp.data as Map<String, dynamic>;
  }
}

class SettingService {
  static Future<Map<String, dynamic>> getSettingsFlat() async {
    final resp = await ApiClient.get('/settings/flat');
    return resp.data as Map<String, dynamic>;
  }

  static Future<void> bulkUpdate(Map<String, dynamic> settings) async {
    await ApiClient.put('/settings', data: {'settings': settings});
  }
}

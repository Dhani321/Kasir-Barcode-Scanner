import 'api_client.dart';
import '../models/activity_log.dart';

class ActivityLogService {
  static Future<Map<String, dynamic>> getActivityLogs({
    String? search,
    String? action,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 30,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'per_page': perPage};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (action != null && action.isNotEmpty) query['action'] = action;
    if (dateFrom != null && dateFrom.isNotEmpty) query['date_from'] = dateFrom;
    if (dateTo != null && dateTo.isNotEmpty) query['date_to'] = dateTo;

    final response = await ApiClient.get('/activity-logs', params: query);
    final data = response.data;
    
    final List<ActivityLog> logs = (data['data'] as List)
        .map((e) => ActivityLog.fromJson(e))
        .toList();

    return {
      'logs': logs,
      'total': data['total'] ?? logs.length,
      'current_page': data['current_page'] ?? 1,
      'last_page': data['last_page'] ?? 1,
    };
  }

  static Future<Map<String, dynamic>> getStockMovementReport({
    required int month,
    required int year,
  }) async {
    final response = await ApiClient.get('/reports/stock-movement', params: {
      'month': month,
      'year': year,
    });
    return response.data;
  }
}

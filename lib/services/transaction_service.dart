import '../services/api_client.dart';

class TransactionService {
  static Future<Map<String, dynamic>> createTransaction({
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required double paymentAmount,
    String? customerName,
  }) async {
    final resp = await ApiClient.post('/transactions', data: {
      'items': items,
      'payment_method': paymentMethod,
      'payment_amount': paymentAmount,
      if (customerName != null) 'customer_name': customerName,
    });
    return resp.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getTransactions({
    String? dateFrom,
    String? dateTo,
    String? status,
    int page = 1,
  }) async {
    final resp = await ApiClient.get('/transactions', params: {
      if (dateFrom != null) 'date_from': dateFrom,
      if (dateTo != null) 'date_to': dateTo,
      if (status != null) 'status': status,
      'page': page,
    });
    return resp.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getTransaction(int id) async {
    final resp = await ApiClient.get('/transactions/$id');
    return resp.data as Map<String, dynamic>;
  }

  static Future<void> voidTransaction(int id) async {
    await ApiClient.patch('/transactions/$id/void');
  }
}

class ShiftService {
  static Future<Map<String, dynamic>> openShift({double openingCash = 0}) async {
    final resp = await ApiClient.post('/shifts/open',
        data: {'opening_cash': openingCash});
    return resp.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> closeShift({
    double closingCash = 0,
    String? notes,
  }) async {
    final resp = await ApiClient.post('/shifts/close',
        data: {'closing_cash': closingCash, if (notes != null) 'notes': notes});
    return resp.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> getCurrentShift() async {
    try {
      final resp = await ApiClient.get('/shifts/current');
      return resp.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getShifts({int page = 1}) async {
    final resp = await ApiClient.get('/shifts', params: {'page': page});
    return resp.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getShift(int id) async {
    final resp = await ApiClient.get('/shifts/$id');
    return resp.data as Map<String, dynamic>;
  }
}

import '../services/api_client.dart';
import '../models/product.dart';

class ProductService {
  static Future<Map<String, dynamic>> getProducts({
    String? search,
    String? category,
    bool lowStockOnly = false,
    int page = 1,
    int perPage = 50,
  }) async {
    final resp = await ApiClient.get('/products', params: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null) 'category': category,
      if (lowStockOnly) 'low_stock': '1',
      'page': page,
      'per_page': perPage,
    });
    return resp.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> checkSku(String sku) async {
    final resp = await ApiClient.get('/products/check-sku/$sku');
    final data = resp.data as Map<String, dynamic>;
    if (data['exists'] == true && data['product'] != null) {
      return {
        'exists': true,
        'product': Product.fromJson(data['product'] as Map<String, dynamic>),
      };
    }
    return {'exists': false, 'product': null};
  }

  static Future<List<String>> getCategories() async {
    final resp = await ApiClient.get('/products/categories');
    return (resp.data as List).map((e) => e.toString()).toList();
  }

  static Future<Product> getProduct(int id) async {
    final resp = await ApiClient.get('/products/$id');
    return Product.fromJson(resp.data as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final resp = await ApiClient.post('/products', data: data);
    final body = resp.data;
    if (body is Map<String, dynamic> && body.containsKey('product')) {
      return {
        'product': Product.fromJson(body['product'] as Map<String, dynamic>),
        'message': body['message'],
        'is_existing': body['is_existing'] ?? false,
      };
    }
    return {
      'product': Product.fromJson(body as Map<String, dynamic>),
      'message': 'Produk berhasil ditambahkan',
      'is_existing': false,
    };
  }

  static Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    final resp = await ApiClient.put('/products/$id', data: data);
    return Product.fromJson(resp.data as Map<String, dynamic>);
  }

  static Future<Product> adjustStock(int id, int adjustment, {String? note}) async {
    final resp = await ApiClient.patch('/products/$id/stock', data: {
      'adjustment': adjustment,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return Product.fromJson(resp.data as Map<String, dynamic>);
  }

  static Future<void> deleteProduct(int id, {String? note}) async {
    await ApiClient.delete('/products/$id');
  }
}

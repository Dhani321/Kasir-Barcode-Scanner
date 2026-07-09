import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/transaction_item.dart';

class CartProvider extends ChangeNotifier {
  final List<TransactionItem> _items = [];

  List<TransactionItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  double get subtotal => _items.fold(0, (s, i) => s + i.subtotal);
  double get tax => subtotal * 0.10;
  double get total => subtotal + tax;

  void addProduct(Product product) {
    final idx = _items.indexWhere((i) => i.productId == product.id);
    if (idx >= 0) {
      _items[idx].qty++;
    } else {
      _items.add(TransactionItem(
        id: 'cart-${product.id}',
        productId: product.id,
        name: product.name,
        sku: product.sku,
        category: product.category,
        price: product.price,
        qty: 1,
      ));
    }
    notifyListeners();
  }

  void updateQty(int index, int delta) {
    _items[index].qty += delta;
    if (_items[index].qty <= 0) _items.removeAt(index);
    notifyListeners();
  }

  void removeAt(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> toApiItems() =>
      _items.map((i) => i.toApiJson()).toList();
}

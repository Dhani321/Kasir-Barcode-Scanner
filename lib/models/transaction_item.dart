class TransactionItem {
  final String id;
  final int? productId;
  final String name;
  final String sku;
  final String category;
  final double price;
  int qty;
  final bool hasPromo;

  TransactionItem({
    required this.id,
    this.productId,
    required this.name,
    required this.sku,
    this.category = '',
    required this.price,
    this.qty = 1,
    this.hasPromo = false,
  });

  double get subtotal => price * qty;

  // For API submission
  Map<String, dynamic> toApiJson() => {
    'product_id': productId,
    'qty': qty,
  };
}

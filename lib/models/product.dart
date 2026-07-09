class Product {
  final int id;
  final String name;
  final String sku;
  final String category;
  final double price;
  final int stock;
  final int minStock;
  final String unit;
  final bool isActive;
  final bool isLowStock;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.price,
    required this.stock,
    this.minStock = 5,
    this.unit = 'pcs',
    this.isActive = true,
    this.isLowStock = false,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] as int,
    name: j['name'] as String,
    sku: j['sku'] as String,
    category: j['category'] as String? ?? 'Lainnya',
    price: (j['price'] as num).toDouble(),
    stock: (j['stock'] as num).toInt(),
    minStock: (j['min_stock'] as num?)?.toInt() ?? 5,
    unit: j['unit'] as String? ?? 'pcs',
    isActive: j['is_active'] as bool? ?? true,
    isLowStock: j['is_low_stock'] as bool? ?? false,
    imageUrl: j['image_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'sku': sku, 'category': category,
    'price': price, 'stock': stock, 'min_stock': minStock,
    'unit': unit, 'is_active': isActive,
  };

  // Fallback dummy list used when API is unreachable
  static List<Product> get fallbackList => [
    Product(id: 1, name: 'Air Mineral 600ml', sku: 'BEV-AIR-600',
        category: 'Minuman', price: 2500, stock: 300),
    Product(id: 2, name: 'Mie Instan Goreng', sku: 'FD-MI-GRG',
        category: 'Makanan', price: 3500, stock: 200),
  ];
}

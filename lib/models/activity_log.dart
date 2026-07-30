class ActivityLog {
  final int id;
  final int? userId;
  final String userName;
  final String userRole;
  final String action;
  final int? productId;
  final String? productName;
  final String? sku;
  final int qtyChange;
  final int? oldStock;
  final int? newStock;
  final String? description;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    this.userId,
    required this.userName,
    required this.userRole,
    required this.action,
    this.productId,
    this.productName,
    this.sku,
    required this.qtyChange,
    this.oldStock,
    this.newStock,
    this.description,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      userName: json['user_name'] ?? 'Sistem',
      userRole: json['user_role'] ?? 'system',
      action: json['action'] ?? '',
      productId: json['product_id'] as int?,
      productName: json['product_name'] as String?,
      sku: json['sku'] as String?,
      qtyChange: json['qty_change'] as int? ?? 0,
      oldStock: json['old_stock'] as int?,
      newStock: json['new_stock'] as int?,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  String get actionLabel {
    switch (action) {
      case 'create_product':
        return 'Tambah Produk Baru';
      case 'add_stock':
        return 'Tambah Stok';
      case 'reduce_stock':
        return 'Kurangi Stok';
      case 'update_product':
        return 'Edit Produk';
      case 'delete_product':
        return 'Hapus Produk';
      case 'sale_stock_out':
        return 'Penjualan (Stok Keluar)';
      default:
        return action;
    }
  }
}

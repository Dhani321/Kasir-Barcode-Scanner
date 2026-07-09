import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/product.dart';
import '../../../services/product_service.dart';

class StokTab extends StatefulWidget {
  const StokTab({super.key});
  @override
  State<StokTab> createState() => _StokTabState();
}

class _StokTabState extends State<StokTab> {
  List<Product> _products = [];
  List<String> _categories = [];
  int _total = 0;
  int _lowStockCount = 0;
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({String? search}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ProductService.getProducts(search: search, perPage: 50),
        ProductService.getProducts(lowStockOnly: true, perPage: 100),
        ProductService.getCategories(),
      ]);
      final data = results[0] as Map<String, dynamic>;
      final lowStockData = results[1] as Map<String, dynamic>;
      final cats = results[2] as List<String>;
      final list = (data['data'] as List).map((e) => Product.fromJson(e)).toList();
      setState(() {
        _products = list;
        _categories = cats;
        _total = data['total'] as int? ?? list.length;
        _lowStockCount = lowStockData['total'] as int? ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Gagal memuat produk: $e'; _loading = false; });
    }
  }

  double get _totalValue => _products.fold(0, (s, p) => s + p.price * p.stock);

  String _fmt(double v) => 'Rp ${v.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: AppColors.surfaceContainerLowest,
        child: Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Manajemen Inventori', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('Kelola produk, harga, dan level stok.',
                style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
          ])),
          OutlinedButton.icon(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.outlineVariant),
              foregroundColor: AppColors.onSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showProductDialog(context),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Tambah Produk'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ]),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadProducts)
              : _buildContent()),
    ]);
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        // Stats
        Row(children: [
          Expanded(child: _StokStatCard(icon: Icons.inventory_2_rounded, label: 'Total Item',
              value: '$_total', iconBg: AppColors.primaryContainer, iconFg: AppColors.onPrimaryContainer)),
          const SizedBox(width: 16),
          Expanded(child: _StokStatCard(icon: Icons.warning_rounded, label: 'Peringatan Stok',
              value: '$_lowStockCount', iconBg: _lowStockCount > 0 ? AppColors.error : AppColors.outline,
              iconFg: AppColors.onError,
              valueColor: _lowStockCount > 0 ? AppColors.error : null,
              borderColor: _lowStockCount > 0 ? AppColors.error : null)),
          const SizedBox(width: 16),
          Expanded(child: _StokStatCard(icon: Icons.payments_rounded, label: 'Nilai Stok',
              value: _fmt(_totalValue), iconBg: AppColors.secondaryContainer, iconFg: AppColors.onSecondaryContainer)),
        ]),
        const SizedBox(height: 20),
        // Table
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant)),
          child: Column(children: [
            // Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: AppColors.outlineVariant))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Menampilkan ${_products.length} dari $_total produk',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (v) => _loadProducts(search: v),
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.onSurfaceVariant),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () { _searchCtrl.clear(); _loadProducts(); })
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.outlineVariant)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.outlineVariant)),
                    ),
                  ),
                ),
              ]),
            ),
            // Header
            Container(
              color: AppColors.surfaceContainer,
              child: const Row(children: [
                SizedBox(width: 60, child: _TH('Foto')),
                Expanded(flex: 3, child: _TH('Nama / SKU')),
                Expanded(flex: 2, child: _TH('Kategori')),
                Expanded(flex: 2, child: _TH('Harga', right: true)),
                Expanded(flex: 2, child: _TH('Level Stok', center: true)),
                SizedBox(width: 100, child: _TH('Aksi', center: true)),
              ]),
            ),
            // Rows
            ..._products.map((p) => _ProductRow(product: p, onEdit: () => _showProductDialog(context, product: p), onStockAdjust: (adj) async {
              await ProductService.adjustStock(p.id, adj);
              _loadProducts();
            })),
            if (_products.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Text('Tidak ada produk ditemukan', style: TextStyle(color: AppColors.onSurfaceVariant)),
              ),
          ]),
        ),
      ]),
    );
  }

  void _showProductDialog(BuildContext context, {Product? product}) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final skuCtrl = TextEditingController(text: product?.sku ?? '');
    String selectedCat = product?.category ?? (_categories.isNotEmpty ? _categories.first : 'Lainnya');
    if (!_categories.contains(selectedCat) && _categories.isNotEmpty) selectedCat = _categories.first;
    final priceCtrl = TextEditingController(text: product?.price.toStringAsFixed(0) ?? '');
    final stockCtrl = TextEditingController(text: product?.stock.toString() ?? '0');
    final minStockCtrl = TextEditingController(text: product?.minStock.toString() ?? '5');
    final isEdit = product != null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _DField('Nama Produk', nameCtrl),
                const SizedBox(height: 10),
                _DField('SKU', skuCtrl),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outlineVariant)),
                  ),
                  items: _categories.isNotEmpty ? _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList() 
                      : [DropdownMenuItem(value: selectedCat, child: Text(selectedCat))],
                  onChanged: (v) => setStateDialog(() => selectedCat = v!),
                ),
                const SizedBox(height: 10),
                _DField('Harga (Rp)', priceCtrl, numeric: true),
                const SizedBox(height: 10),
                _DField('Stok', stockCtrl, numeric: true),
                const SizedBox(height: 10),
                _DField('Stok Minimum', minStockCtrl, numeric: true),
              ]),
            ),
          ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final data = {
                'name': nameCtrl.text, 'sku': skuCtrl.text, 'category': selectedCat,
                'price': double.tryParse(priceCtrl.text) ?? 0,
                'stock': int.tryParse(stockCtrl.text) ?? 0,
                'min_stock': int.tryParse(minStockCtrl.text) ?? 5,
              };
              try {
                if (isEdit) {
                  await ProductService.updateProduct(product!.id, data);
                } else {
                  await ProductService.createProduct(data);
                }
                _loadProducts();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text(isEdit ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    ),
  );
}
}

class _DField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool numeric;
  const _DField(this.label, this.controller, {this.numeric = false});
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: numeric ? TextInputType.number : null,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outlineVariant)),
    ),
  );
}

class _TH extends StatelessWidget {
  final String text;
  final bool right, center;
  const _TH(this.text, {this.right = false, this.center = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Text(text,
        textAlign: right ? TextAlign.right : (center ? TextAlign.center : TextAlign.left),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
  );
}

class _StokStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color iconBg, iconFg;
  final Color? valueColor, borderColor;
  const _StokStatCard({required this.icon, required this.label, required this.value,
    required this.iconBg, required this.iconFg, this.valueColor, this.borderColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? AppColors.outlineVariant)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.onSurface)),
      ]),
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Icon(icon, color: iconFg, size: 22)),
    ]),
  );
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final Function(int) onStockAdjust;
  const _ProductRow({required this.product, required this.onEdit, required this.onStockAdjust});

  String _fmt(double v) => 'Rp ${v.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.outlineVariant))),
      child: Row(children: [
        SizedBox(width: 60, child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.outlineVariant)),
            child: const Icon(Icons.image_rounded, color: AppColors.outline, size: 18)),
        )),
        Expanded(flex: 3, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(product.sku, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, fontFamily: 'monospace')),
          ]),
        )),
        Expanded(flex: 2, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(6)),
            child: Text(product.category, style: const TextStyle(fontSize: 11)),
          ),
        )),
        Expanded(flex: 2, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(_fmt(product.price), textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
        )),
        Expanded(flex: 2, child: Center(child: product.isLowStock
            ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.error)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.warning_rounded, size: 13, color: AppColors.onErrorContainer),
            const SizedBox(width: 4),
            Text('${product.stock}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColors.onErrorContainer)),
          ]),
        )
            : Text('${product.stock}', style: const TextStyle(fontSize: 13)))),
        SizedBox(width: 100, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, color: AppColors.onSurfaceVariant, size: 18), tooltip: 'Edit'),
          IconButton(onPressed: () => _showStockDialog(context), icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 18), tooltip: 'Adjust Stok'),
        ])),
      ]),
    );
  }

  void _showStockDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Adjust Stok - ${product.name}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Stok saat ini: ${product.stock} ${product.unit}', style: const TextStyle(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 12),
        TextField(controller: ctrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Jumlah (+/- angka)', hintText: 'e.g. 50 atau -10')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () {
            final adj = int.tryParse(ctrl.text);
            if (adj != null) { onStockAdjust(adj); Navigator.pop(context); }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: const Text('Simpan'),
        ),
      ],
    ));
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.outline),
      const SizedBox(height: 16),
      Text(message, style: const TextStyle(color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded),
          label: const Text('Coba Lagi'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
    ],
  ));
}

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/product.dart';
import '../../../services/product_service.dart';
import '../../../services/activity_log_service.dart';

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
            Text('Kelola produk, harga, stok, dan laporan barang masuk/keluar.',
                style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
          ])),
          OutlinedButton.icon(
            onPressed: () => _showExportReportDialog(context),
            icon: const Icon(Icons.file_download_outlined, size: 16),
            label: const Text('Export Laporan Stok'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(width: 8),
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
            label: const Text('Tambah / Top Up Stok'),
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
                  width: 260,
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (v) => _loadProducts(search: v),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau kode barang...',
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
                Expanded(flex: 3, child: _TH('Nama / Kode Barang')),
                Expanded(flex: 2, child: _TH('Kategori')),
                Expanded(flex: 2, child: _TH('Harga', right: true)),
                Expanded(flex: 2, child: _TH('Level Stok', center: true)),
                SizedBox(width: 150, child: _TH('Aksi', center: true)),
              ]),
            ),
            // Rows
            ..._products.map((p) => _ProductRow(
              product: p, 
              onEdit: () => _showProductDialog(context, product: p), 
              onStockAdjust: (adj, note) async {
                await ProductService.adjustStock(p.id, adj, note: note);
                _loadProducts();
              },
              onDelete: (note) => _confirmDeleteProduct(p, note: note),
            )),
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

  void _confirmDeleteProduct(Product product, {String? note}) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus / Menonaktifkan Produk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin menghapus produk "${product.name}" (Kode: ${product.sku})?'),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Catatan / Alasan Hapus (Opsional)',
                hintText: 'Misal: Produk rusak atau tidak dijual lagi',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ProductService.deleteProduct(product.id, note: noteCtrl.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Produk "${product.name}" telah dinonaktifkan.')));
                }
                _loadProducts();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus produk: $e'), backgroundColor: AppColors.error));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(BuildContext context, {Product? product}) {
    final isEdit = product != null;

    final skuCtrl = TextEditingController(text: product?.sku ?? '');
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    String selectedCat = product?.category ?? (_categories.isNotEmpty ? _categories.first : 'Lainnya');
    if (!_categories.contains(selectedCat) && _categories.isNotEmpty) selectedCat = _categories.first;
    final priceCtrl = TextEditingController(text: product?.price.toStringAsFixed(0) ?? '');
    final stockCtrl = TextEditingController(text: '1');
    final minStockCtrl = TextEditingController(text: product?.minStock.toString() ?? '5');
    final noteCtrl = TextEditingController();

    bool isCheckingSku = false;
    bool isExistingProduct = false;
    Product? foundProduct;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          
          Future<void> checkSkuValidation() async {
            final sku = skuCtrl.text.trim();
            if (sku.isEmpty) return;
            setStateDialog(() => isCheckingSku = true);
            try {
              final res = await ProductService.checkSku(sku);
              if (res['exists'] == true && res['product'] != null) {
                foundProduct = res['product'] as Product;
                isExistingProduct = true;
                nameCtrl.text = foundProduct!.name;
                priceCtrl.text = foundProduct!.price.toStringAsFixed(0);
                selectedCat = foundProduct!.category;
              } else {
                foundProduct = null;
                isExistingProduct = false;
              }
            } catch (_) {
              isExistingProduct = false;
              foundProduct = null;
            }
            setStateDialog(() => isCheckingSku = false);
          }

          return AlertDialog(
            title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk / Input Stok Baru'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (!isEdit) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _DField('Kode Barang / Barcode (SKU)', skuCtrl)),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isCheckingSku ? null : checkSkuValidation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                          child: isCheckingSku
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Cek Kode', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isExistingProduct && foundProduct != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Produk Ditemukan: ${foundProduct!.name}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('Sisa Stok: ${foundProduct!.stock} ${foundProduct!.unit} | Harga: Rp ${foundProduct!.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
                              const SizedBox(height: 2),
                              const Text('Hanya perlu memasukkan jumlah stok yang ditambahkan.', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black54)),
                            ]),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      _DField('Jumlah Stok yang Ditambahkan', stockCtrl, numeric: true),
                      const SizedBox(height: 10),
                      _DField('Catatan / Keterangan (Opsional)', noteCtrl),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(children: [
                          Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              skuCtrl.text.isNotEmpty 
                                  ? 'Kode barang belum terdaftar. Silakan isi data produk baru di bawah:'
                                  : 'Masukkan Kode Barang lalu klik "Cek Kode" atau isi form di bawah.',
                              style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      _DField('Nama Produk', nameCtrl),
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
                      _DField('Jumlah Stok Awal', stockCtrl, numeric: true),
                      const SizedBox(height: 10),
                      _DField('Stok Minimum Alert', minStockCtrl, numeric: true),
                      const SizedBox(height: 10),
                      _DField('Catatan / Keterangan (Opsional)', noteCtrl),
                    ],
                  ] else ...[
                    // Edit mode (without Stok Total field as requested)
                    _DField('Kode Barang / Barcode (SKU)', skuCtrl),
                    const SizedBox(height: 10),
                    _DField('Nama Produk', nameCtrl),
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
                    _DField('Stok Minimum Alert', minStockCtrl, numeric: true),
                  ],
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () async {
                  if (skuCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kode barang (SKU) wajib diisi!'), backgroundColor: AppColors.error));
                    return;
                  }
                  Navigator.pop(context);
                  final data = {
                    'sku': skuCtrl.text.trim(), 
                    'name': nameCtrl.text.trim(), 
                    'category': selectedCat,
                    'price': double.tryParse(priceCtrl.text) ?? 0,
                    'stock': int.tryParse(stockCtrl.text) ?? 0,
                    'min_stock': int.tryParse(minStockCtrl.text) ?? 5,
                    if (noteCtrl.text.trim().isNotEmpty) 'note': noteCtrl.text.trim(),
                  };
                  try {
                    if (isEdit) {
                      await ProductService.updateProduct(product.id, data);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Produk "${product.name}" berhasil diperbarui.')));
                      }
                    } else {
                      final res = await ProductService.createProduct(data);
                      if (mounted) {
                        final msg = res['message'] ?? 'Produk berhasil ditambahkan';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor: res['is_existing'] == true ? Colors.blue.shade700 : Colors.green.shade700,
                          ),
                        );
                      }
                    }
                    _loadProducts();
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: Text(isEdit ? 'Simpan' : 'Tambah / Update Stok'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExportReportDialog(BuildContext context) {
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return AlertDialog(
            title: const Row(children: [
              Icon(Icons.assessment_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Export Laporan Stok Barang Masuk & Keluar'),
            ]),
            content: SizedBox(
              width: 500,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Pilih periode bulan dan tahun untuk laporan pergerakan stok:',
                    style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedMonth,
                      decoration: const InputDecoration(labelText: 'Bulan', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Januari')),
                        DropdownMenuItem(value: 2, child: Text('Februari')),
                        DropdownMenuItem(value: 3, child: Text('Maret')),
                        DropdownMenuItem(value: 4, child: Text('April')),
                        DropdownMenuItem(value: 5, child: Text('Mei')),
                        DropdownMenuItem(value: 6, child: Text('Juni')),
                        DropdownMenuItem(value: 7, child: Text('Juli')),
                        DropdownMenuItem(value: 8, child: Text('Agustus')),
                        DropdownMenuItem(value: 9, child: Text('September')),
                        DropdownMenuItem(value: 10, child: Text('Oktober')),
                        DropdownMenuItem(value: 11, child: Text('November')),
                        DropdownMenuItem(value: 12, child: Text('Desember')),
                      ],
                      onChanged: (v) => setStateModal(() => selectedMonth = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedYear,
                      decoration: const InputDecoration(labelText: 'Tahun', border: OutlineInputBorder()),
                      items: [2024, 2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                      onChanged: (v) => setStateModal(() => selectedYear = v!),
                    ),
                  ),
                ]),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openStockReportPreviewModal(context, selectedMonth, selectedYear);
                },
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('Tampilkan Laporan'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openStockReportPreviewModal(BuildContext context, int month, int year) async {
    showDialog(
      context: context,
      builder: (ctx) => _StockReportPreviewDialog(month: month, year: year),
    );
  }
}

class _StockReportPreviewDialog extends StatefulWidget {
  final int month;
  final int year;
  const _StockReportPreviewDialog({required this.month, required this.year});

  @override
  State<_StockReportPreviewDialog> createState() => _StockReportPreviewDialogState();
}

class _StockReportPreviewDialogState extends State<_StockReportPreviewDialog> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      final res = await ActivityLogService.getStockMovementReport(
        month: widget.month,
        year: widget.year,
      );
      setState(() {
        _reportData = res;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat laporan: $e';
        _loading = false;
      });
    }
  }

  String _getMonthName(int m) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return (m >= 1 && m <= 12) ? months[m - 1] : '$m';
  }

  @override
  Widget build(BuildContext context) {
    final title = 'Laporan Stok Barang Masuk & Keluar - ${_getMonthName(widget.month)} ${widget.year}';
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 850,
        height: 650,
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Rekapitulasi pergerakan barang masuk dan keluar beserta log penanggung jawab.',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ]),
            IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
          ]),
          const Divider(height: 24),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
                    : _buildReportBody(),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _loading || _error != null
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Menyiapkan & mencetak $title...'),
                          backgroundColor: AppColors.primary,
                          duration: const Duration(seconds: 2),
                        ));
                      },
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('Cetak / Print Laporan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildReportBody() {
    final summary = _reportData?['summary'] ?? {};
    final totalIn = summary['total_stock_in'] ?? 0;
    final totalOut = summary['total_stock_out'] ?? 0;
    final inLogs = (_reportData?['stock_in_logs'] as List?) ?? [];
    final outLogs = (_reportData?['stock_out_logs'] as List?) ?? [];

    return DefaultTabController(
      length: 2,
      child: Column(children: [
        Row(children: [
          Expanded(child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total Barang Masuk (Stok In)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade800)),
              const SizedBox(height: 4),
              Text('+$totalIn pcs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
            ]),
          )),
          const SizedBox(width: 16),
          Expanded(child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total Barang Keluar (Stok Out)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade800)),
              const SizedBox(height: 4),
              Text('-$totalOut pcs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
            ]),
          )),
        ]),
        const SizedBox(height: 16),
        Container(
          height: 40,
          decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
          child: const TabBar(
            tabs: [
              Tab(text: 'Barang Masuk (Stock In)'),
              Tab(text: 'Barang Keluar (Stock Out)'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            children: [
              _buildLogTable(inLogs, isStockIn: true),
              _buildLogTable(outLogs, isStockIn: false),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildLogTable(List<dynamic> logs, {required bool isStockIn}) {
    if (logs.isEmpty) {
      return Center(
        child: Text(
          isStockIn ? 'Tidak ada data barang masuk di bulan ini.' : 'Tidak ada data barang keluar di bulan ini.',
          style: const TextStyle(color: AppColors.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, i) {
        final item = logs[i];
        final dateStr = item['created_at']?.toString().substring(0, 16).replaceAll('T', ' ') ?? '';
        final prodName = item['product_name'] ?? '-';
        final sku = item['sku'] ?? '-';
        final user = item['user_name'] ?? 'Sistem';
        final qty = item['qty_change'] ?? 0;
        final desc = item['description'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(children: [
            Icon(
              isStockIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isStockIn ? Colors.green : Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(prodName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Kode: $sku | Waktu: $dateStr', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                if (desc.isNotEmpty) Text(desc, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
              ]),
            ),
            Expanded(
              flex: 2,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Oleh:', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                Text(user, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isStockIn ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isStockIn ? '+$qty pcs' : '$qty pcs',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isStockIn ? Colors.green.shade900 : Colors.orange.shade900,
                ),
              ),
            ),
          ]),
        );
      },
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
  final Function(int, String?) onStockAdjust;
  final Function(String?) onDelete;
  const _ProductRow({required this.product, required this.onEdit, required this.onStockAdjust, required this.onDelete});

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
            Text('Kode: ${product.sku}', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, fontFamily: 'monospace')),
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
        SizedBox(width: 150, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Tooltip(
            message: 'Edit Produk',
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.edit_rounded, color: AppColors.onSurfaceVariant, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: 'Adjust Stok',
            child: InkWell(
              onTap: () => _showStockDialog(context),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: 'Hapus Produk',
            child: InkWell(
              onTap: () => onDelete(null),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.delete, color: AppColors.error, size: 18),
              ),
            ),
          ),
        ])),
      ]),
    );
  }

  void _showStockDialog(BuildContext context) {
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Adjust Stok - ${product.name}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Stok saat ini: ${product.stock} ${product.unit}', style: const TextStyle(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 12),
        TextField(controller: qtyCtrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Jumlah (+/- angka)', hintText: 'e.g. 50 atau -10', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: noteCtrl,
            decoration: const InputDecoration(labelText: 'Catatan / Alasan Adjust (Opsional)', hintText: 'Misal: Barang masuk dari supplier', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () {
            final adj = int.tryParse(qtyCtrl.text);
            if (adj != null) { onStockAdjust(adj, noteCtrl.text.trim()); Navigator.pop(context); }
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

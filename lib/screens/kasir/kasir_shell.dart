import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/product.dart';
import '../../models/transaction_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/product_service.dart';
import '../../services/transaction_service.dart';
import '../login_screen.dart';
import 'pembayaran_screen.dart';
import 'laporan_shift_screen.dart';

class KasirShell extends StatefulWidget {
  const KasirShell({super.key});
  @override
  State<KasirShell> createState() => _KasirShellState();
}

class _KasirShellState extends State<KasirShell> {
  int _currentTab = 0;
  List<Product> _products = [];
  bool _loadingProducts = true;
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> _categories = ['Semua'];
  final _searchCtrl = TextEditingController();

  bool _isShiftOpen = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final shift = await ShiftService.getCurrentShift();
      final results = await Future.wait([
        ProductService.getProducts(search: _searchQuery, category: _selectedCategory == 'Semua' ? null : _selectedCategory, perPage: 100),
        ProductService.getCategories(),
      ]);
      final pData = results[0] as Map<String, dynamic>;
      final cats = results[1] as List<String>;
      setState(() {
        _isShiftOpen = shift != null && shift['id'] != null;
        _products = (pData['data'] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        _categories = ['Semua', ...cats];
        _loadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _products = Product.fallbackList;
        _loadingProducts = false;
      });
    }
  }

  void _addToCart(Product product) {
    if (!_isShiftOpen) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Buka shift terlebih dahulu di tab Laporan'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    context.read<CartProvider>().addProduct(product);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${product.name} ditambahkan ke keranjang'),
      duration: const Duration(seconds: 1),
      backgroundColor: AppColors.primary,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _KasirTopBar(
          userName: user?.fullName ?? 'Kasir',
          initials: user?.initials ?? 'K',
          onLogout: () async {
            await context.read<AuthProvider>().logout();
            if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          },
          searchCtrl: _searchCtrl,
          onSearchChanged: (v) {
            _searchQuery = v;
            _loadProducts();
          },
          onSearchSubmitted: (v) {
            final val = v.trim().toLowerCase();
            if (val.isEmpty) return;
            // Check if there is an exact SKU match
            final match = _products.where((p) => p.sku.toLowerCase() == val).toList();
            if (match.isNotEmpty) {
              _addToCart(match.first);
              _searchCtrl.clear();
              _searchQuery = '';
              _loadProducts();
            }
          },
        ),
        Expanded(child: Row(children: [
          _LeftSidebar(
            currentTab: _currentTab,
            onTabChanged: (i) {
              if (i == 2) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LaporanShiftScreen())).then((_) {
                  _loadProducts(); // Refresh shift status after returning
                });
              } else {
                setState(() => _currentTab = i);
              }
            },
          ),
          // Center: product grid or inventory view
          Expanded(
            child: _currentTab == 0
                ? _TransactionArea(
                    products: _products,
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    isLoading: _loadingProducts,
                    onCategoryChanged: (c) { setState(() => _selectedCategory = c); _loadProducts(); },
                    onAddToCart: _addToCart,
                  )
                : _InventoriView(products: _products, isLoading: _loadingProducts),
          ),
          // Right: Cart sidebar
          if (_currentTab == 0) _CartSidebar(
            onPayNow: () async {
              if (!_isShiftOpen) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Buka shift terlebih dahulu di tab Laporan'),
                  backgroundColor: AppColors.error,
                ));
                return;
              }
              final cart = context.read<CartProvider>();
              if (cart.isEmpty) return;
              final result = await Navigator.push<bool>(
                context, MaterialPageRoute(builder: (_) => PembayaranScreen(total: cart.total)));
              if (result == true && mounted) {
                cart.clear();
                _loadProducts(); // refresh stock
              }
            },
          ),
        ])),
      ]),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────
class _KasirTopBar extends StatelessWidget {
  final String userName, initials;
  final VoidCallback onLogout;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;

  const _KasirTopBar({required this.userName, required this.initials, required this.onLogout,
    required this.searchCtrl, required this.onSearchChanged, required this.onSearchSubmitted});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant))),
      child: Row(children: [
        const Text('Retail Desa', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(width: 24),
        Expanded(child: Container(
          height: 42,
          decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant)),
          child: Row(children: [
            const SizedBox(width: 12),
            const Icon(Icons.search_rounded, color: AppColors.outlineVariant, size: 20),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: searchCtrl,
              onChanged: onSearchChanged,
              onSubmitted: onSearchSubmitted,
              decoration: const InputDecoration(
                hintText: 'Cari produk atau scan barcode...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppColors.outline, fontSize: 14),
              ),
            )),
            const Icon(Icons.barcode_reader, color: AppColors.outlineVariant, size: 20),
            const SizedBox(width: 12),
          ]),
        )),
        const SizedBox(width: 12),
        IconButton(onPressed: onLogout, icon: const Icon(Icons.logout_rounded, color: AppColors.onSurfaceVariant), tooltip: 'Keluar'),
        const SizedBox(width: 4),
        CircleAvatar(radius: 18, backgroundColor: AppColors.primaryContainer,
            child: Text(initials, style: const TextStyle(color: AppColors.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 12))),
        const SizedBox(width: 4),
        Text(userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
      ]),
    );
  }
}

// ─── Left Sidebar ─────────────────────────────────────────────
class _LeftSidebar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTabChanged;
  const _LeftSidebar({required this.currentTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    final items = [(Icons.point_of_sale_rounded, 'Transaksi'), (Icons.inventory_2_rounded, 'Inventori'), (Icons.receipt_long_rounded, 'Laporan')];
    return Container(
      width: 96,
      decoration: const BoxDecoration(color: AppColors.surfaceContainerLowest, border: Border(right: BorderSide(color: AppColors.outlineVariant))),
      child: Column(children: [
        const SizedBox(height: 12),
        ...List.generate(items.length, (i) {
          final active = currentTab == i;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: GestureDetector(
              onTap: () => onTabChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Icon(items[i].$1, size: 26, color: active ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant),
                  const SizedBox(height: 6),
                  Text(items[i].$2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: active ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center),
                ]),
              ),
            ),
          );
        }),
      ]),
    );
  }
}

// ─── Transaction Area (product grid) ──────────────────────────
class _TransactionArea extends StatelessWidget {
  final List<Product> products;
  final List<String> categories;
  final String? selectedCategory;
  final bool isLoading;
  final ValueChanged<String?> onCategoryChanged;
  final Function(Product) onAddToCart;

  const _TransactionArea({required this.products, required this.categories, required this.selectedCategory,
    required this.isLoading, required this.onCategoryChanged, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header + categories
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.surfaceContainerLowest,
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Pilih Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text('${products.length} produk tersedia', style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = categories[i];
                final active = (selectedCategory == null && cat == 'Semua') || selectedCategory == cat;
                return GestureDetector(
                  onTap: () => onCategoryChanged(cat == 'Semua' ? null : cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? AppColors.primary : AppColors.outlineVariant)),
                    child: Text(cat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.onSurface)),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
      const Divider(height: 1, color: AppColors.outlineVariant),
      // Product Grid
      Expanded(child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(child: Text('Tidak ada produk', style: TextStyle(color: AppColors.onSurfaceVariant)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
                  itemCount: products.length,
                  itemBuilder: (_, i) => _ProductGridCard(product: products[i], onAdd: () => onAddToCart(products[i])),
                )),
    ]);
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;
  const _ProductGridCard({required this.product, required this.onAdd});

  String _fmt(double v) => 'Rp ${v.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stock == 0;
    return GestureDetector(
      onTap: outOfStock ? null : onAdd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: product.isLowStock ? AppColors.error.withOpacity(0.5) : AppColors.outlineVariant),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image area
          Expanded(child: Container(
            decoration: BoxDecoration(
              color: outOfStock ? AppColors.surfaceContainerHighest : AppColors.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14))),
            child: Center(child: Stack(children: [
              Icon(Icons.inventory_2_rounded, size: 40,
                  color: outOfStock ? AppColors.outline.withOpacity(0.5) : AppColors.primary.withOpacity(0.3)),
              if (outOfStock)
                const Center(child: Text('HABIS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.error))),
            ])),
          )),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: outOfStock ? AppColors.outline : AppColors.onSurface),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_fmt(product.price), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: product.isLowStock ? AppColors.errorContainer : AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(6)),
                  child: Text('${product.stock}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: product.isLowStock ? AppColors.error : AppColors.primary)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Cart Sidebar ─────────────────────────────────────────────
class _CartSidebar extends StatelessWidget {
  final VoidCallback onPayNow;
  const _CartSidebar({required this.onPayNow});

  String _fmt(double v) => 'Rp ${v.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Container(
      width: 340,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.outlineVariant))),
      child: Column(children: [
        // Customer
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surfaceContainerLowest,
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: const BoxDecoration(color: AppColors.surfaceContainer, shape: BoxShape.circle),
              child: const Icon(Icons.account_circle_rounded, color: AppColors.primary, size: 22)),
            const SizedBox(width: 8),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PELANGGAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant, letterSpacing: 0.8)),
              Text('Walk-in', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ])),
          ]),
        ),
        // Quick actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppColors.surfaceContainerLowest,
          child: Row(children: [
            _QuickAction(icon: Icons.backspace_rounded, label: 'Void', onTap: () {}),
            const SizedBox(width: 8),
            _QuickAction(icon: Icons.sell_rounded, label: 'Diskon', onTap: () {}),
            const SizedBox(width: 8),
            _QuickAction(icon: Icons.delete_sweep_rounded, label: 'Hapus Semua',
                onTap: () { if (!cart.isEmpty) context.read<CartProvider>().clear(); }),
          ]),
        ),
        const Divider(height: 1, color: AppColors.outlineVariant),
        // Cart items
        Expanded(child: cart.isEmpty
            ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.outlineVariant),
                SizedBox(height: 12),
                Text('Keranjang kosong', style: TextStyle(color: AppColors.outline, fontSize: 14)),
                SizedBox(height: 4),
                Text('Tap produk untuk menambahkan', style: TextStyle(color: AppColors.outline, fontSize: 12)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: cart.items.length,
                itemBuilder: (_, i) {
                  final item = cart.items[i];
                  return _CartItemTile(
                    item: item,
                    onDecrease: () => context.read<CartProvider>().updateQty(i, -1),
                    onIncrease: () => context.read<CartProvider>().updateQty(i, 1),
                    onDelete: () => context.read<CartProvider>().removeAt(i),
                  );
                },
              )),
        // Totals + Pay
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border(top: BorderSide(color: AppColors.outlineVariant))),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Subtotal', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
              Text(_fmt(cart.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Text('Pajak ', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(4)),
                  child: const Text('10%', style: TextStyle(fontSize: 10, color: AppColors.outline))),
              ]),
              Text(_fmt(cart.tax), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: AppColors.outlineVariant)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              Text(_fmt(cart.total), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
                  color: AppColors.primary, letterSpacing: -1)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: cart.isEmpty ? null : onPayNow,
                icon: const Icon(Icons.payments_rounded, size: 22),
                label: const Column(children: [
                  Text('BAYAR SEKARANG', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  Text('Tekan untuk proses', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400)),
                ]),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryContainer,
                  foregroundColor: AppColors.onSecondaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final TransactionItem item;
  final VoidCallback onDecrease, onIncrease, onDelete;
  const _CartItemTile({required this.item, required this.onDecrease, required this.onIncrease, required this.onDelete});

  String _fmt(double v) => 'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant)),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(_fmt(item.price), style: const TextStyle(fontSize: 12, color: AppColors.primary)),
      ])),
      Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.outlineVariant), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          _QBtn(icon: Icons.remove_rounded, onTap: onDecrease),
          SizedBox(width: 32, child: Center(child: Text('${item.qty}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)))),
          _QBtn(icon: Icons.add_rounded, onTap: onIncrease),
        ]),
      ),
      const SizedBox(width: 8),
      Text(_fmt(item.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
      const SizedBox(width: 4),
      GestureDetector(onTap: onDelete, child: const Icon(Icons.close_rounded, size: 16, color: AppColors.outline)),
    ]),
  );
}

class _QBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(width: 32, height: 32, child: Icon(icon, size: 16, color: AppColors.onSurfaceVariant)));
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border.all(color: AppColors.outlineVariant), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
      ]),
    ),
  ));
}

// ─── Inventori View ────────────────────────────────────────────
class _InventoriView extends StatelessWidget {
  final List<Product> products;
  final bool isLoading;
  const _InventoriView({required this.products, required this.isLoading});

  String _fmt(double v) => 'Rp ${v.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppColors.surfaceContainerLowest,
      child: const Row(children: [Text('Inventori Stok', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))]),
    ),
    Expanded(child: isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final p = products[i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.isLowStock ? AppColors.error : AppColors.outlineVariant)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(p.sku, style: const TextStyle(fontSize: 11, color: AppColors.outline)),
                  ])),
                  Text(_fmt(p.price), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: p.isLowStock ? AppColors.errorContainer : AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(20)),
                    child: Text('${p.stock} pcs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: p.isLowStock ? AppColors.onErrorContainer : AppColors.primary)),
                  ),
                ]),
              );
            },
          )),
  ]);
}

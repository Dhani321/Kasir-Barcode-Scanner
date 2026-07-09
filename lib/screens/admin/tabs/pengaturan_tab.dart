import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/user_service.dart'; // contains SettingService

class PengaturanTab extends StatefulWidget {
  const PengaturanTab({super.key});
  @override
  State<PengaturanTab> createState() => _PengaturanTabState();
}

class _PengaturanTabState extends State<PengaturanTab> {
  bool _printReceipt = true;
  bool _lowStockAlert = true;
  bool _autoBackup = false;
  
  final _storeNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _categoriesCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose(); _addressCtrl.dispose(); _taxCtrl.dispose(); _categoriesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() { _loading = true; _error = null; });
    try {
      final settings = await SettingService.getSettingsFlat();
      setState(() {
        _storeNameCtrl.text = settings['store_name']?.toString() ?? 'Retail Desa';
        _addressCtrl.text = settings['store_address']?.toString() ?? 'Jl. Desa Maju';
        _taxCtrl.text = settings['tax_percentage']?.toString() ?? '10';
        _categoriesCtrl.text = settings['product_categories']?.toString() ?? 'Makanan,Minuman,Snack,Perawatan,Rumah Tangga,Lainnya';
        
        _printReceipt = (settings['print_receipt_auto']?.toString() ?? '1') == '1';
        _lowStockAlert = (settings['low_stock_alert']?.toString() ?? '1') == '1';
        _autoBackup = (settings['auto_backup']?.toString() ?? '0') == '1';
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Gagal memuat pengaturan: $e'; _loading = false; });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      await SettingService.bulkUpdate({
        'store_name': _storeNameCtrl.text,
        'store_address': _addressCtrl.text,
        'tax_percentage': _taxCtrl.text,
        'product_categories': _categoriesCtrl.text,
        'print_receipt_auto': _printReceipt ? '1' : '0',
        'low_stock_alert': _lowStockAlert ? '1' : '0',
        'auto_backup': _autoBackup ? '1' : '0',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan berhasil disimpan'), backgroundColor: AppColors.primary));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: AppColors.surfaceContainerLowest,
        child: Row(children: [
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pengaturan Sistem', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text('Konfigurasi toko dan preferensi sistem.', style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
            ]),
          ),
          OutlinedButton.icon(
            onPressed: _loadSettings,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
          )
        ]),
      ),
      Expanded(
        child: _loading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(children: [
                _Section(
                  title: 'Informasi Toko',
                  icon: Icons.store_rounded,
                  children: [
                    _SettingField(label: 'Nama Toko', controller: _storeNameCtrl),
                    const SizedBox(height: 12),
                    _SettingField(label: 'Alamat', controller: _addressCtrl),
                    const SizedBox(height: 12),
                    _SettingField(label: 'Pajak (%)', controller: _taxCtrl, keyboardType: TextInputType.number),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingField(label: 'Kategori Produk', controller: _categoriesCtrl),
                const SizedBox(height: 16),
                _Section(
                  title: 'Struk & Notifikasi',
                  icon: Icons.receipt_rounded,
                  children: [
                    _ToggleSetting(
                      label: 'Cetak Struk Otomatis',
                      sub: 'Cetak struk setiap transaksi selesai',
                      value: _printReceipt,
                      onChanged: (v) => setState(() => _printReceipt = v),
                    ),
                    _ToggleSetting(
                      label: 'Peringatan Stok Rendah',
                      sub: 'Notifikasi jika stok di bawah minimum',
                      value: _lowStockAlert,
                      onChanged: (v) => setState(() => _lowStockAlert = v),
                    ),
                  ],
                ),
              ])),
              const SizedBox(width: 16),
              Expanded(child: Column(children: [
                _Section(
                  title: 'Sistem & Data',
                  icon: Icons.storage_rounded,
                  children: [
                    _ToggleSetting(
                      label: 'Backup Otomatis',
                      sub: 'Backup data setiap hari pukul 00:00',
                      value: _autoBackup,
                      onChanged: (v) => setState(() => _autoBackup = v),
                    ),
                    const SizedBox(height: 8),
                    _ActionTile(
                      icon: Icons.backup_rounded, label: 'Backup Sekarang',
                      sub: 'Sinkronisasi dengan server', color: AppColors.primary, onTap: () {},
                    ),
                    _ActionTile(
                      icon: Icons.delete_sweep_rounded, label: 'Hapus Cache & Data Lokal',
                      sub: 'Mengosongkan memori sementara', color: AppColors.error, onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Tentang Sistem',
                  icon: Icons.info_outline_rounded,
                  children: [
                    const _InfoRow('Nama Aplikasi', 'Retail Desa POS'),
                    const _InfoRow('Versi', '1.0.0 (Connected to API)'),
                    const _InfoRow('Terminal ID', 'T-001'),
                    if (_error != null)
                      Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: AppColors.error))),
                  ],
                ),
              ])),
            ],
          ),
        ),
      ),
      // Save Button
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          ElevatedButton.icon(
            onPressed: _loading || _saving ? null : _saveSettings,
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded, size: 18),
            label: Text(_saving ? 'Menyimpan...' : 'Simpan Pengaturan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _Section({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineVariant)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ]),
      const Divider(color: AppColors.outlineVariant, height: 20),
      ...children,
    ]),
  );
}

class _SettingField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  const _SettingField({required this.label, required this.controller, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    const SizedBox(height: 6),
    TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    ),
  ]);
}

class _ToggleSetting extends StatelessWidget {
  final String label;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleSetting({required this.label, required this.sub, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
      ])),
      Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
    ]),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
    title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
    subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
    trailing: Icon(Icons.chevron_right_rounded, color: color),
    onTap: onTap,
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );
}

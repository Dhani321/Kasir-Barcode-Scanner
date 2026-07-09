import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/user_service.dart'; // also exports ReportService and SettingService


class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ReportService.getDashboardStats();
      setState(() { _stats = data; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Gagal memuat data: $e'; _loading = false; });
    }
  }

  String _fmt(dynamic v) {
    final val = (v is int ? v.toDouble() : (v is double ? v : double.tryParse(v.toString()) ?? 0.0));
    return 'Rp ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: AppColors.surfaceContainerLowest,
        child: Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Riwayat Penjualan',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            SizedBox(height: 4),
            Text('Pantau seluruh transaksi dan performa penjualan.',
                style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
          ])),
          OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onSurface,
              side: const BorderSide(color: AppColors.outlineVariant),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Export Laporan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
          ),
        ]),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadData)
              : _buildContent()),
    ]);
  }

  Widget _buildContent() {
    final todaySales = _stats?['today_sales'] ?? 0;
    final todayCount = _stats?['today_transactions'] ?? 0;
    final lowStock = _stats?['low_stock_count'] ?? 0;
    final weekly = (_stats?['weekly_sales'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        // Stats row
        Row(children: [
          Expanded(flex: 2, child: _StatCard(
            icon: Icons.payments_rounded, label: 'Total Penjualan Hari Ini',
            value: _fmt(todaySales), sub: '$todayCount transaksi',
            badge: '+Today', badgeBg: AppColors.primaryContainer, badgeFg: AppColors.onPrimaryContainer,
          )),
          const SizedBox(width: 16),
          Expanded(child: _StatCard(
            icon: Icons.warning_rounded, label: 'Peringatan Stok',
            value: '$lowStock Item', sub: 'Stok hampir habis',
            bg: lowStock > 0 ? AppColors.errorContainer : AppColors.surfaceContainerLowest,
            fg: lowStock > 0 ? AppColors.onErrorContainer : AppColors.onSurface,
          )),
          const SizedBox(width: 16),
          Expanded(child: _StatCard(
            icon: Icons.receipt_long_rounded, label: 'Transaksi Hari Ini',
            value: '$todayCount', sub: 'Transaksi selesai',
          )),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 380,
          child: Row(children: [
            Expanded(flex: 2, child: _WeeklyChartCard(weekly: weekly)),
            const SizedBox(width: 16),
            Expanded(child: _ActivityCard()),
          ]),
        ),
      ]),
    );
  }
}

class _WeeklyChartCard extends StatelessWidget {
  final List<dynamic> weekly;
  const _WeeklyChartCard({required this.weekly});

  @override
  Widget build(BuildContext context) {
    final maxVal = weekly.isEmpty ? 1.0
        : weekly.map((e) => double.tryParse(e['total'].toString()) ?? 0.0).reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Penjualan 7 Hari', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(6)),
              child: const Text('7 Hari', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const Divider(height: 1, color: AppColors.outlineVariant),
        Expanded(
          child: weekly.isEmpty
              ? const Center(child: Text('Belum ada data', style: TextStyle(color: AppColors.onSurfaceVariant)))
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: LayoutBuilder(builder: (context, constraints) {
                    final maxBarH = constraints.maxHeight - 28.0;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: weekly.map((e) {
                        final val = double.tryParse(e['total'].toString()) ?? 0.0;
                        final ratio = maxVal > 0 ? val / maxVal : 0.0;
                        final day = (e['date'] as String).substring(5);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                              Tooltip(
                                message: 'Rp ${val.toStringAsFixed(0)}',
                                child: Container(
                                  width: 32, // Fixed width to prevent zero-size
                                  height: (maxBarH * ratio) < 4.0 ? 4.0 : (maxBarH * ratio), // Minimum height
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(day, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                            ]),
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ),
        ),
      ]),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Aktivitas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(6)),
              child: const Text('Live', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
            ),
          ]),
        ),
        const Divider(height: 1, color: AppColors.outlineVariant),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              const items = [
                (Icons.receipt_long_rounded, AppColors.primaryContainer, AppColors.onPrimaryContainer,
                    'Transaksi Selesai', 'Data real-time', 'Terhubung ke server'),
                (Icons.inventory_2_rounded, AppColors.errorContainer, AppColors.onErrorContainer,
                    'Cek Stok', 'Lihat tab Stok', 'Untuk stok rendah'),
                (Icons.person_rounded, AppColors.surfaceContainerHighest, AppColors.onSurfaceVariant,
                    'Kelola Akun', 'Tab Register Akun', 'Tambah kasir baru'),
              ];
              final a = items[i];
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: a.$2, borderRadius: BorderRadius.circular(8)),
                  child: Icon(a.$1, size: 16, color: a.$3),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.$4, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(a.$5, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  Text(a.$6, style: const TextStyle(fontSize: 11, color: AppColors.outline)),
                ])),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value, sub;
  final String? badge;
  final Color? badgeBg, badgeFg;
  final Color bg, fg;

  const _StatCard({
    required this.icon, required this.label, required this.value, required this.sub,
    this.badge, this.badgeBg, this.badgeFg,
    this.bg = AppColors.surfaceContainerLowest, this.fg = AppColors.onSurface,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child: Row(children: [
            Icon(icon, color: fg == AppColors.onSurface ? AppColors.onSurfaceVariant : fg, size: 18),
            const SizedBox(width: 6),
            Flexible(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: fg == AppColors.onSurface ? AppColors.onSurfaceVariant : fg))),
          ]),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
            child: Text(badge!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badgeFg)),
          ),
      ]),
      const SizedBox(height: 12),
      Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: fg, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text(sub, style: TextStyle(fontSize: 13, color: fg == AppColors.onSurface ? AppColors.onSurfaceVariant : fg.withOpacity(0.7))),
    ]),
  );
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
      Text(message, style: const TextStyle(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: onRetry, icon: const Icon(Icons.refresh_rounded),
        label: const Text('Coba Lagi'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      ),
    ],
  ));
}

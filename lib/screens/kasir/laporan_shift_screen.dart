import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/transaction_service.dart';
import '../../services/user_service.dart';
import '../shared/shift_detail_screen.dart';

class LaporanShiftScreen extends StatefulWidget {
  const LaporanShiftScreen({super.key});
  @override
  State<LaporanShiftScreen> createState() => _LaporanShiftScreenState();
}

class _LaporanShiftScreenState extends State<LaporanShiftScreen> {
  Map<String, dynamic>? _shift;
  Map<String, dynamic>? _report;
  List<dynamic> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShift();
  }

  Future<void> _loadShift() async {
    setState(() { _loading = true; _error = null; });
    try {
      final shift = await ShiftService.getCurrentShift();
      final historyData = await ShiftService.getShifts();
      _history = (historyData['data'] as List?) ?? [];
      
      if (shift == null || shift['id'] == null) {
        setState(() { _shift = null; _loading = false; });
        return;
      }
      final report = await ReportService.getShiftReport(shift['id'] as int);
      setState(() {
        _shift = shift;
        _report = report;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openShift() async {
    setState(() => _loading = true);
    try {
      await ShiftService.openShift(openingCash: 0);
      _loadShift();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _closeShift() async {
    setState(() => _loading = true);
    try {
      await ShiftService.closeShift(closingCash: 0, notes: 'Ditutup oleh sistem');
      _loadShift();
      if (mounted) {
        Navigator.pop(context); // Go back to shell
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shift berhasil ditutup')));
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _fmt(dynamic v) {
    final val = (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    return 'Rp ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Laporan Shift', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.outlineVariant)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: AppColors.error)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shift == null ? _buildNoShift() : _buildReport(),
                      const SizedBox(height: 32),
                      _buildHistory(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Riwayat Shift Sebelumnya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            children: _history.map((h) {
              final start = h['start_time']?.toString().substring(0, 16) ?? '';
              final end = h['end_time']?.toString().substring(0, 16) ?? 'Aktif';
              final isClosed = h['status'] == 'closed';
              return ListTile(
                leading: Icon(isClosed ? Icons.check_circle_rounded : Icons.access_time_filled_rounded, 
                  color: isClosed ? AppColors.tertiary : AppColors.primary),
                title: Text('Shift: $start - $end'),
                subtitle: Text('Status: ${h['status']}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ShiftDetailScreen(shiftId: h['id']),
                  ));
                },
              );
            }).toList(),
          ),
        )
      ],
    );
  }

  Widget _buildNoShift() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.point_of_sale_rounded, size: 64, color: AppColors.outlineVariant),
          const SizedBox(height: 16),
          const Text('Tidak ada shift aktif', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Buka shift baru untuk memulai transaksi', style: TextStyle(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _openShift,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            child: const Text('Buka Shift Baru'),
          )
        ],
      ),
    );
  }

  Widget _buildReport() {
    final sum = _report?['summary'] ?? {};
    final txns = (_report?['transactions'] as List?) ?? [];
    final startTime = _shift!['start_time']?.toString().substring(11, 16) ?? '--:--';
    final kasirName = _shift!['kasir']?['name'] ?? 'Kasir';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Shift Info
        Container(
          decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(16)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ShiftDetailScreen(shiftId: _shift!['id']),
                ));
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  const Icon(Icons.access_time_rounded, color: AppColors.onPrimaryContainer, size: 32),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Shift Aktif', style: TextStyle(fontSize: 12, color: AppColors.onPrimaryContainer)),
                    Text('Sejak $startTime WIB', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onPrimaryContainer)),
                    Text('Kasir: $kasirName • Terminal 01', style: const TextStyle(fontSize: 13, color: AppColors.onPrimaryContainer)),
                  ])),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.onPrimaryContainer),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Stats
        Row(children: [
          Expanded(child: _ShiftStat(label: 'Total Penjualan', value: _fmt(sum['total_sales'] ?? 0), icon: Icons.payments_rounded, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: _ShiftStat(label: 'Jumlah Transaksi', value: '${sum['total_transactions'] ?? 0}', icon: Icons.receipt_long_rounded, color: AppColors.secondary)),
          const SizedBox(width: 12),
          Expanded(child: _ShiftStat(label: 'Item Terjual', value: '${sum['total_items'] ?? 0} pcs', icon: Icons.inventory_2_rounded, color: AppColors.tertiary)),
        ]),
        const SizedBox(height: 20),
        // Transaction list
        Container(
          decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineVariant)),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Riwayat Transaksi Shift Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('${txns.length} transaksi', style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
              ]),
            ),
            const Divider(height: 1, color: AppColors.outlineVariant),
            Container(
              color: AppColors.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Row(children: [
                Expanded(flex: 2, child: Text('No. Transaksi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant))),
                Expanded(child: Text('Waktu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant))),
                Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant))),
                Expanded(child: Padding(padding: EdgeInsets.only(left: 12), child: Text('Metode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)))),
              ]),
            ),
            if (txns.isEmpty)
              const Padding(padding: EdgeInsets.all(32), child: Text('Belum ada transaksi', style: TextStyle(color: AppColors.onSurfaceVariant)))
            else
              ...txns.map((t) => _TxnRow(txn: t)),
          ]),
        ),
        const SizedBox(height: 20),
        // Close shift button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Tutup Shift?'),
                content: const Text('Yakin ingin menutup shift? Pastikan semua transaksi sudah selesai.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                  ElevatedButton(
                    onPressed: () { Navigator.pop(context); _closeShift(); },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                    child: const Text('Tutup Shift'),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Tutup Shift & Keluar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShiftStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _ShiftStat({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.outlineVariant)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 10),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
    ]),
  );
}

class _TxnRow extends StatelessWidget {
  final dynamic txn;
  const _TxnRow({required this.txn});

  String _fmt(dynamic v) {
    final val = (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    return 'Rp ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}';
  }

  @override
  Widget build(BuildContext context) {
    final time = txn['created_at']?.toString().substring(11, 16) ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.outlineVariant))),
      child: Row(children: [
        Expanded(flex: 2, child: Text(txn['transaction_number'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace'))),
        Expanded(child: Text(time, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant))),
        Expanded(flex: 2, child: Text(_fmt(txn['grand_total']), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary))),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(6)),
            child: Text((txn['payment_method'] ?? '').toString().toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
          ),
        )),
      ]),
    );
  }
}

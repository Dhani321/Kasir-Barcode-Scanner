import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/transaction_service.dart'; // Contains ShiftService
import '../../shared/shift_detail_screen.dart';

class AktivitasTab extends StatefulWidget {
  const AktivitasTab({super.key});

  @override
  State<AktivitasTab> createState() => _AktivitasTabState();
}

class _AktivitasTabState extends State<AktivitasTab> {
  List<dynamic> _shifts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  Future<void> _loadShifts() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ShiftService.getShifts();
      setState(() {
        _shifts = res['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Gagal memuat aktivitas shift: $e'; _loading = false; });
    }
  }

  String _fmtMoney(dynamic v) {
    final val = (v is int ? v.toDouble() : (v is double ? v : double.tryParse(v.toString()) ?? 0.0));
    return 'Rp ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: AppColors.surfaceContainerLowest,
          child: Row(children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Aktivitas Kasir & Laporan Shift', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              SizedBox(height: 4),
              Text('Pantau histori shift aktif dan tertutup dari seluruh kasir.', style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
            ])),
            OutlinedButton.icon(
              onPressed: _loadShifts,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
            ),
          ]),
        ),
        // Content
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
                  : _buildList(),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_shifts.isEmpty) {
      return const Center(child: Text('Belum ada riwayat aktivitas shift.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _shifts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final shift = _shifts[i];
        final kasir = shift['kasir']?['name'] ?? 'Unknown Kasir';
        final status = shift['status'];
        final startTime = shift['start_time']?.toString().substring(0, 16) ?? '';
        final endTime = shift['end_time']?.toString().substring(0, 16) ?? 'Sekarang';
        final totalSales = shift['total_sales'] ?? 0;
        final totalTxn = shift['total_transactions'] ?? 0;

        final isClosed = status == 'closed';

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ShiftDetailScreen(shiftId: shift['id']),
              ));
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: isClosed ? AppColors.surfaceVariant : AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isClosed ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                    color: isClosed ? AppColors.onSurfaceVariant : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Kasir: $kasir', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('$startTime  →  $endTime', style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isClosed ? AppColors.surfaceVariant : AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isClosed ? 'TUTUP' : 'AKTIF',
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: isClosed ? AppColors.onSurfaceVariant : AppColors.primary,
                        ),
                      ),
                    ),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(_fmtMoney(totalSales), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text('$totalTxn Transaksi', style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                ]),
              ],
            ),
          ),
        ),
      );
      },
    );
  }
}

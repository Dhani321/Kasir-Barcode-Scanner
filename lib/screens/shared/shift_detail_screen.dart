import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';

class ShiftDetailScreen extends StatefulWidget {
  final int shiftId;
  const ShiftDetailScreen({super.key, required this.shiftId});

  @override
  State<ShiftDetailScreen> createState() => _ShiftDetailScreenState();
}

class _ShiftDetailScreenState extends State<ShiftDetailScreen> {
  Map<String, dynamic>? _shift;
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
      final res = await ApiClient.get('/shifts/${widget.shiftId}');
      setState(() {
        _shift = res.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Gagal memuat detail shift: $e'; _loading = false; });
    }
  }

  String _fmt(dynamic v) {
    final val = (v is int ? v.toDouble() : (v is double ? v : double.tryParse(v.toString()) ?? 0.0));
    return 'Rp ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Shift', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: AppColors.surfaceContainerLowest,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final kasirName = _shift!['kasir']?['name'] ?? 'Kasir';
    final startTime = _shift!['start_time']?.toString().substring(0, 16) ?? '--:--';
    final endTime = _shift!['end_time']?.toString().substring(0, 16) ?? 'Aktif';
    final status = _shift!['status'] ?? 'unknown';
    final totalSales = _shift!['total_sales'] ?? 0;
    final txns = (_shift!['transactions'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header Shift
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: status == 'closed' ? AppColors.surfaceContainerLowest : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(children: [
                Icon(
                  status == 'closed' ? Icons.check_circle_rounded : Icons.access_time_rounded,
                  color: status == 'closed' ? AppColors.tertiary : AppColors.onPrimaryContainer,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Kasir: $kasirName', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: status == 'closed' ? AppColors.onSurface : AppColors.onPrimaryContainer)),
                    const SizedBox(height: 4),
                    Text('$startTime  →  $endTime', style: TextStyle(fontSize: 14, color: status == 'closed' ? AppColors.onSurfaceVariant : AppColors.onPrimaryContainer)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(_fmt(totalSales), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: status == 'closed' ? AppColors.primary : AppColors.onPrimaryContainer)),
                  const SizedBox(height: 4),
                  Text('${txns.length} Transaksi', style: TextStyle(fontSize: 13, color: status == 'closed' ? AppColors.onSurfaceVariant : AppColors.onPrimaryContainer)),
                ]),
              ]),
            ),
            const SizedBox(height: 24),
            // Transaction List
            const Text('Daftar Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            if (txns.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Belum ada transaksi di shift ini.', style: TextStyle(color: AppColors.onSurfaceVariant)),
              ))
            else
              ...txns.map((t) => _buildTransactionCard(t)),
          ]),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(dynamic txn) {
    final tNum = txn['transaction_number'] ?? '-';
    final time = txn['created_at']?.toString().substring(11, 16) ?? '';
    final grandTotal = txn['grand_total'] ?? 0;
    final method = txn['payment_method'] ?? '-';
    final items = (txn['items'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Txn Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(tNum, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Row(children: [
              Text(method.toString().toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              const SizedBox(width: 12),
              Text(time, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ]),
          ]),
        ),
        // Items
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: items.map((i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(flex: 3, child: Text(i['product_name'] ?? 'Unknown', style: const TextStyle(fontSize: 13))),
                  Expanded(child: Text('${i['qty']}x', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant))),
                  Expanded(flex: 2, child: Text(_fmt(i['subtotal'] ?? 0), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                ]),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1, color: AppColors.outlineVariant),
        // Total
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total Transaksi:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(_fmt(grandTotal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]),
        ),
      ]),
    );
  }
}

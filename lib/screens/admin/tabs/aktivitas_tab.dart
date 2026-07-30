import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/transaction_service.dart'; // Contains ShiftService
import '../../../services/activity_log_service.dart';
import '../../../services/api_client.dart';
import '../../../models/activity_log.dart';
import '../../shared/shift_detail_screen.dart';

class AktivitasTab extends StatefulWidget {
  const AktivitasTab({super.key});

  @override
  State<AktivitasTab> createState() => _AktivitasTabState();
}

class _AktivitasTabState extends State<AktivitasTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Shift state
  List<dynamic> _shifts = [];
  bool _loadingShifts = true;
  String? _errorShifts;

  // Activity log state
  List<ActivityLog> _logs = [];
  bool _loadingLogs = true;
  String? _errorLogs;
  String? _selectedActionFilter;
  final TextEditingController _searchLogCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadShifts();
    _loadLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchLogCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadShifts() async {
    setState(() { _loadingShifts = true; _errorShifts = null; });
    try {
      final res = await ShiftService.getShifts();
      setState(() {
        _shifts = res['data'] ?? [];
        _loadingShifts = false;
      });
    } catch (e) {
      setState(() { _errorShifts = 'Gagal memuat aktivitas shift: $e'; _loadingShifts = false; });
    }
  }

  Future<void> _loadLogs({String? search, String? action}) async {
    setState(() { _loadingLogs = true; _errorLogs = null; });
    try {
      final res = await ActivityLogService.getActivityLogs(
        search: search ?? _searchLogCtrl.text,
        action: action ?? _selectedActionFilter,
        perPage: 50,
      );
      setState(() {
        _logs = res['logs'] as List<ActivityLog>;
        _loadingLogs = false;
      });
    } catch (e) {
      setState(() { _errorLogs = 'Gagal memuat log aktivitas: $e'; _loadingLogs = false; });
    }
  }

  String _fmtMoney(dynamic v) {
    final val = (v is int ? v.toDouble() : (v is double ? v : double.tryParse(v.toString()) ?? 0.0));
    return 'Rp ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  List<_GroupedLogItem> _getGroupedLogs() {
    final List<_GroupedLogItem> result = [];
    final Map<String, List<ActivityLog>> saleGroups = {};

    for (final log in _logs) {
      if (log.action == 'sale_stock_out') {
        final match = RegExp(r'\[Transaksi #(.*?)\]').firstMatch(log.description ?? '');
        final txnKey = match != null ? match.group(1) : null;
        if (txnKey != null && txnKey.isNotEmpty) {
          saleGroups.putIfAbsent(txnKey, () => []).add(log);
        } else {
          result.add(_GroupedLogItem(singleLog: log));
        }
      } else {
        result.add(_GroupedLogItem(singleLog: log));
      }
    }

    saleGroups.forEach((txnNum, items) {
      result.add(_GroupedLogItem(
        transactionNumber: txnNum,
        groupLogs: items,
      ));
    });

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with TabBar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: AppColors.surfaceContainerLowest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Log Aktivitas & Shift Kasir', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                  SizedBox(height: 4),
                  Text('Pantau jejak aktivitas inventori, pengguna, dan histori shift kasir.', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                ])),
                if (_tabController.index == 1) ...[
                  OutlinedButton.icon(
                    onPressed: () => _openMonthlyCashierReportFilterModal(context),
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text('Export Laporan Kasir Bulanan'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(width: 8),
                ],
                OutlinedButton.icon(
                  onPressed: () {
                    _loadShifts();
                    _loadLogs();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh'),
                ),
              ]),
              const SizedBox(height: 16),
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.onSurfaceVariant,
                  tabs: const [
                    Tab(text: 'Log Aktivitas Stok & Produk'),
                    Tab(text: 'Histori Shift Kasir'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Content Area
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLogsView(),
              _buildShiftsView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogsView() {
    if (_loadingLogs) return const Center(child: CircularProgressIndicator());
    if (_errorLogs != null) return Center(child: Text(_errorLogs!, style: const TextStyle(color: AppColors.error)));

    final groupedLogs = _getGroupedLogs();

    return Column(
      children: [
        // Filters bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: AppColors.surfaceContainerLow,
          child: Row(children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchLogCtrl,
                  onSubmitted: (val) => _loadLogs(),
                  decoration: InputDecoration(
                    hintText: 'Cari produk, kode barang, atau pengguna...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchLogCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchLogCtrl.clear();
                              _loadLogs();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 40,
              width: 200,
              child: DropdownButtonFormField<String?>(
                initialValue: _selectedActionFilter,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                hint: const Text('Semua Jenis Aktivitas', style: TextStyle(fontSize: 12)),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua Jenis Aktivitas', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'create_product', child: Text('Tambah Produk', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'add_stock', child: Text('Tambah Stok', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'reduce_stock', child: Text('Kurangi Stok', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'update_product', child: Text('Edit Produk', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'delete_product', child: Text('Hapus Produk', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'sale_stock_out', child: Text('Penjualan Kasir', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (val) {
                  setState(() => _selectedActionFilter = val);
                  _loadLogs(action: val);
                },
              ),
            ),
          ]),
        ),
        // Log list
        Expanded(
          child: groupedLogs.isEmpty
              ? const Center(child: Text('Belum ada log aktivitas terdeteksi.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: groupedLogs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = groupedLogs[i];
                    if (item.isGroupedSale) {
                      return _SaleTransactionAccordionCard(item: item);
                    } else if (item.singleLog != null) {
                      return _ActivityLogCard(log: item.singleLog!);
                    }
                    return const SizedBox.shrink();
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildShiftsView() {
    if (_loadingShifts) return const Center(child: CircularProgressIndicator());
    if (_errorShifts != null) return Center(child: Text(_errorShifts!, style: const TextStyle(color: AppColors.error)));
    if (_shifts.isEmpty) return const Center(child: Text('Belum ada riwayat aktivitas shift.'));

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

  void _openMonthlyCashierReportFilterModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _MonthlyCashierFilterDialog(),
    );
  }
}

class _MonthlyCashierFilterDialog extends StatefulWidget {
  const _MonthlyCashierFilterDialog();

  @override
  State<_MonthlyCashierFilterDialog> createState() => _MonthlyCashierFilterDialogState();
}

class _MonthlyCashierFilterDialogState extends State<_MonthlyCashierFilterDialog> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _selectedKasirId = 'all';
  List<dynamic> _cashiers = [];

  @override
  void initState() {
    super.initState();
    _loadCashiers();
  }

  Future<void> _loadCashiers() async {
    try {
      final res = await ApiClient.get('/users');
      final list = (res.data as List).where((u) => u['role'] == 'kasir' || u['role'] == 'admin').toList();
      setState(() {
        _cashiers = list;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [
        Icon(Icons.assessment_rounded, color: AppColors.primary),
        SizedBox(width: 10),
        Text('Export Laporan Shift Kasir Bulanan'),
      ]),
      content: SizedBox(
        width: 480,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pilih user kasir dan periode bulan/tahun untuk laporan shift:',
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedKasirId,
            decoration: const InputDecoration(labelText: 'Pilih User Kasir', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('Semua Kasir')),
              ..._cashiers.map((u) => DropdownMenuItem(
                    value: u['id'].toString(),
                    child: Text('${u['name']} (${u['employee_id'] ?? u['role']})'),
                  )),
            ],
            onChanged: (v) => setState(() => _selectedKasirId = v!),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _selectedMonth,
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
                onChanged: (v) => setState(() => _selectedMonth = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _selectedYear,
                decoration: const InputDecoration(labelText: 'Tahun', border: OutlineInputBorder()),
                items: [2024, 2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                onChanged: (v) => setState(() => _selectedYear = v!),
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
            showDialog(
              context: context,
              builder: (ctx) => _MonthlyCashierShiftReportPreviewModal(
                month: _selectedMonth,
                year: _selectedYear,
                kasirId: _selectedKasirId,
              ),
            );
          },
          icon: const Icon(Icons.visibility_rounded, size: 18),
          label: const Text('Tampilkan Laporan'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        ),
      ],
    );
  }
}

class _MonthlyCashierShiftReportPreviewModal extends StatefulWidget {
  final int month;
  final int year;
  final String kasirId;
  const _MonthlyCashierShiftReportPreviewModal({required this.month, required this.year, required this.kasirId});

  @override
  State<_MonthlyCashierShiftReportPreviewModal> createState() => _MonthlyCashierShiftReportPreviewModalState();
}

class _MonthlyCashierShiftReportPreviewModalState extends State<_MonthlyCashierShiftReportPreviewModal> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      final res = await ApiClient.get('/reports/cashier-shifts', params: {
        'month': widget.month,
        'year': widget.year,
        'kasir_id': widget.kasirId,
      });
      setState(() {
        _data = res.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat laporan shift kasir: $e';
        _loading = false;
      });
    }
  }

  String _fmt(dynamic v) {
    final val = (v is int ? v.toDouble() : (v is double ? v : double.tryParse(v.toString()) ?? 0.0));
    return 'Rp ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _getMonthName(int m) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return (m >= 1 && m <= 12) ? months[m - 1] : '$m';
  }

  @override
  Widget build(BuildContext context) {
    final title = 'Laporan Shift Kasir Bulanan - ${_getMonthName(widget.month)} ${widget.year}';
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
              const Text('Rekapitulasi shift pembukaan/penutupan kasir beserta total penjualan.',
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
                    : _buildReportContent(),
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

  Widget _buildReportContent() {
    final summary = _data?['summary'] ?? {};
    final totalSales = summary['total_sales'] ?? 0;
    final totalShifts = summary['total_shifts'] ?? 0;
    final totalTxns = summary['total_transactions'] ?? 0;
    final avgSales = summary['avg_sales_per_shift'] ?? 0;
    final shifts = (_data?['shifts'] as List?) ?? [];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Total Omset Penjualan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onPrimaryContainer)),
            const SizedBox(height: 4),
            Text(_fmt(totalSales), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ]),
        )),
        const SizedBox(width: 10),
        Expanded(child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Total Shift Kasir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSecondaryContainer)),
            const SizedBox(height: 4),
            Text('$totalShifts Shift', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSecondaryContainer)),
          ]),
        )),
        const SizedBox(width: 10),
        Expanded(child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Rata-Rata per Shift', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(_fmt(avgSales), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
        )),
      ]),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Daftar Shift Kasir (${shifts.length} Shift Terdata)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text('Total Transaksi: $totalTxns', style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 8),
      Expanded(
        child: shifts.isEmpty
            ? const Center(child: Text('Tidak ada shift kasir terdata pada periode ini.'))
            : ListView.separated(
                itemCount: shifts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final s = shifts[i];
                  final kasirName = s['kasir']?['name'] ?? 'Kasir';
                  final empId = s['kasir']?['employee_id'] ?? '';
                  final start = s['start_time']?.toString().substring(0, 16) ?? '-';
                  final end = s['end_time']?.toString().substring(0, 16) ?? 'Aktif';
                  final sales = s['total_sales'] ?? 0;
                  final txnsCount = s['total_transactions'] ?? 0;
                  final isClosed = s['status'] == 'closed';

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isClosed ? Colors.grey.shade200 : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isClosed ? 'TUTUP' : 'AKTIF',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isClosed ? Colors.grey.shade800 : Colors.blue.shade900),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Kasir: $kasirName ${empId.isNotEmpty ? "($empId)" : ""}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('$start  →  $end', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(_fmt(sales), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Text('$txnsCount Transaksi', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                      ]),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }
}

class _GroupedLogItem {
  final String? transactionNumber;
  final List<ActivityLog>? groupLogs;
  final ActivityLog? singleLog;

  _GroupedLogItem({this.transactionNumber, this.groupLogs, this.singleLog});

  bool get isGroupedSale => transactionNumber != null && groupLogs != null && groupLogs!.isNotEmpty;

  DateTime get createdAt {
    if (isGroupedSale) return groupLogs!.first.createdAt;
    return singleLog!.createdAt;
  }
}

class _SaleTransactionAccordionCard extends StatelessWidget {
  final _GroupedLogItem item;
  const _SaleTransactionAccordionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final logs = item.groupLogs!;
    final first = logs.first;
    final timeStr = first.createdAt.toString().substring(0, 16).replaceAll('T', ' ');
    final totalUnits = logs.fold<int>(0, (sum, l) => sum + l.qtyChange.abs());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_cart_checkout_rounded, color: Colors.teal.shade700, size: 22),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Text(
                  'PENJUALAN (STOK KELUAR)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Transaksi #${item.transactionNumber} (${logs.length} jenis barang)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Oleh: ${first.userName} (${first.userRole})',
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                Text(
                  'Total stok keluar: -$totalUnits pcs | $timeStr',
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.teal.shade50.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8, left: 4),
                    child: Text('Rincian Barang yang Keluar dalam Transaksi ini:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
                  ),
                  ...logs.map((l) {
                    final prodName = l.productName ?? 'Produk';
                    final sku = l.sku ?? '-';
                    final qty = l.qtyChange.abs();
                    final oldS = l.oldStock ?? '-';
                    final newS = l.newStock ?? '-';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 16, color: Colors.teal.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(prodName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('Kode: $sku', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '-$qty pcs',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Stok: $oldS → $newS',
                            style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityLogCard extends StatelessWidget {
  final ActivityLog log;
  const _ActivityLogCard({required this.log});

  Color _getBadgeColor() {
    switch (log.action) {
      case 'create_product':
        return Colors.green.shade700;
      case 'add_stock':
        return Colors.blue.shade700;
      case 'reduce_stock':
        return Colors.orange.shade800;
      case 'update_product':
        return Colors.purple.shade700;
      case 'delete_product':
        return Colors.red.shade700;
      case 'sale_stock_out':
        return Colors.teal.shade700;
      default:
        return AppColors.primary;
    }
  }

  IconData _getBadgeIcon() {
    switch (log.action) {
      case 'create_product':
        return Icons.add_box_rounded;
      case 'add_stock':
        return Icons.arrow_downward_rounded;
      case 'reduce_stock':
        return Icons.arrow_upward_rounded;
      case 'update_product':
        return Icons.edit_note_rounded;
      case 'delete_product':
        return Icons.delete_forever_rounded;
      case 'sale_stock_out':
        return Icons.shopping_cart_checkout_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = log.createdAt.toString().substring(0, 16).replaceAll('T', ' ');
    final badgeColor = _getBadgeColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_getBadgeIcon(), color: badgeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        log.actionLabel.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ),
                    Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  log.description ?? '${log.actionLabel} pada ${log.productName ?? 'produk'}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Oleh: ${log.userName} (${log.userRole})',
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500),
                    ),
                    if (log.oldStock != null && log.newStock != null) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Stok: ${log.oldStock} → ${log.newStock}',
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

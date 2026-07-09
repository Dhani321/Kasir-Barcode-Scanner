import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../services/transaction_service.dart';

class PembayaranScreen extends StatefulWidget {
  final double total;
  const PembayaranScreen({super.key, required this.total});
  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  String _method = 'cash';
  String _input = '';
  bool _printReceipt = true;
  bool _isProcessing = false;
  String? _transactionNumber;

  double get _tendered => double.tryParse(_input) ?? 0;
  double get _change => _tendered - widget.total;
  bool get _canConfirm => _method != 'cash' || _change >= 0;

  String _fmt(double v) => 'Rp ${v.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  void _pressKey(String key) {
    setState(() {
      if (key == 'C') { _input = ''; return; }
      if (key == '⌫') { if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1); return; }
      if (key == 'EXACT') { _input = widget.total.toStringAsFixed(0); return; }
      if (key == '20000') { _input = '20000'; return; }
      if (key == '50000') { _input = '50000'; return; }
      if (key == '100000') { _input = '100000'; return; }
      if (_input.length < 12) _input += key;
    });
  }

  Future<void> _confirmPayment() async {
    final cart = context.read<CartProvider>();
    setState(() => _isProcessing = true);
    try {
      final result = await TransactionService.createTransaction(
        items: cart.toApiItems(),
        paymentMethod: _method,
        paymentAmount: _method == 'cash' ? _tendered : widget.total,
      );
      final txnNo = result['transaction_number'] as String? ?? '-';
      setState(() { _transactionNumber = txnNo; _isProcessing = false; });
      _showSuccessDialog(txnNo);
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: ${_parseError(e)}'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  String _parseError(dynamic e) {
    try { return (e as dynamic).response?.data?['message'] ?? e.toString(); } catch (_) { return e.toString(); }
  }

  void _showSuccessDialog(String txnNo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 72, height: 72, decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.onPrimaryContainer, size: 42)),
          const SizedBox(height: 20),
          const Text('Pembayaran Berhasil!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('No. Transaksi: $txnNo', style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant, fontFamily: 'monospace')),
          if (_method == 'cash') ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Kembalian:', style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant)),
                Text(_fmt(_change), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ]),
            ),
          ],
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);         // close dialog
                Navigator.pop(context, true);   // return true = success
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Selesai & Transaksi Baru', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = ['1','2','3','4','5','6','7','8','9','C','0','⌫','20rb','50rb','100rb','EXACT'];

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerHigh,
      body: Center(
        child: Container(
          width: 900, height: 700,
          decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outlineVariant),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 32, offset: const Offset(0, 8))]),
          clipBehavior: Clip.antiAlias,
          child: Row(children: [
            // Left: Payment details
            Expanded(child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.primary),
                      style: IconButton.styleFrom(backgroundColor: AppColors.surfaceContainerLow)),
                  const Expanded(child: Text('Proses Pembayaran', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                  const SizedBox(width: 48),
                ]),
              ),
              const SizedBox(height: 16),
              // Total display
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant)),
                child: Column(children: [
                  const Text('TOTAL PEMBAYARAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(_fmt(widget.total), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700,
                      color: AppColors.primary, letterSpacing: -1)),
                ]),
              ),
              const SizedBox(height: 20),
              // Payment method
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Metode Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(children: [
                    _MethodBtn(icon: Icons.payments_rounded, label: 'Tunai',
                        isActive: _method == 'cash', onTap: () => setState(() => _method = 'cash')),
                    const SizedBox(width: 10),
                    _MethodBtn(icon: Icons.credit_card_rounded, label: 'Kartu',
                        isActive: _method == 'card', onTap: () => setState(() { _method = 'card'; _input = ''; })),
                    const SizedBox(width: 10),
                    _MethodBtn(icon: Icons.qr_code_scanner_rounded, label: 'Digital',
                        isActive: _method == 'digital', onTap: () => setState(() { _method = 'digital'; _input = ''; })),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
              // Cash input
              if (_method == 'cash')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.primary, width: 2), borderRadius: BorderRadius.circular(14)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Uang Diterima', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Text('Rp ', style: TextStyle(fontSize: 20, color: AppColors.onSurfaceVariant)),
                        Text(
                          _input.isEmpty ? '0' : _input.replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.'),
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                      ]),
                      const Divider(color: AppColors.outlineVariant),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Kembalian', style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
                        Text(
                          _tendered == 0 ? '-' : _change >= 0 ? _fmt(_change) : 'Kurang!',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                              color: _tendered == 0 ? AppColors.outline : _change >= 0 ? AppColors.primary : AppColors.error)),
                      ]),
                    ]),
                  ),
                ),
              // Non-cash info
              if (_method != 'cash')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(14)),
                    child: Column(children: [
                      Icon(_method == 'card' ? Icons.credit_card_rounded : Icons.qr_code_rounded,
                          size: 40, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text(_method == 'card' ? 'Tempelkan / Gesek Kartu' : 'Scan QR Code',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      const SizedBox(height: 4),
                      const Text('Transaksi akan diproses otomatis', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                    ]),
                  ),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(children: [
                  Checkbox(value: _printReceipt, onChanged: (v) => setState(() => _printReceipt = v!), activeColor: AppColors.primary),
                  const Text('Cetak Struk'),
                  const SizedBox(width: 16),
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.outline),
                  const SizedBox(width: 4),
                  const Text('Stok otomatis berkurang', style: TextStyle(fontSize: 12, color: AppColors.outline)),
                ]),
              ),
            ])),
            // Right: Keypad
            Container(
              width: 320,
              decoration: const BoxDecoration(color: AppColors.surfaceContainerLow,
                  border: Border(left: BorderSide(color: AppColors.outlineVariant))),
              child: Column(children: [
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    padding: const EdgeInsets.all(14),
                    crossAxisSpacing: 8, mainAxisSpacing: 8,
                    childAspectRatio: 1.4,
                    children: keys.map((k) {
                      final isSpecial = k == 'C' || k == '⌫';
                      final isShortcut = k == '20rb' || k == '50rb' || k == '100rb' || k == 'EXACT';
                      return GestureDetector(
                        onTap: () => _pressKey(
                            k == '20rb' ? '20000' : k == '50rb' ? '50000' : k == '100rb' ? '100000' : k),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 80),
                          decoration: BoxDecoration(
                            color: isSpecial ? AppColors.surfaceVariant : AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.outlineVariant),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 2)]),
                          child: Center(child: k == '⌫'
                              ? const Icon(Icons.backspace_outlined, size: 20)
                              : Text(k, style: TextStyle(
                                  fontSize: isShortcut ? 13 : 22, fontWeight: FontWeight.w600,
                                  color: isShortcut ? AppColors.primary : AppColors.onSurface))),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Confirm button
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: double.infinity, height: 68,
                    child: ElevatedButton.icon(
                      onPressed: (!_canConfirm || _isProcessing) ? null : _confirmPayment,
                      icon: _isProcessing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle_rounded, size: 24),
                      label: Text(_isProcessing ? 'Memproses...' : 'Konfirmasi Pembayaran',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryContainer,
                        foregroundColor: AppColors.onSecondaryContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 2),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MethodBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _MethodBtn({required this.icon, required this.label, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryContainer : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.outlineVariant, width: isActive ? 2 : 1)),
        child: Column(children: [
          Icon(icon, size: 28, color: isActive ? AppColors.onPrimaryContainer : AppColors.onSurface),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: isActive ? AppColors.onPrimaryContainer : AppColors.onSurface)),
        ]),
      ),
    ),
  );
}

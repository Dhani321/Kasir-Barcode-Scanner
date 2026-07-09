import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'admin/admin_shell.dart';
import 'kasir/kasir_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_usernameCtrl.text.trim(), _passwordCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      final role = auth.user?.role ?? 'kasir';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => role == 'admin' ? const AdminShell() : const KasirShell()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Login gagal'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 420,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 6, color: AppColors.primary),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(children: [
                    Container(
                      width: 72, height: 72,
                      decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                      child: const Icon(Icons.storefront_rounded, size: 36, color: AppColors.onPrimaryContainer),
                    ),
                    const SizedBox(height: 16),
                    const Text('Retail Desa',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    const Text('Masuk untuk mengakses terminal',
                        style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 32),
                    _buildLabel('ID Karyawan / Username'),
                    const SizedBox(height: 6),
                    _buildTextField(controller: _usernameCtrl, hint: 'e.g. ADM-001 atau KSR-001',
                        prefixIcon: Icons.person_outline_rounded),
                    const SizedBox(height: 16),
                    _buildLabel('Password / PIN'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      onSubmitted: (_) => _login(),
                      decoration: _inputDeco(
                        hint: 'Masukkan PIN',
                        prefixIcon: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.outline, size: 20),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: () {},
                          child: const Text('Lupa PIN?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary))),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _login,
                        icon: isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.login_rounded, size: 20),
                        label: Text(isLoading ? 'Memproses...' : 'Masuk ke Terminal',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.outlineVariant),
                    const SizedBox(height: 12),
                    const Text('Versi 1.0.0  •  Terminal ID: T-001',
                        style: TextStyle(fontSize: 11, color: AppColors.outline)),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
  );

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData prefixIcon}) =>
      TextField(controller: controller, decoration: _inputDeco(hint: hint, prefixIcon: prefixIcon));

  InputDecoration _inputDeco({required String hint, required IconData prefixIcon, Widget? suffix}) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(prefixIcon, color: AppColors.outline, size: 20),
    suffixIcon: suffix,
    filled: true, fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outlineVariant)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outlineVariant)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
  );
}

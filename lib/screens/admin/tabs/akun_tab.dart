import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/user.dart';
import '../../../services/user_service.dart';

class AkunTab extends StatefulWidget {
  const AkunTab({super.key});
  @override
  State<AkunTab> createState() => _AkunTabState();
}

class _AkunTabState extends State<AkunTab> {
  final _nameCtrl = TextEditingController();
  final _empIdCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _role = 'kasir';
  bool _obscurePin = true;
  
  List<AppUser> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _empIdCtrl.dispose();
    _emailCtrl.dispose(); _pinCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({String? search}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await UserService.getUsers(search: search);
      setState(() {
        _users = list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _createUser() async {
    if (_nameCtrl.text.isEmpty || _pinCtrl.text.isEmpty) return;
    try {
      await UserService.createUser({
        'name': _nameCtrl.text,
        'employee_id': _empIdCtrl.text,
        'email': _emailCtrl.text,
        'password': _pinCtrl.text,
        'pin': _pinCtrl.text, // Assuming PIN same as password for simplicity
        'role': _role,
      });
      _nameCtrl.clear(); _empIdCtrl.clear(); _emailCtrl.clear(); _pinCtrl.clear();
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun berhasil dibuat'), backgroundColor: AppColors.primary));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _toggleUser(AppUser u) async {
    try {
      await UserService.toggleActive(u.id);
      _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: AppColors.surfaceContainerLowest,
          child: Row(children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Akun Pengguna', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Kelola akses sistem dan peran.', style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
              ]),
            ),
            OutlinedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
            )
          ]),
        ),
        Expanded(
          child: _loading && _users.isEmpty ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form
                SizedBox(
                  width: 300,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Tambah Akun Baru',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      const Divider(color: AppColors.outlineVariant, height: 24),
                      _FormField(label: 'Nama Lengkap', hint: 'e.g. Budi Santoso', controller: _nameCtrl),
                      const SizedBox(height: 12),
                      _FormField(label: 'ID Karyawan', hint: 'e.g. KSR-005', controller: _empIdCtrl),
                      const SizedBox(height: 12),
                      _FormField(label: 'Email / Username', hint: 'budi@retail.desa', controller: _emailCtrl),
                      const SizedBox(height: 12),
                      const Text('PIN / Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _pinCtrl,
                        obscureText: _obscurePin,
                        decoration: InputDecoration(
                          hintText: '••••',
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 18, color: AppColors.onSurfaceVariant),
                            onPressed: () => setState(() => _obscurePin = !_obscurePin),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.outlineVariant)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.outlineVariant)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Peran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(border: Border.all(color: AppColors.outlineVariant), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _role, isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                              DropdownMenuItem(value: 'admin', child: Text('Admin')),
                            ],
                            onChanged: (v) => setState(() => _role = v ?? 'kasir'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _createUser,
                          icon: const Icon(Icons.person_add_rounded, size: 18),
                          label: const Text('Buat Akun'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(width: 20),
                // User List Table
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Akun Tersedia (${_users.length})',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary)),
                            SizedBox(
                              width: 180,
                              child: TextField(
                                controller: _searchCtrl,
                                onSubmitted: (v) => _loadUsers(search: v),
                                decoration: InputDecoration(
                                  hintText: 'Filter akun...',
                                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.onSurfaceVariant),
                                  suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () {
                                    _searchCtrl.clear(); _loadUsers();
                                  }) : null,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
                                      borderSide: const BorderSide(color: AppColors.outlineVariant)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
                                      borderSide: const BorderSide(color: AppColors.outlineVariant)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Table Header
                      Container(
                        color: AppColors.surfaceContainerLow,
                        child: const Row(children: [
                          SizedBox(width: 56),
                          Expanded(flex: 2, child: _TH('Nama / ID')),
                          Expanded(child: _TH('Email / Username')),
                          Expanded(child: _TH('Peran')),
                          Expanded(child: _TH('Status')),
                          SizedBox(width: 80, child: _TH('Aksi', right: true)),
                        ]),
                      ),
                      if (_error != null)
                        Padding(padding: const EdgeInsets.all(20), child: Text('Error: $_error', style: const TextStyle(color: AppColors.error)))
                      else if (_users.isEmpty)
                        const Padding(padding: EdgeInsets.all(40), child: Text('Tidak ada akun ditemukan'))
                      else
                        ..._users.map((u) => _UserRow(user: u, onToggle: () => _toggleUser(u))),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  final bool right;
  const _TH(this.text, {this.right = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Text(text,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
  );
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  const _FormField({required this.label, required this.hint, required this.controller});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    const SizedBox(height: 6),
    TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    ),
  ]);
}

class _UserRow extends StatelessWidget {
  final AppUser user;
  final VoidCallback onToggle;
  const _UserRow({required this.user, required this.onToggle});

  static const _colors = [AppColors.primaryContainer, AppColors.secondaryContainer, AppColors.surfaceVariant, AppColors.tertiaryContainer];
  static const _fgs = [AppColors.onPrimaryContainer, AppColors.onSecondaryContainer, AppColors.onSurfaceVariant, AppColors.onTertiaryContainer];

  @override
  Widget build(BuildContext context) {
    final idx = user.id.hashCode % 4;
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.outlineVariant))),
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: CircleAvatar(
            radius: 16, backgroundColor: _colors[idx],
            child: Text(user.initials, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _fgs[idx])),
          ),
        ),
        Expanded(flex: 2, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.fullName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: user.isActive ? AppColors.onSurface : AppColors.onSurfaceVariant)),
            Text(user.employeeId, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
          ]),
        )),
        Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(user.email.isNotEmpty ? user.email : user.employeeId, style: TextStyle(fontSize: 11, color: user.isActive ? AppColors.onSurfaceVariant : AppColors.outline)),
        )),
        Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.outlineVariant)),
            child: Text(user.role.toUpperCase(), style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
          ),
        )),
        Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: user.isActive ? AppColors.primary : AppColors.error, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(user.isActive ? 'Aktif' : 'Nonaktif', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: user.isActive ? AppColors.primary : AppColors.error)),
          ]),
        )),
        SizedBox(
          width: 80,
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(
              onPressed: onToggle,
              icon: Icon(user.isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                  size: 18, color: user.isActive ? AppColors.error : AppColors.primary),
              tooltip: user.isActive ? 'Nonaktifkan' : 'Aktifkan',
            ),
          ]),
        ),
      ]),
    );
  }
}

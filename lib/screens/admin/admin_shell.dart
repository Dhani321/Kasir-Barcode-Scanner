import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../screens/login_screen.dart';
import '../../providers/auth_provider.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/stok_tab.dart';
import 'tabs/akun_tab.dart';
import 'tabs/pengaturan_tab.dart';
import 'tabs/aktivitas_tab.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentTab = 0;

  final _navItems = const [
    _NavItem(icon: Icons.history_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Manajemen Stok'),
    _NavItem(icon: Icons.pending_actions_rounded, label: 'Aktivitas Kasir'),
    _NavItem(icon: Icons.person_add_rounded, label: 'Register Akun'),
    _NavItem(icon: Icons.settings_rounded, label: 'Pengaturan'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _TopBar(),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildContent()),
                _Sidebar(
                  currentTab: _currentTab,
                  navItems: _navItems,
                  onTabChanged: (i) => setState(() => _currentTab = i),
                  onLogout: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentTab) {
      case 0: return const DashboardTab();
      case 1: return const StokTab();
      case 2: return const AktivitasTab();
      case 3: return const AkunTab();
      case 4: return const PengaturanTab();
      default: return const DashboardTab();
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          const Text('Retail Desa',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(width: 24),
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari...',
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.outline, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _iconBtn(Icons.person_outline_rounded),
          _iconBtn(Icons.signal_cellular_alt_rounded),
          _iconBtn(Icons.sync_rounded),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryContainer,
            child: const Text('A', style: TextStyle(color: AppColors.onPrimaryContainer, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon) => IconButton(
    icon: Icon(icon, color: AppColors.onSurfaceVariant),
    onPressed: () {},
  );
}

class _Sidebar extends StatelessWidget {
  final int currentTab;
  final List<_NavItem> navItems;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.currentTab,
    required this.navItems,
    required this.onTabChanged,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(left: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: AppColors.onPrimaryContainer, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Admin Portal',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                    Text('Head Office',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(navItems.length, (i) => _NavTile(
            item: navItems[i],
            isActive: currentTab == i,
            onTap: () => onTabChanged(i),
          )),
          const Spacer(),
          const Divider(color: AppColors.outlineVariant, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text('Keluar', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
            onTap: onLogout,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(item.icon,
                  color: isActive ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
                  size: 22),
              const SizedBox(width: 12),
              Text(item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

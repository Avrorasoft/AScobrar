import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/data_service.dart';
import '../home/collector_dashboard.dart';
import '../reports/daily_collection_report_screen.dart';
import '../clients/clients_list_screen.dart';
import '../loans/loans_list_screen.dart';
import '../settings/settings_screen.dart';

class CollectorShell extends ConsumerStatefulWidget {
  const CollectorShell({super.key});

  @override
  ConsumerState<CollectorShell> createState() => _CollectorShellState();
}

class _CollectorShellState extends ConsumerState<CollectorShell> {
  int _index = 0;

  final _pages = const [
    CollectorDashboard(),
    DailyCollectionReportScreen(),
    ClientsListScreen(),
    LoansListScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthGuard();
    });
  }

  void _checkAuthGuard() {
    final user = ref.read(currentUserProvider) ?? DataService.getCurrentUserSession();
    // Guarda estricta: Si no hay usuario o no es cobrador autenticado, expulsar a login
    if (user == null || user.role != UserRole.collector) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider) ?? DataService.getCurrentUserSession();
    if (user == null || user.role != UserRole.collector) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.neonCyan),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  emoji: '🏍️',
                  label: 'Mi Ruta',
                  selected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                _NavItem(
                  emoji: '📊',
                  label: 'Reporte',
                  selected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
                _NavItem(
                  emoji: '👥',
                  label: 'Clientes',
                  selected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
                _NavItem(
                  emoji: '💰',
                  label: 'Créditos',
                  selected: _index == 3,
                  onTap: () => setState(() => _index = 3),
                ),
                _NavItem(
                  emoji: '⚙️',
                  label: 'Ajustes',
                  selected: _index == 4,
                  onTap: () => setState(() => _index = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.neonCyan.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.neonCyan.withOpacity(0.4) : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppColors.neonCyan : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

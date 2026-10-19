import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/config_service.dart';
import '../home/owner_dashboard.dart';
import '../clients/clients_list_screen.dart';
import '../loans/loans_list_screen.dart';
import '../reports/daily_collection_report_screen.dart';
import '../alarms/alarms_list_screen.dart';
import '../settings/settings_screen.dart';

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    OwnerDashboard(),
    ClientsListScreen(),
    LoansListScreen(),
    DailyCollectionReportScreen(),
    AlarmsListScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final company = ConfigService.companyName;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: AppColors.surfaceDark,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: AppColors.neonCyan),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.neonCyan,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
            unselectedLabelTextStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
            useIndicator: true,
            indicatorColor: AppColors.primaryMid.withOpacity(0.18),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.neonCyan.withOpacity(0.5), width: 1.5),
                    ),
                    child: const Icon(Icons.account_balance, color: AppColors.neonCyan, size: 26),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 76,
                    child: Text(
                      company,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Tablero'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Clientes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.monetization_on_outlined),
                selectedIcon: Icon(Icons.monetization_on),
                label: Text('Préstamos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale),
                label: Text('Caja'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.alarm_outlined),
                selectedIcon: Icon(Icons.alarm),
                label: Text('Alarmas'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Ajustes'),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'AScobrar',
                    style: TextStyle(
                      color: AppColors.textMuted.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1, color: AppColors.cardBorder),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

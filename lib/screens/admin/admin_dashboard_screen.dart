import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../home/owner_dashboard.dart';
import '../reports/daily_collection_report_screen.dart';
import '../collectors/collectors_management_screen.dart';
import '../clients/clients_list_screen.dart';
import '../loans/loans_list_screen.dart';
import '../alarms/alarms_screen.dart';
import '../settings/settings_screen.dart';
import '../../services/data_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    OwnerDashboard(),
    DailyCollectionReportScreen(),
    ClientsListScreen(),
    LoansListScreen(),
    CollectorsManagementScreen(),
    AlarmsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.neonCyan,
        unselectedItemColor: AppColors.textMuted,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Panel'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Reporte Diario'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Préstamos'),
          BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Cobradores'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active), label: 'Alarmas'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}

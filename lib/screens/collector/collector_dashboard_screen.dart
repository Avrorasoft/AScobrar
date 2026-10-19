import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../home/collector_dashboard.dart';
import '../reports/daily_collection_report_screen.dart';
import '../clients/clients_list_screen.dart';
import '../loans/loans_list_screen.dart';
import '../../services/data_service.dart';

class CollectorDashboardScreen extends StatefulWidget {
  const CollectorDashboardScreen({super.key});

  @override
  State<CollectorDashboardScreen> createState() => _CollectorDashboardScreenState();
}

class _CollectorDashboardScreenState extends State<CollectorDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CollectorDashboard(),
    DailyCollectionReportScreen(),
    ClientsListScreen(),
    LoansListScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.motorcycle), label: 'Mi Ruta'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Mi Reporte Diario'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Cobros'),
        ],
      ),
    );
  }
}

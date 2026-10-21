import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client_model.dart';
import '../../models/loan_model.dart';
import '../../models/payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/data_service.dart';
import '../clients/client_detail_screen.dart';
import '../clients/new_client_screen.dart';
import '../collectors/collectors_management_screen.dart';
import '../loans/new_loan_screen.dart';
import '../reports/daily_collection_report_screen.dart';

class OwnerDashboard extends ConsumerStatefulWidget {
  const OwnerDashboard({super.key});

  @override
  ConsumerState<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends ConsumerState<OwnerDashboard> {
  String _search = '';
  StreamSubscription? _clientsSub;
  StreamSubscription? _loansSub;
  StreamSubscription? _paymentsSub;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Suscripción reactiva a los eventos de Hive en tiempo real
    _clientsSub = DataService.clients.watch().listen((_) {
      if (mounted) setState(() {});
    });
    _loansSub = DataService.loans.watch().listen((_) {
      if (mounted) setState(() {});
    });
    _paymentsSub = DataService.payments.watch().listen((_) {
      if (mounted) setState(() {});
    });

    // En Flutter Web, sincronización suave cada 2 segundos entre pestañas abiertas
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clientsSub?.cancel();
    _loansSub?.cancel();
    _paymentsSub?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clients = DataService.allClients();
    final loans = DataService.allLoans();
    final payments = DataService.allPayments();

    final activeLoans = loans.where((l) => l.status == LoanStatus.active).toList();
    final double totalLent = loans.fold(0.0, (s, l) => s + l.principal);
    final double totalCollected = payments.fold(0.0, (s, p) => s + p.amount);

    final filteredClients = clients.where((c) {
      final q = _search.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.documentId.toLowerCase().contains(q) ||
          c.phone.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: const Icon(Icons.account_balance, color: AppColors.neonCyan),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel Administrador - AScobrar',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight, fontSize: 16),
            ),
            Text(
              'Sincronizado en tiempo real',
              style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Botón de refresco manual
          IconButton(
            tooltip: 'Actualizar Datos',
            icon: const Icon(Icons.refresh, color: AppColors.neonCyan, size: 24),
            onPressed: () {
              setState(() {});
            },
          ),
          // BOTÓN PRINCIPAL PARA GESTIONAR COBRADORES Y CLAVES
          IconButton(
            tooltip: 'Gestión de Cobradores (Crear y Claves)',
            icon: const Icon(Icons.badge, color: AppColors.neonCyan, size: 26),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CollectorsManagementScreen()),
              );
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            tooltip: 'Cierre Diario de Caja',
            icon: const Icon(Icons.summarize, color: AppColors.warning, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailyCollectionReportScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Cerrar Sesión',
            icon: const Icon(Icons.logout, color: AppColors.alarmRed, size: 24),
            onPressed: () async {
              await ref.read(currentUserProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // TARJETAS DE ACCESO RÁPIDO Y TOTALES
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surfaceDark,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          title: 'Total Clientes',
                          value: '${clients.length}',
                          icon: Icons.people,
                          color: AppColors.neonCyan,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metricCard(
                          title: 'Préstamos Activos',
                          value: '${activeLoans.length}',
                          icon: Icons.monetization_on,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metricCard(
                          title: 'Total Cobrado',
                          value: 'Bs. ${totalCollected.toStringAsFixed(0)}',
                          icon: Icons.savings,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // BOTÓN DESTACADO PARA CREAR / ADMINISTRAR COBRADORES
                  InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CollectorsManagementScreen()),
                      );
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.neonCyan.withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.badge, color: AppColors.neonCyan, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cobradores y Contraseñas',
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Crear cobrador, dar contraseña de ingreso o cambiar con la llavecita 🔑',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.neonCyan),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),

            // BUSCADOR Y LISTADO DE CLIENTES
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: AppColors.textLight),
                decoration: InputDecoration(
                  hintText: 'Buscar cliente por nombre, DNI o teléfono...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.neonCyan),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),

            Expanded(
              child: filteredClients.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay clientes registrados',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: filteredClients.length,
                      itemBuilder: (context, index) {
                        final c = filteredClients[index];
                        final cLoans = loans.where((l) => l.clientId == c.id).toList();

                        return Card(
                          color: AppColors.cardDark,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.cardBorder),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.surfaceDark,
                              child: Icon(Icons.person, color: AppColors.neonCyan),
                            ),
                            title: Text(
                              c.name,
                              style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Tel: ${c.phone} • Préstamos: ${cLoans.length}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClientDetailScreen(client: c),
                                ),
                              );
                              if (mounted) setState(() {});
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.neonCyan,
        foregroundColor: AppColors.bgDark,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewClientScreen()),
          );
          if (mounted) setState(() {});
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: AppColors.textLight, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

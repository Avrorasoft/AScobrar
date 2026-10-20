import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/loan_model.dart';
import '../../providers/clients_provider.dart';
import '../../services/admin_security_service.dart';
import '../../services/data_service.dart';
import 'client_detail_screen.dart';
import 'new_client_screen.dart';

class ClientsListScreen extends ConsumerWidget {
  const ClientsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text(
          'Cartera de Clientes',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight),
        ),
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.neonCyan),
            tooltip: 'Actualizar',
            onPressed: () {
              ref.invalidate(clientsStreamProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_clients',
        backgroundColor: AppColors.primaryMid,
        child: const Icon(Icons.person_add, color: AppColors.bgDark),
        onPressed: () async {
          final res = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NewClientScreen()),
          );
          if (res == true) {
            ref.invalidate(clientsStreamProvider);
          }
        },
      ),
      body: SafeArea(
        child: clientsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.alarmRed, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Error al cargar cartera: $err',
                  style: const TextStyle(color: AppColors.alarmRed),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(clientsStreamProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
          data: (clients) {
            if (clients.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: AppColors.textMuted.withOpacity(0.4)),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay clientes registrados',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonCyan,
                        foregroundColor: AppColors.bgDark,
                      ),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Registrar Primer Cliente'),
                      onPressed: () async {
                        final res = await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NewClientScreen()),
                        );
                        if (res == true) {
                          ref.invalidate(clientsStreamProvider);
                        }
                      },
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: clients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final client = clients[index];
                final loans = DataService.loansOfClient(client.id);

                double totalDebt = 0.0;
                int activeLoansCount = 0;
                for (final l in loans) {
                  if (l.status == LoanStatus.active) {
                    totalDebt += l.pendingAmount;
                    activeLoansCount++;
                  }
                }

                return Card(
                  color: AppColors.surfaceDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: activeLoansCount > 0 ? AppColors.neonCyan.withOpacity(0.3) : AppColors.cardBorder,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryMid.withOpacity(0.2),
                      child: Text(
                        client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.primaryMid,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      client.name,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'CI: ${client.documentId} • Tel: ${client.phone}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                        if (client.fullAddress.isNotEmpty && client.fullAddress != 'Sin dirección registrada')
                          Text(
                            client.fullAddress,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (activeLoansCount > 0 ? AppColors.alarmRed : AppColors.success).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                activeLoansCount > 0
                                    ? '$activeLoansCount Activo(s) • Deuda: Bs. ${totalDebt.round()}'
                                    : 'Sin deudas activas',
                                style: TextStyle(
                                  color: activeLoansCount > 0 ? AppColors.alarmRed : AppColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
                          tooltip: 'Eliminar cliente (SuperAdmin)',
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final confirmed = await AdminSecurityService.requestSuperAdminAuth(
                              context: context,
                              actionTitle: 'Eliminar Cliente',
                              actionWarning:
                                  'Se eliminará a ${client.name} y todos sus préstamos asociados.',
                            );
                            if (confirmed) {
                              await AdminSecurityService.deleteClientCascade(client.id);
                              ref.invalidate(clientsStreamProvider);
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Cliente eliminado exitosamente.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textMuted),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClientDetailScreen(client: client),
                        ),
                      );
                      ref.invalidate(clientsStreamProvider);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

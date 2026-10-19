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
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_clients',
        backgroundColor: AppColors.primaryMid,
        child: const Icon(Icons.person_add, color: AppColors.bgDark),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NewClientScreen()),
          );
        },
      ),
      body: SafeArea(
        child: clientsAsync.when(
          data: (clients) {
            if (clients.isEmpty) {
              return const Center(
                child: Text(
                  'No hay clientes registrados aún.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: clients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final client = clients[index];
                final loans = DataService.loansOfClient(client.id);

                double totalDebt = 0.0;
                for (final l in loans) {
                  if (l.status != LoanStatus.cancelled) {
                    final paid = DataService.totalPaidOfLoan(l.id);
                    totalDebt += (l.totalToPay - paid).clamp(0.0, double.infinity);
                  }
                }

                return Card(
                  color: AppColors.cardDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.cardBorder, width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMid.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: AppColors.primaryMid),
                    ),
                    title: Text(
                      client.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
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
                        const SizedBox(height: 2),
                        Text(
                          totalDebt > 0
                              ? 'Saldo pendiente: Bs. ${totalDebt.round()}'
                              : 'Al día (Sin deuda pendiente)',
                          style: TextStyle(
                            color: totalDebt > 0 ? AppColors.alarmRed : AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
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
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClientDetailScreen(client: client),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryMid),
          ),
          error: (err, _) => Center(
            child: Text('Error: $err', style: const TextStyle(color: AppColors.alarmRed)),
          ),
        ),
      ),
    );
  }
}

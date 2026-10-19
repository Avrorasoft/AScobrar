import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/loans_provider.dart';
import '../../services/admin_security_service.dart';
import '../../services/data_service.dart';
import 'loan_detail_screen.dart';
import 'new_loan_screen.dart';

class LoansListScreen extends ConsumerWidget {
  const LoansListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(loansStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text(
          'Gestión de Préstamos',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight),
        ),
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textLight,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_loans',
        backgroundColor: AppColors.primaryMid,
        child: const Icon(Icons.add, color: AppColors.bgDark),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NewLoanScreen()),
          );
        },
      ),
      body: SafeArea(
        child: loansAsync.when(
          data: (loans) {
            if (loans.isEmpty) {
              return const Center(
                child: Text(
                  'No hay préstamos activos registrados.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: loans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final loan = loans[index];
                final paid = DataService.totalPaidOfLoan(loan.id);
                final remaining = (loan.totalToPay - paid).clamp(0.0, double.infinity);
                final isCompleted = remaining <= 0.5;

                return Card(
                  color: AppColors.cardDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isCompleted
                          ? AppColors.success.withOpacity(0.5)
                          : AppColors.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isCompleted
                          ? AppColors.success.withOpacity(0.15)
                          : AppColors.primaryMid.withOpacity(0.15),
                      child: Text(
                        isCompleted ? '✅' : '💰',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          'Capital: Bs. ${loan.principal.round()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        const Spacer(),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.success),
                            ),
                            child: const Text(
                              'PAGADO',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          isCompleted
                              ? 'Total cancelado: Bs. ${loan.totalToPay.round()}'
                              : 'Saldo pendiente: Bs. ${remaining.round()}',
                          style: TextStyle(
                            color: isCompleted ? AppColors.success : AppColors.alarmRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${loan.paidInstallments}/${loan.installments} cuotas pagadas',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
                          tooltip: 'Eliminar préstamo (SuperAdmin)',
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final confirmed = await AdminSecurityService.requestSuperAdminAuth(
                              context: context,
                              actionTitle: 'Eliminar Préstamo',
                              actionWarning:
                                  'Se eliminará este crédito y todos sus pagos vinculados.',
                            );
                            if (confirmed) {
                              await AdminSecurityService.deleteLoanCascade(loan.id);
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Préstamo eliminado exitosamente.'),
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
                          builder: (_) => LoanDetailScreen(loan: loan),
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

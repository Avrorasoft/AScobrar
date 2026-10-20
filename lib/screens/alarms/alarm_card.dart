import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/alarm_model.dart';
import '../../models/client_model.dart';
import '../../models/loan_model.dart';
import '../../models/user_model.dart';
import '../../services/data_service.dart';
import '../payments/new_payment_screen.dart';

class AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  final VoidCallback? onPaymentSuccess;

  const AlarmCard({
    super.key,
    required this.alarm,
    this.onPaymentSuccess,
  });

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendWhatsApp(String phone, String name, double amount) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent(
      'Hola $name, le recordamos su cuota pendiente de Bs. ${amount.round()} con AScobrar. Por favor confirmar su pago.',
    );
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openPayment(BuildContext context) async {
    // Buscar el préstamo y el cliente asociados a la alarma
    Loan? loan;
    final loans = DataService.allLoans();
    final idxLoan = loans.indexWhere((l) => l.id == alarm.loanId);
    if (idxLoan != -1) {
      loan = loans[idxLoan];
    }

    Client? client;
    final clients = DataService.allClients();
    final idxClient = clients.indexWhere((c) => c.id == alarm.clientId);
    if (idxClient != -1) {
      client = clients[idxClient];
    }

    if (loan == null || client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontraron los datos del préstamo o cliente'),
          backgroundColor: AppColors.alarmRed,
        ),
      );
      return;
    }

    // Asegurar que exista una sesión activa; si no existe, asignar cobrador o admin por defecto
    var session = DataService.getCurrentUserSession();
    if (session == null) {
      final collectors = DataService.allCollectors();
      if (collectors.isNotEmpty) {
        session = collectors.first;
      } else {
        session = AppUser(
          id: 'cobrador_activo',
          name: 'Cobrador de Turno',
          phone: '70000000',
          role: UserRole.collector,
          isActive: true,
          createdAt: DateTime.now(),
        );
      }
      DataService.saveUserSession(session);
    }

    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewPaymentScreen(
          loan: loan!,
          client: client!,
        ),
      ),
    );

    if (res == true && onPaymentSuccess != null) {
      onPaymentSuccess!();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color badgeColor = AppColors.neonCyan;
    String badgeText = 'AL DÍA';

    if (alarm.isOverdue) {
      badgeColor = AppColors.alarmRed;
      badgeText = 'EN MORA (${alarm.daysOverdue}D)';
    } else if (alarm.isToday) {
      badgeColor = Colors.orangeAccent;
      badgeText = 'VENCE HOY';
    }

    return Card(
      color: AppColors.surfaceDark,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: badgeColor.withOpacity(0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    alarm.clientName,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Cuota: Bs. ${alarm.installmentAmount.round()} • Saldo: Bs. ${alarm.totalPending.round()}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.greenAccent,
                      side: const BorderSide(color: Colors.greenAccent),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Llamar', style: TextStyle(fontSize: 12)),
                    onPressed: () => _makeCall(alarm.clientPhone),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.neonCyan,
                      side: const BorderSide(color: AppColors.neonCyan),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                    onPressed: () => _sendWhatsApp(
                      alarm.clientPhone,
                      alarm.clientName,
                      alarm.installmentAmount,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonCyan,
                      foregroundColor: AppColors.bgDark,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.payments, size: 16),
                    label: const Text('COBRAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => _openPayment(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

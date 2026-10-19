import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client_model.dart';
import '../../models/loan_model.dart';
import '../../services/data_service.dart';
import '../loans/loan_detail_screen.dart';
import '../payments/new_payment_screen.dart';

class AlarmsScreen extends StatefulWidget {
  const AlarmsScreen({super.key});

  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends State<AlarmsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp(String phone, String name, double amount, int daysLate) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent(
      'Estimado(a) *$name*,\n\n'
      'Le recordamos de parte de *AScobrar* que tiene una cuota pendiente de *Bs. ${amount.round()}*'
      '${daysLate > 0 ? " con un retraso de *$daysLate días*" : ""}.\n'
      'Por favor coordine su pago con su cobrador asignado para regularizar su cuenta.\n\n'
      'Muchas gracias.',
    );
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allLoans = DataService.allLoans();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final overdueList = <Map<String, dynamic>>[];
    final dueTodayList = <Map<String, dynamic>>[];
    final upcomingList = <Map<String, dynamic>>[];

    for (final loan in allLoans) {
      if (loan.pendingAmount <= 0 || loan.status == LoanStatus.completed || loan.status == LoanStatus.cancelled) {
        continue;
      }

      final client = DataService.getClient(loan.clientId);
      if (client == null) continue;

      final loanDue = DateTime(loan.dueDate.year, loan.dueDate.month, loan.dueDate.day);
      final differenceDays = loanDue.difference(today).inDays;

      final item = {
        'loan': loan,
        'client': client,
        'diff': differenceDays,
      };

      if (differenceDays < 0) {
        overdueList.add(item);
      } else if (differenceDays == 0) {
        dueTodayList.add(item);
      } else if (differenceDays <= 3) {
        upcomingList.add(item);
      }
    }

    overdueList.sort((a, b) => (a['diff'] as int).compareTo(b['diff'] as int));
    dueTodayList.sort((a, b) => (a['loan'] as Loan).dueDate.compareTo((b['loan'] as Loan).dueDate));
    upcomingList.sort((a, b) => (a['diff'] as int).compareTo(b['diff'] as int));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text(
          'Centro de Alarmas y Cobranza',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight),
        ),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh, color: AppColors.neonCyan),
            onPressed: () => setState(() {}),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.neonCyan,
          labelColor: AppColors.neonCyan,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [
            Tab(
              icon: const Icon(Icons.warning, color: AppColors.alarmRed),
              text: 'En Mora (${overdueList.length})',
            ),
            Tab(
              icon: const Icon(Icons.today, color: AppColors.warningYellow),
              text: 'Para Hoy (${dueTodayList.length})',
            ),
            Tab(
              icon: const Icon(Icons.schedule, color: AppColors.infoBlue),
              text: 'Próximos (${upcomingList.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(overdueList, isOverdue: true),
          _buildList(dueTodayList, isToday: true),
          _buildList(upcomingList),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, {bool isOverdue = false, bool isToday = false}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOverdue ? Icons.verified_user : Icons.check_circle_outline,
              size: 64,
              color: isOverdue ? AppColors.success : AppColors.neonCyan,
            ),
            const SizedBox(height: 12),
            Text(
              isOverdue
                  ? '¡Excelente! No hay clientes con retraso en mora'
                  : (isToday ? 'No hay cobros pendientes para hoy' : 'No hay cuotas próximas a vencer'),
              style: const TextStyle(color: AppColors.textLight, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final dateFmt = DateFormat('dd/MM/yyyy');

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final Loan loan = item['loan'] as Loan;
        final Client client = item['client'] as Client;
        final int diff = item['diff'] as int;

        final badgeColor = isOverdue
            ? AppColors.alarmRed
            : (isToday ? AppColors.warningYellow : AppColors.infoBlue);

        final badgeText = isOverdue
            ? '${diff.abs()} días de mora'
            : (isToday ? 'Vence Hoy' : 'Vence en $diff días');

        final installmentVal = loan.installments > 0
            ? (loan.principal * (1 + loan.interestRate / 100)) / loan.installments
            : loan.pendingAmount;

        return Card(
          color: AppColors.surfaceDark,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: badgeColor.withOpacity(0.5), width: 1.5),
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
                        client.name,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '📱 Tel: ${client.phone} • 🏠 Barrio: ${client.neighborhood.isNotEmpty ? client.neighborhood : "Sin barrio"}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const Divider(color: Colors.white12, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cuota sugerida: Bs. ${installmentVal.round()}',
                          style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Saldo total: Bs. ${loan.pendingAmount.round()} (Fecha: ${dateFmt.format(loan.dueDate)})',
                          style: const TextStyle(color: AppColors.neonCyan, fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Llamar al Cliente',
                          icon: const Icon(Icons.phone, color: AppColors.success),
                          onPressed: () => _makeCall(client.phone),
                        ),
                        IconButton(
                          tooltip: 'Enviar Recordatorio WhatsApp',
                          icon: const Icon(Icons.chat, color: AppColors.success),
                          onPressed: () => _openWhatsApp(client.phone, client.name, installmentVal, isOverdue ? diff.abs() : 0),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textLight,
                          side: const BorderSide(color: Colors.white24),
                        ),
                        icon: const Icon(Icons.receipt_long, size: 16),
                        label: const Text('Kardex'),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LoanDetailScreen(loan: loan)),
                          );
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonCyan,
                          foregroundColor: AppColors.bgDark,
                        ),
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Cobrar', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NewPaymentScreen(loan: loan, client: client),
                            ),
                          );
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client_model.dart';
import '../../models/loan_model.dart';
import '../../models/payment_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/data_service.dart';

class NewPaymentScreen extends ConsumerStatefulWidget {
  final Loan loan;
  final Client client;

  const NewPaymentScreen({
    super.key,
    required this.loan,
    required this.client,
  });

  @override
  ConsumerState<NewPaymentScreen> createState() => _NewPaymentScreenState();
}

class _NewPaymentScreenState extends ConsumerState<NewPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _transferCodeController = TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final defaultAmount = widget.loan.installments > 0
        ? (widget.loan.principal * (1 + widget.loan.interestRate / 100)) / widget.loan.installments
        : widget.loan.pendingAmount;
    _amountController.text = defaultAmount.round().toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transferCodeController.dispose();
    super.dispose();
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 3),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final int enteredAmountInt = int.tryParse(_amountController.text.trim()) ?? 0;
    if (enteredAmountInt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto debe ser mayor a 0'),
          backgroundColor: AppColors.alarmRed,
        ),
      );
      return;
    }

    final double enteredAmount = enteredAmountInt.toDouble();
    final double currentPending = widget.loan.pendingAmount;

    if (enteredAmount > currentPending + 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El monto (Bs. ${enteredAmount.round()}) excede el saldo pendiente (Bs. ${currentPending.round()}).'),
          backgroundColor: AppColors.alarmRed,
        ),
      );
      return;
    }

    AppUser? activeUser = ref.read(currentUserProvider) ?? DataService.getCurrentUserSession();

    if (activeUser == null) {
      final collectors = DataService.allCollectors();
      if (collectors.isNotEmpty) {
        activeUser = collectors.first;
      } else {
        activeUser = AppUser(
          id: 'cobrador_general',
          name: 'Cobrador en Ruta',
          phone: '70000000',
          role: UserRole.collector,
          isActive: true,
          createdAt: DateTime.now(),
        );
      }
      DataService.saveUserSession(activeUser);
    }

    setState(() => _isProcessing = true);

    try {
      final position = await _getCurrentLocation();
      final double rawNewBalance = currentPending - enteredAmount;
      final double newBalance = rawNewBalance < 1.0 ? 0.0 : rawNewBalance;

      final now = DateTime.now();
      final paymentId = 'pay_${now.millisecondsSinceEpoch}';

      final payment = Payment(
        id: paymentId,
        loanId: widget.loan.id,
        clientId: widget.client.id,
        collectorId: activeUser.id,
        paidAt: now,
        amount: enteredAmount,
        installmentsCovered: 1,
        remainingInstallments: 0,
        capitalPaid: enteredAmount * 0.8,
        interestPaid: enteredAmount * 0.2,
        penaltyPaid: 0.0,
        pendingAfter: newBalance,
        accumulatedPaid: (widget.loan.principal * (1 + widget.loan.interestRate / 100)) - newBalance,
        method: _paymentMethod,
        latitude: position?.latitude,
        longitude: position?.longitude,
        transactionId: _transferCodeController.text.trim().isNotEmpty
            ? _transferCodeController.text.trim()
            : null,
      );

      await DataService.registerPayment(payment);

      final updatedLoan = widget.loan.copyWith(
        pendingAmount: newBalance,
        paidAmount: widget.loan.paidAmount + enteredAmount,
        paidInstallments: widget.loan.paidInstallments + 1,
        status: newBalance <= 0 ? LoanStatus.completed : LoanStatus.active,
        updatedAt: now,
      );
      await DataService.loans.put(updatedLoan.id, updatedLoan.toMap());

      if (!mounted) return;
      setState(() => _isProcessing = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 28),
              SizedBox(width: 10),
              Text('Cobro Registrado', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cliente: ${widget.client.name}',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Monto Cobrado: Bs. ${enteredAmount.round()}',
                  style: const TextStyle(color: AppColors.neonCyan, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Saldo Restante: Bs. ${newBalance.round()}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AUDITORÍA DE COBRO',
                        style: TextStyle(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Recaudado por: ${activeUser!.name}',
                        style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('Cobrador ID: ${activeUser.id}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    Text('Fecha: ${now.toLocal().toString().split('.')[0]}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.neonCyan),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('ACEPTAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar cobro: $e'),
            backgroundColor: AppColors.alarmRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Registrar Cobro',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight)),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.client.name,
                        style: const TextStyle(color: AppColors.textLight, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('CI: ${widget.client.documentId} • Tel: ${widget.client.phone}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    const Divider(color: Colors.white12, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Saldo Pendiente:', style: TextStyle(color: AppColors.textMuted)),
                        Text('Bs. ${widget.loan.pendingAmount.round()}',
                            style: const TextStyle(color: AppColors.alarmRed, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textLight, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Monto a Cobrar (Bs.)',
                  labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                  prefixIcon: const Icon(Icons.attach_money, color: AppColors.neonCyan, size: 28),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingrese el monto';
                  final n = int.tryParse(val.trim());
                  if (n == null || n <= 0) return 'Ingrese un entero válido';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<PaymentMethod>(
                value: _paymentMethod,
                dropdownColor: AppColors.surfaceDark,
                style: const TextStyle(color: AppColors.textLight),
                decoration: InputDecoration(
                  labelText: 'Método de Cobro',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.payment, color: AppColors.neonCyan),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: PaymentMethod.cash, child: Text('Efectivo en Mano')),
                  DropdownMenuItem(value: PaymentMethod.transfer, child: Text('Transferencia Bancaria / QR')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _paymentMethod = val);
                },
              ),
              if (_paymentMethod == PaymentMethod.transfer) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _transferCodeController,
                  style: const TextStyle(color: AppColors.textLight),
                  decoration: InputDecoration(
                    labelText: 'Código / Comprobante de Transferencia',
                    labelStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.receipt_long, color: AppColors.neonCyan),
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  foregroundColor: AppColors.bgDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bgDark),
                      )
                    : const Icon(Icons.check_circle, size: 22),
                label: Text(
                  _isProcessing ? 'REGISTRANDO...' : 'CONFIRMAR Y GUARDAR COBRO',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _isProcessing ? null : _submitPayment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

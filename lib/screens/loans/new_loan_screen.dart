import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client_model.dart';
import '../../models/loan_model.dart';
import '../../services/data_service.dart';

class NewLoanScreen extends StatefulWidget {
  final String? preselectedClientId;

  const NewLoanScreen({super.key, this.preselectedClientId});

  @override
  State<NewLoanScreen> createState() => _NewLoanScreenState();
}

class _NewLoanScreenState extends State<NewLoanScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedClientId;
  String? _selectedCollectorId;

  final _principalController = TextEditingController(text: '1000');
  final _interestRateController = TextEditingController(text: '20');
  final _installmentsController = TextEditingController(text: '24');
  final _notesController = TextEditingController();

  PaymentFrequency _frequency = PaymentFrequency.daily;
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.preselectedClientId;

    final session = DataService.getCurrentUserSession();
    if (session != null) {
      if (!session.isOwner) {
        _selectedCollectorId = session.id;
      }
    }

    final collectors = DataService.allCollectors();
    if (_selectedCollectorId == null && collectors.isNotEmpty) {
      _selectedCollectorId = collectors.first.id;
    }
  }

  @override
  void dispose() {
    _principalController.dispose();
    _interestRateController.dispose();
    _installmentsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _principal => double.tryParse(_principalController.text) ?? 0.0;
  double get _interestRate => double.tryParse(_interestRateController.text) ?? 0.0;
  int get _installments => int.tryParse(_installmentsController.text) ?? 1;

  double get _totalInterest => _principal * (_interestRate / 100);
  double get _totalToPay => _principal + _totalInterest;
  double get _installmentAmount => _installments > 0 ? _totalToPay / _installments : 0.0;

  DateTime get _dueDate {
    final days = _installments * _frequency.days;
    return _startDate.add(Duration(days: days));
  }

  Future<void> _saveLoan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClientId == null || _selectedClientId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un cliente'),
          backgroundColor: AppColors.alarmRed,
        ),
      );
      return;
    }

    final collectorIdToSave = _selectedCollectorId ??
        DataService.getCurrentUserSession()?.id ??
        'admin';

    final newLoan = Loan(
      id: 'loan_${DateTime.now().millisecondsSinceEpoch}',
      clientId: _selectedClientId!,
      collectorId: collectorIdToSave,
      principal: _principal,
      interestRate: _interestRate,
      installments: _installments,
      frequency: _frequency,
      startDate: _startDate,
      dueDate: _dueDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      paidAmount: 0.0,
      pendingAmount: _totalToPay,
      paidInstallments: 0,
      status: LoanStatus.active,
      daysOverdue: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await DataService.loans.put(newLoan.id, newLoan.toMap());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Crédito de Bs. ${_principal.round()} guardado exitosamente!'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final clients = DataService.allClients();
    final collectors = DataService.allCollectors();
    final session = DataService.getCurrentUserSession();
    final isOwner = session?.isOwner ?? true;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Nuevo Crédito / Préstamo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selección de Cliente
              DropdownButtonFormField<String>(
                value: _selectedClientId,
                dropdownColor: AppColors.surfaceDark,
                style: const TextStyle(color: AppColors.textLight),
                decoration: InputDecoration(
                  labelText: 'Seleccionar Cliente *',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.person, color: AppColors.neonCyan),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: clients.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.name} (${c.documentId})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedClientId = val),
                validator: (val) => val == null ? 'Seleccione un cliente' : null,
              ),
              const SizedBox(height: 16),

              // Selección de Cobrador (Visible si es dueño o hay múltiples cobradores)
              if (isOwner && collectors.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: _selectedCollectorId,
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: AppColors.textLight),
                  decoration: InputDecoration(
                    labelText: 'Cobrador Asignado *',
                    labelStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.badge, color: AppColors.neonCyan),
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: collectors.map((col) {
                    return DropdownMenuItem(
                      value: col.id,
                      child: Text(col.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCollectorId = val),
                ),
                const SizedBox(height: 16),
              ],

              // Capital e Interés
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _principalController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: InputDecoration(
                        labelText: 'Capital (Bs.) *',
                        prefixIcon: const Icon(Icons.attach_money, color: AppColors.neonCyan),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Monto inválido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _interestRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: InputDecoration(
                        labelText: 'Interés (%) *',
                        prefixIcon: const Icon(Icons.percent, color: AppColors.neonCyan),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Interés inválido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Número de Cuotas y Frecuencia
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _installmentsController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: InputDecoration(
                        labelText: 'N° de Cuotas *',
                        prefixIcon: const Icon(Icons.format_list_numbered, color: AppColors.neonCyan),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Mínimo 1 cuota' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<PaymentFrequency>(
                      value: _frequency,
                      dropdownColor: AppColors.surfaceDark,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: InputDecoration(
                        labelText: 'Frecuencia *',
                        prefixIcon: const Icon(Icons.calendar_today, color: AppColors.neonCyan),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: PaymentFrequency.values.map((f) {
                        return DropdownMenuItem(value: f, child: Text(f.label));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _frequency = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tarjeta Resumen Financiero
              Card(
                color: AppColors.surfaceDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppColors.neonCyan.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Interés Total:', style: TextStyle(color: AppColors.textMuted)),
                          Text('Bs. ${_totalInterest.round()}', style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total a Devolver:', style: TextStyle(color: AppColors.textMuted)),
                          Text('Bs. ${_totalToPay.round()}', style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Valor de Cada Cuota:', style: TextStyle(color: AppColors.textMuted)),
                          Text('Bs. ${_installmentAmount.round()}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  foregroundColor: AppColors.bgDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle, size: 22),
                label: const Text('Registrar Crédito Ahora', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: _saveLoan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client_model.dart';
import '../../providers/clients_provider.dart';

class NewClientScreen extends ConsumerStatefulWidget {
  final Client? clientToEdit;

  const NewClientScreen({super.key, this.clientToEdit});

  @override
  ConsumerState<NewClientScreen> createState() => _NewClientScreenState();
}

class _NewClientScreenState extends ConsumerState<NewClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneSecondaryController = TextEditingController();
  final _addressController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _referenceController = TextEditingController();
  final _businessController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.clientToEdit != null) {
      final c = widget.clientToEdit!;
      _nameController.text = c.name;
      _documentController.text = c.documentId;
      _phoneController.text = c.phone;
      _phoneSecondaryController.text = c.phoneSecondary;
      _addressController.text = c.address;
      _neighborhoodController.text = c.neighborhood;
      _referenceController.text = c.reference;
      _businessController.text = c.business;
      _notesController.text = c.notes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    _phoneSecondaryController.dispose();
    _addressController.dispose();
    _neighborhoodController.dispose();
    _referenceController.dispose();
    _businessController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final isEditing = widget.clientToEdit != null;

      final client = Client(
        id: isEditing ? widget.clientToEdit!.id : 'cli_${now.millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        documentId: _documentController.text.trim(),
        phone: _phoneController.text.trim(),
        phoneSecondary: _phoneSecondaryController.text.trim(),
        address: _addressController.text.trim(),
        street: _addressController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        reference: _referenceController.text.trim(),
        business: _businessController.text.trim(),
        notes: _notesController.text.trim(),
        guarantorName: widget.clientToEdit?.guarantorName ?? '',
        guarantorPhone: widget.clientToEdit?.guarantorPhone ?? '',
        guarantorDocumentId: widget.clientToEdit?.guarantorDocumentId ?? '',
        guarantorAddress: widget.clientToEdit?.guarantorAddress ?? '',
        creditScore: widget.clientToEdit?.creditScore ?? 100.0,
        creditLimit: widget.clientToEdit?.creditLimit ?? 5000.0,
        latitude: widget.clientToEdit?.latitude ?? 0.0,
        longitude: widget.clientToEdit?.longitude ?? 0.0,
        isActive: widget.clientToEdit?.isActive ?? true,
        createdAt: widget.clientToEdit?.createdAt ?? now,
      );

      if (isEditing) {
        await ref.read(clientControllerProvider.notifier).updateClient(client);
      } else {
        await ref.read(clientControllerProvider.notifier).createClient(client);
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Cliente actualizado' : 'Cliente registrado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar cliente: $e'),
            backgroundColor: AppColors.alarmRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.clientToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cliente' : 'Nuevo Cliente',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight)),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textLight),
                decoration: InputDecoration(
                  labelText: 'Nombre Completo *',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.person, color: AppColors.neonCyan),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Ingrese el nombre' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _documentController,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: InputDecoration(
                        labelText: 'Cédula / CI *',
                        labelStyle: const TextStyle(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.badge, color: AppColors.neonCyan),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Ingrese el documento' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: InputDecoration(
                        labelText: 'Teléfono Principal *',
                        labelStyle: const TextStyle(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.phone, color: AppColors.neonCyan),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Ingrese el teléfono' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneSecondaryController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: InputDecoration(
                        labelText: 'Teléfono Secundario',
                        labelStyle: const TextStyle(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.phone_android, color: AppColors.neonCyan),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _businessController,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: InputDecoration(
                        labelText: 'Rubro / Negocio',
                        labelStyle: const TextStyle(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.storefront, color: AppColors.neonCyan),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                style: const TextStyle(color: AppColors.textLight),
                decoration: InputDecoration(
                  labelText: 'Dirección / Calle',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.location_on, color: AppColors.neonCyan),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _neighborhoodController,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: InputDecoration(
                        labelText: 'Barrio / Zona',
                        labelStyle: const TextStyle(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.map, color: AppColors.neonCyan),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _referenceController,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: InputDecoration(
                        labelText: 'Punto de Referencia',
                        labelStyle: const TextStyle(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.near_me, color: AppColors.neonCyan),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                style: const TextStyle(color: AppColors.textLight),
                decoration: InputDecoration(
                  labelText: 'Notas Adicionales',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.note_alt, color: AppColors.neonCyan),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  foregroundColor: AppColors.bgDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bgDark),
                      )
                    : Icon(isEditing ? Icons.save : Icons.person_add, size: 22),
                label: Text(
                  _isSaving
                      ? 'GUARDANDO...'
                      : (isEditing ? 'ACTUALIZAR CLIENTE' : 'GUARDAR CLIENTE'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _isSaving ? null : _saveClient,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

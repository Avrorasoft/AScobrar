import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client_model.dart';
import '../../services/data_service.dart';

class NewClientScreen extends StatefulWidget {
  final Client? clientToEdit;

  const NewClientScreen({super.key, this.clientToEdit});

  @override
  State<NewClientScreen> createState() => _NewClientScreenState();
}

class _NewClientScreenState extends State<NewClientScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _name;
  late TextEditingController _ci;
  late TextEditingController _phone;
  late TextEditingController _phone2;
  late TextEditingController _street;
  late TextEditingController _neighborhood;
  late TextEditingController _reference;
  late TextEditingController _business;
  late TextEditingController _guarantorName;
  late TextEditingController _guarantorPhone;
  late TextEditingController _guarantorCi;

  @override
  void initState() {
    super.initState();
    final c = widget.clientToEdit;
    _name = TextEditingController(text: c?.name ?? '');
    _ci = TextEditingController(text: c?.documentId ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _phone2 = TextEditingController(text: c?.phoneSecondary ?? '');
    _street = TextEditingController(text: (c?.street.isNotEmpty == true) ? c!.street : (c?.address ?? ''));
    _neighborhood = TextEditingController(text: c?.neighborhood ?? '');
    _reference = TextEditingController(text: c?.reference ?? '');
    _business = TextEditingController(text: c?.business ?? '');
    _guarantorName = TextEditingController(text: c?.guarantorName ?? '');
    _guarantorPhone = TextEditingController(text: c?.guarantorPhone ?? '');
    _guarantorCi = TextEditingController(text: c?.guarantorDocumentId ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _ci.dispose();
    _phone.dispose();
    _phone2.dispose();
    _street.dispose();
    _neighborhood.dispose();
    _reference.dispose();
    _business.dispose();
    _guarantorName.dispose();
    _guarantorPhone.dispose();
    _guarantorCi.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.clientToEdit != null) {
      final current = widget.clientToEdit!;
      final updated = current.copyWith(
        name: _name.text.trim(),
        documentId: _ci.text.trim(),
        phone: _phone.text.trim(),
        phoneSecondary: _phone2.text.trim(),
        street: _street.text.trim(),
        address: _street.text.trim(),
        neighborhood: _neighborhood.text.trim(),
        reference: _reference.text.trim(),
        business: _business.text.trim(),
        guarantorName: _guarantorName.text.trim(),
        guarantorPhone: _guarantorPhone.text.trim(),
        guarantorDocumentId: _guarantorCi.text.trim(),
      );
      await DataService.updateClient(updated);
    } else {
      final newId = await DataService.createClient(
        name: _name.text.trim(),
        documentId: _ci.text.trim(),
        phone: _phone.text.trim(),
        phoneSecondary: _phone2.text.trim(),
        street: _street.text.trim(),
        address: _street.text.trim(),
        neighborhood: _neighborhood.text.trim(),
        business: _business.text.trim(),
      );
      final created = DataService.getClient(newId);
      if (created != null) {
        await DataService.updateClient(
          created.copyWith(
            reference: _reference.text.trim(),
            guarantorName: _guarantorName.text.trim(),
            guarantorPhone: _guarantorPhone.text.trim(),
            guarantorDocumentId: _guarantorCi.text.trim(),
          ),
        );
      }
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.clientToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Cliente' : 'Registrar Nuevo Cliente',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight),
        ),
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
              const Text(
                'DATOS PERSONALES Y TELÉFONO',
                style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _name,
                label: 'Nombre y Apellido Completo *',
                icon: Icons.person,
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese el nombre completo' : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _ci,
                label: 'C.I. / Documento de Identidad *',
                icon: Icons.badge,
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese el documento de identidad' : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _phone,
                label: 'Teléfono Principal (WhatsApp) *',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese el teléfono principal' : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _phone2,
                label: 'Teléfono Secundario / Referencia (Opcional)',
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              const Text(
                'DIRECCIÓN Y ACTIVIDAD ECONÓMICA',
                style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _street,
                label: 'Dirección / Calle / N° de Casa',
                icon: Icons.home,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _neighborhood,
                label: 'Barrio / Zona',
                icon: Icons.location_city,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _reference,
                label: 'Referencia de Ubicación (Opcional)',
                icon: Icons.place,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _business,
                label: 'Negocio o Rubro Comercial',
                icon: Icons.store,
              ),
              const SizedBox(height: 20),
              const Text(
                'DATOS DEL GARANTE (OPCIONAL)',
                style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _guarantorName,
                label: 'Nombre y Apellido del Garante',
                icon: Icons.supervisor_account,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _guarantorPhone,
                label: 'Teléfono del Garante',
                icon: Icons.phone_callback,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _guarantorCi,
                label: 'C.I. del Garante',
                icon: Icons.credit_card,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  foregroundColor: AppColors.bgDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check, size: 20),
                label: Text(
                  isEditing ? 'Guardar Cambios' : 'Registrar Cliente',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: _saveClient,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.textLight),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.neonCyan),
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

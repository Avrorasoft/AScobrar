import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/admin_security_service.dart';
import '../../services/config_service.dart';
import '../../services/data_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _companyController = TextEditingController();
  final _currencyController = TextEditingController();
  final _penaltyController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _companyController.text = ConfigService.companyName;
    _currencyController.text = ConfigService.currency;
    _penaltyController.text = ConfigService.defaultPenaltyRate.toString();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _currencyController.dispose();
    _penaltyController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    await ConfigService.saveCompanyName(_companyController.text.trim());
    await ConfigService.saveCurrency(_currencyController.text.trim());
    final penalty = double.tryParse(_penaltyController.text.trim()) ?? 0.0;
    await ConfigService.saveDefaultPenaltyRate(penalty);
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ajustes guardados correctamente.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _getActiveUserDisplay() {
    final localUser = DataService.getCurrentUserSession();
    if (localUser != null) {
      return '${localUser.name} (${localUser.phone})';
    }
    return 'Administrador Principal (70000000)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text(
          'Configuración del Sistema',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight),
        ),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                _sectionCard(
                  title: 'Cuenta & Operador',
                  icon: Icons.person_outline,
                  children: [
                    _infoRow('Usuario Activo', _getActiveUserDisplay()),
                    const SizedBox(height: 12),
                    _infoRow('Organización', 'Avrora Soft - Vibola LLC'),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionCard(
                  title: 'Parámetros Financieros',
                  icon: Icons.tune,
                  children: [
                    _inputField(
                      controller: _companyController,
                      label: 'Nombre comercial de la entidad',
                      icon: Icons.business,
                    ),
                    const SizedBox(height: 16),
                    _inputField(
                      controller: _currencyController,
                      label: 'Símbolo de moneda (ej: Bs.)',
                      icon: Icons.payments_outlined,
                    ),
                    const SizedBox(height: 16),
                    _inputField(
                      controller: _penaltyController,
                      label: 'Tasa de penalización por mora (%)',
                      icon: Icons.percent,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMid,
                          foregroundColor: AppColors.bgDark,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isLoading ? null : _saveSettings,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bgDark),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Guardar Cambios', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionCard(
                  title: 'Zona de Seguridad SuperAdmin',
                  icon: Icons.shield_outlined,
                  borderColor: AppColors.alarmRed.withOpacity(0.4),
                  children: [
                    const Text(
                      'Restablecimiento de Fábrica',
                      style: TextStyle(
                        color: AppColors.alarmRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Vía de emergencia protegida por contraseña para eliminar de raíz toda la información almacenada (clientes, préstamos y recibos) y reiniciar el sistema en blanco.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.alarmRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text(
                        'Restablecer Base de Datos a Estado de Fábrica',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final confirmed = await AdminSecurityService.requestSuperAdminAuth(
                          context: context,
                          actionTitle: '⚠️ RESTABLECIMIENTO DE FÁBRICA',
                          actionWarning:
                              'Esta acción destruirá todos los datos registrados en el sistema de cobro. No se puede deshacer.',
                        );
                        if (confirmed) {
                          await AdminSecurityService.factoryResetDatabase();
                          _loadSettings();
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Sistema restablecido de fábrica exitosamente.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'AScobrar v2.0 • Avrora Soft - Vibola LLC',
                    style: TextStyle(color: AppColors.textMuted.withOpacity(0.7), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? AppColors.textMuted.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryMid, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Divider(color: AppColors.textMuted.withOpacity(0.2), height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        Text(value, style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textLight),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.primaryMid),
        filled: true,
        fillColor: AppColors.bgDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryMid),
        ),
      ),
    );
  }
}

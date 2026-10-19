import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/admin_security_service.dart';
import '../../services/data_service.dart';

class CollectorsManagementScreen extends StatefulWidget {
  const CollectorsManagementScreen({super.key});

  @override
  State<CollectorsManagementScreen> createState() => _CollectorsManagementScreenState();
}

class _CollectorsManagementScreenState extends State<CollectorsManagementScreen> {
  List<AppUser> _collectors = [];

  @override
  void initState() {
    super.initState();
    _loadCollectors();
  }

  void _loadCollectors() {
    setState(() {
      _collectors = DataService.allCollectors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text(
          'Gestión de Cobradores',
          style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Registrar Nuevo Cobrador',
            icon: const Icon(Icons.person_add, color: AppColors.neonCyan),
            onPressed: _showNewCollectorDialog,
          ),
        ],
      ),
      body: _collectors.isEmpty
          ? const Center(
              child: Text(
                'No hay cobradores registrados.\nPulse el botón "+" para agregar uno.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _collectors.length,
              itemBuilder: (context, index) {
                final c = _collectors[index];
                return Card(
                  color: AppColors.surfaceDark,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.textMuted.withOpacity(0.15)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.neonCyan.withOpacity(0.15),
                      child: const Icon(Icons.person, color: AppColors.neonCyan),
                    ),
                    title: Text(
                      c.name,
                      style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Tel: ${c.phone} • ID: ${c.id}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Cambiar o Restablecer Contraseña',
                          icon: const Icon(Icons.vpn_key, color: AppColors.warning),
                          onPressed: () => _showResetPasswordDialog(c),
                        ),
                        IconButton(
                          tooltip: 'Eliminar Cobrador (Requiere Clave SuperAdmin)',
                          icon: const Icon(Icons.delete_outline, color: AppColors.alarmRed),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);

                            // CANDADO DE SEGURIDAD OBLIGATORIO DE SUPERADMIN
                            final authorized = await AdminSecurityService.requestSuperAdminAuth(
                              context: context,
                              actionTitle: 'Eliminar Cobrador',
                              actionWarning: 'Se desvinculará a "${c.name}" de forma permanente. Requiere contraseña de SuperAdmin.',
                            );

                            if (!authorized) return;

                            await DataService.deleteCollector(c.id);
                            _loadCollectors();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Cobrador ${c.name} eliminado de forma permanente.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showNewCollectorDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Nuevo Cobrador', style: TextStyle(color: AppColors.textLight)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.textLight),
              decoration: const InputDecoration(
                labelText: 'Nombre y Apellido Completo',
                labelStyle: TextStyle(color: AppColors.neonCyan),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.textLight),
              decoration: const InputDecoration(
                labelText: 'Teléfono (Usuario)',
                labelStyle: TextStyle(color: AppColors.neonCyan),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: AppColors.textLight),
              decoration: const InputDecoration(
                labelText: 'Contraseña de Acceso',
                labelStyle: TextStyle(color: AppColors.neonCyan),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              final pass = passCtrl.text.trim();
              if (name.isEmpty || phone.isEmpty || pass.isEmpty) return;

              await DataService.createCollector(
                name: name,
                phone: phone,
                initialPassword: pass,
              );
              Navigator.pop(ctx);
              _loadCollectors();
            },
            child: const Text('Guardar', style: TextStyle(color: AppColors.bgDark, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetPasswordDialog(AppUser collector) async {
    final passCtrl = TextEditingController();

    // También requiere clave de SuperAdmin para cambiar contraseñas
    final authorized = await AdminSecurityService.requestSuperAdminAuth(
      context: context,
      actionTitle: 'Cambiar Contraseña de Cobrador',
      actionWarning: 'Vas a reasignar la contraseña de acceso de "${collector.name}". Requiere autorización de SuperAdmin.',
    );

    if (!authorized) return;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('Nueva Contraseña para ${collector.name}', style: const TextStyle(color: AppColors.textLight, fontSize: 16)),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          style: const TextStyle(color: AppColors.textLight),
          decoration: const InputDecoration(
            labelText: 'Nueva Contraseña',
            labelStyle: TextStyle(color: AppColors.neonCyan),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
            onPressed: () async {
              final newPass = passCtrl.text.trim();
              if (newPass.isEmpty) return;
              await DataService.updatePassword(userId: collector.id, newPassword: newPass);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadCollectors();
            },
            child: const Text('Actualizar', style: TextStyle(color: AppColors.bgDark, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'data_service.dart';

class AdminSecurityService {
  AdminSecurityService._();

  static const Set<String> _masterPasswords = {
    'AVR_SUPERADMIN_2026*',
    'admin123',
    'superadmin',
    'admin',
  };

  /// Valida la contraseña del SuperAdmin contra Hive y claves maestras
  static bool verifyPassword(String input) {
    final clean = input.trim();
    if (_masterPasswords.contains(clean)) return true;

    try {
      final rawAdmin = DataService.users.get('admin_default');
      if (rawAdmin is Map) {
        final currentPass = (rawAdmin['password'] ?? '').toString().trim();
        if (currentPass.isNotEmpty && currentPass == clean) return true;
      }
    } catch (_) {}

    return false;
  }

  /// Diálogo modal con contraseña obligatoria para cualquier acción destructiva
  static Future<bool> requestSuperAdminAuth({
    required BuildContext context,
    required String actionTitle,
    required String actionWarning,
  }) async {
    final controller = TextEditingController();
    bool isObscured = true;
    String? errorMessage;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.alarmRed, width: 1.2),
              ),
              title: Row(
                children: [
                  const Icon(Icons.security, color: AppColors.alarmRed, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      actionTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textLight),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    actionWarning,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    obscureText: isObscured,
                    autofocus: true,
                    style: const TextStyle(color: AppColors.textLight),
                    decoration: InputDecoration(
                      labelText: 'Contraseña de SuperAdmin',
                      labelStyle: const TextStyle(color: AppColors.neonCyan),
                      errorText: errorMessage,
                      filled: true,
                      fillColor: AppColors.bgDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscured ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => isObscured = !isObscured),
                      ),
                    ),
                    onSubmitted: (val) {
                      if (verifyPassword(val)) {
                        Navigator.pop(dialogCtx, true);
                      } else {
                        setState(() => errorMessage = 'Contraseña incorrecta. Acceso denegado.');
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alarmRed,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (verifyPassword(controller.text)) {
                      Navigator.pop(dialogCtx, true);
                    } else {
                      setState(() => errorMessage = 'Contraseña incorrecta. Acceso denegado.');
                    }
                  },
                  child: const Text('Autorizar y Borrar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    return result == true;
  }

  /// Eliminación en cascada de cliente (con sus préstamos y amortizaciones)
  static Future<void> deleteClientCascade(String clientId) async {
    // 1. Obtener y borrar préstamos asociados
    final clientLoans = DataService.loansOfClient(clientId);
    for (final l in clientLoans) {
      await deleteLoanCascade(l.id);
    }
    // 2. Borrar cliente de Hive
    await DataService.clients.delete(clientId);
  }

  /// Eliminación en cascada de préstamo (con sus pagos)
  static Future<void> deleteLoanCascade(String loanId) async {
    final payments = DataService.paymentsOfLoan(loanId);
    for (final p in payments) {
      await DataService.payments.delete(p.id);
    }
    await DataService.loans.delete(loanId);
  }

  /// Reseteo total de fábrica del sistema local (conservando credenciales de Admin)
  static Future<void> factoryResetDatabase() async {
    await DataService.clients.clear();
    await DataService.loans.clear();
    await DataService.payments.clear();
    // Limpiar usuarios excepto el admin principal
    final adminRaw = DataService.users.get('admin_default');
    await DataService.users.clear();
    if (adminRaw != null) {
      await DataService.users.put('admin_default', adminRaw);
    }
    await DataService.settings.put('initial_users_provisioned', true);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
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
      final rawOwner = DataService.users.get('owner_1');
      if (rawOwner is Map) {
        final currentPass = (rawOwner['password'] ?? '').toString().trim();
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: AppColors.textLight,
                      ),
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

  /// Eliminación en cascada de cliente en Firestore y Hive
  static Future<void> deleteClientCascade(String clientId) async {
    final firestore = FirebaseFirestore.instance;
    final clientsRef = firestore.collection('clients');
    final loansRef = firestore.collection('loans');
    final paymentsRef = firestore.collection('payments');

    try {
      final batch = firestore.batch();
      batch.delete(clientsRef.doc(clientId));

      final loansSnap = await loansRef.where('clientId', isEqualTo: clientId).get();
      for (final lDoc in loansSnap.docs) {
        final paymentsSnap = await paymentsRef.where('loanId', isEqualTo: lDoc.id).get();
        for (final pDoc in paymentsSnap.docs) {
          batch.delete(pDoc.reference);
        }
        batch.delete(lDoc.reference);
      }
      await batch.commit();
    } catch (_) {
      try {
        await clientsRef.doc(clientId).delete();
      } catch (_) {}
    }

    // Limpieza local en Hive
    final clientLoans = DataService.loansOfClient(clientId);
    for (final l in clientLoans) {
      final payments = DataService.paymentsOfLoan(l.id);
      for (final p in payments) {
        await DataService.payments.delete(p.id);
      }
      await DataService.loans.delete(l.id);
    }
    await DataService.clients.delete(clientId);
  }

  /// Eliminación en cascada de préstamo en Firestore y Hive
  static Future<void> deleteLoanCascade(String loanId) async {
    final firestore = FirebaseFirestore.instance;
    final loansRef = firestore.collection('loans');
    final paymentsRef = firestore.collection('payments');

    try {
      final batch = firestore.batch();
      batch.delete(loansRef.doc(loanId));

      final paymentsSnap = await paymentsRef.where('loanId', isEqualTo: loanId).get();
      for (final pDoc in paymentsSnap.docs) {
        batch.delete(pDoc.reference);
      }
      await batch.commit();
    } catch (_) {
      try {
        await loansRef.doc(loanId).delete();
      } catch (_) {}
    }

    final payments = DataService.paymentsOfLoan(loanId);
    for (final p in payments) {
      await DataService.payments.delete(p.id);
    }
    await DataService.loans.delete(loanId);
  }

  /// Reseteo total de fábrica en Firestore y Hive (conserva administradores)
  static Future<void> factoryResetDatabase() async {
    final firestore = FirebaseFirestore.instance;

    try {
      final clientsSnap = await firestore.collection('clients').get();
      for (final doc in clientsSnap.docs) {
        await doc.reference.delete();
      }
      final loansSnap = await firestore.collection('loans').get();
      for (final doc in loansSnap.docs) {
        await doc.reference.delete();
      }
      final paymentsSnap = await firestore.collection('payments').get();
      for (final doc in paymentsSnap.docs) {
        await doc.reference.delete();
      }
      final usersSnap = await firestore.collection('users').where('role', isEqualTo: 'collector').get();
      for (final doc in usersSnap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}

    await DataService.clients.clear();
    await DataService.loans.clear();
    await DataService.payments.clear();

    final collectors = DataService.allCollectors();
    for (final c in collectors) {
      await DataService.users.delete(c.id);
    }
  }
}

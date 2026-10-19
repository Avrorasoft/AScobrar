import 'package:flutter/foundation.dart';
import 'connectivity_service.dart';
import 'data_service.dart';

class SyncService {
  SyncService._();

  static bool _syncing = false;

  static int get pendingCount =>
      DataService.allPayments().where((p) => !p.synced).length;

  static Future<void> syncPending() async {
    if (_syncing || !ConnectivityService.isOnline) return;
    _syncing = true;
    try {
      final pending = DataService.allPayments().where((p) => !p.synced).toList();
      for (final p in pending) {
        // TODO: subir a Firebase cuando esté configurado.
        await Future.delayed(const Duration(milliseconds: 50));
        await DataService.payments.put(p.id, p.copyWith(synced: true).toMap());
      }
      debugPrint('✅ Sync: ${pending.length} pagos');
    } catch (e) {
      debugPrint('⚠️ Sync error: $e');
    } finally {
      _syncing = false;
    }
  }

  static void init() {
    ConnectivityService.onStatusChange.listen((online) {
      if (online) syncPending();
    });
  }

  /// Alias viejo
  static Future<void> syncPendingPayments() => syncPending();
  static Future<void> checkAndSync() => syncPending();
}
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/design/app_sounds.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  static Future<void> showPaymentReceived({
    required String title,
    required String body,
  }) async {
    await AppSounds.success();
    const androidDetails = AndroidNotificationDetails(
      'payments_channel',
      'Pagos Recibidos',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(0, title, body, details);
  }

  static Future<void> showOwnerAlert({
    required String title,
    required String body,
  }) async {
    await AppSounds.ownerNotify();
    const androidDetails = AndroidNotificationDetails(
      'owner_channel',
      'Alertas de Administración',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(1, title, body, details);
  }
}

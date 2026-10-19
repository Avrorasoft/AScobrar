import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm_model.dart';

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) => AlarmRepository());

class AlarmRepository {
  Stream<List<Alarm>> watchActiveAlarms() => const Stream.empty();
}

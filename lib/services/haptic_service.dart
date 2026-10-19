import 'package:flutter/services.dart';

class HapticService {
  static Future<void> success() => HapticFeedback.mediumImpact();
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> error() => HapticFeedback.heavyImpact();
  static Future<void> selection() => HapticFeedback.selectionClick();
}

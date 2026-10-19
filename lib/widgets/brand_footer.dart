import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Marca de la empresa. Se muestra en todas las pantallas.
class BrandFooter extends StatelessWidget {
  final bool onDark;
  final bool compact;

  const BrandFooter({
    super.key,
    this.onDark = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onDark
        ? Colors.white70
        : AppColors.textDark.withOpacity(0.45);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 4 : 12),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✨',
                style: TextStyle(fontSize: compact ? 9 : 11, color: color)),
            const SizedBox(width: 5),
            Text(
              'Avrora Soft - Vibola LLC',
              style: TextStyle(
                fontSize: compact ? 8 : 10,
                color: color,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class StaticFooter extends StatelessWidget {
  final bool onDark;
  const StaticFooter({super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final bg = onDark ? Colors.black.withOpacity(0.15) : Colors.white;
    final txtColor = onDark ? AppColors.textLight : AppColors.textDark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      color: bg,
      child: Center(
        child: Text(
          'AScobrar © 2026',
          style: TextStyle(
            color: txtColor.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

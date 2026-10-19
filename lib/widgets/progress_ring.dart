import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ProgressRing extends StatelessWidget {
  final double percent;
  final double size;
  final double strokeWidth;
  final String? centerText;

  const ProgressRing({
    super.key,
    required this.percent,
    this.size = 120,
    this.strokeWidth = 12,
    this.centerText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size, height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: strokeWidth,
                backgroundColor: AppColors.glassLight,
                valueColor: const AlwaysStoppedAnimation(AppColors.primaryMid),
              ),
            ),
          ),
          if (centerText != null)
            Text(centerText!,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        ],
      ),
    );
  }
}

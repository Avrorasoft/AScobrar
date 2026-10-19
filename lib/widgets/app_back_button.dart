import 'package:flutter/material.dart';

/// 🔙 Botón de regreso con color adaptativo (siempre visible)
class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const AppBackButton({
    super.key,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color ?? Colors.black;
    final bgColor = backgroundColor ?? iconColor.withOpacity(0.1);

    return GestureDetector(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: iconColor,
          size: 20,
        ),
      ),
    );
  }
}
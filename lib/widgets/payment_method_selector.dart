import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../services/haptic_service.dart';

enum PaymentMethod { cash, qr, bank }

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MethodCard(
            method: PaymentMethod.cash,
            selected: selected == PaymentMethod.cash,
            emoji: '💵',
            label: 'Efectivo',
            subtitle: 'En mano',
            color: AppColors.success,
            onTap: () {
              HapticService.light();
              onChanged(PaymentMethod.cash);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MethodCard(
            method: PaymentMethod.qr,
            selected: selected == PaymentMethod.qr,
            emoji: '📱',
            label: 'QR',
            subtitle: 'Escaneo',
            color: AppColors.primaryMid,
            onTap: () {
              HapticService.light();
              onChanged(PaymentMethod.qr);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MethodCard(
            method: PaymentMethod.bank,
            selected: selected == PaymentMethod.bank,
            emoji: '🏦',
            label: 'Banco',
            subtitle: 'Transfer.',
            color: AppColors.info,
            onTap: () {
              HapticService.light();
              onChanged(PaymentMethod.bank);
            },
          ),
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final String emoji;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MethodCard({
    required this.method,
    required this.selected,
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.25),
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: selected ? Colors.white70 : AppColors.textDark.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    ).animate(target: selected ? 1 : 0).shimmer(duration: 800.ms);
  }
}
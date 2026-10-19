import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_typography.dart';

class EmojiHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final Color? emojiColor;

  const EmojiHeader({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.emojiColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji,
                style: TextStyle(fontSize: 32, color: emojiColor))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              duration: 1500.ms,
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.15, 1.15),
              curve: Curves.easeInOut,
            ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle ?? AppTypography.titleLarge),
              if (subtitle != null)
                Text(subtitle!, style: AppTypography.label),
            ],
          ),
        ),
      ],
    );
  }
}
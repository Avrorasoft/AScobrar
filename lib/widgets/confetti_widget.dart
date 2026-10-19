import 'dart:math';
import 'package:flutter/material.dart';

/// 🎉 Widget de confetti personalizado (alternativa al paquete confetti)
class ConfettiBlast extends StatefulWidget {
  final bool isActive;
  final Duration duration;
  final List<Color> colors;

  const ConfettiBlast({
    super.key,
    this.isActive = false,
    this.duration = const Duration(seconds: 3),
    this.colors = const [
      Color(0xFFFACC15),
      Color(0xFFEC4899),
      Color(0xFF06B6D4),
      Color(0xFF84CC16),
      Color(0xFFFB923C),
      Color(0xFF7C3AED),
    ],
  });

  @override
  State<ConfettiBlast> createState() => _ConfettiBlastState();
}

class _ConfettiBlastState extends State<ConfettiBlast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(() => setState(() {}));

    if (widget.isActive) _generateParticles();
  }

  @override
  void didUpdateWidget(ConfettiBlast oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _generateParticles();
      _controller.forward(from: 0);
    }
  }

  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < 80; i++) {
      _particles.add(_ConfettiParticle(
        color: widget.colors[_random.nextInt(widget.colors.length)],
        startX: 0.5,
        startY: 0.5,
        angle: _random.nextDouble() * 2 * pi,
        speed: 0.3 + _random.nextDouble() * 0.7,
        size: 6 + _random.nextDouble() * 8,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive || _particles.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  final Color color;
  final double startX, startY;
  final double angle;
  final double speed;
  final double size;
  final double rotation;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final distance = p.speed * progress * size.height;
      final x = size.width * p.startX + cos(p.angle) * distance;
      final y = size.height * p.startY + sin(p.angle) * distance + (progress * progress * size.height * 0.5);
      final alpha = (1 - progress).clamp(0.0, 1.0);
      final currentRotation = p.rotation + p.rotationSpeed * progress;

      final paint = Paint()
        ..color = p.color.withOpacity(alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(currentRotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class AlarmDetailScreen extends StatelessWidget {
  final dynamic alarm;

  const AlarmDetailScreen({super.key, required this.alarm});

  Color get _color {
    switch (alarm.severity) {
      case 'red':
        return AppColors.alarmRed;
      case 'orange':
        return AppColors.alarmOrange;
      default:
        return AppColors.alarmYellow;
    }
  }

  Future<void> _call() async {
    final uri = Uri.parse('tel:${alarm.phone}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    final phone = alarm.phone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _map() async {
    final q = Uri.encodeComponent(alarm.address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: _color,
        elevation: 0,
        title: Text('${alarm.emoji} Detalle de alarma',
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header cliente
            GlassCard(
              child: Column(children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: _color,
                  child: Text(alarm.clientName[0],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Text(alarm.clientName, style: AppTypography.displayMedium),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${alarm.emoji} ${alarm.daysOverdue} días de atraso',
                      style: AppTypography.label.copyWith(color: _color)),
                ),
              ]),
            ).animate().fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 16),

            // Datos de contacto
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('📇', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text('Datos de contacto', style: AppTypography.titleMedium),
                  ]),
                  const SizedBox(height: 16),
                  _InfoRow(icon: '📞', label: 'Teléfono', value: alarm.phone),
                  const SizedBox(height: 12),
                  _InfoRow(icon: '🏠', label: 'Dirección', value: alarm.address),
                  const SizedBox(height: 12),
                  _InfoRow(
                      icon: '💰',
                      label: 'Monto vencido',
                      value: '\$${alarm.overdueAmount.toStringAsFixed(2)}',
                      valueColor: _color),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 16),

            // Familiar apoderado
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('👨‍👩‍👦', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text('Familiar apoderado',
                        style: AppTypography.titleMedium),
                  ]),
                  const SizedBox(height: 16),
                  _InfoRow(icon: '👤', label: 'Nombre', value: 'Ana Pérez'),
                  const SizedBox(height: 12),
                  _InfoRow(icon: '🔗', label: 'Parentesco', value: 'Hermana'),
                  const SizedBox(height: 12),
                  _InfoRow(
                      icon: '📞', label: 'Teléfono', value: '+591 70099999'),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 24),

            // Botones de acción
            Row(children: [
              Expanded(
                child: GradientButton(
                    label: 'Llamar', emoji: '📞', onTap: _call),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                    label: 'WhatsApp',
                    emoji: '💬',
                    onTap: _whatsapp,
                    gradient: const LinearGradient(colors: [
                      Color(0xFF25D366),
                      Color(0xFF128C7E)
                    ])),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: GradientButton(
                    label: 'Ver en mapa', emoji: '🗺️', onTap: _map),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(label, style: AppTypography.label),
        ),
        Expanded(
          child: Text(value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              )),
        ),
      ],
    );
  }
}
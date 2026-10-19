import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/alarm_model.dart';

class AlarmCard extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback? onTap;

  const AlarmCard({
    super.key,
    required this.alarm,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color severityColor;
    switch (alarm.severity) {
      case AlarmSeverity.red:
        severityColor = AppColors.alarmRed;
        break;
      case AlarmSeverity.orange:
        severityColor = AppColors.alarmOrange;
        break;
      case AlarmSeverity.yellow:
        severityColor = AppColors.alarmYellow;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: severityColor.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: severityColor.withOpacity(0.15),
          child: Icon(Icons.warning_amber_rounded, color: severityColor),
        ),
        title: Text(
          alarm.clientName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${alarm.daysOverdue} días de mora • Deuda: Bs. ${alarm.overdueAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              'Tel: ${alarm.phone}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: severityColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            alarm.severity.name.toUpperCase(),
            style: TextStyle(
              color: severityColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}

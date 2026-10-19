enum AlarmSeverity { yellow, orange, red }

class Alarm {
  final String id;
  final String loanId;
  final String clientId;
  final String collectorId;
  final AlarmSeverity severity;
  final int daysOverdue;
  final double overdueAmount;
  final DateTime detectedAt;
  final DateTime? nextActionAt;
  final String? collectorNotes;
  final bool escalated;
  final bool resolved;

  // Datos del cliente (desnormalizados para mostrar rápido)
  final String clientName;
  final String phone;
  final String address;
  final String? guarantorName;
  final String? guarantorPhone;

  Alarm({
    required this.id,
    required this.loanId,
    required this.clientId,
    required this.collectorId,
    required this.severity,
    required this.daysOverdue,
    required this.overdueAmount,
    required this.detectedAt,
    this.nextActionAt,
    this.collectorNotes,
    this.escalated = false,
    this.resolved = false,
    required this.clientName,
    required this.phone,
    required this.address,
    this.guarantorName,
    this.guarantorPhone,
  });

  int get colorValue {
    switch (severity) {
      case AlarmSeverity.yellow:
        return 0xFFFBBF24;
      case AlarmSeverity.orange:
        return 0xFFF97316;
      case AlarmSeverity.red:
        return 0xFFEF4444;
    }
  }

  String get emoji {
    switch (severity) {
      case AlarmSeverity.yellow:
        return '🟡';
      case AlarmSeverity.orange:
        return '🟠';
      case AlarmSeverity.red:
        return '🔴';
    }
  }

  String get title {
    switch (severity) {
      case AlarmSeverity.yellow:
        return 'Recordatorio';
      case AlarmSeverity.orange:
        return 'Atención';
      case AlarmSeverity.red:
        return 'Crítico';
    }
  }

  factory Alarm.fromMap(Map m) => Alarm(
        id: m['id'] ?? '',
        loanId: m['loanId'] ?? '',
        clientId: m['clientId'] ?? '',
        collectorId: m['collectorId'] ?? '',
        severity: AlarmSeverity.values[m['severity'] ?? 0],
        daysOverdue: m['daysOverdue'] ?? 0,
        overdueAmount: (m['overdueAmount'] as num?)?.toDouble() ?? 0,
        detectedAt: m['detectedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['detectedAt'] as int)
            : DateTime.now(),
        nextActionAt: m['nextActionAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['nextActionAt'] as int)
            : null,
        collectorNotes: m['collectorNotes'],
        escalated: m['escalated'] ?? false,
        resolved: m['resolved'] ?? false,
        clientName: m['clientName'] ?? '',
        phone: m['phone'] ?? '',
        address: m['address'] ?? '',
        guarantorName: m['guarantorName'],
        guarantorPhone: m['guarantorPhone'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'loanId': loanId,
        'clientId': clientId,
        'collectorId': collectorId,
        'severity': severity.index,
        'daysOverdue': daysOverdue,
        'overdueAmount': overdueAmount,
        'detectedAt': detectedAt.millisecondsSinceEpoch,
        'nextActionAt': nextActionAt?.millisecondsSinceEpoch,
        'collectorNotes': collectorNotes,
        'escalated': escalated,
        'resolved': resolved,
        'clientName': clientName,
        'phone': phone,
        'address': address,
        'guarantorName': guarantorName,
        'guarantorPhone': guarantorPhone,
      };
}
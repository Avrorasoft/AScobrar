import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String id;
  final String userId;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> changes;
  final DateTime timestamp;
  final String? ipAddress;

  AuditLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.changes,
    required this.timestamp,
    this.ipAddress,
  });

  factory AuditLog.fromMap(Map<String, dynamic> m, String id) => AuditLog(
        id: id,
        userId: m['userId'] ?? '',
        action: m['action'] ?? '',
        entityType: m['entityType'] ?? '',
        entityId: m['entityId'] ?? '',
        changes: Map<String, dynamic>.from(m['changes'] ?? {}),
        timestamp: (m['timestamp'] as Timestamp).toDate(),
        ipAddress: m['ipAddress'],
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'changes': changes,
        'timestamp': Timestamp.fromDate(timestamp),
        'ipAddress': ipAddress,
      };
}

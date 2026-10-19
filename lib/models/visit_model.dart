import 'package:cloud_firestore/cloud_firestore.dart';

enum VisitResult { paid, promise, notHome, stillOverdue }

class Visit {
  final String id;
  final String loanId;
  final String clientId;
  final String collectorId;
  final DateTime visitedAt;
  final VisitResult result;
  final String? notes;
  final double? latitude;
  final double? longitude;

  Visit({
    required this.id,
    required this.loanId,
    required this.clientId,
    required this.collectorId,
    required this.visitedAt,
    required this.result,
    this.notes,
    this.latitude,
    this.longitude,
  });

  factory Visit.fromMap(Map<String, dynamic> m, String id) => Visit(
        id: id,
        loanId: m['loanId'] ?? '',
        clientId: m['clientId'] ?? '',
        collectorId: m['collectorId'] ?? '',
        visitedAt: (m['visitedAt'] as Timestamp).toDate(),
        result: VisitResult.values[m['result'] ?? 0],
        notes: m['notes'],
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'loanId': loanId,
        'clientId': clientId,
        'collectorId': collectorId,
        'visitedAt': Timestamp.fromDate(visitedAt),
        'result': result.index,
        'notes': notes,
        'latitude': latitude,
        'longitude': longitude,
      };
}

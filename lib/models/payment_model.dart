import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod { cash, transfer, card, qr }

class Payment {
  final String id;
  final String loanId;
  final String clientId;
  final String collectorId;
  final DateTime paidAt;
  final double amount;
  final int installmentsCovered;
  final int remainingInstallments;
  final double capitalPaid;
  final double interestPaid;
  final double penaltyPaid;
  final double pendingAfter;
  final double accumulatedPaid;
  final PaymentMethod method;
  final String? transactionId;
  final String? receiptUrl;
  final double? latitude;
  final double? longitude;
  final bool synced;

  Payment({
    required this.id,
    required this.loanId,
    required this.clientId,
    this.collectorId = '',
    required this.paidAt,
    required this.amount,
    required this.installmentsCovered,
    this.remainingInstallments = 0,
    required this.capitalPaid,
    required this.interestPaid,
    this.penaltyPaid = 0,
    required this.pendingAfter,
    required this.accumulatedPaid,
    required this.method,
    this.transactionId,
    this.receiptUrl,
    this.latitude,
    this.longitude,
    this.synced = false,
  });

  Payment copyWith({bool? synced}) => Payment(
        id: id,
        loanId: loanId,
        clientId: clientId,
        collectorId: collectorId,
        paidAt: paidAt,
        amount: amount,
        installmentsCovered: installmentsCovered,
        remainingInstallments: remainingInstallments,
        capitalPaid: capitalPaid,
        interestPaid: interestPaid,
        penaltyPaid: penaltyPaid,
        pendingAfter: pendingAfter,
        accumulatedPaid: accumulatedPaid,
        method: method,
        transactionId: transactionId,
        receiptUrl: receiptUrl,
        latitude: latitude,
        longitude: longitude,
        synced: synced ?? this.synced,
      );

  factory Payment.fromMap(Map m) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    PaymentMethod parseMethod(dynamic v) {
      if (v is int && v >= 0 && v < PaymentMethod.values.length) {
        return PaymentMethod.values[v];
      }
      if (v is String) {
        for (var m in PaymentMethod.values) {
          if (m.name.toLowerCase() == v.toLowerCase()) return m;
        }
      }
      return PaymentMethod.cash;
    }

    return Payment(
      id: (m['id'] ?? '').toString(),
      loanId: (m['loanId'] ?? '').toString(),
      clientId: (m['clientId'] ?? '').toString(),
      collectorId: (m['collectorId'] ?? '').toString(),
      paidAt: parseDate(m['paidAt']),
      amount: ((m['amount'] ?? 0) as num).toDouble(),
      installmentsCovered: ((m['installmentsCovered'] ?? 0) as num).toInt(),
      remainingInstallments: ((m['remainingInstallments'] ?? 0) as num).toInt(),
      capitalPaid: ((m['capitalPaid'] ?? 0) as num).toDouble(),
      interestPaid: ((m['interestPaid'] ?? 0) as num).toDouble(),
      penaltyPaid: ((m['penaltyPaid'] ?? 0) as num).toDouble(),
      pendingAfter: ((m['pendingAfter'] ?? 0) as num).toDouble(),
      accumulatedPaid: ((m['accumulatedPaid'] ?? 0) as num).toDouble(),
      method: parseMethod(m['method']),
      transactionId: m['transactionId']?.toString(),
      receiptUrl: m['receiptUrl']?.toString(),
      latitude: (m['latitude'] as num?)?.toDouble(),
      longitude: (m['longitude'] as num?)?.toDouble(),
      synced: m['synced'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'loanId': loanId,
        'clientId': clientId,
        'collectorId': collectorId,
        'paidAt': paidAt.millisecondsSinceEpoch,
        'amount': amount,
        'installmentsCovered': installmentsCovered,
        'remainingInstallments': remainingInstallments,
        'capitalPaid': capitalPaid,
        'interestPaid': interestPaid,
        'penaltyPaid': penaltyPaid,
        'pendingAfter': pendingAfter,
        'accumulatedPaid': accumulatedPaid,
        'method': method.index,
        'transactionId': transactionId,
        'receiptUrl': receiptUrl,
        'latitude': latitude,
        'longitude': longitude,
        'synced': synced,
      };
}

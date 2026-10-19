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

  factory Payment.fromMap(Map m) => Payment(
        id: m['id'] ?? '',
        loanId: m['loanId'] ?? '',
        clientId: m['clientId'] ?? '',
        collectorId: m['collectorId'] ?? '',
        paidAt: DateTime.fromMillisecondsSinceEpoch(m['paidAt'] as int),
        amount: (m['amount'] as num).toDouble(),
        installmentsCovered: m['installmentsCovered'] ?? 0,
        remainingInstallments: m['remainingInstallments'] ?? 0,
        capitalPaid: (m['capitalPaid'] as num).toDouble(),
        interestPaid: (m['interestPaid'] as num).toDouble(),
        penaltyPaid: (m['penaltyPaid'] as num?)?.toDouble() ?? 0,
        pendingAfter: (m['pendingAfter'] as num).toDouble(),
        accumulatedPaid: (m['accumulatedPaid'] as num).toDouble(),
        method: PaymentMethod.values[m['method'] ?? 0],
        transactionId: m['transactionId'],
        receiptUrl: m['receiptUrl'],
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        synced: m['synced'] ?? false,
      );

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
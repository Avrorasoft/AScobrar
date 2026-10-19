class BusinessConfig {
  String id;
  String businessName;
  String? tagline;
  String? phone;
  String? logoBase64;
  double defaultInterestRate;
  double defaultPenaltyRate;
  int defaultGraceDays;
  String currency;
  DateTime createdAt;
  DateTime updatedAt;

  BusinessConfig({
    required this.id,
    required this.businessName,
    this.tagline,
    this.phone,
    this.logoBase64,
    this.defaultInterestRate = 10.0,
    this.defaultPenaltyRate = 2.0,
    this.defaultGraceDays = 0,
    this.currency = 'BOB',
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessConfig.empty() => BusinessConfig(
        id: 'default',
        businessName: 'Mi Negocio de Préstamos',
        tagline: '',
        phone: '',
        logoBase64: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  factory BusinessConfig.fromMap(Map m) => BusinessConfig(
        id: m['id'] ?? 'default',
        businessName: m['businessName'] ?? 'Mi Negocio',
        tagline: m['tagline'],
        phone: m['phone'],
        logoBase64: m['logoBase64'],
        defaultInterestRate:
            (m['defaultInterestRate'] as num?)?.toDouble() ?? 10.0,
        defaultPenaltyRate:
            (m['defaultPenaltyRate'] as num?)?.toDouble() ?? 2.0,
        defaultGraceDays: m['defaultGraceDays'] ?? 0,
        currency: m['currency'] ?? 'BOB',
        createdAt: m['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int)
            : DateTime.now(),
        updatedAt: m['updatedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['updatedAt'] as int)
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'businessName': businessName,
        'tagline': tagline,
        'phone': phone,
        'logoBase64': logoBase64,
        'defaultInterestRate': defaultInterestRate,
        'defaultPenaltyRate': defaultPenaltyRate,
        'defaultGraceDays': defaultGraceDays,
        'currency': currency,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };
}
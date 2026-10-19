class Client {
  final String id;
  final String name;
  final String documentId;
  final String phone;
  final String phoneSecondary;
  final String address;
  final String street;
  final String neighborhood;
  final String reference;
  final String business;
  final String guarantorName;
  final String guarantorPhone;
  final String guarantorDocumentId;
  final String guarantorAddress;
  final String notes;
  final double creditScore;
  final double creditLimit;
  final double latitude;
  final double longitude;
  final bool isActive;
  final DateTime createdAt;

  Client({
    required this.id,
    required this.name,
    required this.documentId,
    required this.phone,
    this.phoneSecondary = '',
    this.address = '',
    this.street = '',
    this.neighborhood = '',
    this.reference = '',
    this.business = '',
    this.guarantorName = '',
    this.guarantorPhone = '',
    this.guarantorDocumentId = '',
    this.guarantorAddress = '',
    this.notes = '',
    this.creditScore = 100.0,
    this.creditLimit = 5000.0,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.isActive = true,
    required this.createdAt,
  });

  String get fullAddress {
    final s = street.trim().isNotEmpty ? street.trim() : address.trim();
    final n = neighborhood.trim();
    if (s.isNotEmpty && n.isNotEmpty) return '$s, Zona/Barrio: $n';
    if (s.isNotEmpty) return s;
    if (n.isNotEmpty) return 'Zona/Barrio: $n';
    return 'Sin dirección registrada';
  }

  Client copyWith({
    String? id,
    String? name,
    String? documentId,
    String? phone,
    String? phoneSecondary,
    String? address,
    String? street,
    String? neighborhood,
    String? reference,
    String? business,
    String? guarantorName,
    String? guarantorPhone,
    String? guarantorDocumentId,
    String? guarantorAddress,
    String? notes,
    double? creditScore,
    double? creditLimit,
    double? latitude,
    double? longitude,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      documentId: documentId ?? this.documentId,
      phone: phone ?? this.phone,
      phoneSecondary: phoneSecondary ?? this.phoneSecondary,
      address: address ?? this.address,
      street: street ?? this.street,
      neighborhood: neighborhood ?? this.neighborhood,
      reference: reference ?? this.reference,
      business: business ?? this.business,
      guarantorName: guarantorName ?? this.guarantorName,
      guarantorPhone: guarantorPhone ?? this.guarantorPhone,
      guarantorDocumentId: guarantorDocumentId ?? this.guarantorDocumentId,
      guarantorAddress: guarantorAddress ?? this.guarantorAddress,
      notes: notes ?? this.notes,
      creditScore: creditScore ?? this.creditScore,
      creditLimit: creditLimit ?? this.creditLimit,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Client.fromMap(Map m, [String? fallbackId]) {
    final rawStreet = (m['street'] ?? m['address'] ?? '').toString();
    final rawAddress = (m['address'] ?? m['street'] ?? '').toString();

    return Client(
      id: (m['id'] ?? fallbackId ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      documentId: (m['documentId'] ?? '').toString(),
      phone: (m['phone'] ?? '').toString(),
      phoneSecondary: (m['phoneSecondary'] ?? '').toString(),
      address: rawAddress,
      street: rawStreet,
      neighborhood: (m['neighborhood'] ?? '').toString(),
      reference: (m['reference'] ?? '').toString(),
      business: (m['business'] ?? '').toString(),
      guarantorName: (m['guarantorName'] ?? '').toString(),
      guarantorPhone: (m['guarantorPhone'] ?? '').toString(),
      guarantorDocumentId: (m['guarantorDocumentId'] ?? '').toString(),
      guarantorAddress: (m['guarantorAddress'] ?? '').toString(),
      notes: (m['notes'] ?? '').toString(),
      creditScore: (m['creditScore'] as num?)?.toDouble() ?? 100.0,
      creditLimit: (m['creditLimit'] as num?)?.toDouble() ?? 5000.0,
      latitude: (m['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (m['longitude'] as num?)?.toDouble() ?? 0.0,
      isActive: m['isActive'] == null ? true : (m['isActive'] == true),
      createdAt: m['createdAt'] != null
          ? DateTime.tryParse(m['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final effectiveAddress = street.trim().isNotEmpty ? street.trim() : address.trim();
    return {
      'id': id,
      'name': name.trim(),
      'documentId': documentId.trim(),
      'phone': phone.trim(),
      'phoneSecondary': phoneSecondary.trim(),
      'address': effectiveAddress,
      'street': effectiveAddress,
      'neighborhood': neighborhood.trim(),
      'reference': reference.trim(),
      'business': business.trim(),
      'guarantorName': guarantorName.trim(),
      'guarantorPhone': guarantorPhone.trim(),
      'guarantorDocumentId': guarantorDocumentId.trim(),
      'guarantorAddress': guarantorAddress.trim(),
      'notes': notes.trim(),
      'creditScore': creditScore,
      'creditLimit': creditLimit,
      'latitude': latitude,
      'longitude': longitude,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

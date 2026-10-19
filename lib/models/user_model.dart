enum UserRole { owner, collector }

class AppUser {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isOwner => role == UserRole.owner;
  bool get isCollector => role == UserRole.collector;

  factory AppUser.fromMap(Map<String, dynamic> m, String id) {
    final roleStr = (m['role'] ?? 'collector').toString().toLowerCase();
    final role = roleStr == 'owner' || roleStr == 'admin' ? UserRole.owner : UserRole.collector;

    return AppUser(
      id: id,
      name: (m['name'] ?? '').toString(),
      phone: (m['phone'] ?? '').toString(),
      role: role,
      isActive: m['isActive'] ?? true,
      createdAt: m['createdAt'] != null
          ? DateTime.tryParse(m['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? phone,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MODEL: User
//  Matches backend User schema exactly
// ─────────────────────────────────────────────────────────────
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;   // 'superadmin' | 'operator'
  final String? phone;
  final String? businessName;
  final String? city;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.businessName,
    this.city,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:           json['_id']?.toString()       ?? json['id']?.toString() ?? '',
      name:         json['name']?.toString()       ?? '',
      email:        json['email']?.toString()      ?? '',
      role:         json['role']?.toString()       ?? 'operator',
      phone:        json['phone']?.toString(),
      businessName: json['businessName']?.toString(),
      city:         json['city']?.toString(),
      isActive:     json['isActive'] as bool?      ?? true,
    );
  }

  bool get isSuperAdmin => role == 'superadmin';
  bool get isOperator   => role == 'operator';

  String get displayRole =>
      role == 'superadmin' ? 'Super Admin' : 'Operator';

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}
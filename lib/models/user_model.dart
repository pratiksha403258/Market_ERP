// user_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;   // 'superadmin' | 'operator'
  final String? phone;
  final String? businessName;
  final String? address;
  final String? city;
  final String? state;
  final String? gstNumber;
  final String? panNumber;
  final String? bankAccountNumber;
  final String? ifscCode;
  final String? bankName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.businessName,
    this.address,
    this.city,
    this.state,
    this.gstNumber,
    this.panNumber,
    this.bankAccountNumber,
    this.ifscCode,
    this.bankName,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'operator',
      phone: json['phone']?.toString(),
      businessName: json['businessName']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      gstNumber: json['gstNumber']?.toString(),
      panNumber: json['panNumber']?.toString(),
      bankAccountNumber: json['bankAccountNumber']?.toString(),
      ifscCode: json['ifscCode']?.toString(),
      bankName: json['bankName']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.tryParse(json['lastLoginAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'businessName': businessName,
      'address': address,
      'city': city,
      'state': state,
      'gstNumber': gstNumber,
      'panNumber': panNumber,
      'bankAccountNumber': bankAccountNumber,
      'ifscCode': ifscCode,
      'bankName': bankName,
    };
  }

  bool get isSuperAdmin => role == 'superadmin';
  bool get isOperator => role == 'operator';

  String get displayRole => role == 'superadmin' ? 'Super Admin' : 'Operator';

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? businessName,
    String? address,
    String? city,
    String? state,
    String? gstNumber,
    String? panNumber,
    String? bankAccountNumber,
    String? ifscCode,
    String? bankName,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      phone: phone ?? this.phone,
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      bankName: bankName ?? this.bankName,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt,
    );
  }
}
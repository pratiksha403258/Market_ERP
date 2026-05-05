// ─────────────────────────────────────────────────────────────
//  MODEL: Farmer
//  Matches backend Farmer schema exactly
// ─────────────────────────────────────────────────────────────
class FarmerModel {
  final String id;
  final String operatorId;     
  final String name;
  final String mobile;
  final String? address;
  final String? village;
  final String? city;
  final String? bankAccountNumber;
  final String? ifscCode;
  final String? bankName;
  final String? gstNumber;
  final double totalPurchases;
  final double totalPaid;
  final double pendingDues;
  final double advanceBalance;
  final bool isActive;
  final DateTime? createdAt;

  const FarmerModel({
    required this.id,
    required this.operatorId,
    required this.name,
    required this.mobile,
    this.address,
    this.village,
    this.city,
    this.bankAccountNumber,
    this.ifscCode,
    this.bankName,
    this.gstNumber,
    required this.totalPurchases,
    required this.totalPaid,
    required this.pendingDues,
    required this.advanceBalance,
    required this.isActive,
    this.createdAt,
  });

  factory FarmerModel.fromJson(Map<String, dynamic> json) {
    return FarmerModel(
      id:                  json['_id']?.toString()             ?? json['id']?.toString() ?? '',
      operatorId:          json['vendorId']?.toString()        ?? '',
      name:                json['name']?.toString()            ?? '',
      mobile:              json['mobile']?.toString()          ?? '',
      address:             json['address']?.toString(),
      village:             json['village']?.toString(),
      city:                json['city']?.toString(),
      bankAccountNumber:   json['bankAccountNumber']?.toString(),
      ifscCode:            json['ifscCode']?.toString(),
      bankName:            json['bankName']?.toString(),
      gstNumber:           json['gstNumber']?.toString(),
      totalPurchases:      (json['totalPurchases'] as num?)?.toDouble()  ?? 0.0,
      totalPaid:           (json['totalPaid']       as num?)?.toDouble() ?? 0.0,
      pendingDues:         (json['pendingDues']     as num?)?.toDouble() ?? 0.0,
      advanceBalance:      (json['advanceBalance']  as num?)?.toDouble() ?? 0.0,
      isActive:            json['isActive'] as bool?                     ?? true,
      createdAt:           json['createdAt'] != null
                             ? DateTime.tryParse(json['createdAt'].toString())
                             : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name':               name,
    'mobile':             mobile,
    if (address != null)  'address':   address,
    if (village != null)  'village':   village,
    if (city != null)     'city':      city,
    if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
    if (ifscCode != null) 'ifscCode':  ifscCode,
    if (bankName != null) 'bankName':  bankName,
    if (gstNumber != null) 'gstNumber': gstNumber,
  };

  String get displayLocation {
    if (village != null && city != null) return '$village, $city';
    if (village != null) return village!;
    if (city != null)    return city!;
    return '—';
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'F';
  }

  bool get hasPendingDues => pendingDues > 0;
  bool get hasAdvanceBalance => advanceBalance > 0;
}

// Response wrapper for paginated farmer list
class FarmerListResponse {
  final List<FarmerModel> farmers;
  final int total;
  final int page;
  final int totalPages;

  const FarmerListResponse({
    required this.farmers,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory FarmerListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['farmers'] as List? ?? json['data'] as List? ?? [];
    return FarmerListResponse(
      farmers:    data.map((e) => FarmerModel.fromJson(e as Map<String, dynamic>)).toList(),
      total:      (json['total']      as num?)?.toInt() ?? 0,
      page:       (json['page']       as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

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
    // ── Safe double parser ────────────────────────────────────
    double toD(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

    // ── Handle nested 'data' wrapper if present ───────────────
    // Some endpoints return { data: { farmer: {...} } }
    // Others return the farmer object directly
    Map<String, dynamic> j = json;
    if (json['data'] is Map<String, dynamic>) {
      final inner = json['data'] as Map<String, dynamic>;
      if (inner['farmer'] is Map<String, dynamic>) {
        j = inner['farmer'] as Map<String, dynamic>;
      } else {
        j = inner;
      }
    } else if (json['farmer'] is Map<String, dynamic>) {
      j = json['farmer'] as Map<String, dynamic>;
    }

    // ── ID: backend uses _id (MongoDB) ────────────────────────
    final id = j['_id']?.toString() ?? j['id']?.toString() ?? '';

    // ── Financial summary fields ──────────────────────────────
    // Backend may return these under different keys depending on
    // whether it's the list endpoint or detail endpoint.
    // List:   totalPurchases / totalPurchaseValue / purchaseTotal
    // Detail: totalPurchases / stats.totalPurchases
    double totalPurchases = 0;
    double totalPaid = 0;
    double pendingDues = 0;
    double advanceBalance = 0;

    // Try direct fields first
    totalPurchases = toD(j['totalPurchases']) > 0
        ? toD(j['totalPurchases'])
        : toD(j['totalPurchaseValue']) > 0
            ? toD(j['totalPurchaseValue'])
            : toD(j['purchaseTotal']);

    totalPaid = toD(j['totalPaid']) > 0
        ? toD(j['totalPaid'])
        : toD(j['totalPaidAmount']) > 0
            ? toD(j['totalPaidAmount'])
            : toD(j['paidAmount']);

    pendingDues = toD(j['pendingDues']) > 0
        ? toD(j['pendingDues'])
        : toD(j['pendingAmount']) > 0
            ? toD(j['pendingAmount'])
            : toD(j['dueAmount']) > 0
                ? toD(j['dueAmount'])
                : toD(j['amountDue']);

    advanceBalance = toD(j['advanceBalance']) > 0
        ? toD(j['advanceBalance'])
        : toD(j['advance']) > 0
            ? toD(j['advance'])
            : toD(j['advanceAmount']);

    // Try nested 'stats' or 'summary' object (detail endpoint variant)
    if (j['stats'] is Map<String, dynamic>) {
      final stats = j['stats'] as Map<String, dynamic>;
      if (totalPurchases == 0) totalPurchases = toD(stats['totalPurchases']);
      if (totalPaid == 0) totalPaid = toD(stats['totalPaid']);
      if (pendingDues == 0) pendingDues = toD(stats['pendingDues']);
      if (advanceBalance == 0) advanceBalance = toD(stats['advanceBalance']);
    }

    if (j['summary'] is Map<String, dynamic>) {
      final summary = j['summary'] as Map<String, dynamic>;
      if (totalPurchases == 0) totalPurchases = toD(summary['totalPurchases']);
      if (totalPaid == 0) totalPaid = toD(summary['totalPaid']);
      if (pendingDues == 0) pendingDues = toD(summary['pendingDues']);
      if (advanceBalance == 0) advanceBalance = toD(summary['advanceBalance']);
    }

    // ── String fields — handle null/empty safely ──────────────
    String? nullIfEmpty(dynamic v) {
      final s = v?.toString();
      return (s == null || s.isEmpty || s == 'null') ? null : s;
    }

    return FarmerModel(
      id: id,
      operatorId: j['vendorId']?.toString() ??
          j['operatorId']?.toString() ??
          j['operator']?.toString() ??
          '',
      name: j['name']?.toString() ?? '',
      mobile: j['mobile']?.toString() ??
          j['phone']?.toString() ??
          j['mobileNumber']?.toString() ??
          '',
      address: nullIfEmpty(j['address']),
      village: nullIfEmpty(j['village']),
      city: nullIfEmpty(j['city']),
      bankAccountNumber: nullIfEmpty(j['bankAccountNumber']) ??
          nullIfEmpty(j['accountNumber']),
      ifscCode: nullIfEmpty(j['ifscCode']) ?? nullIfEmpty(j['ifsc']),
      bankName: nullIfEmpty(j['bankName']) ?? nullIfEmpty(j['bank']),
      gstNumber: nullIfEmpty(j['gstNumber']) ?? nullIfEmpty(j['gst']),
      totalPurchases: totalPurchases,
      totalPaid: totalPaid,
      pendingDues: pendingDues,
      advanceBalance: advanceBalance,
      isActive: j['isActive'] as bool? ?? j['active'] as bool? ?? true,
      createdAt: j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'mobile': mobile,
        if (address != null) 'address': address,
        if (village != null) 'village': village,
        if (city != null) 'city': city,
        if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
        if (ifscCode != null) 'ifscCode': ifscCode,
        if (bankName != null) 'bankName': bankName,
        if (gstNumber != null) 'gstNumber': gstNumber,
      };

  String get displayLocation {
    if (village != null && city != null) return '$village, $city';
    if (village != null) return village!;
    if (city != null) return city!;
    return '—';
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'F';
  }

  bool get hasPendingDues => pendingDues > 0;
  bool get hasAdvanceBalance => advanceBalance > 0;

  /// Useful for debugging — prints all financial values
  void debugPrint() {
    // ignore: avoid_print
    print('🌾 FarmerModel[$id] name=$name mobile=$mobile '
        'totalPurchases=$totalPurchases totalPaid=$totalPaid '
        'pendingDues=$pendingDues advanceBalance=$advanceBalance '
        'isActive=$isActive');
  }
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
    // Handle { success, data: { farmers: [], pagination: {} } }
    // or     { farmers: [], total: N }
    // or     { data: [], total: N }
    List rawFarmers = [];
    int total = 0;
    int page = 1;
    int totalPages = 1;

    if (json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;
      rawFarmers = data['farmers'] as List? ??
          data['data'] as List? ??
          [];
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      total = (pagination['total'] as num?)?.toInt() ??
          (data['total'] as num?)?.toInt() ??
          rawFarmers.length;
      page = (pagination['page'] as num?)?.toInt() ??
          (data['page'] as num?)?.toInt() ??
          1;
      totalPages = (pagination['pages'] as num?)?.toInt() ??
          (pagination['totalPages'] as num?)?.toInt() ??
          (data['totalPages'] as num?)?.toInt() ??
          1;
    } else if (json['data'] is List) {
      rawFarmers = json['data'] as List;
      total = (json['total'] as num?)?.toInt() ?? rawFarmers.length;
      page = (json['page'] as num?)?.toInt() ?? 1;
      totalPages = (json['totalPages'] as num?)?.toInt() ?? 1;
    } else {
      rawFarmers = json['farmers'] as List? ?? [];
      total = (json['total'] as num?)?.toInt() ?? rawFarmers.length;
      page = (json['page'] as num?)?.toInt() ?? 1;
      totalPages = (json['totalPages'] as num?)?.toInt() ?? 1;
    }

    return FarmerListResponse(
      farmers: rawFarmers
          .map((e) => FarmerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: total,
      page: page,
      totalPages: totalPages,
    );
  }
}
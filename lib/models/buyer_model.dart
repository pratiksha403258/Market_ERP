class Buyer {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String? alternateMobile;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String? gstNumber;
  final String? panNumber;
  final String businessName;
  final String businessType;
  final double creditLimit;
  final int creditDays;
  final String defaultPaymentMode;
  final bool isActive;
  final String? notes;
  final int totalPurchases;
  final double totalPurchaseValue;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String fullAddress;
  final String displayName;

  Buyer({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    this.alternateMobile,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.gstNumber,
    this.panNumber,
    required this.businessName,
    required this.businessType,
    required this.creditLimit,
    required this.creditDays,
    required this.defaultPaymentMode,
    required this.isActive,
    this.notes,
    required this.totalPurchases,
    required this.totalPurchaseValue,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.fullAddress,
    required this.displayName,
  });

  factory Buyer.fromJson(Map<String, dynamic> json) {
    return Buyer(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      alternateMobile: json['alternateMobile'],
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      gstNumber: json['gstNumber'],
      panNumber: json['panNumber'],
      businessName: json['businessName'] ?? '',
      businessType: json['businessType'] ?? 'individual',
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
      creditDays: json['creditDays'] ?? 0,
      defaultPaymentMode: json['defaultPaymentMode'] ?? 'cash',
      isActive: json['isActive'] ?? true,
      notes: json['notes'],
      totalPurchases: json['totalPurchases'] ?? 0,
      totalPurchaseValue: (json['totalPurchaseValue'] as num?)?.toDouble() ?? 0,
      createdBy: json['createdBy'] is Map ? json['createdBy']['_id'] : json['createdBy'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      fullAddress: json['fullAddress'] ?? '',
      displayName: json['displayName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'mobile': mobile,
      'alternateMobile': alternateMobile,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'gstNumber': gstNumber,
      'panNumber': panNumber,
      'businessName': businessName,
      'businessType': businessType,
      'creditLimit': creditLimit,
      'creditDays': creditDays,
      'defaultPaymentMode': defaultPaymentMode,
      'notes': notes,
    };
  }
}

class BuyerSummary {
  final int totalBuyers;
  final int activeBuyers;
  final int inactiveBuyers;
  final double totalPurchaseValue;
  final double averagePurchasePerBuyer;
  final List<Buyer> topBuyers;

  BuyerSummary({
    required this.totalBuyers,
    required this.activeBuyers,
    required this.inactiveBuyers,
    required this.totalPurchaseValue,
    required this.averagePurchasePerBuyer,
    required this.topBuyers,
  });

  factory BuyerSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return BuyerSummary(
      totalBuyers: data['totalBuyers'] ?? 0,
      activeBuyers: data['activeBuyers'] ?? 0,
      inactiveBuyers: data['inactiveBuyers'] ?? 0,
      totalPurchaseValue: (data['totalPurchaseValue'] as num?)?.toDouble() ?? 0,
      averagePurchasePerBuyer: (data['averagePurchasePerBuyer'] as num?)?.toDouble() ?? 0,
      topBuyers: (data['topBuyers'] as List?)
          ?.map((e) => Buyer.fromJson(e))
          .toList() ?? [],
    );
  }
}
class ProductModel {
  final String id;
  final String productName;
  final String description;
  bool isActive;
  final dynamic createdBy; // Can be either String (ID) or Map
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.productName,
    required this.description,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      // ── safe id ──────────────────────────────────────────────
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',

      // ── safe productName (was crashing when null) ─────────────
      productName: json['productName']?.toString() ?? '',

      // ── safe description ──────────────────────────────────────
      description: json['description']?.toString() ?? '',

      // ── safe isActive (was crashing when null) ────────────────
      isActive: json['isActive'] as bool? ?? true,

      // ── createdBy can be String ID or Map object ──────────────
      createdBy: json['createdBy'],

      // ── safe DateTime parse (was crashing when null/missing) ──
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),

      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productName': productName,
      'description': description,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get initials {
    if (productName.isEmpty) return 'P';
    final parts = productName.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String get createdByName {
    if (createdBy is Map) {
      return (createdBy as Map)['name']?.toString() ?? 'Unknown';
    } else if (createdBy is String) {
      return 'User';
    }
    return 'Unknown';
  }
}
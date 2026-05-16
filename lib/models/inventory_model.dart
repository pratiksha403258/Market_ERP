class InventoryItem {
  final String id;
  final String productName;
  final String warehouse;
  final double currentStock;
  final String unit;
  final DateTime lastUpdated;

  InventoryItem({
    required this.id,
    required this.productName,
    required this.warehouse,
    required this.currentStock,
    required this.unit,
    required this.lastUpdated,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      // ── was: json['_id'] as String  → crashes if null ─────────
      id: json['_id']?.toString() ?? '',

      // ── was: json['productName'] as String → crashes if missing ─
      productName: json['productName']?.toString() ?? '',

      // ── was: json['warehouse'] as String → crashes if null ─────
      warehouse: json['warehouse']?.toString() ?? '',

      // ── was: (json['currentStock'] as num) → crashes if null ───
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0.0,

      // ── was: json['unit'] as String → crashes if null ──────────
      unit: json['unit']?.toString() ?? 'kg',

      // ── was: DateTime.parse(json['lastUpdated'] as String) ─────
      //    crashes if lastUpdated is null/missing
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isLowStock => currentStock <= 10;
}
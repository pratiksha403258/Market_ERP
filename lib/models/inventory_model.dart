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
      id: json['_id'] as String,
      productName: json['productName'] as String,
      warehouse: json['warehouse'] as String,
      currentStock: (json['currentStock'] as num).toDouble(),
      unit: json['unit'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  bool get isLowStock => currentStock <= 10;
}
// ─────────────────────────────────────────────────────────────
// PURCHASE MODEL
// ─────────────────────────────────────────────────────────────

class PurchaseLine {
  String id;
  String productName;
  String pricingType; // kg, quintal, piece, bunch, crate, dozen, flat
  double bags;
  double weightPerBag;
  double actualQty;
  double qualityDeduction;
  double rate;
  bool rateLocked;

  // Computed
  double get grossQty =>
      pricingType == 'kg' && bags > 0 && weightPerBag > 0
          ? bags * weightPerBag
          : actualQty;
  double get billedQty => (grossQty - qualityDeduction).clamp(0, double.infinity);
  double get lineTotal => pricingType == 'flat' ? rate : billedQty * rate;
  String get unit => const {
        'kg': 'kg',
        'quintal': 'qtl',
        'piece': 'pcs',
        'bunch': 'bunch',
        'crate': 'crate',
        'dozen': 'doz',
        'flat': 'flat',
      }[pricingType] ??
      '';

  PurchaseLine({
    required this.id,
    this.productName = '',
    this.pricingType = 'kg',
    this.bags = 0,
    this.weightPerBag = 0,
    this.actualQty = 0,
    this.qualityDeduction = 0,
    this.rate = 0,
    this.rateLocked = false,
  });

  Map<String, dynamic> toJson() => {
    'productName': productName,
    'pricingType': pricingType,
    'bags': bags,
    'weightPerBag': weightPerBag,
    'actualQty': actualQty,
    'qualityDeduction': qualityDeduction,
    'billedQty': billedQty,
    'rate': rate,
    'lineTotal': lineTotal,
  };

  PurchaseLine copyWith({
    String? id,
    String? productName,
    String? pricingType,
    double? bags,
    double? weightPerBag,
    double? actualQty,
    double? qualityDeduction,
    double? rate,
    bool? rateLocked,
  }) {
    return PurchaseLine(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      pricingType: pricingType ?? this.pricingType,
      bags: bags ?? this.bags,
      weightPerBag: weightPerBag ?? this.weightPerBag,
      actualQty: actualQty ?? this.actualQty,
      qualityDeduction: qualityDeduction ?? this.qualityDeduction,
      rate: rate ?? this.rate,
      rateLocked: rateLocked ?? this.rateLocked,
    );
  }
}
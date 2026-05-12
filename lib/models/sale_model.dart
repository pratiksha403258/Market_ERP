// ─────────────────────────────────────────────────────────────
//  SALE MODEL
//  Matches backend Sale schema exactly
//  Used for: Sales Invoice, Profit/Loss calculation
// ─────────────────────────────────────────────────────────────
 
class SaleModel {
  final String id;
  final String invoiceNumber;
  final String buyerName;
  final String? buyerGst;
  final String? buyerMobile;
  final String? buyerAddress;
  final DateTime saleDate;
  final String productName;
  final double quantity;
  final String unit;
  final double sellingPricePerUnit;
  final double subtotal;
  final double gstPercentage;
  final double gstAmount;
  final double totalAmount;
  final String paymentStatus; // paid, partial, pending
  final double amountPaid;
  final double amountDue;
  final String? notes;
  final Map<String, dynamic>? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
 
  const SaleModel({
    required this.id,
    required this.invoiceNumber,
    required this.buyerName,
    this.buyerGst,
    this.buyerMobile,
    this.buyerAddress,
    required this.saleDate,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.sellingPricePerUnit,
    required this.subtotal,
    required this.gstPercentage,
    required this.gstAmount,
    required this.totalAmount,
    required this.paymentStatus,
    required this.amountPaid,
    required this.amountDue,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });
 
  factory SaleModel.fromJson(Map<String, dynamic> j) {
    // Helper to safely parse doubles
    double toD(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
 
    return SaleModel(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      invoiceNumber: j['invoiceNumber']?.toString() ?? '',
      buyerName: j['buyerName']?.toString() ?? '',
      buyerGst: j['buyerGst']?.toString(),
      buyerMobile: j['buyerMobile']?.toString(),
      buyerAddress: j['buyerAddress']?.toString(),
      saleDate: DateTime.tryParse(j['saleDate']?.toString() ?? '') ??
          DateTime.now(),
      productName: j['productName']?.toString() ?? '',
      quantity: toD(j['quantity']),
      unit: j['unit']?.toString() ?? '',
      sellingPricePerUnit: toD(j['sellingPricePerUnit']),
      subtotal: toD(j['subtotal']),
      gstPercentage: toD(j['gstPercentage']),
      gstAmount: toD(j['gstAmount']),
      totalAmount: toD(j['totalAmount']),
      paymentStatus: j['paymentStatus']?.toString() ?? 'pending',
      amountPaid: toD(j['amountPaid']),
      amountDue: toD(j['amountDue']),
      notes: j['notes']?.toString(),
      createdBy:
          j['createdBy'] is Map ? j['createdBy'] as Map<String, dynamic> : null,
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(j['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
 
  Map<String, dynamic> toJson() => {
        'buyerName': buyerName,
        if (buyerGst != null) 'buyerGst': buyerGst,
        if (buyerMobile != null) 'buyerMobile': buyerMobile,
        if (buyerAddress != null) 'buyerAddress': buyerAddress,
        'saleDate': saleDate.toIso8601String().split('T')[0],
        'productName': productName,
        'quantity': quantity,
        'unit': unit,
        'sellingPricePerUnit': sellingPricePerUnit,
        'subtotal': subtotal,
        'gstPercentage': gstPercentage,
        'gstAmount': gstAmount,
        'totalAmount': totalAmount,
        'paymentStatus': paymentStatus,
        if (notes != null) 'notes': notes,
      };
 
  // ── Computed helpers ─────────────────────────────────────────
  bool get isPaid => paymentStatus == 'paid';
  bool get isPartial => paymentStatus == 'partial';
  bool get isPending => paymentStatus == 'pending';
  bool get hasDue => amountDue > 0;
 
  String get paymentStatusLabel {
    switch (paymentStatus) {
      case 'paid':
        return 'Paid';
      case 'partial':
        return 'Partial';
      case 'pending':
        return 'Pending';
      default:
        return paymentStatus;
    }
  }
 
  String get initials {
    final parts = buyerName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return buyerName.isNotEmpty ? buyerName[0].toUpperCase() : 'B';
  }
 
  String get createdByName =>
      createdBy?['name']?.toString() ?? '';
}
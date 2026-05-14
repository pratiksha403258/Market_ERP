
class SaleModel {
  final String id;
  final String invoiceNumber;
  final String buyerName;
  final String? buyerMobile;
  final String? buyerGst;
  final String? buyerAddress;
  final DateTime saleDate;
  final List<SaleLine> lines;

  
  final double grossTotal;
  final double totalDeductions;
  final double finalReceivable;
  final double amountReceived;
  final double amountDue;
  final String status; // pending | partial | paid

  // Legacy / optional fields
  final double subTotal;
  final double gstPercent;
  final double gstAmount;
  final double grandTotal;
  final String paymentMode;
  final String? referenceNumber;
  final String? notes;
  final SaleDeductions? deductions;
  final Map<String, dynamic>? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SaleModel({
    required this.id,
    required this.invoiceNumber,
    required this.buyerName,
    this.buyerMobile,
    this.buyerGst,
    this.buyerAddress,
    required this.saleDate,
    required this.lines,
    required this.grossTotal,
    required this.totalDeductions,
    required this.finalReceivable,
    required this.amountReceived,
    required this.amountDue,
    required this.status,
    required this.subTotal,
    required this.gstPercent,
    required this.gstAmount,
    required this.grandTotal,
    required this.paymentMode,
    this.referenceNumber,
    this.notes,
    this.deductions,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SaleModel.fromJson(Map<String, dynamic> j) {
    double toD(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

    return SaleModel(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      invoiceNumber: j['invoiceNumber']?.toString() ?? '',
      buyerName: j['buyerName']?.toString() ?? '',
      buyerMobile: j['buyerMobile']?.toString(),
      buyerGst: j['buyerGst']?.toString(),
      buyerAddress: j['buyerAddress']?.toString(),
      saleDate:
          DateTime.tryParse(j['saleDate']?.toString() ?? '') ?? DateTime.now(),
      lines: (j['lines'] as List? ?? [])
          .map((e) => SaleLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      grossTotal: toD(j['grossTotal']),
      totalDeductions: toD(j['totalDeductions']),
      finalReceivable: toD(j['finalReceivable']),
      amountReceived: toD(j['amountReceived']),
      amountDue: toD(j['amountDue']),
      status: j['status']?.toString() ?? 'pending',
      subTotal: toD(j['subTotal']),
      gstPercent: toD(j['gstPercent']),
      gstAmount: toD(j['gstAmount']),
      grandTotal: toD(j['grandTotal']),
      paymentMode: j['paymentMode']?.toString() ?? 'cash',
      referenceNumber: j['referenceNumber']?.toString(),
      notes: j['notes']?.toString(),
      deductions: j['deductions'] != null
          ? SaleDeductions.fromJson(j['deductions'] as Map<String, dynamic>)
          : null,
      createdBy:
          j['createdBy'] is Map ? j['createdBy'] as Map<String, dynamic> : null,
      createdAt:
          DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(j['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  // ── Computed helpers ─────────────────────────────────────────
  bool get isPaid => status == 'paid';
  bool get isPartial => status == 'partial';
  bool get isPending => status == 'pending';
  bool get hasDue => amountDue > 0;

  String get paymentStatusLabel {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'partial':
        return 'Partial';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  String get initials {
    final parts = buyerName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return buyerName.isNotEmpty ? buyerName[0].toUpperCase() : 'B';
  }

  String get createdByName => createdBy?['name']?.toString() ?? '';

  /// Display amount: prefer finalReceivable if set, else grandTotal
  double get displayTotal =>
      finalReceivable > 0 ? finalReceivable : grandTotal;
}

// ── Sale Line ─────────────────────────────────────────────────
class SaleLine {
  final String productName;
  final String warehouse;

  final String pricingType; // kg | quintal | fixed
  final int bags;
  final double weightPerBag;
  final double actualQty; // total weight
  final double qualityDeduction; // weight deducted for quality
  final double rate; // rate per unit

  // Legacy / computed
  final double qty;
  final String unit;
  final double sellingPrice;
  final double lineTotal;
  final String? notes;

  SaleLine({
    required this.productName,
    required this.warehouse,
    required this.pricingType,
    required this.bags,
    required this.weightPerBag,
    required this.actualQty,
    required this.qualityDeduction,
    required this.rate,
    required this.qty,
    required this.unit,
    required this.sellingPrice,
    required this.lineTotal,
    this.notes,
  });

  factory SaleLine.fromJson(Map<String, dynamic> j) {
    double toD(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
    int toI(dynamic v) => (v as num?)?.toInt() ?? 0;

    return SaleLine(
      productName: j['productName']?.toString() ?? '',
      warehouse: j['warehouse']?.toString() ?? '',
      pricingType: j['pricingType']?.toString() ?? 'kg',
      bags: toI(j['bags']),
      weightPerBag: toD(j['weightPerBag']),
      actualQty: toD(j['actualQty']),
      qualityDeduction: toD(j['qualityDeduction']),
      rate: toD(j['rate']),
      qty: toD(j['qty']),
      unit: j['unit']?.toString() ?? 'kg',
      sellingPrice: toD(j['sellingPrice']),
      lineTotal: toD(j['lineTotal']),
      notes: j['notes']?.toString(),
    );
  }

  /// Net qty after quality deduction
  double get netQty => actualQty > 0 ? actualQty - qualityDeduction : qty;

  /// Effective rate for display
  double get effectiveRate => rate > 0 ? rate : sellingPrice;
}

// ── Deductions ────────────────────────────────────────────────
class SaleDeductions {
  final double transport;
  final double labour;
  final double commission;
  final String commissionType; // fixed | percent
  final double storage;
  final String? storageNote;
  final double returnDeduction;
  final String? returnNote;
  final double advanceAdjusted;
  final double other;
  final String? otherNote;

  const SaleDeductions({
    required this.transport,
    required this.labour,
    required this.commission,
    required this.commissionType,
    required this.storage,
    this.storageNote,
    required this.returnDeduction,
    this.returnNote,
    required this.advanceAdjusted,
    required this.other,
    this.otherNote,
  });

  factory SaleDeductions.fromJson(Map<String, dynamic> j) {
    double toD(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
    return SaleDeductions(
      transport: toD(j['transport']),
      labour: toD(j['labour']),
      commission: toD(j['commission']),
      commissionType: j['commissionType']?.toString() ?? 'fixed',
      storage: toD(j['storage']),
      storageNote: j['storageNote']?.toString(),
      returnDeduction: toD(j['returnDeduction']),
      returnNote: j['returnNote']?.toString(),
      advanceAdjusted: toD(j['advanceAdjusted']),
      other: toD(j['other']),
      otherNote: j['otherNote']?.toString(),
    );
  }

  double get total =>
      transport + labour + commission + storage + returnDeduction + advanceAdjusted + other;
}

// ── Summary (for list screen) ─────────────────────────────────
class SaleSummary {
  final int totalCount;
  final double totalRevenue;
  final double totalReceived;
  final double totalDue;
  final double totalGst;

  const SaleSummary({
    required this.totalCount,
    required this.totalRevenue,
    required this.totalReceived,
    required this.totalDue,
    required this.totalGst,
  });

  factory SaleSummary.fromJson(Map<String, dynamic> j) {
    double toD(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
    return SaleSummary(
      totalCount: (j['totalCount'] as num?)?.toInt() ?? 0,
      totalRevenue: toD(j['totalRevenue']),
      totalReceived: toD(j['totalReceived']),
      totalDue: toD(j['totalDue']),
      totalGst: toD(j['totalGst']),
    );
  }

  factory SaleSummary.fromSales(List<SaleModel> sales) {
    return SaleSummary(
      totalCount: sales.length,
      totalRevenue: sales.fold(0, (s, e) => s + e.finalReceivable),
      totalReceived: sales.fold(0, (s, e) => s + e.amountReceived),
      totalDue: sales.fold(0, (s, e) => s + e.amountDue),
      totalGst: sales.fold(0, (s, e) => s + e.gstAmount),
    );
  }
}

// ── Invoice Data (for PDF / print screen) ────────────────────
class SalesInvoiceData {
  final String id;
  final String invoiceNumber;
  final String buyerName;
  final String? buyerMobile;
  final String? buyerGst;
  final String? buyerAddress;
  final DateTime saleDate;
  final List<SaleLine> lines;
  final double grossTotal;
  final double totalDeductions;
  final double finalReceivable;
  final double amountReceived;
  final double amountDue;
  final String status;
  final double subTotal;
  final double gstPercent;
  final double gstAmount;
  final double grandTotal;
  final String paymentMode;
  final String? referenceNumber;
  final String? notes;
  final SaleDeductions? deductions;
  final Map<String, dynamic>? createdBy;
  final DateTime createdAt;

  SalesInvoiceData({
    required this.id,
    required this.invoiceNumber,
    required this.buyerName,
    this.buyerMobile,
    this.buyerGst,
    this.buyerAddress,
    required this.saleDate,
    required this.lines,
    required this.grossTotal,
    required this.totalDeductions,
    required this.finalReceivable,
    required this.amountReceived,
    required this.amountDue,
    required this.status,
    required this.subTotal,
    required this.gstPercent,
    required this.gstAmount,
    required this.grandTotal,
    required this.paymentMode,
    this.referenceNumber,
    this.notes,
    this.deductions,
    this.createdBy,
    required this.createdAt,
  });

  factory SalesInvoiceData.fromJson(Map<String, dynamic> j) {
    double toD(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
    return SalesInvoiceData(
      id: j['_id']?.toString() ?? '',
      invoiceNumber: j['invoiceNumber']?.toString() ?? '',
      buyerName: j['buyerName']?.toString() ?? '',
      buyerMobile: j['buyerMobile']?.toString(),
      buyerGst: j['buyerGst']?.toString(),
      buyerAddress: j['buyerAddress']?.toString(),
      saleDate:
          DateTime.tryParse(j['saleDate']?.toString() ?? '') ?? DateTime.now(),
      lines: (j['lines'] as List? ?? [])
          .map((e) => SaleLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      grossTotal: toD(j['grossTotal']),
      totalDeductions: toD(j['totalDeductions']),
      finalReceivable: toD(j['finalReceivable']),
      amountReceived: toD(j['amountReceived']),
      amountDue: toD(j['amountDue']),
      status: j['status']?.toString() ?? 'pending',
      subTotal: toD(j['subTotal']),
      gstPercent: toD(j['gstPercent']),
      gstAmount: toD(j['gstAmount']),
      grandTotal: toD(j['grandTotal']),
      paymentMode: j['paymentMode']?.toString() ?? 'cash',
      referenceNumber: j['referenceNumber']?.toString(),
      notes: j['notes']?.toString(),
      deductions: j['deductions'] != null
          ? SaleDeductions.fromJson(j['deductions'] as Map<String, dynamic>)
          : null,
      createdBy:
          j['createdBy'] is Map ? j['createdBy'] as Map<String, dynamic> : null,
      createdAt:
          DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Convenience: build from SaleModel
  factory SalesInvoiceData.fromSaleModel(SaleModel m) => SalesInvoiceData(
        id: m.id,
        invoiceNumber: m.invoiceNumber,
        buyerName: m.buyerName,
        buyerMobile: m.buyerMobile,
        buyerGst: m.buyerGst,
        buyerAddress: m.buyerAddress,
        saleDate: m.saleDate,
        lines: m.lines,
        grossTotal: m.grossTotal,
        totalDeductions: m.totalDeductions,
        finalReceivable: m.finalReceivable,
        amountReceived: m.amountReceived,
        amountDue: m.amountDue,
        status: m.status,
        subTotal: m.subTotal,
        gstPercent: m.gstPercent,
        gstAmount: m.gstAmount,
        grandTotal: m.grandTotal,
        paymentMode: m.paymentMode,
        referenceNumber: m.referenceNumber,
        notes: m.notes,
        deductions: m.deductions,
        createdBy: m.createdBy,
        createdAt: m.createdAt,
      );
}
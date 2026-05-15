// ─────────────────────────────────────────────────────────────
//  SALE PAYMENT MODEL
//  Matches POST /api/sale-payments and GET /api/sale-payments
// ─────────────────────────────────────────────────────────────

class SalePayment {
  final String id;
  final String saleId;
  final String? buyerId;
  final double amount;
  final String paymentMode;       // cash | upi | bank | cheque | credit
  final String? referenceNumber;
  final DateTime paymentDate;
  final String? chequeNumber;
  final DateTime? chequeDate;
  final String? bankName;
  final String? chequeStatus;     // null | pending | cleared | bounced
  final String? notes;
  final SalePaymentSaleSummary? sale;
  final SalePaymentBuyer? buyer;
  final SalePaymentCreatedBy? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SalePayment({
    required this.id,
    required this.saleId,
    this.buyerId,
    required this.amount,
    required this.paymentMode,
    this.referenceNumber,
    required this.paymentDate,
    this.chequeNumber,
    this.chequeDate,
    this.bankName,
    this.chequeStatus,
    this.notes,
    this.sale,
    this.buyer,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SalePayment.fromJson(Map<String, dynamic> json) {
    // Handle both flat list response (_id) and detail response (id)
    final id = json['_id'] ?? json['id'] ?? '';

    // sale can be a String (id only) or a Map (populated)
    SalePaymentSaleSummary? sale;
    final saleRaw = json['sale'];
    String saleId = '';
    if (saleRaw is Map<String, dynamic>) {
      sale = SalePaymentSaleSummary.fromJson(saleRaw);
      saleId = sale.id;
    } else if (saleRaw is String) {
      saleId = saleRaw;
    }

    // buyer can be null, String, or Map
    SalePaymentBuyer? buyer;
    final buyerRaw = json['buyer'];
    String? buyerId;
    if (buyerRaw is Map<String, dynamic>) {
      buyer = SalePaymentBuyer.fromJson(buyerRaw);
      buyerId = buyer.id;
    } else if (buyerRaw is String) {
      buyerId = buyerRaw;
    }

    // createdBy can be a String or Map
    SalePaymentCreatedBy? createdBy;
    final createdByRaw = json['createdBy'];
    if (createdByRaw is Map<String, dynamic>) {
      createdBy = SalePaymentCreatedBy.fromJson(createdByRaw);
    }

    return SalePayment(
      id: id,
      saleId: saleId,
      buyerId: buyerId,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentMode: json['paymentMode'] ?? 'cash',
      referenceNumber: _nullableString(json['referenceNumber']),
      paymentDate:
          DateTime.tryParse(json['paymentDate'] ?? '') ?? DateTime.now(),
      chequeNumber: _nullableString(json['chequeNumber']),
      chequeDate: json['chequeDate'] != null
          ? DateTime.tryParse(json['chequeDate'])
          : null,
      bankName: _nullableString(json['bankName']),
      chequeStatus: _nullableString(json['chequeStatus']),
      notes: _nullableString(json['notes']),
      sale: sale,
      buyer: buyer,
      createdBy: createdBy,
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  static String? _nullableString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}

// ── Nested: Sale summary inside a payment ────────────────────
class SalePaymentSaleSummary {
  final String id;
  final String invoiceNumber;
  final double finalReceivable;
  final double amountDue;

  const SalePaymentSaleSummary({
    required this.id,
    required this.invoiceNumber,
    required this.finalReceivable,
    required this.amountDue,
  });

  factory SalePaymentSaleSummary.fromJson(Map<String, dynamic> json) {
    return SalePaymentSaleSummary(
      id: json['_id'] ?? json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      finalReceivable:
          (json['finalReceivable'] as num?)?.toDouble() ?? 0,
      amountDue: (json['amountDue'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ── Nested: Buyer summary inside a payment ───────────────────
class SalePaymentBuyer {
  final String id;
  final String name;
  final String? mobile;
  final String? businessName;

  const SalePaymentBuyer({
    required this.id,
    required this.name,
    this.mobile,
    this.businessName,
  });

  factory SalePaymentBuyer.fromJson(Map<String, dynamic> json) {
    return SalePaymentBuyer(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'],
      businessName: json['businessName'],
    );
  }
}

// ── Nested: CreatedBy inside a payment ───────────────────────
class SalePaymentCreatedBy {
  final String id;
  final String name;
  final String email;

  const SalePaymentCreatedBy({
    required this.id,
    required this.name,
    required this.email,
  });

  factory SalePaymentCreatedBy.fromJson(Map<String, dynamic> json) {
    return SalePaymentCreatedBy(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

// ── POST response: ledger summary returned after recording ───
class PaymentLedgerSummary {
  final double buyerDebit;
  final double buyerCredit;
  final double buyerBalance;
  final double operatorDebit;
  final double operatorCredit;
  final double operatorBalance;

  const PaymentLedgerSummary({
    required this.buyerDebit,
    required this.buyerCredit,
    required this.buyerBalance,
    required this.operatorDebit,
    required this.operatorCredit,
    required this.operatorBalance,
  });

  factory PaymentLedgerSummary.fromJson(Map<String, dynamic> json) {
    final buyer = json['buyer'] as Map<String, dynamic>? ?? {};
    final operator = json['operator'] as Map<String, dynamic>? ?? {};
    return PaymentLedgerSummary(
      buyerDebit: (buyer['debit'] as num?)?.toDouble() ?? 0,
      buyerCredit: (buyer['credit'] as num?)?.toDouble() ?? 0,
      buyerBalance: (buyer['balance'] as num?)?.toDouble() ?? 0,
      operatorDebit: (operator['debit'] as num?)?.toDouble() ?? 0,
      operatorCredit: (operator['credit'] as num?)?.toDouble() ?? 0,
      operatorBalance: (operator['balance'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ── POST response: sale status after payment ─────────────────
class PaymentSaleStatus {
  final String id;
  final String invoiceNumber;
  final double amountReceived;
  final double amountDue;
  final String status;  // paid | partial | unpaid

  const PaymentSaleStatus({
    required this.id,
    required this.invoiceNumber,
    required this.amountReceived,
    required this.amountDue,
    required this.status,
  });

  factory PaymentSaleStatus.fromJson(Map<String, dynamic> json) {
    return PaymentSaleStatus(
      id: json['id'] ?? json['_id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      amountReceived: (json['amountReceived'] as num?)?.toDouble() ?? 0,
      amountDue: (json['amountDue'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? 'unpaid',
    );
  }
}

// ── Full POST /api/sale-payments response data ────────────────
class RecordPaymentResponse {
  final String id;
  final double amount;
  final String paymentMode;
  final String? referenceNumber;
  final DateTime paymentDate;
  final PaymentSaleStatus sale;
  final PaymentLedgerSummary? ledgerSummary;

  const RecordPaymentResponse({
    required this.id,
    required this.amount,
    required this.paymentMode,
    this.referenceNumber,
    required this.paymentDate,
    required this.sale,
    this.ledgerSummary,
  });

  factory RecordPaymentResponse.fromJson(Map<String, dynamic> json) {
    return RecordPaymentResponse(
      id: json['id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentMode: json['paymentMode'] ?? 'cash',
      referenceNumber: json['referenceNumber'],
      paymentDate:
          DateTime.tryParse(json['paymentDate'] ?? '') ?? DateTime.now(),
      sale: PaymentSaleStatus.fromJson(
          json['sale'] as Map<String, dynamic>? ?? {}),
      ledgerSummary: json['ledgerSummary'] != null
          ? PaymentLedgerSummary.fromJson(
              json['ledgerSummary'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ── Paginated list response ───────────────────────────────────
class SalePaymentListResponse {
  final List<SalePayment> payments;
  final SalePaymentSummary summary;
  final int page;
  final int limit;
  final int total;
  final int pages;

  const SalePaymentListResponse({
    required this.payments,
    required this.summary,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory SalePaymentListResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return SalePaymentListResponse(
      payments: dataList
          .map((e) => SalePayment.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: SalePaymentSummary.fromJson(
          json['summary'] as Map<String, dynamic>? ?? {}),
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      limit: (pagination['limit'] as num?)?.toInt() ?? 20,
      total: (pagination['total'] as num?)?.toInt() ?? 0,
      pages: (pagination['pages'] as num?)?.toInt() ?? 1,
    );
  }
}

class SalePaymentSummary {
  final double totalAmount;
  final int totalPayments;
  final double avgAmount;

  const SalePaymentSummary({
    required this.totalAmount,
    required this.totalPayments,
    required this.avgAmount,
  });

  factory SalePaymentSummary.fromJson(Map<String, dynamic> json) {
    return SalePaymentSummary(
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      totalPayments: (json['totalPayments'] as num?)?.toInt() ?? 0,
      avgAmount: (json['avgAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ── Generic result wrapper ────────────────────────────────────
class PaymentResult<T> {
  final bool isSuccess;
  final T? data;
  final String? message;

  const PaymentResult._({
    required this.isSuccess,
    this.data,
    this.message,
  });

  factory PaymentResult.success({required T data}) =>
      PaymentResult._(isSuccess: true, data: data);

  factory PaymentResult.failure({required String message}) =>
      PaymentResult._(isSuccess: false, message: message);
}
// lib/models/ledger_models.dart
// No json_annotation required

// ------------------- Common Models -------------------
class OperatorInfo {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;

  OperatorInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  factory OperatorInfo.fromJson(Map<String, dynamic> json) => OperatorInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        role: json['role'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
      };
}

class FinancialSummary {
  final double totalSales;
  final double totalPurchases;
  final double totalExpenses;
  final double totalPaymentsToFarmers;
  final double totalAdvancesGiven;
  final double totalAdvancesAdjusted;
  final double netAdvances;
  final double grossProfit;
  final double netProfit;
  final int totalTransactionCount;

  FinancialSummary({
    required this.totalSales,
    required this.totalPurchases,
    required this.totalExpenses,
    required this.totalPaymentsToFarmers,
    required this.totalAdvancesGiven,
    required this.totalAdvancesAdjusted,
    required this.netAdvances,
    required this.grossProfit,
    required this.netProfit,
    required this.totalTransactionCount,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) => FinancialSummary(
        totalSales: _toDouble(json['totalSales']),
        totalPurchases: _toDouble(json['totalPurchases']),
        totalExpenses: _toDouble(json['totalExpenses']),
        totalPaymentsToFarmers: _toDouble(json['totalPaymentsToFarmers']),
        totalAdvancesGiven: _toDouble(json['totalAdvancesGiven']),
        totalAdvancesAdjusted: _toDouble(json['totalAdvancesAdjusted']),
        netAdvances: _toDouble(json['netAdvances']),
        grossProfit: _toDouble(json['grossProfit']),
        netProfit: _toDouble(json['netProfit']),
        totalTransactionCount: (json['totalTransactionCount'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'totalSales': totalSales,
        'totalPurchases': totalPurchases,
        'totalExpenses': totalExpenses,
        'totalPaymentsToFarmers': totalPaymentsToFarmers,
        'totalAdvancesGiven': totalAdvancesGiven,
        'totalAdvancesAdjusted': totalAdvancesAdjusted,
        'netAdvances': netAdvances,
        'grossProfit': grossProfit,
        'netProfit': netProfit,
        'totalTransactionCount': totalTransactionCount,
      };
}

class FarmerReference {
  final String id;
  final String name;
  final String mobile;

  FarmerReference({required this.id, required this.name, required this.mobile});

  factory FarmerReference.fromJson(Map<String, dynamic> json) => FarmerReference(
        id: json['id'] as String,
        name: json['name'] as String,
        mobile: json['mobile'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'mobile': mobile};
}

class LedgerTransaction {
  final String id;
  final FarmerReference? farmer;
  final DateTime entryDate;
  final String entryType; // payment, purchase, advance_given, sale, expense
  final String description;
  final double debit;
  final double credit;
  final double runningBalance;
  final String? refId;
  final String? refModel;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? referenceNumber;

  LedgerTransaction({
    required this.id,
    this.farmer,
    required this.entryDate,
    required this.entryType,
    required this.description,
    required this.debit,
    required this.credit,
    required this.runningBalance,
    this.refId,
    this.refModel,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.referenceNumber,
  });

  factory LedgerTransaction.fromJson(Map<String, dynamic> json) {
    return LedgerTransaction(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      farmer: json['farmer'] != null ? FarmerReference.fromJson(json['farmer']) : null,
      entryDate: DateTime.tryParse(json['entryDate']?.toString() ?? '') ?? DateTime.now(),
      entryType: json['entryType'] as String? ?? '',
      description: json['description'] as String? ?? '',
      debit: _toDouble(json['debit']),
      credit: _toDouble(json['credit']),
      runningBalance: _toDouble(json['runningBalance']),
      refId: json['refId'] as String?,
      refModel: json['refModel'] as String?,
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      referenceNumber: json['referenceNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'farmer': farmer?.toJson(),
        'entryDate': entryDate.toIso8601String(),
        'entryType': entryType,
        'description': description,
        'debit': debit,
        'credit': credit,
        'runningBalance': runningBalance,
        'refId': refId,
        'refModel': refModel,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'referenceNumber': referenceNumber,
      };
}

// ------------------- All Operators Response -------------------
class OperatorLedgerItem {
  final OperatorInfo operator;
  final Map<String, dynamic> period;
  final FinancialSummary financialSummary;
  final List<LedgerTransaction> recentTransactions;
  final int transactionCount;

  OperatorLedgerItem({
    required this.operator,
    required this.period,
    required this.financialSummary,
    required this.recentTransactions,
    required this.transactionCount,
  });

  factory OperatorLedgerItem.fromJson(Map<String, dynamic> json) => OperatorLedgerItem(
        operator: OperatorInfo.fromJson(json['operator']),
        period: json['period'] as Map<String, dynamic>? ?? {},
        financialSummary: FinancialSummary.fromJson(json['financialSummary']),
        recentTransactions: (json['recentTransactions'] as List?)
                ?.map((e) => LedgerTransaction.fromJson(e))
                .toList() ??
            [],
        transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'operator': operator.toJson(),
        'period': period,
        'financialSummary': financialSummary.toJson(),
        'recentTransactions': recentTransactions.map((e) => e.toJson()).toList(),
        'transactionCount': transactionCount,
      };
}

class OperatorsLedgerSummary {
  final int totalOperators;
  final double totalSales;
  final double totalPurchases;
  final double totalExpenses;
  final double totalPayments;
  final double totalAdvancesGiven;
  final double totalNetAdvances;
  final double totalGrossProfit;
  final double totalNetProfit;
  final int totalTransactions;
  final double averageProfitPerOperator;

  OperatorsLedgerSummary({
    required this.totalOperators,
    required this.totalSales,
    required this.totalPurchases,
    required this.totalExpenses,
    required this.totalPayments,
    required this.totalAdvancesGiven,
    required this.totalNetAdvances,
    required this.totalGrossProfit,
    required this.totalNetProfit,
    required this.totalTransactions,
    required this.averageProfitPerOperator,
  });

  factory OperatorsLedgerSummary.fromJson(Map<String, dynamic> json) => OperatorsLedgerSummary(
        totalOperators: (json['totalOperators'] as num?)?.toInt() ?? 0,
        totalSales: _toDouble(json['totalSales']),
        totalPurchases: _toDouble(json['totalPurchases']),
        totalExpenses: _toDouble(json['totalExpenses']),
        totalPayments: _toDouble(json['totalPayments']),
        totalAdvancesGiven: _toDouble(json['totalAdvancesGiven']),
        totalNetAdvances: _toDouble(json['totalNetAdvances']),
        totalGrossProfit: _toDouble(json['totalGrossProfit']),
        totalNetProfit: _toDouble(json['totalNetProfit']),
        totalTransactions: (json['totalTransactions'] as num?)?.toInt() ?? 0,
        averageProfitPerOperator: _toDouble(json['averageProfitPerOperator']),
      );

  Map<String, dynamic> toJson() => {
        'totalOperators': totalOperators,
        'totalSales': totalSales,
        'totalPurchases': totalPurchases,
        'totalExpenses': totalExpenses,
        'totalPayments': totalPayments,
        'totalAdvancesGiven': totalAdvancesGiven,
        'totalNetAdvances': totalNetAdvances,
        'totalGrossProfit': totalGrossProfit,
        'totalNetProfit': totalNetProfit,
        'totalTransactions': totalTransactions,
        'averageProfitPerOperator': averageProfitPerOperator,
      };
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;
  final bool hasNext;
  final bool hasPrev;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) => PaginationInfo(
        page: (json['page'] as num?)?.toInt() ?? 1,
        limit: (json['limit'] as num?)?.toInt() ?? 20,
        total: (json['total'] as num?)?.toInt() ?? 0,
        pages: (json['pages'] as num?)?.toInt() ?? 1,
        hasNext: json['hasNext'] as bool? ?? false,
        hasPrev: json['hasPrev'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'page': page,
        'limit': limit,
        'total': total,
        'pages': pages,
        'hasNext': hasNext,
        'hasPrev': hasPrev,
      };
}

class AllOperatorsLedgerData {
  final Map<String, dynamic> period;
  final Map<String, dynamic> filters;
  final List<OperatorLedgerItem> operators;
  final OperatorsLedgerSummary summary;
  final PaginationInfo pagination;

  AllOperatorsLedgerData({
    required this.period,
    required this.filters,
    required this.operators,
    required this.summary,
    required this.pagination,
  });

  factory AllOperatorsLedgerData.fromJson(Map<String, dynamic> json) => AllOperatorsLedgerData(
        period: json['period'] as Map<String, dynamic>? ?? {},
        filters: json['filters'] as Map<String, dynamic>? ?? {},
        operators: (json['operators'] as List?)?.map((e) => OperatorLedgerItem.fromJson(e)).toList() ?? [],
        summary: OperatorsLedgerSummary.fromJson(json['summary']),
        pagination: PaginationInfo.fromJson(json['pagination']),
      );

  Map<String, dynamic> toJson() => {
        'period': period,
        'filters': filters,
        'operators': operators.map((e) => e.toJson()).toList(),
        'summary': summary.toJson(),
        'pagination': pagination.toJson(),
      };
}

class AllOperatorsLedgerResponse {
  final bool success;
  final AllOperatorsLedgerData data;

  AllOperatorsLedgerResponse({required this.success, required this.data});

  factory AllOperatorsLedgerResponse.fromJson(Map<String, dynamic> json) => AllOperatorsLedgerResponse(
        success: json['success'] as bool? ?? false,
        data: AllOperatorsLedgerData.fromJson(json['data']),
      );

  Map<String, dynamic> toJson() => {'success': success, 'data': data.toJson()};
}

// ------------------- Single Operator Ledger Response -------------------
class SingleOperatorLedgerSummary {
  final double totalSales;
  final double totalPurchases;
  final double totalExpenses;
  final double totalPaymentsToFarmers;
  final double netProfit;
  final int transactionCount;

  SingleOperatorLedgerSummary({
    required this.totalSales,
    required this.totalPurchases,
    required this.totalExpenses,
    required this.totalPaymentsToFarmers,
    required this.netProfit,
    required this.transactionCount,
  });

  factory SingleOperatorLedgerSummary.fromJson(Map<String, dynamic> json) => SingleOperatorLedgerSummary(
        totalSales: _toDouble(json['totalSales']),
        totalPurchases: _toDouble(json['totalPurchases']),
        totalExpenses: _toDouble(json['totalExpenses']),
        totalPaymentsToFarmers: _toDouble(json['totalPaymentsToFarmers']),
        netProfit: _toDouble(json['netProfit']),
        transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'totalSales': totalSales,
        'totalPurchases': totalPurchases,
        'totalExpenses': totalExpenses,
        'totalPaymentsToFarmers': totalPaymentsToFarmers,
        'netProfit': netProfit,
        'transactionCount': transactionCount,
      };
}

class SingleOperatorLedgerData {
  final OperatorInfo operator;
  final Map<String, dynamic> period;
  final SingleOperatorLedgerSummary summary;
  final List<LedgerTransaction> transactions;
  final PaginationInfo pagination;

  SingleOperatorLedgerData({
    required this.operator,
    required this.period,
    required this.summary,
    required this.transactions,
    required this.pagination,
  });

  factory SingleOperatorLedgerData.fromJson(Map<String, dynamic> json) => SingleOperatorLedgerData(
        operator: OperatorInfo.fromJson(json['operator']),
        period: json['period'] as Map<String, dynamic>? ?? {},
        summary: SingleOperatorLedgerSummary.fromJson(json['summary']),
        transactions: (json['transactions'] as List?)?.map((e) => LedgerTransaction.fromJson(e)).toList() ?? [],
        pagination: PaginationInfo.fromJson(json['pagination']),
      );

  Map<String, dynamic> toJson() => {
        'operator': operator.toJson(),
        'period': period,
        'summary': summary.toJson(),
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'pagination': pagination.toJson(),
      };
}

class SingleOperatorLedgerResponse {
  final bool success;
  final SingleOperatorLedgerData data;

  SingleOperatorLedgerResponse({required this.success, required this.data});

  factory SingleOperatorLedgerResponse.fromJson(Map<String, dynamic> json) => SingleOperatorLedgerResponse(
        success: json['success'] as bool? ?? false,
        data: SingleOperatorLedgerData.fromJson(json['data']),
      );

  Map<String, dynamic> toJson() => {'success': success, 'data': data.toJson()};
}

// Helper
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
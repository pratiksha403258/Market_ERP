import 'package:dio/dio.dart';
import '../services/dio_client.dart';

class ExpenseService {
  ExpenseService._();
  static final ExpenseService instance = ExpenseService._();

  final Dio _dio = DioClient.instance.dio;
  static const String _base = '/expenses';

  // ── CREATE ────────────────────────────────────────────────────
  Future<ExpenseResult<Map<String, dynamic>>> createExpense({
    required String category,
    required double amount,
    required String description,
    required DateTime expenseDate,
    required String paidBy,
    String? paidTo,
    String? referenceNumber,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{
        'category': category,
        'amount': amount,
        'description': description.trim(),
        'expenseDate': expenseDate.toIso8601String().split('T')[0],
        'paidBy': paidBy,
        if (paidTo != null && paidTo.isNotEmpty) 'paidTo': paidTo.trim(),
        if (referenceNumber != null && referenceNumber.isNotEmpty) 'referenceNumber': referenceNumber.trim(),
        if (notes != null && notes.isNotEmpty) 'notes': notes.trim(),
      };

      final res = await _dio.post(_base, data: payload);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return ExpenseResult.success(data: data['data'] ?? data);
        }
        return ExpenseResult.failure(message: data['message']?.toString() ?? 'Failed to create expense');
      }
      return ExpenseResult.failure(message: 'Server error (${res.statusCode})');
    } on DioException catch (e) {
      return ExpenseResult.failure(message: _parseDioError(e));
    }
  }

  // ── UPDATE ────────────────────────────────────────────────────
  Future<ExpenseResult<Map<String, dynamic>>> updateExpense({
    required String id,
    String? category,
    double? amount,
    String? description,
    DateTime? expenseDate,
    String? paidBy,
    String? paidTo,
    String? referenceNumber,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (category != null) payload['category'] = category;
      if (amount != null) payload['amount'] = amount;
      if (description != null) payload['description'] = description.trim();
      if (expenseDate != null) payload['expenseDate'] = expenseDate.toIso8601String().split('T')[0];
      if (paidBy != null) payload['paidBy'] = paidBy;
      if (paidTo != null && paidTo.isNotEmpty) payload['paidTo'] = paidTo.trim();
      if (referenceNumber != null && referenceNumber.isNotEmpty) payload['referenceNumber'] = referenceNumber.trim();
      if (notes != null && notes.isNotEmpty) payload['notes'] = notes.trim();

      final res = await _dio.put('$_base/$id', data: payload);
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return ExpenseResult.success(data: data['data'] ?? data);
        }
        return ExpenseResult.failure(message: data['message']?.toString() ?? 'Failed to update expense');
      }
      return ExpenseResult.failure(message: 'Server error (${res.statusCode})');
    } on DioException catch (e) {
      return ExpenseResult.failure(message: _parseDioError(e));
    }
  }

  // ── GET LIST (using 'status' query param) ─────────────────────
  Future<ExpenseResult<ExpenseListResponse>> getExpenses({
    int page = 1,
    int limit = 20,
    String? category,
    String? status,         // 'created' or 'cancelled'
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (category != null && category != 'all') params['category'] = category;
      if (status != null && status != 'all') params['status'] = status;
      if (startDate != null) params['startDate'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) params['endDate'] = endDate.toIso8601String().split('T')[0];

      final res = await _dio.get(_base, queryParameters: params);
      final data = res.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final rawList = data['data'] as List? ?? [];
        final expenses = rawList.map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>)).toList();
        final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
        return ExpenseResult.success(
          data: ExpenseListResponse(
            expenses: expenses,
            total: (pagination['total'] as num?)?.toInt() ?? expenses.length,
            page: (pagination['page'] as num?)?.toInt() ?? page,
            totalPages: (pagination['pages'] as num?)?.toInt() ?? 1,
          ),
        );
      }
      return ExpenseResult.failure(message: data['message']?.toString() ?? 'Failed to load expenses');
    } on DioException catch (e) {
      return ExpenseResult.failure(message: _parseDioError(e));
    }
  }

  // ── GET SUMMARY ───────────────────────────────────────────────
  Future<ExpenseResult<ExpenseSummaryResponse>> getSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (startDate != null) params['startDate'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) params['endDate'] = endDate.toIso8601String().split('T')[0];

      final res = await _dio.get('$_base/summary', queryParameters: params);
      final data = res.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final d = data['data'] as Map<String, dynamic>;
        final byCategory = (d['byCategory'] as List? ?? [])
            .map((e) => ExpenseCategorySummary.fromJson(e as Map<String, dynamic>))
            .toList();
        return ExpenseResult.success(
          data: ExpenseSummaryResponse(
            byCategory: byCategory,
            grandTotal: (d['grandTotal'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
      return ExpenseResult.failure(message: data['message']?.toString() ?? 'Failed to load summary');
    } on DioException catch (e) {
      return ExpenseResult.failure(message: _parseDioError(e));
    }
  }

  // ── CANCEL ────────────────────────────────────────────────────
Future<ExpenseResult<bool>> cancelExpense(String id, {required String reason}) async {
  try {
    final res = await _dio.patch('$_base/$id/cancel', data: {'reason': reason.trim()});
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        if (data['success'] == true) return ExpenseResult.success(data: true);
        return ExpenseResult.failure(message: data['message']?.toString() ?? 'Cancel failed');
      }
      return ExpenseResult.failure(message: 'Server error (${res.statusCode})');
    } on DioException catch (e) {
      return ExpenseResult.failure(message: _parseDioError(e));
    }
  }

  String _parseDioError(DioException e) {
    if (e.response?.data is Map) {
      final d = e.response!.data as Map;
      return d['message']?.toString() ?? d['error']?.toString() ?? 'Server error';
    }
    if (e.type == DioExceptionType.connectionError) return 'No internet connection.';
    if (e.type == DioExceptionType.connectionTimeout) return 'Connection timed out.';
    return 'Server error. Please try again.';
  }
}

// ── Response Wrappers ─────────────────────────────────────────
class ExpenseResult<T> {
  final bool isSuccess;
  final T? data;
  final String? message;
  const ExpenseResult._({required this.isSuccess, this.data, this.message});
  factory ExpenseResult.success({required T data}) => ExpenseResult._(isSuccess: true, data: data);
  factory ExpenseResult.failure({required String message}) => ExpenseResult._(isSuccess: false, message: message);
}

class ExpenseListResponse {
  final List<ExpenseModel> expenses;
  final int total;
  final int page;
  final int totalPages;
  const ExpenseListResponse({required this.expenses, required this.total, required this.page, required this.totalPages});
}

class ExpenseSummaryResponse {
  final List<ExpenseCategorySummary> byCategory;
  final double grandTotal;
  const ExpenseSummaryResponse({required this.byCategory, required this.grandTotal});
}

// ── EXPENSE MODEL (maps 'status' field) ────────────────────────
class ExpenseModel {
  final String id;
  final String category;
  final double amount;
  final String description;
  final DateTime expenseDate;
  final String paidBy;
  final String paidTo;
  final String referenceNumber;
  final String status;          // "created" or "cancelled"
  final String cancellationReason;
  final Map<String, dynamic>? createdBy;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.expenseDate,
    required this.paidBy,
    required this.paidTo,
    required this.referenceNumber,
    required this.status,
    required this.cancellationReason,
    this.createdBy,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> j) {
    // API returns "status" field (not "approvalStatus")
    final rawStatus = j['status']?.toString() ?? j['approvalStatus']?.toString() ?? 'created';
    return ExpenseModel(
      id:       j['_id']?.toString() ?? j['id']?.toString() ?? '',
      category: j['category']?.toString() ?? '',
      amount:   (j['amount'] as num?)?.toDouble() ?? 0,
      description: j['description']?.toString() ?? '',
      expenseDate: DateTime.tryParse(j['expenseDate']?.toString() ?? '') ?? DateTime.now(),
      paidBy:   j['paidBy']?.toString() ?? '',
      paidTo:   j['paidTo']?.toString() ?? '',
      referenceNumber: j['referenceNumber']?.toString() ?? '',
      status:   rawStatus,
      cancellationReason: j['cancelReason']?.toString() ?? j['cancellationReason']?.toString() ?? '',
      createdBy: j['createdBy'] is Map ? j['createdBy'] as Map<String, dynamic> : null,
      notes:    j['notes']?.toString() ?? '',
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(j['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  String get categoryLabel => ExpenseCategory.labelFor(category);
  bool get isCreated => status == 'created';
  bool get isCancelled => status == 'cancelled';
  bool get canCancel => !isCancelled;          // only created expenses can be cancelled
  String get createdByName => createdBy?['name']?.toString() ?? '';
}

// ── EXPENSE CATEGORY ───────────────────────────────────────────
class ExpenseCategory {
  static const List<Map<String, String>> all = [
    {'value': 'transport_logistics', 'label': 'Transport & Logistics',},
    {'value': 'labour_wages', 'label': 'Labour & Wages',},
    {'value': 'market_fees', 'label': 'Market Fees', },
    {'value': 'storage_cold_chain', 'label': 'Storage & Cold Chain',},
    {'value': 'shop_office', 'label': 'Shop & Office', },
    {'value': 'repairs_maintenance', 'label': 'Repairs & Maintenance',},
    {'value': 'banking_finance', 'label': 'Banking & Finance',},
    {'value': 'marketing_misc', 'label': 'Marketing & Misc', },
  ];

  static String labelFor(String value) =>
      all.firstWhere((c) => c['value'] == value, orElse: () => {'label': value})['label']!;
}

class ExpenseCategorySummary {
  final String category;
  final double total;
  final int count;
  const ExpenseCategorySummary({required this.category, required this.total, required this.count});
  factory ExpenseCategorySummary.fromJson(Map<String, dynamic> j) => ExpenseCategorySummary(
    category: j['_id']?.toString() ?? '',
    total: (j['total'] as num?)?.toDouble() ?? 0,
    count: (j['count'] as num?)?.toInt() ?? 0,
  );
  String get label => ExpenseCategory.labelFor(category);
}
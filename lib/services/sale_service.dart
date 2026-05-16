// ─────────────────────────────────────────────────────────────
//  SALE SERVICE
//  All API calls for Sales module + Profit/Loss
// ─────────────────────────────────────────────────────────────
import 'package:agr_market/models/profit_loss_model.dart';
import 'package:agr_market/models/sale_model.dart';
import 'package:agr_market/services/constant_service.dart';
import 'package:agr_market/services/dio_client.dart';
import 'package:dio/dio.dart';

class SaleService {
  SaleService._();
  static final SaleService instance = SaleService._();
  final Dio _dio = DioClient.instance.dio;

  // ── GET LIST ──────────────────────────────────────────────────
  Future<SaleResult<SaleListResponse>> getSales({
    int page = 1,
    int limit = 20,
    String? status, // pending | partial | paid
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null && status != 'all') params['status'] = status;
      if (startDate != null) {
        params['startDate'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        params['endDate'] = endDate.toIso8601String().split('T')[0];
      }
      if (search != null && search.isNotEmpty) params['search'] = search;

      final res = await _dio.get(
        ApiRoutes.sales,
        queryParameters: params,
        options: Options(validateStatus: (s) => true),
      );

      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        if (data['success'] == true) {
          final rawList = data['data'] as List? ?? [];
          final sales = rawList
              .map((e) => SaleModel.fromJson(e as Map<String, dynamic>))
              .toList();
          final pagination =
              data['pagination'] as Map<String, dynamic>? ?? {};
          final summary = data['summary'] != null
              ? SaleSummary.fromJson(
                  data['summary'] as Map<String, dynamic>)
              : SaleSummary.fromSales(sales);

          return SaleResult.success(
            data: SaleListResponse(
              sales: sales,
              total:
                  (pagination['total'] as num?)?.toInt() ?? sales.length,
              page: (pagination['page'] as num?)?.toInt() ?? page,
              totalPages:
                  (pagination['pages'] as num?)?.toInt() ?? 1,
              summary: summary,
            ),
          );
        }
        return SaleResult.failure(
            message:
                data['message']?.toString() ?? 'Failed to load sales');
      }
      return SaleResult.failure(
          message: 'Server error (${res.statusCode})');
    } on DioException catch (e) {
      return SaleResult.failure(message: _parseError(e));
    }
  }

  // ── CREATE SALE ───────────────────────────────────────────────
  Future<SaleResult<SaleModel>> createSale(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post(
        ApiRoutes.sales,
        data: payload,
        options: Options(validateStatus: (s) => true),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = res.data as Map<String, dynamic>;
        if (body['success'] == true) {
          final d = body['data'] as Map<String, dynamic>? ?? {};
          final minimal = <String, dynamic>{
            '_id': d['id'] ?? d['_id'] ?? '',
            'invoiceNumber': d['invoiceNumber'] ?? '',
            'buyerName': payload['buyerName'] ?? '',
            'saleDate': payload['saleDate'] ?? '',
            'lines': payload['lines'] ?? [],
            'finalReceivable': d['finalReceivable'] ?? 0,
            'amountDue': d['amountDue'] ?? 0,
            'status': d['status'] ?? 'pending',
            'grossTotal': 0,
            'totalDeductions': 0,
            'amountReceived': 0,
            'subTotal': 0,
            'gstPercent': 0,
            'gstAmount': 0,
            'grandTotal': d['finalReceivable'] ?? 0,
            'paymentMode': 'cash',
            'deductions': payload['deductions'],
          };
          return SaleResult.success(data: SaleModel.fromJson(minimal));
        }
        return SaleResult.failure(
            message:
                body['message']?.toString() ?? 'Failed to create sale');
      }
      return SaleResult.failure(message: _extractError(res.data));
    } on DioException catch (e) {
      return SaleResult.failure(message: _parseError(e));
    }
  }

  // ── GET SINGLE SALE ───────────────────────────────────────────
  Future<SaleResult<SaleModel>> getSaleById(String id) async {
    try {
      final res = await _dio.get(
        ApiRoutes.saleById(id),
        options: Options(validateStatus: (s) => true),
      );
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        final saleData = data['data'] ?? data['sale'] ?? data;
        return SaleResult.success(
            data: SaleModel.fromJson(saleData as Map<String, dynamic>));
      }
      return SaleResult.failure(message: 'Sale not found');
    } on DioException catch (e) {
      return SaleResult.failure(message: _parseError(e));
    }
  }

  // ── RECORD PAYMENT ────────────────────────────────────────────
  Future<SaleResult<SaleModel>> recordPayment({
    required String saleId,
    required double amount,
    required String paymentMode,
    String? referenceNumber,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{
        'amount': amount,
        'paymentMode': paymentMode,
        if (referenceNumber != null && referenceNumber.isNotEmpty)
          'referenceNumber': referenceNumber,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final res = await _dio.post(
        ApiRoutes.salePayment(saleId),
        data: payload,
        options: Options(validateStatus: (s) => true),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = res.data as Map<String, dynamic>;
        if (body['success'] == true) {
          final saleData = body['data'] ?? body['sale'] ?? body;
          return SaleResult.success(
              data: SaleModel.fromJson(saleData as Map<String, dynamic>));
        }
        return SaleResult.failure(
            message: body['message']?.toString() ?? 'Payment failed');
      }
      return SaleResult.failure(message: _extractError(res.data));
    } on DioException catch (e) {
      return SaleResult.failure(message: _parseError(e));
    }
  }

  // ── PROFIT/LOSS REPORT ────────────────────────────────────────
  /// Calls GET /api/reports/profit-loss
  /// Response shape:
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "period": { "startDate": "...", "endDate": "..." },
  ///     "totalSales": 3156394,
  ///     "totalPurchases": 14751768,
  ///     "totalExpenses": 33800,
  ///     "grossProfit": -11595374,
  ///     "netProfit": -11629174,
  ///     "profitMargin": "-368.43%"
  ///   }
  /// }
 // ── PROFIT/LOSS REPORT ────────────────────────────────────────
Future<SaleResult<ProfitLossReport>> getProfitLossReport({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  try {
    final start = startDate.toIso8601String().split('T')[0];
    final end = endDate.toIso8601String().split('T')[0];

    final res = await _dio.get(
      ApiRoutes.profitLossReport,
      queryParameters: {'startDate': start, 'endDate': end},
      options: Options(validateStatus: (s) => true),
    );

    if (res.statusCode == 200) {
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final d = body['data'] as Map<String, dynamic>;

        return SaleResult.success(
          data: ProfitLossReport(
            totalSales: (d['totalSales'] as num?)?.toDouble() ?? 0.0,
            totalGstCollected: 0.0,
            netRevenue: (d['totalSales'] as num?)?.toDouble() ?? 0.0,
            totalPurchaseCost: (d['totalPurchases'] as num?)?.toDouble() ?? 0.0,
            totalPurchaseDeductions: 0.0,
            totalExpenses: (d['totalExpenses'] as num?)?.toDouble() ?? 0.0,
            grossProfit: (d['grossProfit'] as num?)?.toDouble() ?? 0.0,
            netProfit: (d['netProfit'] as num?)?.toDouble() ?? 0.0,
            profitMargin: d['profitMargin']?.toString() ?? '0%',
            periodStart: startDate,
            periodEnd: endDate,
          ),
        );
      }
      return SaleResult.failure(
        message: body['message']?.toString() ?? 'Failed to load P&L report'
      );
    }
    return SaleResult.failure(
      message: 'Server error (${res.statusCode})'
    );
  } on DioException catch (e) {
    return SaleResult.failure(message: _parseError(e));
  }
}

  // ── Helpers ───────────────────────────────────────────────────
  String _parseError(DioException e) {
    if (e.response?.data is Map) {
      final d = e.response!.data as Map;
      return d['message']?.toString() ??
          d['error']?.toString() ??
          'Server error';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timed out.';
    }
    return 'Server error. Please try again.';
  }

  String _extractError(dynamic data) {
    if (data is Map) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          data.toString();
    }
    return data?.toString() ?? 'Unknown error';
  }
}

// ── Result Wrapper ────────────────────────────────────────────
class SaleResult<T> {
  final bool isSuccess;
  final T? data;
  final String? message;

  const SaleResult._(
      {required this.isSuccess, this.data, this.message});

  factory SaleResult.success({required T data}) =>
      SaleResult._(isSuccess: true, data: data);
  factory SaleResult.failure({required String message}) =>
      SaleResult._(isSuccess: false, message: message);
}

class SaleListResponse {
  final List<SaleModel> sales;
  final int total;
  final int page;
  final int totalPages;
  final SaleSummary summary;

  const SaleListResponse({
    required this.sales,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.summary,
  });
}
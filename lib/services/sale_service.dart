// ─────────────────────────────────────────────────────────────
//  SALE SERVICE
//  All API calls for Sales module + Profit/Loss
// ─────────────────────────────────────────────────────────────

import 'package:agr_market/models/profitLoss_model.dart';
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
    String? paymentStatus,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (paymentStatus != null && paymentStatus != 'all') {
        params['paymentStatus'] = paymentStatus;
      }
      if (startDate != null) {
        params['startDate'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        params['endDate'] = endDate.toIso8601String().split('T')[0];
      }
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      final res = await _dio.get(
        ApiRoutes.sales,
        queryParameters: params,
        options: Options(validateStatus: (s) => true),
      );

      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        if (data['success'] == true) {
          final rawList = data['data'] as List? ?? [];
          final sales =
              rawList.map((e) => SaleModel.fromJson(e as Map<String, dynamic>)).toList();
          final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
          final summary = data['summary'] != null
              ? SaleSummary.fromJson(data['summary'] as Map<String, dynamic>)
              : SaleSummary.fromSales(sales);

          return SaleResult.success(
            data: SaleListResponse(
              sales: sales,
              total: (pagination['total'] as num?)?.toInt() ?? sales.length,
              page: (pagination['page'] as num?)?.toInt() ?? page,
              totalPages: (pagination['pages'] as num?)?.toInt() ?? 1,
              summary: summary,
            ),
          );
        }
        return SaleResult.failure(
            message: data['message']?.toString() ?? 'Failed to load sales');
      }
      return SaleResult.failure(
          message: 'Server error (${res.statusCode})');
    } on DioException catch (e) {
      return SaleResult.failure(message: _parseError(e));
    }
  }

  // ── CREATE SALE ───────────────────────────────────────────────
  Future<SaleResult<SaleModel>> createSale(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(
        ApiRoutes.sales,
        data: data,
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
            message: body['message']?.toString() ?? 'Failed to create sale');
      }
      return SaleResult.failure(
          message: _extractError(res.data));
    } on DioException catch (e) {
      return SaleResult.failure(message: _parseError(e));
    }
  }

  // ── GET SINGLE SALE ───────────────────────────────────────────
  Future<SaleResult<SaleModel>> getSaleById(String id) async {
    try {
      final res = await _dio.get(ApiRoutes.saleById(id),
          options: Options(validateStatus: (s) => true));
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

  // ── RECORD PAYMENT FOR SALE ───────────────────────────────────
  Future<SaleResult<SaleModel>> recordPayment({
    required String saleId,
    required double amount,
    required String paymentMode, // cash, upi, bank, cheque
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

  // ── GET INVOICE PDF URL ───────────────────────────────────────
  Future<String> getInvoicePdfUrl(String saleId) async {
    final res = await _dio.get(ApiRoutes.saleInvoice(saleId));
    return res.data['pdfUrl']?.toString() ?? '';
  }

  // ── PROFIT/LOSS REPORT ────────────────────────────────────────
  /// Fetches data for all three sides: sales, purchases, expenses
  /// in the given period and computes P&L
  Future<SaleResult<ProfitLossReport>> getProfitLossReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final start = startDate.toIso8601String().split('T')[0];
      final end = endDate.toIso8601String().split('T')[0];

      // 1. Try dedicated P&L endpoint first
      try {
        final plRes = await _dio.get(
          ApiRoutes.profitLossReport,
          queryParameters: {'startDate': start, 'endDate': end},
          options: Options(validateStatus: (s) => true),
        );
        if (plRes.statusCode == 200) {
          final data = plRes.data as Map<String, dynamic>;
          if (data['success'] == true) {
            final d = data['data'] as Map<String, dynamic>;
            final report = ProfitLossReport(
              periodStart: startDate,
              periodEnd: endDate,
              totalSalesRevenue: (d['totalSalesRevenue'] as num?)?.toDouble() ?? 0,
              totalGstCollected: (d['totalGstCollected'] as num?)?.toDouble() ?? 0,
              netRevenue: (d['netRevenue'] as num?)?.toDouble() ?? 0,
              totalPurchaseCost: (d['totalPurchaseCost'] as num?)?.toDouble() ?? 0,
              totalPurchaseDeductions: (d['totalPurchaseDeductions'] as num?)?.toDouble() ?? 0,
              totalExpenses: (d['totalExpenses'] as num?)?.toDouble() ?? 0,
            );
            return SaleResult.success(data: report);
          }
        }
      } catch (_) {
        // Fall through to manual computation
      }

      // 2. Manual computation from separate endpoints
      double salesRevenue = 0, gstCollected = 0;
      double purchaseCost = 0, purchaseDeductions = 0;
      double expenses = 0;

      // Sales
      try {
        final salesRes = await _dio.get(
          ApiRoutes.sales,
          queryParameters: {
            'startDate': start,
            'endDate': end,
            'limit': 1000,
            'page': 1,
          },
          options: Options(validateStatus: (s) => true),
        );
        if (salesRes.statusCode == 200) {
          final salesData = salesRes.data as Map<String, dynamic>;
          // Try summary first
          final summary = salesData['summary'] as Map<String, dynamic>?;
          if (summary != null) {
            salesRevenue = (summary['totalRevenue'] as num?)?.toDouble() ?? 0;
            gstCollected = (summary['totalGst'] as num?)?.toDouble() ?? 0;
          } else {
            // Compute from list
            final rawList = salesData['data'] as List? ?? [];
            for (final s in rawList) {
              salesRevenue += (s['totalAmount'] as num?)?.toDouble() ?? 0;
              gstCollected += (s['gstAmount'] as num?)?.toDouble() ?? 0;
            }
          }
        }
      } catch (_) {}

      // Purchases
      try {
        final purchRes = await _dio.get(
          ApiRoutes.purchases,
          queryParameters: {
            'startDate': start,
            'endDate': end,
            'status': 'saved,partial,paid',
            'limit': 1000,
            'page': 1,
          },
          options: Options(validateStatus: (s) => true),
        );
        if (purchRes.statusCode == 200) {
          final pData = purchRes.data as Map<String, dynamic>;
          final rawList = pData['data'] as List? ?? [];
          for (final p in rawList) {
            // finalPayable = what we owed farmers after deductions
            purchaseCost += (p['finalPayable'] as num?)?.toDouble() ?? 0;
            purchaseDeductions += (p['totalDeductions'] as num?)?.toDouble() ?? 0;
          }
        }
      } catch (_) {}

      // Expenses (approved only)
      try {
        final expRes = await _dio.get(
          ApiRoutes.expenses,
          queryParameters: {
            'startDate': start,
            'endDate': end,
            'approvalStatus': 'approved,auto_approved',
            'limit': 1000,
            'page': 1,
          },
          options: Options(validateStatus: (s) => true),
        );
        if (expRes.statusCode == 200) {
          final eData = expRes.data as Map<String, dynamic>;
          final rawList = eData['data'] as List? ?? [];
          for (final e in rawList) {
            expenses += (e['amount'] as num?)?.toDouble() ?? 0;
          }
        }
      } catch (_) {}

      final netRev = salesRevenue - gstCollected;
      final report = ProfitLossReport(
        periodStart: startDate,
        periodEnd: endDate,
        totalSalesRevenue: salesRevenue,
        totalGstCollected: gstCollected,
        netRevenue: netRev,
        totalPurchaseCost: purchaseCost,
        totalPurchaseDeductions: purchaseDeductions,
        totalExpenses: expenses,
      );

      return SaleResult.success(data: report);
    } catch (e) {
      return SaleResult.failure(message: 'Failed to compute P&L: $e');
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

  const SaleResult._({required this.isSuccess, this.data, this.message});

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
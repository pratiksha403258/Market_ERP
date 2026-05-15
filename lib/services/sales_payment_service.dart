import 'package:agr_market/models/Sale%20payment%20model.dart';
import 'package:agr_market/services/constant_service.dart';
import 'package:agr_market/services/dio_client.dart';
import 'package:dio/dio.dart';

// ─────────────────────────────────────────────────────────────
//  SALE PAYMENT SERVICE
//  POST   /api/sale-payments              → record payment
//  GET    /api/sale-payments              → all payments (paginated)
//  GET    /api/sale-payments/sale/:saleId → payments for a sale
//  GET    /api/sale-payments/:id          → single payment detail
//  PATCH  /api/sale-payments/:id/cheque-status → update cheque status
// ─────────────────────────────────────────────────────────────

class SalePaymentService {
  SalePaymentService._();
  static final SalePaymentService instance = SalePaymentService._();

  final Dio _dio = DioClient.instance.dio;

  // ── RECORD PAYMENT ────────────────────────────────────────
  /// POST /api/sale-payments
  ///
  /// Required: saleId, amount, paymentMode, paymentDate
  /// Optional (mode-dependent):
  ///   upi/bank → referenceNumber
  ///   cheque   → chequeNumber, chequeDate, bankName
  ///   bank     → bankName, referenceNumber
  Future<PaymentResult<RecordPaymentResponse>> recordPayment({
    required String saleId,
    required double amount,
    required String paymentMode,
    required DateTime paymentDate,
    String? referenceNumber,
    String? chequeNumber,
    DateTime? chequeDate,
    String? bankName,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'saleId': saleId,
        'amount': amount,
        'paymentMode': paymentMode,
        'paymentDate': paymentDate.toIso8601String().split('T').first,
      };

      // Conditionally add optional fields (avoid sending null/empty)
      if (referenceNumber != null && referenceNumber.isNotEmpty) {
        body['referenceNumber'] = referenceNumber;
      }
      if (chequeNumber != null && chequeNumber.isNotEmpty) {
        body['chequeNumber'] = chequeNumber;
      }
      if (chequeDate != null) {
        body['chequeDate'] = chequeDate.toIso8601String().split('T').first;
      }
      if (bankName != null && bankName.isNotEmpty) {
        body['bankName'] = bankName;
      }
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      final response = await _dio.post(
        ApiRoutes.salePayments,
        data: body,
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>;

      return PaymentResult.success(
        data: RecordPaymentResponse.fromJson(data),
      );
    } on DioException catch (e) {
      return PaymentResult.failure(message: _parseError(e));
    }
  }

  // ── GET ALL PAYMENTS (paginated) ──────────────────────────
  /// GET /api/sale-payments
  Future<PaymentResult<SalePaymentListResponse>> getAllPayments({
    int page = 1,
    int limit = 20,
    String? buyerId,
    String? paymentMode,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (buyerId != null && buyerId.isNotEmpty) params['buyerId'] = buyerId;
      if (paymentMode != null && paymentMode.isNotEmpty) {
        params['paymentMode'] = paymentMode;
      }
      if (startDate != null) {
        params['startDate'] = startDate.toIso8601String().split('T').first;
      }
      if (endDate != null) {
        params['endDate'] = endDate.toIso8601String().split('T').first;
      }

      final response = await _dio.get(
        ApiRoutes.salePayments,
        queryParameters: params,
      );

      return PaymentResult.success(
        data: SalePaymentListResponse.fromJson(
            response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return PaymentResult.failure(message: _parseError(e));
    }
  }

  // ── GET PAYMENTS FOR A SALE ───────────────────────────────
  /// GET /api/sale-payments/sale/:saleId
  Future<PaymentResult<List<SalePayment>>> getPaymentsForSale(
      String saleId) async {
    try {
      final response = await _dio.get(
        ApiRoutes.salePaymentsBySale(saleId),
      );
      final responseData = response.data as Map<String, dynamic>;
      final dataList = responseData['data'] as List? ?? [];

      final payments = dataList
          .map((e) => SalePayment.fromJson(e as Map<String, dynamic>))
          .toList();

      return PaymentResult.success(data: payments);
    } on DioException catch (e) {
      return PaymentResult.failure(message: _parseError(e));
    }
  }

  // ── GET SINGLE PAYMENT ────────────────────────────────────
  /// GET /api/sale-payments/:id
  Future<PaymentResult<SalePayment>> getPaymentById(String id) async {
    try {
      final response = await _dio.get(ApiRoutes.salePaymentById(id));
      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>;

      return PaymentResult.success(data: SalePayment.fromJson(data));
    } on DioException catch (e) {
      return PaymentResult.failure(message: _parseError(e));
    }
  }

  // ── UPDATE CHEQUE STATUS ──────────────────────────────────
  /// PATCH /api/sale-payments/:id/cheque-status
  /// status: 'pending' | 'cleared' | 'bounced'
  Future<PaymentResult<SalePayment>> updateChequeStatus(
      String id, String status) async {
    try {
      final response = await _dio.patch(
        ApiRoutes.salePaymentChequeStatus(id),
        data: {'status': status},
      );
      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>;

      return PaymentResult.success(data: SalePayment.fromJson(data));
    } on DioException catch (e) {
      return PaymentResult.failure(message: _parseError(e));
    }
  }

  // ── Error Parser ──────────────────────────────────────────
  String _parseError(DioException e) {
    if (e.response?.data is Map) {
      final d = e.response!.data as Map;
      return d['error']?.toString() ??
          d['message']?.toString() ??
          'Server error';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
    return 'Server error. Please try again.';
  }
}
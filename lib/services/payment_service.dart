
import 'package:dio/dio.dart';
import '../models/payment_model.dart';
import 'dio_client.dart';
import 'constant_service.dart';
 
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();
 
  final Dio _dio = DioClient.instance.dio;
 
  /// POST /api/payments
  /// Records payment and auto-updates purchase status (partial/paid)
  Future<PaymentModel> recordPayment(PaymentRequest request) async {
    try {
      final response = await _dio.post(
        ApiRoutes.payments,
        data: request.toJson(),
        options: Options(validateStatus: (s) => true),
      );
 
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          // Payment data may be nested under 'data' or at root
          final paymentData = data['data'] ?? data['payment'] ?? data;
          return PaymentModel.fromJson(paymentData as Map<String, dynamic>);
        }
        throw Exception(data['message']?.toString() ?? data['error']?.toString() ?? 'Payment failed');
      }
 
      // Parse error response
      final errorData = response.data;
      String errorMsg = 'Payment failed (${response.statusCode})';
      if (errorData is Map) {
        errorMsg = errorData['message']?.toString() ??
            errorData['error']?.toString() ??
            errorMsg;
      }
      throw Exception(errorMsg);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }
 
  /// GET /api/payments with filters
  Future<List<PaymentModel>> getPayments({
    String? purchaseId,
    String? farmerId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (purchaseId != null) params['purchaseId'] = purchaseId;
      if (farmerId != null)   params['farmerId'] = farmerId;
 
      final response = await _dio.get(
        ApiRoutes.payments,
        queryParameters: params,
      );
 
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = data['data'] as List? ?? data['payments'] as List? ?? [];
        return list.map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }
 
  String _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data as Map<String, dynamic>?;
      return data?['message']?.toString() ?? data?['error']?.toString() ?? 'Server error';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
    return e.message ?? 'Payment failed';
  }
}
 
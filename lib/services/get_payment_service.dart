import 'package:dio/dio.dart';
import '../models/get_payment_model.dart';
import 'dio_client.dart';
import 'constant_service.dart';

class GetPaymentService {
  GetPaymentService._();
  static final GetPaymentService instance = GetPaymentService._();

  final Dio _dio = DioClient.instance.dio;

  // GET /payments - Get all payments with pagination, search, filters
  Future<GetPaymentListResponse> getPayments({
    int page = 1,
    int limit = 20,
    String? search,
    String? startDate,
    String? endDate,
    double? minAmount,
    double? maxAmount,
    String? paymentMode,
    String? status,
    String? sortBy = 'paymentDate',
    String? sortOrder = 'desc',
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (minAmount != null) 'minAmount': minAmount,
        if (maxAmount != null) 'maxAmount': maxAmount,
        if (paymentMode != null) 'paymentMode': paymentMode,
        if (status != null) 'status': status,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortOrder != null) 'sortOrder': sortOrder,
      };

      final response = await _dio.get(
        ApiRoutes.payments,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final paymentsList = (data['data'] as List? ?? [])
          .map((p) => GetPaymentModel.fromJson(p))
          .toList();
      final summary = data['summary'] != null
          ? GetPaymentSummaryModel.fromJson(data['summary'])
          : null;
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

      return GetPaymentListResponse(
        success: data['success'] ?? true,
        payments: paymentsList,
        summary: summary,
        pagination: GetPaginationInfo(
          page: pagination['page'] as int? ?? page,
          limit: pagination['limit'] as int? ?? limit,
          total: pagination['total'] as int? ?? 0,
          pages: pagination['pages'] as int? ?? 0,
        ),
        businessDetails: data['businessDetails'] as Map<String, dynamic>?,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // GET /payments/due-summary - Get due summary
  Future<GetDueSummaryResponse> getDueSummary({
    String? operatorId,
    int daysOverdue = 30,
  }) async {
    try {
      final queryParams = {
        'daysOverdue': daysOverdue,
        if (operatorId != null && operatorId.isNotEmpty) 'operatorId': operatorId,
      };

      final response = await _dio.get(
        ApiRoutes.paymentDueSummary,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;

      return GetDueSummaryResponse(
        success: data['success'] ?? true,
        dueSummary: GetDueSummaryModel.fromJson(data),
        businessDetails: data['businessDetails'] as Map<String, dynamic>?,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      return data['message']?.toString() ?? data['error']?.toString() ?? 'Server error';
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your network.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

// Response Models
class GetPaymentListResponse {
  final bool success;
  final List<GetPaymentModel> payments;
  final GetPaymentSummaryModel? summary;
  final GetPaginationInfo pagination;
  final Map<String, dynamic>? businessDetails;

  GetPaymentListResponse({
    required this.success,
    required this.payments,
    this.summary,
    required this.pagination,
    this.businessDetails,
  });
}

class GetDueSummaryResponse {
  final bool success;
  final GetDueSummaryModel dueSummary;
  final Map<String, dynamic>? businessDetails;

  GetDueSummaryResponse({
    required this.success,
    required this.dueSummary,
    this.businessDetails,
  });
}

class GetPaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;

  GetPaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });
}
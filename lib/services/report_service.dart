// lib/services/report_service.dart
import 'package:dio/dio.dart';
import 'dio_client.dart';
import 'constant_service.dart';

class ReportService {
  ReportService._();
  static final instance = ReportService._();
  final Dio _dio = DioClient.instance.dio;

  Future<Map<String, dynamic>> getProfitLoss({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _dio.get(
      ApiRoutes.profitLossReport,
      queryParameters: {
        'startDate': startDate.toIso8601String().split('T')[0],
        'endDate': endDate.toIso8601String().split('T')[0],
      },
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getInventorySummary({int days = 90}) async {
    final response = await _dio.get(
      ApiRoutes.inventorySummaryReport,
      queryParameters: {'days': days},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getProductPerformance({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _dio.get(
      ApiRoutes.productPerformanceReport,
      queryParameters: {
        'startDate': startDate.toIso8601String().split('T')[0],
        'endDate': endDate.toIso8601String().split('T')[0],
      },
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getInventoryHistory({
    required String productId,
    String? warehouse,
    DateTime? startDate,
    DateTime? endDate,
    String? movementType,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (warehouse != null) queryParams['warehouse'] = warehouse;
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
    if (movementType != null) queryParams['movementType'] = movementType;

    final response = await _dio.get(
      ApiRoutes.inventoryHistoryReport(productId),
      queryParameters: queryParams,
    );
    return response.data;
  }
}
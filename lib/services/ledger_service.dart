import 'package:agr_market/services/constant_service.dart';
import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../models/ledger_models.dart';


class LedgerService {
  LedgerService._();
  static final LedgerService instance = LedgerService._();

  final Dio _dio = DioClient.instance.dio;

  /// SuperAdmin only: Get all operators ledger with pagination and filters.
  Future<LedgerResult<AllOperatorsLedgerData>> getAllOperatorsLedger({
    DateTime? startDate,
    DateTime? endDate,
    String? operatorId,
    String? search,
    int page = 1,
    int limit = 20,
    String sortBy = 'name',
    String sortOrder = 'asc',
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };
      if (startDate != null) params['startDate'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) params['endDate'] = endDate.toIso8601String().split('T')[0];
      if (operatorId != null && operatorId.isNotEmpty) params['operatorId'] = operatorId;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await _dio.get(
        ApiRoutes.allOperatorsLedger,
        queryParameters: params,
      );
      final json = response.data as Map<String, dynamic>;
      if (json['success'] == true) {
        final data = AllOperatorsLedgerData.fromJson(json['data']);
        return LedgerResult.success(data: data);
      }
      return LedgerResult.failure(message: json['message']?.toString() ?? 'Failed to fetch operators ledger');
    } on DioException catch (e) {
      return LedgerResult.failure(message: _parseDioError(e));
    } catch (e) {
      return LedgerResult.failure(message: e.toString());
    }
  }

  /// Get ledger for a specific operator (operator can view own, SuperAdmin/Operator can view any).
  Future<LedgerResult<SingleOperatorLedgerData>> getOperatorLedger(
    String operatorId, {
    DateTime? startDate,
    DateTime? endDate,
    String? export,   // e.g., '1' to trigger export (if needed)
    int limit = 100,
  }) async {
    try {
      final params = <String, dynamic>{
        'limit': limit,
      };
      if (startDate != null) params['startDate'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) params['endDate'] = endDate.toIso8601String().split('T')[0];
      if (export != null) params['export'] = export;

      final response = await _dio.get(
        ApiRoutes.operatorLedger(operatorId),
        queryParameters: params,
      );
      final json = response.data as Map<String, dynamic>;
      if (json['success'] == true) {
        final data = SingleOperatorLedgerData.fromJson(json['data']);
        return LedgerResult.success(data: data);
      }
      return LedgerResult.failure(message: json['message']?.toString() ?? 'Failed to fetch operator ledger');
    } on DioException catch (e) {
      return LedgerResult.failure(message: _parseDioError(e));
    } catch (e) {
      return LedgerResult.failure(message: e.toString());
    }
  }

  String _parseDioError(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      return data['message']?.toString() ?? data['error']?.toString() ?? 'Server error';
    }
    if (e.type == DioExceptionType.connectionError) return 'No internet connection.';
    if (e.type == DioExceptionType.connectionTimeout) return 'Connection timed out.';
    return 'Server error. Please try again.';
  }
}

/// Generic result wrapper (similar to ExpenseResult)
class LedgerResult<T> {
  final bool isSuccess;
  final T? data;
  final String? message;

  const LedgerResult._({required this.isSuccess, this.data, this.message});

  factory LedgerResult.success({required T data}) => LedgerResult._(isSuccess: true, data: data);
  factory LedgerResult.failure({required String message}) => LedgerResult._(isSuccess: false, message: message);
}
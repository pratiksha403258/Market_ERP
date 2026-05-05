import 'package:agr_market/services/constant_service.dart';
import 'package:agr_market/services/dio_client.dart';
import 'package:dio/dio.dart';
import '../models/farmer_model.dart';


// ─────────────────────────────────────────────────────────────
//  FARMER SERVICE — CRUD API calls
//  GET list, GET by id, POST create, PUT update, DELETE deactivate
// ─────────────────────────────────────────────────────────────

class FarmerService {
  FarmerService._();
  static final FarmerService instance = FarmerService._();

  final Dio _dio = DioClient.instance.dio;

  // ── GET ALL ───────────────────────────────────────────────────
  /// GET /farmers?page=1&limit=20&search=
  Future<FarmerResult<FarmerListResponse>> getFarmers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final response = await _dio.get(
        ApiRoutes.farmers,
        queryParameters: params,
      );
      return FarmerResult.success(
          data: FarmerListResponse.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return FarmerResult.failure(message: _parseError(e));
    }
  }

  // ── GET BY ID ─────────────────────────────────────────────────
  Future<FarmerResult<FarmerModel>> getFarmerById(String id) async {
    try {
      final response = await _dio.get(ApiRoutes.farmerById(id));
      final data = response.data as Map<String, dynamic>;
      final farmerData = data['farmer'] as Map<String, dynamic>? ?? data;
      return FarmerResult.success(data: FarmerModel.fromJson(farmerData));
    } on DioException catch (e) {
      return FarmerResult.failure(message: _parseError(e));
    }
  }

  // ── CREATE ────────────────────────────────────────────────────
  /// POST /farmers
  Future<FarmerResult<FarmerModel>> createFarmer({
    required String name,
    required String mobile,
    String? village,
    String? city,
    String? address,
    String? bankAccountNumber,
    String? ifscCode,
    String? bankName,
    String? gstNumber,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name':   name.trim(),
        'mobile': mobile.trim(),
        if (village != null && village.isNotEmpty) 'village': village.trim(),
        if (city    != null && city.isNotEmpty)    'city':    city.trim(),
        if (address != null && address.isNotEmpty) 'address': address.trim(),
        if (bankAccountNumber != null && bankAccountNumber.isNotEmpty)
          'bankAccountNumber': bankAccountNumber.trim(),
        if (ifscCode != null && ifscCode.isNotEmpty) 'ifscCode': ifscCode.trim().toUpperCase(),
        if (bankName != null && bankName.isNotEmpty) 'bankName': bankName.trim(),
        if (gstNumber != null && gstNumber.isNotEmpty) 'gstNumber': gstNumber.trim().toUpperCase(),
      };
      final response = await _dio.post(ApiRoutes.farmers, data: payload);
      final data = response.data as Map<String, dynamic>;
      final farmerData = data['farmer'] as Map<String, dynamic>? ?? data;
      return FarmerResult.success(data: FarmerModel.fromJson(farmerData));
    } on DioException catch (e) {
      return FarmerResult.failure(message: _parseError(e));
    }
  }

  // ── UPDATE ────────────────────────────────────────────────────
  /// PUT /farmers/:id
  Future<FarmerResult<FarmerModel>> updateFarmer(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.put(ApiRoutes.farmerById(id), data: updates);
      final data = response.data as Map<String, dynamic>;
      final farmerData = data['farmer'] as Map<String, dynamic>? ?? data;
      return FarmerResult.success(data: FarmerModel.fromJson(farmerData));
    } on DioException catch (e) {
      return FarmerResult.failure(message: _parseError(e));
    }
  }

  // ── DELETE (soft) ─────────────────────────────────────────────
  /// DELETE /farmers/:id  (sets isActive=false)
  Future<FarmerResult<bool>> deleteFarmer(String id) async {
    try {
      await _dio.delete(ApiRoutes.farmerById(id));
      return FarmerResult.success(data: true);
    } on DioException catch (e) {
      return FarmerResult.failure(message: _parseError(e));
    }
  }

  // ── Error Parser ──────────────────────────────────────────────
  String _parseError(DioException e) {
    if (e.response?.data is Map) {
      final d = e.response!.data as Map;
      return d['error']?.toString() ?? d['message']?.toString() ?? 'Server error';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
    return 'Server error. Please try again.';
  }
}

// ── Generic Result wrapper ────────────────────────────────────
class FarmerResult<T> {
  final bool isSuccess;
  final T? data;
  final String? message;

  const FarmerResult._({required this.isSuccess, this.data, this.message});

  factory FarmerResult.success({required T data}) =>
      FarmerResult._(isSuccess: true, data: data);
  factory FarmerResult.failure({required String message}) =>
      FarmerResult._(isSuccess: false, message: message);
}
import 'package:agr_market/services/constant_service.dart';
import 'package:agr_market/services/dio_client.dart';
import 'package:dio/dio.dart';
import '../models/buyer_model.dart';

// ─────────────────────────────────────────────────────────────
//  BUYER SERVICE — CRUD API calls
//  GET list, GET by id, POST create, PUT update, DELETE delete
// ─────────────────────────────────────────────────────────────

class BuyerService {
  BuyerService._();
  static final BuyerService instance = BuyerService._();

  final Dio _dio = DioClient.instance.dio;

  // ── CREATE BUYER ─────────────────────────────────────────────
  /// POST /buyers
  Future<BuyerResult<Buyer>> createBuyer(Map<String, dynamic> buyerData) async {
    try {
      final response = await _dio.post(
        ApiRoutes.buyers,
        data: buyerData,
      );
      final data = response.data as Map<String, dynamic>;
      final buyerDataFromResponse = data['data'] as Map<String, dynamic>;
      return BuyerResult.success(data: Buyer.fromJson(buyerDataFromResponse));
    } on DioException catch (e) {
      return BuyerResult.failure(message: _parseError(e));
    }
  }

  // ── GET ALL BUYERS ───────────────────────────────────────────
  /// GET /buyers?page=1&limit=20&search=
  Future<BuyerResult<BuyerListResponse>> getBuyers({
    int page = 1,
    int limit = 20,
    String? search,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    bool? isActive,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        if (search != null && search.isNotEmpty) 'search': search,
        if (isActive != null) 'isActive': isActive,
      };
      final response = await _dio.get(
        ApiRoutes.buyers,
        queryParameters: params,
      );
      return BuyerResult.success(
        data: BuyerListResponse.fromJson(response.data as Map<String, dynamic>)
      );
    } on DioException catch (e) {
      return BuyerResult.failure(message: _parseError(e));
    }
  }

  // ── GET BUYER SUMMARY ────────────────────────────────────────
  /// GET /buyers/summary
  Future<BuyerResult<BuyerSummary>> getBuyerSummary() async {
    try {
      final response = await _dio.get(ApiRoutes.buyersSummary);
      return BuyerResult.success(
        data: BuyerSummary.fromJson(response.data as Map<String, dynamic>)
      );
    } on DioException catch (e) {
      return BuyerResult.failure(message: _parseError(e));
    }
  }

  // ── GET BUYER BY ID ──────────────────────────────────────────
  /// GET /buyers/:id
  Future<BuyerResult<Buyer>> getBuyerById(String id) async {
    try {
      final response = await _dio.get(ApiRoutes.buyerById(id));
      final data = response.data as Map<String, dynamic>;
      final buyerData = data['data'] as Map<String, dynamic>;
      return BuyerResult.success(data: Buyer.fromJson(buyerData));
    } on DioException catch (e) {
      return BuyerResult.failure(message: _parseError(e));
    }
  }

  // ── UPDATE BUYER ─────────────────────────────────────────────
  /// PUT /buyers/:id
  Future<BuyerResult<Buyer>> updateBuyer(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.put(
        ApiRoutes.buyerById(id),
        data: updates,
      );
      final data = response.data as Map<String, dynamic>;
      final buyerData = data['data'] as Map<String, dynamic>;
      return BuyerResult.success(data: Buyer.fromJson(buyerData));
    } on DioException catch (e) {
      return BuyerResult.failure(message: _parseError(e));
    }
  }

  // ── DELETE BUYER ─────────────────────────────────────────────
  /// DELETE /buyers/:id (permanently deletes buyer)
  Future<BuyerResult<bool>> deleteBuyer(String id) async {
    try {
      await _dio.delete(ApiRoutes.buyerById(id));
      return BuyerResult.success(data: true);
    } on DioException catch (e) {
      return BuyerResult.failure(message: _parseError(e));
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
class BuyerResult<T> {
  final bool isSuccess;
  final T? data;
  final String? message;

  const BuyerResult._({required this.isSuccess, this.data, this.message});

  factory BuyerResult.success({required T data}) =>
      BuyerResult._(isSuccess: true, data: data);
  factory BuyerResult.failure({required String message}) =>
      BuyerResult._(isSuccess: false, message: message);
}

// ── Buyer List Response (for paginated responses) ─────────────
class BuyerListResponse {
  final List<Buyer> buyers;
  final int page;
  final int limit;
  final int total;
  final int pages;

  BuyerListResponse({
    required this.buyers,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory BuyerListResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    
    return BuyerListResponse(
      buyers: dataList.map((e) => Buyer.fromJson(e as Map<String, dynamic>)).toList(),
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? 20,
      total: pagination['total'] as int? ?? 0,
      pages: pagination['pages'] as int? ?? 0,
    );
  }
}
import 'package:agr_market/services/constant_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


// ─────────────────────────────────────────────────────────────
//  DIO CLIENT — singleton with auth interceptor
// ─────────────────────────────────────────────────────────────
class DioClient {
  DioClient._();
  static final DioClient _instance = DioClient._();
  static DioClient get instance => _instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(_AppInterceptor(_storage));

  Dio get dio => _dio;

  // Raw Dio for refresh calls (no interceptor loop)
  final Dio _rawDio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  Dio get rawDio => _rawDio;
}

// ─────────────────────────────────────────────────────────────
//  AUTH INTERCEPTOR — attaches token, handles 401 auto-refresh
// ─────────────────────────────────────────────────────────────
class _AppInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  _AppInterceptor(this._storage);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: AppConstants.keyAccessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try refresh
      try {
        final refreshToken =
            await _storage.read(key: AppConstants.keyRefreshToken);
        if (refreshToken != null) {
          final res = await Dio().post(
            '${AppConstants.baseUrl}/auth/refresh',
            data: {'refreshToken': refreshToken},
          );
          final newToken = res.data['accessToken'] as String;
          await _storage.write(
              key: AppConstants.keyAccessToken, value: newToken);
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryRes = await Dio().fetch(err.requestOptions);
          handler.resolve(retryRes);
          return;
        }
      } catch (_) {
        // Refresh failed — clear everything
        await _storage.deleteAll();
      }
    }
    handler.next(err);
  }
}
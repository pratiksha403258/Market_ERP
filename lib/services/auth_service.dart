// import 'package:dio/dio.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// /// ─────────────────────────────────────────
// ///  Auth Service — handles all auth API calls
// ///  and secure token storage
// /// ─────────────────────────────────────────

// class AuthService {
//   AuthService._();
//   static final AuthService instance = AuthService._();

//   static const String _baseUrl = 'http://192.168.1.8:5000/api'; 

//   static const String _keyAccessToken  = 'access_token';
//   static const String _keyRefreshToken = 'refresh_token';
//   static const String _keyUserRole     = 'user_role';
//   static const String _keyUserId       = 'user_id';

//   final _storage = const FlutterSecureStorage(
//     aOptions: AndroidOptions(encryptedSharedPreferences: true),
//   );

//   late final Dio _dio = Dio(
//     BaseOptions(
//       baseUrl: _baseUrl,
//       connectTimeout: const Duration(seconds: 15),
//       receiveTimeout: const Duration(seconds: 15),
//       headers: {'Content-Type': 'application/json'},
//     ),
//   )..interceptors.add(_AuthInterceptor(_storage));

//   // ── LOGIN ─────────────────────────────────
//   /// POST /api/auth/login
//   /// Returns: { access_token, refresh_token, user }
//   Future<AuthResult> login({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       final response = await _dio.post(
//         '/api/auth/login',
//         data: {'email': email, 'password': password},
//       );

//       final data = response.data as Map<String, dynamic>;
//       final accessToken  = data['access_token']  as String;
//       final refreshToken = data['refresh_token'] as String;
//       final user = data['user'] as Map<String, dynamic>;

//       // Store tokens securely
//       await _storage.write(key: _keyAccessToken,  value: accessToken);
//       await _storage.write(key: _keyRefreshToken, value: refreshToken);
//       await _storage.write(key: _keyUserRole,     value: user['role'] as String);
//       await _storage.write(key: _keyUserId,       value: user['id']   as String);

//       return AuthResult.success(user: UserModel.fromJson(user));
//     } on DioException catch (e) {
//       return AuthResult.failure(message: _extractError(e));
//     }
//   }

//   // ── REGISTER ──────────────────────────────
//   /// POST /api/auth/register  (SuperAdmin only)
//   /// Called to create a new vendor account
//   Future<AuthResult> register({
//     required String name,
//     required String email,
//     required String password,
//     required String phone,
//     required String businessName,
//     String role = 'vendor',
//   }) async {
//     try {
//       final response = await _dio.post(
//         '/api/auth/register',
//         data: {
//           'name': name,
//           'email': email,
//           'password': password,
//           'phone': phone,
//           'business_name': businessName,
//           'role': role,
//         },
//       );

//       final data = response.data as Map<String, dynamic>;
//       return AuthResult.success(user: UserModel.fromJson(data['user'] as Map<String, dynamic>));
//     } on DioException catch (e) {
//       return AuthResult.failure(message: _extractError(e));
//     }
//   }

//   // ── LOGOUT ───────────────────────────────
//   /// POST /api/auth/logout
//   Future<void> logout() async {
//     try {
//       final token = await _storage.read(key: _keyRefreshToken);
//       await _dio.post(
//         '/api/auth/logout',
//         data: {'refresh_token': token},
//       );
//     } catch (_) {
//       // Even if API call fails, clear local tokens
//     } finally {
//       await _storage.deleteAll();
//     }
//   }

//   // ── GET ME ───────────────────────────────
//   /// GET /api/auth/me
//   Future<UserModel?> getMe() async {
//     try {
//       final response = await _dio.get('/api/auth/me');
//       return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
//     } catch (_) {
//       return null;
//     }
//   }

//   // ── REFRESH TOKEN ────────────────────────
//   /// POST /api/auth/refresh
//   Future<bool> refreshToken() async {
//     try {
//       final refreshToken = await _storage.read(key: _keyRefreshToken);
//       if (refreshToken == null) return false;

//       final response = await Dio().post(
//         '$_baseUrl/api/auth/refresh',
//         data: {'refresh_token': refreshToken},
//       );

//       final newAccess = response.data['access_token'] as String;
//       await _storage.write(key: _keyAccessToken, value: newAccess);
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }

//   // ── HELPERS ───────────────────────────────
//   Future<String?> getAccessToken() =>
//       _storage.read(key: _keyAccessToken);

//   Future<bool> isLoggedIn() async {
//     final token = await _storage.read(key: _keyAccessToken);
//     return token != null && token.isNotEmpty;
//   }

//   String _extractError(DioException e) {
//     if (e.response?.data is Map) {
//       final data = e.response!.data as Map;
//       return data['message']?.toString() ??
//           data['error']?.toString() ??
//           'Something went wrong';
//     }
//     if (e.type == DioExceptionType.connectionTimeout) {
//       return 'Connection timed out. Check your network.';
//     }
//     if (e.type == DioExceptionType.connectionError) {
//       return 'No internet connection.';
//     }
//     return 'Server error. Please try again.';
//   }
// }

// // ── DIO INTERCEPTOR ───────────────────────
// /// Automatically attaches Bearer token and handles 401 refresh
// class _AuthInterceptor extends Interceptor {
//   final FlutterSecureStorage _storage;

//   _AuthInterceptor(this._storage);

//   @override
//   Future<void> onRequest(
//     RequestOptions options,
//     RequestInterceptorHandler handler,
//   ) async {
//     final token = await _storage.read(key: 'access_token');
//     if (token != null) {
//       options.headers['Authorization'] = 'Bearer $token';
//     }
//     handler.next(options);
//   }

//   @override
//   Future<void> onError(
//     DioException err,
//     ErrorInterceptorHandler handler,
//   ) async {
//     if (err.response?.statusCode == 401) {
//       // Try token refresh
//       final refreshed = await AuthService.instance.refreshToken();
//       if (refreshed) {
//         // Retry original request with new token
//         final token = await _storage.read(key: 'access_token');
//         err.requestOptions.headers['Authorization'] = 'Bearer $token';
//         try {
//           final retryResponse = await Dio().fetch(err.requestOptions);
//           handler.resolve(retryResponse);
//           return;
//         } catch (_) {}
//       }
//       // Refresh failed — clear tokens, force re-login
//       await _storage.deleteAll();
//     }
//     handler.next(err);
//   }
// }

// // ── MODELS ───────────────────────────────

// class UserModel {
//   final String id;
//   final String name;
//   final String email;
//   final String role;
//   final String? phone;
//   final bool isActive;

//   const UserModel({
//     required this.id,
//     required this.name,
//     required this.email,
//     required this.role,
//     this.phone,
//     required this.isActive,
//   });

//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     return UserModel(
//       id:       json['id']         as String,
//       name:     json['name']       as String,
//       email:    json['email']      as String,
//       role:     json['role']       as String,
//       phone:    json['phone']      as String?,
//       isActive: json['is_active']  as bool? ?? true,
//     );
//   }
// }

// class AuthResult {
//   final bool isSuccess;
//   final String? message;
//   final UserModel? user;

//   const AuthResult._({
//     required this.isSuccess,
//     this.message,
//     this.user,
//   });

//   factory AuthResult.success({required UserModel user}) =>
//       AuthResult._(isSuccess: true, user: user);

//   factory AuthResult.failure({required String message}) =>
//       AuthResult._(isSuccess: false, message: message);
// }

import 'package:agr_market/services/constant_service.dart';
import 'package:agr_market/services/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

// ─────────────────────────────────────────────────────────────
//  AUTH SERVICE — all API calls for authentication
//  Login only (no register in app — superadmin created via script)
// ─────────────────────────────────────────────────────────────

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final Dio _dio     = DioClient.instance.dio;
  final _storage     = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── LOGIN ─────────────────────────────────────────────────────
  /// POST /auth/login
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiRoutes.login,
        data: {'email': email.toLowerCase().trim(), 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        return AuthResult.failure(
            message: data['error']?.toString() ?? 'Login failed');
      }

      final accessToken  = data['accessToken']  as String? ?? data['access_token']  as String? ?? '';
      final refreshToken = data['refreshToken'] as String? ?? data['refresh_token'] as String? ?? '';
      final userData     = data['user']         as Map<String, dynamic>;
      final user         = UserModel.fromJson(userData);


 print('🔐 User ID from API: ${user.id}');  // ✅ Debug print
    print('🔐 User Name from API: ${user.name}');  

      // Persist tokens + basic user info securely
      await _storage.write(key: AppConstants.keyAccessToken,  value: accessToken);
      await _storage.write(key: AppConstants.keyRefreshToken, value: refreshToken);
      await _storage.write(key: AppConstants.keyUserId,       value: user.id);
      await _storage.write(key: AppConstants.keyUserRole,     value: user.role);
      await _storage.write(key: AppConstants.keyUserName,     value: user.name);

      final savedUserId = await _storage.read(key: AppConstants.keyUserId);
    print('🔐 Saved User ID to storage: $savedUserId');  // ✅ Debug print

      return AuthResult.success(user: user);
    } on DioException catch (e) {
      return AuthResult.failure(message: _parseError(e));
    } catch (e) {
      return AuthResult.failure(message: 'Unexpected error: $e');
    }
  }

  // ── GET ME ───────────────────────────────────────────────────
  /// GET /auth/me — refreshes current user profile
  Future<UserModel?> getMe() async {
    try {
      final response = await _dio.get(ApiRoutes.me);
      final data = response.data as Map<String, dynamic>;
      final userData = data['user'] as Map<String, dynamic>? ?? data;
      return UserModel.fromJson(userData);
    } catch (_) {
      return null;
    }
  }

  // ── LOGOUT ───────────────────────────────────────────────────
  /// POST /auth/logout
  Future<void> logout() async {
    try {
      final rt = await _storage.read(key: AppConstants.keyRefreshToken);
      await _dio.post(ApiRoutes.logout, data: {'refreshToken': rt});
    } catch (_) {
      // ignore — clear tokens regardless
    } finally {
      await _storage.deleteAll();
    }
  }

  // ── SESSION CHECK ────────────────────────────────────────────
  Future<bool> hasValidSession() async {
    final token = await _storage.read(key: AppConstants.keyAccessToken);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getAccessToken()   => _storage.read(key: AppConstants.keyAccessToken);
  Future<String?> getCachedUserName()=> _storage.read(key: AppConstants.keyUserName);
  Future<String?> getCachedRole()    => _storage.read(key: AppConstants.keyUserRole);

  // ── Error Parsing ─────────────────────────────────────────────
  String _parseError(DioException e) {
    if (e.response?.data is Map) {
      final d = e.response!.data as Map;
      return d['error']?.toString() ?? d['message']?.toString() ?? 'Server error';
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your network.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please try again.';
      default:
        return 'Server error. Please try again.';
    }
  }
}

// ── Result wrapper ────────────────────────────────────────────
class AuthResult {
  final bool isSuccess;
  final String? message;
  final UserModel? user;

  const AuthResult._({required this.isSuccess, this.message, this.user});

  factory AuthResult.success({required UserModel user}) =>
      AuthResult._(isSuccess: true, user: user);
  factory AuthResult.failure({required String message}) =>
      AuthResult._(isSuccess: false, message: message);
}
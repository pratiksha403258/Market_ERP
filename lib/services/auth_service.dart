import 'package:agr_market/services/constant_service.dart';
import 'package:agr_market/services/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

// ─────────────────────────────────────────────────────────────
//  AUTH SERVICE — all API calls for authentication
// ─────────────────────────────────────────────────────────────

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final Dio _dio = DioClient.instance.dio;
  final _storage = const FlutterSecureStorage(
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

      final accessToken = data['accessToken'] as String? ?? data['access_token'] as String? ?? '';
      final refreshToken = data['refreshToken'] as String? ?? data['refresh_token'] as String? ?? '';
      final userData = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);

      print('🔐 User ID from API: ${user.id}');
      print('🔐 User Name from API: ${user.name}');

      // Persist tokens + basic user info securely
      await _storage.write(key: AppConstants.keyAccessToken, value: accessToken);
      await _storage.write(key: AppConstants.keyRefreshToken, value: refreshToken);
      await _storage.write(key: AppConstants.keyUserId, value: user.id);
      await _storage.write(key: AppConstants.keyUserRole, value: user.role);
      await _storage.write(key: AppConstants.keyUserName, value: user.name);

      final savedUserId = await _storage.read(key: AppConstants.keyUserId);
      print('🔐 Saved User ID to storage: $savedUserId');

      return AuthResult.success(user: user);
    } on DioException catch (e) {
      return AuthResult.failure(message: _parseError(e));
    } catch (e) {
      return AuthResult.failure(message: 'Unexpected error: $e');
    }
  }

  // ── REGISTER ─────────────────────────────────────────────────
  /// POST /auth/register
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String businessName,
    String? address,
    String? city,
    String? state,
    String? gstNumber,
    String? panNumber,
    String? bankAccountNumber,
    String? ifscCode,
    String? bankName,
  }) async {
    try {
      final response = await _dio.post(
        ApiRoutes.register,
        data: {
          'name': name.trim(),
          'email': email.toLowerCase().trim(),
          'password': password,
          'phone': phone.trim(),
          'businessName': businessName.trim(),
          if (address != null && address.isNotEmpty) 'address': address,
          if (city != null && city.isNotEmpty) 'city': city,
          if (state != null && state.isNotEmpty) 'state': state,
          if (gstNumber != null && gstNumber.isNotEmpty) 'gstNumber': gstNumber,
          if (panNumber != null && panNumber.isNotEmpty) 'panNumber': panNumber,
          if (bankAccountNumber != null && bankAccountNumber.isNotEmpty) 'bankAccountNumber': bankAccountNumber,
          if (ifscCode != null && ifscCode.isNotEmpty) 'ifscCode': ifscCode,
          if (bankName != null && bankName.isNotEmpty) 'bankName': bankName,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        return AuthResult.failure(
            message: data['error']?.toString() ?? data['message']?.toString() ?? 'Registration failed'
        );
      }

      final accessToken = data['accessToken'] as String? ?? '';
      final refreshToken = data['refreshToken'] as String? ?? '';
      final userData = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);

      // Store tokens and user info
      if (accessToken.isNotEmpty) {
        await _storage.write(key: AppConstants.keyAccessToken, value: accessToken);
      }
      if (refreshToken.isNotEmpty) {
        await _storage.write(key: AppConstants.keyRefreshToken, value: refreshToken);
      }
      await _storage.write(key: AppConstants.keyUserId, value: user.id);
      await _storage.write(key: AppConstants.keyUserRole, value: user.role);
      await _storage.write(key: AppConstants.keyUserName, value: user.name);

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

  // Add to AuthService class
  Future<AuthResult> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        ApiRoutes.me,
        data: data,
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] != true) {
        return AuthResult.failure(
          message: responseData['message']?.toString() ?? 'Update failed',
        );
      }

      final userData = responseData['user'] as Map<String, dynamic>;
      final updatedUser = UserModel.fromJson(userData);

      // Update cached user info
      await _storage.write(key: AppConstants.keyUserName, value: updatedUser.name);
      if (updatedUser.role != null) {
        await _storage.write(key: AppConstants.keyUserRole, value: updatedUser.role);
      }

      return AuthResult.success(user: updatedUser);
    } on DioException catch (e) {
      return AuthResult.failure(message: _parseError(e));
    } catch (e) {
      return AuthResult.failure(message: 'Unexpected error: $e');
    }
  }

  // Optional: Add method to manually refresh user data
  Future<UserModel?> refreshUserProfile() async {
    return await getMe();
  }

  // ── SESSION CHECK ────────────────────────────────────────────
  Future<bool> hasValidSession() async {
    final token = await _storage.read(key: AppConstants.keyAccessToken);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getAccessToken() => _storage.read(key: AppConstants.keyAccessToken);
  Future<String?> getCachedUserName() => _storage.read(key: AppConstants.keyUserName);
  Future<String?> getCachedRole() => _storage.read(key: AppConstants.keyUserRole);

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


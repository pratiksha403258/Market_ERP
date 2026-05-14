// // import 'package:flutter/material.dart';
// // import '../services/auth_service.dart';

// // /// ─────────────────────────────────────────
// // ///  Auth Provider — manages auth state
// // ///  across the app using ChangeNotifier
// // /// ─────────────────────────────────────────
// // class AuthProvider extends ChangeNotifier {
// //   UserModel? _user;
// //   bool _isLoading = false;
// //   String? _errorMessage;

// //   UserModel? get user => _user;
// //   bool get isLoading => _isLoading;
// //   String? get errorMessage => _errorMessage;
// //   bool get isLoggedIn => _user != null;

// //   void _setLoading(bool value) {
// //     _isLoading = value;
// //     notifyListeners();
// //   }

// //   void _setError(String? msg) {
// //     _errorMessage = msg;
// //     notifyListeners();
// //   }

// //   void clearError() {
// //     _errorMessage = null;
// //     notifyListeners();
// //   }

// //   // ── CHECK SESSION ─────────────────────────
// //   Future<bool> checkSession() async {
// //     final loggedIn = await AuthService.instance.isLoggedIn();
// //     if (loggedIn) {
// //       _user = await AuthService.instance.getMe();
// //       notifyListeners();
// //     }
// //     return loggedIn && _user != null;
// //   }

// //   // ── LOGIN ─────────────────────────────────
// //   Future<bool> login({
// //     required String email,
// //     required String password,
// //   }) async {
// //     _setLoading(true);
// //     _setError(null);

// //     final result = await AuthService.instance.login(
// //       email: email,
// //       password: password,
// //     );

// //     _setLoading(false);

// //     if (result.isSuccess) {
// //       _user = result.user;
// //       notifyListeners();
// //       return true;
// //     } else {
// //       _setError(result.message);
// //       return false;
// //     }
// //   }

// //   // ── REGISTER ──────────────────────────────
// //   Future<bool> register({
// //     required String name,
// //     required String email,
// //     required String password,
// //     required String phone,
// //     required String businessName,
// //   }) async {
// //     _setLoading(true);
// //     _setError(null);

// //     final result = await AuthService.instance.register(
// //       name: name,
// //       email: email,
// //       password: password,
// //       phone: phone,
// //       businessName: businessName,
// //     );

// //     _setLoading(false);

// //     if (result.isSuccess) {
// //       _user = result.user;
// //       notifyListeners();
// //       return true;
// //     } else {
// //       _setError(result.message);
// //       return false;
// //     }
// //   }

// //   // ── LOGOUT ────────────────────────────────
// //   Future<void> logout() async {
// //     _setLoading(true);
// //     await AuthService.instance.logout();
// //     _user = null;
// //     _isLoading = false;
// //     _errorMessage = null;
// //     notifyListeners();
// //   }
// // }

// import 'package:agr_market/models/user_model.dart';
// import 'package:agr_market/services/auth_service.dart';
// import 'package:flutter/material.dart';


// // ─────────────────────────────────────────────────────────────
// //  AUTH PROVIDER — controller for auth state
// // ─────────────────────────────────────────────────────────────
// class AuthProvider extends ChangeNotifier {
//   UserModel? _user;
//   bool       _isLoading  = false;
//   String?    _error;

//   UserModel? get user       => _user;
//   bool       get isLoading  => _isLoading;
//   String?    get error      => _error;
//   bool       get isLoggedIn => _user != null;

//   void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
//   void _setError(String? e){ _error = e;     notifyListeners(); }
//   void clearError()         { _error = null;  notifyListeners(); }

//   // ── Check existing session on app start ───────────────────────
//   Future<bool> checkSession() async {
//     final hasToken = await AuthService.instance.hasValidSession();
//     if (!hasToken) return false;

//     _user = await AuthService.instance.getMe();
//     if (_user != null) notifyListeners();
//     return _user != null;
//   }

//   // ── Login ─────────────────────────────────────────────────────
//   Future<bool> login({required String email, required String password}) async {
//     _setLoading(true);
//     _setError(null);

//     final result = await AuthService.instance.login(
//         email: email, password: password);

//     _setLoading(false);
//     if (result.isSuccess) {
//       _user = result.user;
//       notifyListeners();
//       return true;
//     }
//     _setError(result.message);
//     return false;
//   }

//   // ── Logout ────────────────────────────────────────────────────
//   Future<void> logout() async {
//     _setLoading(true);
//     await AuthService.instance.logout();
//     _user       = null;
//     _isLoading  = false;
//     _error      = null;
//     notifyListeners();
//   }
// }

import 'package:agr_market/models/user_model.dart';
import 'package:agr_market/services/auth_service.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

// ─────────────────────────────────────────────────────────────
//  AUTH PROVIDER — controller for auth state
// ─────────────────────────────────────────────────────────────
class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? e) {
    _error = e;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Check existing session on app start ───────────────────────
  Future<bool> checkSession() async {
    final hasToken = await AuthService.instance.hasValidSession();
    if (!hasToken) return false;

    _user = await AuthService.instance.getMe();
    if (_user != null) notifyListeners();
    return _user != null;
  }

  // ── Login ─────────────────────────────────────────────────────
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _setError(null);

    final result = await AuthService.instance.login(
        email: email, password: password);

    _setLoading(false);
    if (result.isSuccess) {
      _user = result.user;
      notifyListeners();
      return true;
    }
    _setError(result.message);
    return false;
  }

  // ── REGISTER ─────────────────────────────────────────────────
  Future<bool> register({
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
    _setLoading(true);
    _setError(null);

    final result = await AuthService.instance.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      businessName: businessName,
      address: address,
      city: city,
      state: state,
      gstNumber: gstNumber,
      panNumber: panNumber,
      bankAccountNumber: bankAccountNumber,
      ifscCode: ifscCode,
      bankName: bankName,
    );

    _setLoading(false);

    if (result.isSuccess) {
      _user = result.user;
      notifyListeners();
      return true;
    } else {
      _setError(result.message);
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────
  Future<void> logout() async {
    _setLoading(true);
    await AuthService.instance.logout();
    _user = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
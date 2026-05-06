// ─────────────────────────────────────────────────────────────
//  MARKET ERP — App Constants
// ─────────────────────────────────────────────────────────────

class AppConstants {
  AppConstants._();

  // ── API ──────────────────────────────────────────────────────
  //static const String baseUrl = 'http://192.168.1.8:5001/api';
      static const String baseUrl = 'http://192.168.1.15:5001/api';                         
  // ── Secure Storage Keys ───────────────────────────────────────
  static const String keyAccessToken  = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId       = 'user_id';
  static const String keyUserRole     = 'user_role';
  static const String keyUserName     = 'user_name';

  // ── Shared Prefs ──────────────────────────────────────────────
  static const String keyLanguage     = 'selected_language';

  // ── Route Names ───────────────────────────────────────────────
  static const String routeSplash   = '/splash';
  static const String routeLogin    = '/login';
  static const String routeLanguage = '/language';
  static const String routeHome     = '/home';

  // ── Pagination ────────────────────────────────────────────────
  static const int defaultPageSize = 20;
}

class ApiRoutes {
  ApiRoutes._();

  // Auth
  static const String login   = '/auth/login';
  static const String logout  = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String me      = '/auth/me';

  // Farmers
  static const String farmers       = '/farmers';
  static String farmerById(String id) => '/farmers/$id';
  static String farmerLedger(String id) => '/farmers/$id/ledger';

   static const String purchases = '/purchases';
  static String purchaseById(String id)      => '/purchases/$id';  
}
class AppConstants {
  AppConstants._();
 
   static const String baseUrl = 'http://192.168.1.15:5001/api';
 //static const String baseUrl = 'http://192.168.1.8:5001/api';
   // static const baseUrl = "https://codiantsolutions.com/api/agri_tred/api";

  static const String keyAccessToken  = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId       = 'user_id';
  static const String keyUserRole     = 'user_role';
  static const String keyUserName     = 'user_name';
  static const String keyLanguage     = 'selected_language';
 
  static const String routeSplash   = '/splash';
  static const String routeLogin    = '/login';
  static const String routeLanguage = '/language';
  static const String routeHome     = '/home';
 
  static const int defaultPageSize = 20;
}
 
class ApiRoutes {
  ApiRoutes._();
 
  // Auth
  static const String login   = '/auth/login';
  static const String logout  = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String me      = '/auth/me';
 
   static const String register = '/auth/register';
  // Farmers
  static const String farmers               = '/farmers';
  static String farmerById(String id)       => '/farmers/$id';
  static String farmerLedger(String id)     => '/ledger/farmer/$id';
  static String farmerDues(String id)       => '/farmers/$id/dues';
  static String farmerAdvance(String id)    => '/farmers/$id/advance';
  static String farmerDeactivate(String id) => '/farmers/$id/deactivate';
 
  // Purchases
  static const String purchases             = '/purchases';
  static String purchaseById(String id)     => '/purchases/$id';
  static String purchaseStatus(String id)   => '/purchases/$id';
 
  // Payments
  static const String payments              = '/payments';
  static String paymentById(String id)      => '/payments/$id';
  static const String paymentDueSummary     = '/payments/due-summary';


  static const String expenses              = '/expenses';
  static String expenseById(String id)      => '/expenses/$id';
  static String expenseApprove(String id)   => '/expenses/$id/approve';
  static String expenseReject(String id)    => '/expenses/$id/reject';
  static String expenseCancel(String id)    => '/expenses/$id/cancel';
  static const String expenseSummary        = '/expenses/summary';
 
  // Reports / Dashboard
  static const String dashboard             = '/reports/dashboard';

static const String warehouses           = '/warehouse';
static String warehouseById(String id)   => '/warehouse/$id';
static String warehouseHardDelete(String id) => '/warehouse/$id/hard';

 static const String inventory           = '/inventory';
  static String inventoryProduct(String name) => '/inventory/product/$name';
  static const String inventoryAdjust     = '/inventory/adjust';
  static const String inventoryTransfer    = '/inventory/transfer';

// Sales
  static const String sales = '/sales';
  static String saleById(String id) => '/sales/$id';
  static String saleInvoice(String id) => '/sales/$id/invoice';
  static String salePayment(String id) => '/sales/$id/payment';
 

static const String profitLossReport = '/reports/profit-loss';
static String farmerReport(String farmerId) => '/reports/farmer/$farmerId';
static const String productPerformanceReport = '/reports/products';
static const String inventorySummaryReport = '/warehouse/summary/report';
static String inventoryHistoryReport(String productId) => '/warehouse/history/$productId';

static const String allOperatorsLedger = '/ledger/all/operators';
static String operatorLedger(String id) => '/ledger/operator/$id';
static const String allFarmersLedger = '/ledger/all/farmers'; //superadmin only 


  static const String profitLoss = '/reports/profit-loss';

    static const String buyers = '/buyers';
  static String buyerById(String id) => '/buyers/$id';
  static const String buyersSummary = '/buyers/summary';

  static get baseUrl => null;

}
 
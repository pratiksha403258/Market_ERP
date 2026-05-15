
// import 'package:agr_market/services/constant_service.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:dio/dio.dart';
// import '../../../services/dio_client.dart';
// import '../../models/farmer_model.dart';
// import '../../models/purchase_model.dart';
// import '../../models/deduction_model.dart';
 
// class PurchaseService {
//   final DioClient _dioClient = DioClient.instance;
 
//   static const _storage = FlutterSecureStorage(
//     aOptions: AndroidOptions(encryptedSharedPreferences: true),
//   );
 
//   // ── FETCH FARMERS ─────────────────────────────────────────────
//   Future<List<FarmerModel>> fetchFarmers() async {
//     try {
//       final res = await _dioClient.dio.get(ApiRoutes.farmers);
//       final data = res.data;
//       List list = [];
//       if (data is List) {
//         list = data;
//       } else if (data is Map) {
//         list = data['farmers'] as List? ?? data['data'] as List? ?? [];
//       }
//       return list.map((j) => FarmerModel.fromJson(j as Map<String, dynamic>)).toList();
//     } catch (e) {
//       throw Exception('Failed to fetch farmers: $e');
//     }
//   }
 
//   // ── SAVE (CREATE) PURCHASE — POST then PATCH to 'saved' ──────
//   //
//   // WHY PATCH AFTER POST?
//   //   The API creates purchase with status='draft' by default.
//   //   A 'draft' purchase is treated as incomplete/in-progress.
//   //   After the user confirms on Step 4 (Summary), we need to
//   //   mark it as 'saved' so it appears in payment flows and reports.
//   //
//   Future<String> savePurchase({
//     required String farmerId,
//     required List<PurchaseLine> lines,
//     required DeductionData deductions,
//   }) async {
//     final createdBy = await _storage.read(key: AppConstants.keyUserId) ?? '';
//     if (createdBy.isEmpty) {
//       throw Exception('User not authenticated. Please login again.');
//     }
 
//     final payload = _buildPayload(
//       farmerId: farmerId,
//       createdBy: createdBy,
//       lines: lines,
//       deductions: deductions,
//     );
 
//     // STEP 1: Create the purchase (status will be 'draft')
//     // STEP 1: Create the purchase
// final createRes = await _dioClient.dio.post(
//   ApiRoutes.purchases,
//   data: payload,
//   options: Options(validateStatus: (s) => true),
// );

// // 🔍 ADD THIS — see exactly what server returns
// print('📥 Create response [${createRes.statusCode}]: ${createRes.data}');

// if (createRes.statusCode != 201 && createRes.statusCode != 200) {
//   throw Exception('Server error ${createRes.statusCode}: ${_extractErrorMsg(createRes.data)}');
// }

// // Safe extraction — handle any response shape
// String purchaseId = '';
// final raw = createRes.data;

// if (raw is Map<String, dynamic>) {
//   purchaseId =
//       (raw['data'] as Map<String, dynamic>?)?['id']?.toString() ??        // ✅ YOUR CASE
//       (raw['data'] as Map<String, dynamic>?)?['_id']?.toString() ??
//       (raw['purchase'] as Map<String, dynamic>?)?['_id']?.toString() ??
//       (raw['purchase'] as Map<String, dynamic>?)?['id']?.toString() ??
//       raw['_id']?.toString() ??
//       raw['id']?.toString() ??
//       raw['purchaseId']?.toString() ??
//       '';
// }

// if (purchaseId.isEmpty) {
//   print('⚠️ Full server response was: $raw');
//   throw Exception('Purchase created but ID not returned from server');
// }
//     // STEP 2: PATCH status from 'draft' to 'saved'
//     // This marks the purchase as confirmed by the operator
//    final patchRes = await _dioClient.dio.patch(
//   ApiRoutes.purchaseStatus(purchaseId),
//   data: {'status': 'saved'},
//   options: Options(validateStatus: (s) => true),
// );

// print('📥 Patch status [${patchRes.statusCode}]: ${patchRes.data}');

// // ✅ Return ID regardless — purchase exists even if status patch failed
// return purchaseId;
//   }
 
//   // ── UPDATE PURCHASE — PUT ─────────────────────────────────────
//   Future<void> updatePurchase({
//     required String purchaseId,
//     required String farmerId,
//     required List<PurchaseLine> lines,
//     required DeductionData deductions,
//   }) async {
//     final createdBy = await _storage.read(key: AppConstants.keyUserId) ?? '';
//     if (createdBy.isEmpty) {
//       throw Exception('User not authenticated. Please login again.');
//     }
 
//     final payload = _buildPayload(
//       farmerId: farmerId,
//       createdBy: createdBy,
//       lines: lines,
//       deductions: deductions,
//     );
 
//     final res = await _dioClient.dio.put(
//       ApiRoutes.purchaseById(purchaseId),
//       data: payload,
//       options: Options(validateStatus: (s) => true),
//     );
 
//     if (res.statusCode != 200) {
//       throw Exception('Server error ${res.statusCode}: ${_extractErrorMsg(res.data)}');
//     }
//   }
 
//   // ── DELETE PURCHASE ──────────────────────────────────────────
//   Future<void> deletePurchase({
//     required String purchaseId,
//     bool force = false,
//   }) async {
//     final url = force
//         ? '${ApiRoutes.purchaseById(purchaseId)}?force=true'
//         : ApiRoutes.purchaseById(purchaseId);
 
//     final res = await _dioClient.dio.delete(
//       url,
//       options: Options(validateStatus: (s) => true),
//     );
 
//     if (res.statusCode != 200 && res.statusCode != 204) {
//       throw Exception('Server error ${res.statusCode}: ${_extractErrorMsg(res.data)}');
//     }
//   }
 
//   // ── MARK PURCHASE AS PAID (manual override) ──────────────────
//   // Use this if payment API doesn't auto-update status
//   Future<void> markAsPaid(String purchaseId) async {
//     await _dioClient.dio.patch(
//       ApiRoutes.purchaseStatus(purchaseId),
//       data: {'status': 'paid'},
//       options: Options(validateStatus: (s) => true),
//     );
//   }
 
//   // ── PAYLOAD BUILDER ───────────────────────────────────────────
//   Map<String, dynamic> _buildPayload({
//     required String farmerId,
//     required String createdBy,
//     required List<PurchaseLine> lines,
//     required DeductionData deductions,
//   }) {
//     final preparedLines = lines.map((l) {
//       double actualQty = l.actualQty;
//       if (l.pricingType == 'kg' && l.bags > 0 && l.weightPerBag > 0) {
//         actualQty = l.bags * l.weightPerBag;
//       }
//       return {
//         'productName':      l.productName,
//         'pricingType':      l.pricingType,
//         'bags':             l.bags,
//         'weightPerBag':     l.weightPerBag,
//         'actualQty':        actualQty,
//         'qualityDeduction': l.qualityDeduction,
//         'billedQty':        l.billedQty,
//         'unit':             l.unit,
//         'rate':             l.rate,
//         'lineTotal':        l.lineTotal,
//         'notes':            '',
//       };
//     }).toList();
 
//     return {
//       'farmer':       farmerId,
//       'farmerId':     farmerId,
//       'createdBy':    createdBy,
//       'purchaseDate': DateTime.now().toIso8601String(),
//       'lines':        preparedLines,
//       'deductions': {
//         'transport':        deductions.transport,
//         'labour':           deductions.labour,
//         'commission':       deductions.commission,
//         'commissionType':   deductions.commissionType,
//         'storage':          deductions.storage,
//         'storageNote':      deductions.storageNote,
//         'returnDeduction':  deductions.returnDeduction,
//         'returnNote':       deductions.returnNote,
//         'advanceAdjusted':  deductions.advanceAdjusted,
//         'other':            deductions.other,
//         'otherNote':        deductions.otherNote,
//       },
//       'notes': '',
//     };
//   }
 
//   String _extractErrorMsg(dynamic data) {
//     if (data is Map) {
//       return data['error']?.toString() ??
//           data['message']?.toString() ??
//           data.toString();
//     }
//     return data?.toString() ?? 'Unknown error';
//   }
// }
 


import 'package:agr_market/services/constant_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../services/dio_client.dart';
import '../../models/farmer_model.dart';
import '../../models/purchase_model.dart';
import '../../models/deduction_model.dart';
 
class PurchaseService {
  final DioClient _dioClient = DioClient.instance;
 
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
 
  // ── FETCH FARMERS ─────────────────────────────────────────────
  Future<List<FarmerModel>> fetchFarmers() async {
    try {
      final res = await _dioClient.dio.get(ApiRoutes.farmers);
      final data = res.data;
      List list = [];
      if (data is List) {
        list = data;
      } else if (data is Map) {
        list = data['farmers'] as List? ?? data['data'] as List? ?? [];
      }
      return list.map((j) => FarmerModel.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch farmers: $e');
    }
  }
 
  // ── SAVE (CREATE) PURCHASE — POST then PATCH to 'saved' ──────
  //
  // WHY PATCH AFTER POST?
  //   The API creates purchase with status='draft' by default.
  //   A 'draft' purchase is treated as incomplete/in-progress.
  //   After the user confirms on Step 4 (Summary), we need to
  //   mark it as 'saved' so it appears in payment flows and reports.
  //
  Future<String> savePurchase({
    required String farmerId,
    required List<PurchaseLine> lines,
    required DeductionData deductions,
  }) async {
    final createdBy = await _storage.read(key: AppConstants.keyUserId) ?? '';
    if (createdBy.isEmpty) {
      throw Exception('User not authenticated. Please login again.');
    }
 
    final payload = _buildPayload(
      farmerId: farmerId,
      createdBy: createdBy,
      lines: lines,
      deductions: deductions,
    );
 
    // STEP 1: Create the purchase (status will be 'draft')
    // STEP 1: Create the purchase
final createRes = await _dioClient.dio.post(
  ApiRoutes.purchases,
  data: payload,
  options: Options(validateStatus: (s) => true),
);

// 🔍 ADD THIS — see exactly what server returns
print('📥 Create response [${createRes.statusCode}]: ${createRes.data}');

if (createRes.statusCode != 201 && createRes.statusCode != 200) {
  throw Exception('Server error ${createRes.statusCode}: ${_extractErrorMsg(createRes.data)}');
}

// Safe extraction — handle any response shape
String purchaseId = '';
final raw = createRes.data;

if (raw is Map<String, dynamic>) {
  purchaseId =
      (raw['data'] as Map<String, dynamic>?)?['id']?.toString() ??        // ✅ YOUR CASE
      (raw['data'] as Map<String, dynamic>?)?['_id']?.toString() ??
      (raw['purchase'] as Map<String, dynamic>?)?['_id']?.toString() ??
      (raw['purchase'] as Map<String, dynamic>?)?['id']?.toString() ??
      raw['_id']?.toString() ??
      raw['id']?.toString() ??
      raw['purchaseId']?.toString() ??
      '';
}

if (purchaseId.isEmpty) {
  print('⚠️ Full server response was: $raw');
  throw Exception('Purchase created but ID not returned from server');
}
    // STEP 2: PATCH status from 'draft' to 'saved'
    // This marks the purchase as confirmed by the operator
   final patchRes = await _dioClient.dio.patch(
  ApiRoutes.purchaseStatus(purchaseId),
  data: {'status': 'saved'},
  options: Options(validateStatus: (s) => true),
);

print('📥 Patch status [${patchRes.statusCode}]: ${patchRes.data}');

// ✅ Return ID regardless — purchase exists even if status patch failed
return purchaseId;
  }
 
  // ── UPDATE PURCHASE — PUT ─────────────────────────────────────
  Future<void> updatePurchase({
    required String purchaseId,
    required String farmerId,
    required List<PurchaseLine> lines,
    required DeductionData deductions,
  }) async {
    final createdBy = await _storage.read(key: AppConstants.keyUserId) ?? '';
    if (createdBy.isEmpty) {
      throw Exception('User not authenticated. Please login again.');
    }
 
    final payload = _buildPayload(
      farmerId: farmerId,
      createdBy: createdBy,
      lines: lines,
      deductions: deductions,
    );
 
    final res = await _dioClient.dio.put(
      ApiRoutes.purchaseById(purchaseId),
      data: payload,
      options: Options(validateStatus: (s) => true),
    );
 
    if (res.statusCode != 200) {
      throw Exception('Server error ${res.statusCode}: ${_extractErrorMsg(res.data)}');
    }
  }
 
  // ── DELETE PURCHASE ──────────────────────────────────────────
  Future<void> deletePurchase({
    required String purchaseId,
    bool force = false,
  }) async {
    final url = force
        ? '${ApiRoutes.purchaseById(purchaseId)}?force=true'
        : ApiRoutes.purchaseById(purchaseId);
 
    final res = await _dioClient.dio.delete(
      url,
      options: Options(validateStatus: (s) => true),
    );
 
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Server error ${res.statusCode}: ${_extractErrorMsg(res.data)}');
    }
  }
 
  // ── MARK PURCHASE AS PAID (manual override) ──────────────────
  // Use this if payment API doesn't auto-update status
  Future<void> markAsPaid(String purchaseId) async {
    await _dioClient.dio.patch(
      ApiRoutes.purchaseStatus(purchaseId),
      data: {'status': 'paid'},
      options: Options(validateStatus: (s) => true),
    );
  }
 
  // ── PAYLOAD BUILDER ───────────────────────────────────────────
  Map<String, dynamic> _buildPayload({
    required String farmerId,
    required String createdBy,
    required List<PurchaseLine> lines,
    required DeductionData deductions,
  }) {
    final preparedLines = lines.map((l) {
      double actualQty = l.actualQty;
      if (l.pricingType == 'kg' && l.bags > 0 && l.weightPerBag > 0) {
        actualQty = l.bags * l.weightPerBag;
      }
      return {
        'productName':      l.productName,
        'pricingType':      l.pricingType,
        'bags':             l.bags,
        'weightPerBag':     l.weightPerBag,
        'actualQty':        actualQty,
        'qualityDeduction': l.qualityDeduction,
        'billedQty':        l.billedQty,
        'unit':             l.unit,
        'rate':             l.rate,
        'lineTotal':        l.lineTotal,
        'notes':            '',
      };
    }).toList();
 
    return {
      'farmer':       farmerId,
      'farmerId':     farmerId,
      'createdBy':    createdBy,
      'purchaseDate': DateTime.now().toIso8601String(),
      'lines':        preparedLines,
      'deductions': {
        'transport':        deductions.transport,
        'labour':           deductions.labour,
        'commission':       deductions.commission,
        'commissionType':   deductions.commissionType,
        'storage':          deductions.storage,
        'storageNote':      deductions.storageNote,
        'returnDeduction':  deductions.returnDeduction,
        'returnNote':       deductions.returnNote,
        'advanceAdjusted':  deductions.advanceAdjusted,
        'other':            deductions.other,
        'otherNote':        deductions.otherNote,
      },
      'notes': '',
    };
  }
 
  String _extractErrorMsg(dynamic data) {
    if (data is Map) {
      return data['error']?.toString() ??
          data['message']?.toString() ??
          data.toString();
    }
    return data?.toString() ?? 'Unknown error';
  }
}



class ProductService {
  ProductService._();
  static final ProductService instance = ProductService._();

  final Dio _dio = DioClient.instance.dio;

  Future<List<ProductModel>> fetchProducts({
    int page = 1,
    int limit = 50,
    String? searchQuery,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (searchQuery != null && searchQuery.isNotEmpty)
          'search': searchQuery,
      };

      final response = await _dio.get(
        '/products',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to fetch products');
      }

      final productsData = data['data'] as List;
      return productsData
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .where((product) => product.isActive)
          .toList();
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  String _parseError(DioException e) {
    if (e.response?.data is Map) {
      final d = e.response!.data as Map;
      return d['error']?.toString() ??
          d['message']?.toString() ??
          'Server error';
    }
    return 'Network error: ${e.message}';
  }
}
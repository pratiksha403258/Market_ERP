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
//       print('📡 FETCHING FARMERS...');
//       final res = await _dioClient.dio.get(ApiRoutes.farmers);
//       final data = res.data;

//       List list = [];
//       if (data is List) list = data;
//       else if (data is Map && data['farmers'] is List) list = data['farmers'];
//       else if (data is Map && data['data'] is List) list = data['data'];

//       print(' Found ${list.length} farmers');
//       return list.map((j) => FarmerModel.fromJson(j)).toList();
//     } catch (e) {
//       print('❌ Error fetching farmers: $e');
//       throw Exception('Failed to fetch farmers: $e');
//     }
//   }

//   // ── SAVE (CREATE) PURCHASE — POST ────────────────────────────
//   Future<String> savePurchase({
//     required String farmerId,
//     required List<PurchaseLine> lines,
//     required DeductionData deductions,
//   }) async {
//     try {
//       print('\n🔵 ========== STARTING PURCHASE SAVE ==========');


//       final createdBy = await _storage.read(key: AppConstants.keyUserId) ?? '';
//       print('👤 User ID: "$createdBy"');

//       if (createdBy.isEmpty) {
//         throw Exception('User not authenticated. Please login again.');
//       }

//       final payload = _buildPayload(
//         farmerId: farmerId,
//         createdBy: createdBy,
//         lines: lines,
//         deductions: deductions,
//       );

//             print('🚀 POST ${ApiRoutes.purchases}');
//                   print('🧪 farmerId being sent: "$farmerId"');
//                  print('🧪 Full payload: $payload');

//       final res = await _dioClient.dio.post(
//         ApiRoutes.purchases,
//         data: payload,
//         options: Options(validateStatus: (s) => true),
//       );

//       print('📥 Status: ${res.statusCode} | Data: ${res.data}');

//       if (res.statusCode == 201 || res.statusCode == 200) {
//         // Extract and return the created purchase ID
//         final responseData = res.data as Map<String, dynamic>;
//         final purchaseId = responseData['purchase']?['_id']?.toString() ??
//             responseData['_id']?.toString() ??
//             responseData['id']?.toString() ??
//             '';
//         print('✅ Purchase created with ID: $purchaseId');
//         return purchaseId;
//       } else {
//         final errMsg = _extractErrorMsg(res.data);
//         throw Exception('Server error ${res.statusCode}: $errMsg');
//       }
//     } catch (e) {
//       print('❌ savePurchase error: $e');
//       throw Exception('Failed to save purchase: $e');
//     }
//   }

//   // ── UPDATE PURCHASE — PUT (draft only) ───────────────────────
//   Future<void> updatePurchase({
//     required String purchaseId,
//     required String farmerId,
//     required List<PurchaseLine> lines,
//     required DeductionData deductions,
//   }) async {
//     try {
//       print('\n🟡 ========== UPDATING PURCHASE $purchaseId ==========');

//       final createdBy = await _storage.read(key: AppConstants.keyUserId) ?? '';

//       if (createdBy.isEmpty) {
//         throw Exception('User not authenticated. Please login again.');
//       }

//       final payload = _buildPayload(
//         farmerId: farmerId,
//         createdBy: createdBy,
//         lines: lines,
//         deductions: deductions,
//       );

//       print('🚀 PUT ${ApiRoutes.purchaseById(purchaseId)}');

//       final res = await _dioClient.dio.put(
//         ApiRoutes.purchaseById(purchaseId),
//         data: payload,
//         options: Options(validateStatus: (s) => true),
//       );

//       print('📥 Status: ${res.statusCode} | Data: ${res.data}');

//       if (res.statusCode == 200) {
//         print('✅ Purchase updated successfully');
//         return;
//       } else {
//         final errMsg = _extractErrorMsg(res.data);
//         throw Exception('Server error ${res.statusCode}: $errMsg');
//       }
//     } catch (e) {
//       print('❌ updatePurchase error: $e');
//       throw Exception('Failed to update purchase: $e');
//     }
//   }

//   // ── DELETE PURCHASE ──────────────────────────────────────────
//   Future<void> deletePurchase({
//     required String purchaseId,
//     bool force = false,
//   }) async {
//     try {
//       print('\n🔴 ========== DELETING PURCHASE $purchaseId ==========');

//       final url = force
//           ? '${ApiRoutes.purchaseById(purchaseId)}?force=true'
//           : ApiRoutes.purchaseById(purchaseId);

//       print('🚀 DELETE $url');

//       final res = await _dioClient.dio.delete(
//         url,
//         options: Options(validateStatus: (s) => true),
//       );

//       print('📥 Status: ${res.statusCode} | Data: ${res.data}');


//       if (res.statusCode == 200 || res.statusCode == 204) {
//         print('✅ Purchase deleted successfully');
//         return;
//       } else {
//         final errMsg = _extractErrorMsg(res.data);
//         throw Exception('Server error ${res.statusCode}: $errMsg');
//       }
//     } catch (e) {
//       print('❌ deletePurchase error: $e');
//       throw Exception('Failed to delete purchase: $e');
//     }
    
//   }

//   // ── SHARED PAYLOAD BUILDER ────────────────────────────────────
//   Map<String, dynamic> _buildPayload({
//   required String farmerId,
//   required String createdBy,
//   required List<PurchaseLine> lines,
//   required DeductionData deductions,
// }) {
//   final double grossTotal = lines.fold(0.0, (s, l) => s + l.lineTotal);

//   final preparedLines = lines.map((l) {
//     double actualQty = l.actualQty;
//     if (l.pricingType == 'kg' && l.bags > 0 && l.weightPerBag > 0) {
//       actualQty = l.bags * l.weightPerBag;
//     }
//     return {
//       // 'farmer': farmerId, 
//       'productName': l.productName,
//       'pricingType': l.pricingType,
//       'bags': l.bags,
//       'weightPerBag': l.weightPerBag,
//       'actualQty': actualQty,
//       'qualityDeduction': l.qualityDeduction,
//       'billedQty': l.billedQty,
//       'unit': l.unit,
//       'rate': l.rate,
//       'lineTotal': l.lineTotal,
//       'notes': '',
//     };
//   }).toList();

//   return {
//     'farmer': farmerId,      // ← for Mongoose schema
//   'farmerId': farmerId,   
//     'createdBy': createdBy,
//     'purchaseDate': DateTime.now().toIso8601String(),
//     'lines': preparedLines,
//     'deductions': {
//       'transport': deductions.transport,
//       'labour': deductions.labour,
//       'commission': deductions.commission,
//       'commissionType': deductions.commissionType,
//       'storage': deductions.storage,
//       'storageNote': deductions.storageNote,
//       'returnDeduction': deductions.returnDeduction,
//       'returnNote': deductions.returnNote,
//       'advanceAdjusted': deductions.advanceAdjusted,
//       'other': deductions.other,
//       'otherNote': deductions.otherNote,
//     },
//     'notes': '',
//   };
// }
//   // Map<String, dynamic> _buildPayload({
//   //   required String farmerId,
//   //   required String createdBy,
//   //   required List<PurchaseLine> lines,
//   //   required DeductionData deductions,
//   // }) {
//   //   final double grossTotal = lines.fold(0.0, (s, l) => s + l.lineTotal);

//   //   final double commissionAmount = deductions.commissionType == 'percent'
//   //       ? (deductions.commission / 100) * grossTotal
//   //       : deductions.commission;

//   //   final preparedLines = lines.map((l) {
//   //     double actualQty = l.actualQty;
//   //     if (l.pricingType == 'kg' && l.bags > 0 && l.weightPerBag > 0) {
//   //       actualQty = l.bags * l.weightPerBag;
//   //     }
//   //     return {
//   //       'productName': l.productName,
//   //       'pricingType': l.pricingType,
//   //       'bags': l.bags,
//   //       'weightPerBag': l.weightPerBag,
//   //       'actualQty': actualQty,
//   //       'qualityDeduction': l.qualityDeduction,
//   //       'billedQty': l.billedQty,
//   //       'unit': l.unit,
//   //       'rate': l.rate,
//   //       'lineTotal': l.lineTotal,
//   //       'notes': '',
//   //     };
//   //   }).toList();

//   //   return {
//   //     'farmer': farmerId,
//   //     'createdBy': createdBy,
//   //     'purchaseDate': DateTime.now().toIso8601String(),
//   //     'lines': preparedLines,
//   //     'deductions': {
//   //       'transport': deductions.transport,
//   //       'labour': deductions.labour,
//   //       'commission': deductions.commission,
//   //       'commissionType': deductions.commissionType,
//   //       'storage': deductions.storage,
//   //       'storageNote': deductions.storageNote,
//   //       'returnDeduction': deductions.returnDeduction,
//   //       'returnNote': deductions.returnNote,
//   //       'advanceAdjusted': deductions.advanceAdjusted,
//   //       'other': deductions.other,
//   //       'otherNote': deductions.otherNote,
//   //     },
//   //     'notes': '',
//   //   };
    
//   // }

//   // ── ERROR EXTRACTOR ───────────────────────────────────────────
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
    final createRes = await _dioClient.dio.post(
      ApiRoutes.purchases,
      data: payload,
      options: Options(validateStatus: (s) => true),
    );
 
    if (createRes.statusCode != 201 && createRes.statusCode != 200) {
      throw Exception('Server error ${createRes.statusCode}: ${_extractErrorMsg(createRes.data)}');
    }
 
    // Extract purchase ID from response
    final responseData = createRes.data as Map<String, dynamic>;
    final purchaseId =
        (responseData['purchase'] as Map<String, dynamic>?)?['_id']?.toString() ??
        responseData['_id']?.toString() ??
        responseData['id']?.toString() ??
        '';
 
    if (purchaseId.isEmpty) {
      throw Exception('Purchase created but ID not returned from server');
    }
 
    // STEP 2: PATCH status from 'draft' to 'saved'
    // This marks the purchase as confirmed by the operator
    final patchRes = await _dioClient.dio.patch(
      ApiRoutes.purchaseStatus(purchaseId),
      data: {'status': 'saved'},
      options: Options(validateStatus: (s) => true),
    );
 
    if (patchRes.statusCode != 200) {
      // Don't fail the whole flow — purchase was created, just status update failed
      // Log it but return the ID anyway
      print('⚠️ Purchase created but status update failed: ${patchRes.statusCode}');
    }
 
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
 

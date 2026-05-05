// ─────────────────────────────────────────────────────────────
// PURCHASE SERVICE
// ─────────────────────────────────────────────────────────────

import 'package:agr_market/services/constant_service.dart';
import '../../../services/dio_client.dart';
import '../../models/farmer_model.dart';
import '../../models/purchase_model.dart';
import '../../models/deduction_model.dart';

class PurchaseService {
  final DioClient _dioClient = DioClient.instance;

  Future<List<FarmerModel>> fetchFarmers() async {
    try {
      final res = await _dioClient.dio.get(ApiRoutes.farmers);
      final data = res.data;
      List list = [];
      if (data is List) list = data;
      else if (data is Map && data['farmers'] is List) list = data['farmers'];
      else if (data is Map && data['data'] is List) list = data['data'];
      
      return list.map((j) => FarmerModel.fromJson(j)).toList();
    } catch (e) {
      throw Exception('Failed to fetch farmers: $e');
    }
  }

  Future<void> savePurchase({
    required String farmerId,
    required List<PurchaseLine> lines,
    required DeductionData deductions,
  }) async {
    try {
      final payload = {
        'farmerId': farmerId,
        'purchaseDate': DateTime.now().toIso8601String(),
        'lines': lines.map((l) => l.toJson()).toList(),
        'deductions': deductions.toJson(),
      };

      final res = await _dioClient.dio
          .post(ApiRoutes.purchases, data: payload);

      if (res.statusCode != 201 && res.statusCode != 200) {
        throw Exception('Failed to save purchase');
      }
    } catch (e) {
      throw Exception('Failed to save purchase: $e');
    }
  }
}
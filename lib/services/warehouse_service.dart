import 'package:dio/dio.dart';
import '../models/warehouse_model.dart';
import 'dio_client.dart';
import 'constant_service.dart';

class WarehouseService {
  WarehouseService._();
  static final instance = WarehouseService._();
  final Dio _dio = DioClient.instance.dio;

  Future<List<WarehouseModel>> getAll({bool? isActive, String? search}) async {
    final params = <String, dynamic>{};
    if (isActive != null) params['isActive'] = isActive;
    if (search != null) params['search'] = search;

    final res = await _dio.get(ApiRoutes.warehouses, queryParameters: params);
    final data = res.data as Map<String, dynamic>;
    final list = data['data'] as List;
    return list.map((e) => WarehouseModel.fromJson(e)).toList();
  }

  Future<WarehouseModel> create(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiRoutes.warehouses, data: data);
    return WarehouseModel.fromJson(res.data['data']);
  }

  Future<WarehouseModel> update(String id, Map<String, dynamic> data) async {
    final res = await _dio.put(ApiRoutes.warehouseById(id), data: data);
    return WarehouseModel.fromJson(res.data['data']['warehouse']);
  }

  Future<Map<String, dynamic>> delete(String id, {bool forceHardDelete = false}) async {
    try {
      // First try soft delete (mark as inactive)
      final softDeleteRes = await _dio.delete(ApiRoutes.warehouseById(id));
      
      // If soft delete succeeds, check if it was actually soft deleted or hard deleted
      // Backend might return a flag indicating if warehouse was empty and hard deleted
      if (softDeleteRes.data is Map) {
        final responseData = softDeleteRes.data as Map<String, dynamic>;
        final wasHardDeleted = responseData['hardDeleted'] == true || 
                               responseData['permanentlyDeleted'] == true ||
                               responseData['action'] == 'hard_delete';
        
        if (wasHardDeleted) {
          return {'action': 'hard_delete', 'message': 'Warehouse was empty and permanently deleted'};
        } else {
          return {'action': 'soft_delete', 'message': 'Warehouse has inventory and was marked as inactive'};
        }
      }
      
      return {'action': 'soft_delete', 'message': 'Warehouse soft deleted (marked inactive)'};
    } catch (e) {
      // If soft delete fails and forceHardDelete is true, try hard delete
      if (forceHardDelete) {
        try {
          await _dio.delete(ApiRoutes.warehouseHardDelete(id));
          return {'action': 'hard_delete', 'message': 'Warehouse permanently deleted'};
        } catch (hardError) {
          throw Exception('Failed to delete warehouse: $hardError');
        }
      }
      rethrow;
    }
  }

  /// Check if warehouse is empty (has no inventory)
  Future<bool> isWarehouseEmpty(String id) async {
    try {
      final res = await _dio.get(ApiRoutes.warehouseById(id));
      final data = res.data as Map<String, dynamic>;
      final warehouse = WarehouseModel.fromJson(data['data'] ?? data);
      
      // Check if warehouse has any inventory
      // Adjust based on your actual data structure
      final inventory = warehouse.inventory ?? [];
      final totalItems = warehouse.totalItems ?? 0;
      final occupiedSpace = warehouse.occupiedSpace ?? 0;
      
      return inventory.isEmpty && totalItems == 0 && occupiedSpace == 0;
    } catch (e) {
      // If we can't check, assume not empty to be safe
      return false;
    }
  }
}
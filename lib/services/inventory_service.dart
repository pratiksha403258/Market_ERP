import 'package:dio/dio.dart';
import '../models/inventory_model.dart';
import 'dio_client.dart';
import 'constant_service.dart';

class InventoryService {
  InventoryService._();
  static final instance = InventoryService._();
  final Dio _dio = DioClient.instance.dio;

  /// Get all inventory items with filters
  Future<List<InventoryItem>> getInventory({
    String? warehouse,
    String? search,
    bool lowStock = false,
  }) async {
    final params = <String, dynamic>{};
    if (warehouse != null && warehouse.isNotEmpty) params['warehouse'] = warehouse;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (lowStock) params['lowStock'] = true;

    final response = await _dio.get(ApiRoutes.inventory, queryParameters: params);
    final List data = response.data['data'] as List;
    return data.map((e) => InventoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Adjust stock (positive = add, negative = remove)
  Future<void> adjustStock({
    required String productName,
    required String warehouse,
    required double adjustment,
    required String reason,
    String? notes,
  }) async {
    await _dio.post(ApiRoutes.inventoryAdjust, data: {
      'productName': productName,
      'warehouse': warehouse,
      'adjustment': adjustment,
      'reason': reason,
      'notes': notes ?? '',
    });
  }

  /// Transfer stock between warehouses
  Future<void> transferStock({
    required String productName,
    required String fromWarehouse,
    required String toWarehouse,
    required double qty,
  }) async {
    await _dio.post(ApiRoutes.inventoryTransfer, data: {
      'productName': productName,
      'fromWarehouse': fromWarehouse,
      'toWarehouse': toWarehouse,
      'qty': qty,
    });
  }

  /// Get all unique warehouse names (from existing inventory)
  Future<List<String>> getWarehouseNames() async {
    final items = await getInventory();
    final names = items.map((e) => e.warehouse).toSet().toList();
    names.sort();
    return names;
  }

  /// Get all unique product names (for autocomplete)
  Future<List<String>> getProductNames() async {
    final items = await getInventory();
    final names = items.map((e) => e.productName).toSet().toList();
    names.sort();
    return names;
  }
}
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:agr_market/services/dio_client.dart';
import 'package:agr_market/services/constant_service.dart';
import '../models/product_models.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  String? _searchQuery;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> loadProducts({String? search, bool refresh = true}) async {
    if (refresh) {
      _currentPage = 1;
      _products = [];
      _hasMore = true;
      _searchQuery = search;
    }

    if (_isLoading) return;
    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {
        'page': _currentPage,
        'limit': 20,
      };

      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }

      final response = await DioClient.instance.dio.get(
        ApiRoutes.products,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final newProducts = data.map((json) => ProductModel.fromJson(json)).toList();

        final pagination = response.data['pagination'];
        final total = pagination['total'] as int;

        _products.addAll(newProducts);
        _hasMore = _products.length < total;
        _currentPage++;
      } else {
        _error = response.data['message'] ?? 'Failed to load products';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(String productName, String description) async {
    try {
      final response = await DioClient.instance.dio.post(
        ApiRoutes.products,
        data: {
          'productName': productName.trim(),
          'description': description.trim(),
          'isActive': true,
        },
      );

      debugPrint('✅ Add product response: ${response.data}');

      if (response.statusCode == 201 || response.data['success'] == true) {
        Map<String, dynamic> productData;
        if (response.data['data'] != null) {
          productData = response.data['data'];
        } else {
          productData = response.data;
        }

        final newProduct = ProductModel.fromJson(productData);
        _products.insert(0, newProduct);
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? response.data['error'] ?? 'Failed to add product';
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      debugPrint('❌ DioError adding product: $e');
      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data['error'] ?? 'Product with this name already exists';
        _error = errorMessage;
      } else {
        _error = e.message ?? 'Failed to add product';
      }
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Error adding product: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ✅ ADD THIS METHOD - Update existing product
  Future<bool> updateProduct(String id, String productName, String description, bool isActive) async {
    try {
      final response = await DioClient.instance.dio.put(
        ApiRoutes.productById(id),
        data: {
          'productName': productName.trim(),
          'description': description.trim(),
          'isActive': isActive,
        },
      );

      debugPrint('✅ Update product response: ${response.data}');

      if (response.data['success'] == true) {
        // Update the product in the list
        final productData = response.data['data'];
        final updatedProduct = ProductModel.fromJson(productData);

        final index = _products.indexWhere((p) => p.id == id);
        if (index != -1) {
          _products[index] = updatedProduct;
          notifyListeners();
        }
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to update product';
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      debugPrint('❌ DioError updating product: $e');
      _error = e.response?.data['message'] ?? e.message ?? 'Failed to update product';
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Error updating product: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleProductStatus(ProductModel product) async {
    try {
      final response = await DioClient.instance.dio.put(
        ApiRoutes.productById(product.id),
        data: {
          'productName': product.productName,
          'description': product.description,
          'isActive': !product.isActive,
        },
      );

      if (response.data['success'] == true) {
        product.isActive = !product.isActive;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error updating product: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final response = await DioClient.instance.dio.delete(
        ApiRoutes.productById(id),
      );

      if (response.data['success'] == true) {
        _products.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting product: $e');
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
import 'package:agr_market/models/farmer_model.dart';
import 'package:agr_market/services/farmer_service.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  FARMER PROVIDER — controller for farmer state
// ─────────────────────────────────────────────────────────────
class FarmerProvider extends ChangeNotifier {
  List<FarmerModel> _farmers   = [];
  List<FarmerModel> _filteredFarmers = [];
  bool              _isLoading = false;
  bool              _isCreating= false;
  String?           _error;
  String            _search    = '';
  int               _page      = 1;
  int               _total     = 0;
  bool              _hasMore   = true;

  // Return filtered list if search is active, otherwise return all farmers
  List<FarmerModel> get farmers => _search.isEmpty ? _farmers : _filteredFarmers;
  bool              get isLoading  => _isLoading;
  bool              get isCreating => _isCreating;
  String?           get error      => _error;
  int               get total      => _total;
  bool              get hasMore    => _hasMore;
  String            get searchQuery => _search;

  void clearError() { _error = null; notifyListeners(); }

  // ── Search farmers locally by name or village ─────────────────
  void searchFarmers(String query) {
    _search = query;
    
    if (query.isEmpty) {
      _filteredFarmers = [];
      notifyListeners();
      return;
    }

    final lowerQuery = query.toLowerCase();
    _filteredFarmers = _farmers.where((farmer) {
      final nameMatch = farmer.name.toLowerCase().contains(lowerQuery);
      final villageMatch = farmer.village?.toLowerCase().contains(lowerQuery) ?? false;
      // Optional: search by mobile number too
      // final mobileMatch = farmer.mobile.contains(query);
      
      return nameMatch || villageMatch;
    }).toList();
    
    notifyListeners();
  }

  // ── Clear search and reset to full list ───────────────────────
  void clearSearch() {
    _search = '';
    _filteredFarmers = [];
    notifyListeners();
  }

  // ── Load farmers (fresh) ──────────────────────────────────────
  Future<void> loadFarmers({String? search}) async {
    _search  = search ?? '';
    _page    = 1;
    _hasMore = true;
    _filteredFarmers = []; // Clear filtered results
    _setLoading(true);

    final result = await FarmerService.instance.getFarmers(
        page: 1, search: _search.isEmpty ? null : _search);

    _setLoading(false);
    if (result.isSuccess && result.data != null) {
      _farmers    = result.data!.farmers;
      _total      = result.data!.total;
      _hasMore    = _page < result.data!.totalPages;
      
      // If there's an active search, apply it to the new data
      if (_search.isNotEmpty) {
        searchFarmers(_search);
      }
    } else {
      _error = result.message;
    }
    notifyListeners();
  }

  // ── Load more (pagination) ────────────────────────────────────
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore || _search.isNotEmpty) return; // Don't paginate during search
    _page++;
    _setLoading(true);

    final result = await FarmerService.instance.getFarmers(
        page: _page, search: null);

    _setLoading(false);
    if (result.isSuccess && result.data != null) {
      _farmers.addAll(result.data!.farmers);
      _hasMore = _page < result.data!.totalPages;
      notifyListeners();
    }
  }

  // ── Delete farmer ─────────────────────────────────────────────
  Future<bool> deleteFarmer(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await FarmerService.instance.deleteFarmer(id);
    
    _isLoading = false;
    if (result.isSuccess) {
      _farmers.removeWhere((f) => f.id == id);
      _filteredFarmers.removeWhere((f) => f.id == id);
      _total--;
      notifyListeners();
      return true;
    }
    _error = result.message;
    notifyListeners();
    return false;
  }

  // ── Create farmer ─────────────────────────────────────────────
  Future<bool> createFarmer({
    required String name,
    required String mobile,
    String? village,
    String? city,
    String? address,
    String? bankAccountNumber,
    String? ifscCode,
    
    String? bankName,
    String? gstNumber,
  }) async {
    _isCreating = true;
    _error      = null;
    notifyListeners();

    final result = await FarmerService.instance.createFarmer(
      name:              name,
      mobile:            mobile,
      village:           village,
      city:              city,
      address:           address,
      bankAccountNumber: bankAccountNumber,
      ifscCode:          ifscCode,
      bankName:          bankName,
      gstNumber:         gstNumber,
    );

    _isCreating = false;
    if (result.isSuccess && result.data != null) {
      _farmers.insert(0, result.data!);
      _total++;
      
      // If search is active, check if new farmer matches search criteria
      if (_search.isNotEmpty) {
        final lowerQuery = _search.toLowerCase();
        final nameMatch = result.data!.name.toLowerCase().contains(lowerQuery);
        final villageMatch = result.data!.village?.toLowerCase().contains(lowerQuery) ?? false;
        if (nameMatch || villageMatch) {
          _filteredFarmers.insert(0, result.data!);
        }
      }
      
      notifyListeners();
      return true;
    }
    _error = result.message;
    notifyListeners();
    return false;
  }

  // ── Update farmer ─────────────────────────────────────────────
  Future<bool> updateFarmer(String id, Map<String, dynamic> updates) async {
    _isCreating = true;
    notifyListeners();

    final result = await FarmerService.instance.updateFarmer(id, updates);
    _isCreating = false;

    if (result.isSuccess && result.data != null) {
      final idx = _farmers.indexWhere((f) => f.id == id);
      if (idx != -1) _farmers[idx] = result.data!;
      
      // Update in filtered list if present
      final filteredIdx = _filteredFarmers.indexWhere((f) => f.id == id);
      if (filteredIdx != -1) _filteredFarmers[filteredIdx] = result.data!;
      
      notifyListeners();
      return true;
    }
    _error = result.message;
    notifyListeners();
    return false;
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
}
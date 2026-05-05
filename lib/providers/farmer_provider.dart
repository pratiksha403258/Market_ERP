import 'package:agr_market/models/farmer_model.dart';
import 'package:agr_market/services/farmer_service.dart';
import 'package:flutter/material.dart';


// ─────────────────────────────────────────────────────────────
//  FARMER PROVIDER — controller for farmer state
// ─────────────────────────────────────────────────────────────
class FarmerProvider extends ChangeNotifier {
  List<FarmerModel> _farmers   = [];
  bool              _isLoading = false;
  bool              _isCreating= false;
  String?           _error;
  String            _search    = '';
  int               _page      = 1;
  int               _total     = 0;
  bool              _hasMore   = true;

  List<FarmerModel> get farmers    => _farmers;
  bool              get isLoading  => _isLoading;
  bool              get isCreating => _isCreating;
  String?           get error      => _error;
  int               get total      => _total;
  bool              get hasMore    => _hasMore;

  void clearError() { _error = null; notifyListeners(); }

  // ── Load farmers (fresh) ──────────────────────────────────────
  Future<void> loadFarmers({String? search}) async {
    _search  = search ?? '';
    _page    = 1;
    _hasMore = true;
    _setLoading(true);

    final result = await FarmerService.instance.getFarmers(
        page: 1, search: _search.isEmpty ? null : _search);

    _setLoading(false);
    if (result.isSuccess && result.data != null) {
      _farmers    = result.data!.farmers;
      _total      = result.data!.total;
      _hasMore    = _page < result.data!.totalPages;
    } else {
      _error = result.message;
    }
    notifyListeners();
  }

  // ── Load more (pagination) ────────────────────────────────────
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    _page++;
    _setLoading(true);

    final result = await FarmerService.instance.getFarmers(
        page: _page, search: _search.isEmpty ? null : _search);

    _setLoading(false);
    if (result.isSuccess && result.data != null) {
      _farmers.addAll(result.data!.farmers);
      _hasMore = _page < result.data!.totalPages;
      notifyListeners();
    }
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
      notifyListeners();
      return true;
    }
    _error = result.message;
    notifyListeners();
    return false;
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
}
import 'package:flutter/material.dart';
import '../../models/farmer_model.dart';
import '../../models/purchase_model.dart';
import '../../models/deduction_model.dart';
import '../../services/purchase_service.dart';

class PurchaseController extends ChangeNotifier {
  final PurchaseService _purchaseService = PurchaseService();

  // ── State ─────────────────────────────────────────────────────
  int _currentStep = 0;
  FarmerModel? _selectedFarmer;
  List<FarmerModel> _farmers = [];
  bool _loadingFarmers = true;
  final List<PurchaseLine> _lines = [];
  final DeductionData _deductions = DeductionData();
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Edit mode
  String? _editingPurchaseId;

  // ── FIX: savedPurchaseId is properly stored after save ────────
  String? savedPurchaseId;

  bool get isEditMode => _editingPurchaseId != null;

  // ── Getters ───────────────────────────────────────────────────
  int get currentStep => _currentStep;
  FarmerModel? get selectedFarmer => _selectedFarmer;
  List<FarmerModel> get farmers => _filteredFarmers;
  bool get loadingFarmers => _loadingFarmers;
  List<PurchaseLine> get lines => _lines;
  DeductionData get deductions => _deductions;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  List<FarmerModel> get _filteredFarmers {
    if (_searchQuery.isEmpty) return _farmers;
    final query = _searchQuery.toLowerCase();
    return _farmers
        .where((f) =>
            f.name.toLowerCase().contains(query) ||
            f.mobile.contains(query))
        .toList();
  }

  // ── Computed ──────────────────────────────────────────────────
  double get grossTotal => _lines.fold(0, (s, l) => s + l.lineTotal);

  double get commissionAmount {
    if (_deductions.commissionType == 'percent') {
      return (_deductions.commission / 100) * grossTotal;
    }
    return _deductions.commission;
  }

  double get totalDeductions =>
      _deductions.transport +
      _deductions.labour +
      commissionAmount +
      _deductions.storage +
      _deductions.returnDeduction +
      _deductions.advanceAdjusted +
      _deductions.other;

  double get finalPayable =>
      (grossTotal - totalDeductions).clamp(0, double.infinity);

  // ── Init ──────────────────────────────────────────────────────
  PurchaseController() {
    loadFarmers();
    addLine();
  }

  // ── Search ────────────────────────────────────────────────────
  void searchFarmers(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFarmerSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // ── Edit Mode Init ────────────────────────────────────────────
  void initForEdit({
    required String purchaseId,
    required FarmerModel farmer,
    required List<PurchaseLine> existingLines,
    required DeductionData existingDeductions,
  }) {
    _editingPurchaseId = purchaseId;
    _selectedFarmer = farmer;
    _lines
      ..clear()
      ..addAll(existingLines);
    _deductions.transport = existingDeductions.transport;
    _deductions.labour = existingDeductions.labour;
    _deductions.commission = existingDeductions.commission;
    _deductions.commissionType = existingDeductions.commissionType;
    _deductions.storage = existingDeductions.storage;
    _deductions.storageNote = existingDeductions.storageNote;
    _deductions.returnDeduction = existingDeductions.returnDeduction;
    _deductions.returnNote = existingDeductions.returnNote;
    _deductions.advanceAdjusted = existingDeductions.advanceAdjusted;
    _deductions.other = existingDeductions.other;
    _deductions.otherNote = existingDeductions.otherNote;
    notifyListeners();
  }

  // ── Farmers ───────────────────────────────────────────────────
  Future<void> loadFarmers() async {
    setLoadingFarmers(true);
    try {
      _farmers = await _purchaseService.fetchFarmers();
      setError(null);
    } catch (e) {
      setError('Failed to load farmers: $e');
    } finally {
      setLoadingFarmers(false);
    }
  }

  void selectFarmer(FarmerModel farmer) {
    _selectedFarmer = farmer;
    notifyListeners();
  }

  // ── Navigation ────────────────────────────────────────────────
  void nextStep() {
    if (_currentStep == 0 && _selectedFarmer == null) {
      setError('Please select a farmer');
      return;
    }
    if (_currentStep == 1 && !areLinesValid()) {
      setError('Fill all product name and rate fields');
      return;
    }
    if (_currentStep == 1 && _selectedFarmer != null) {
      _deductions.advanceAdjusted =
          _selectedFarmer!.advanceBalance.clamp(0, grossTotal);
    }
    if (_currentStep < 3) {
      setError(null);
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      setError(null);
      _currentStep--;
      notifyListeners();
    }
  }

  bool areLinesValid() =>
      _lines.every((l) => l.productName.isNotEmpty && l.rate > 0);

  // ── Lines ─────────────────────────────────────────────────────
  void addLine() {
    _lines.add(PurchaseLine(
        id: DateTime.now().millisecondsSinceEpoch.toString()));
    notifyListeners();
  }

  void removeLine(String id) {
    if (_lines.length == 1) return;
    _lines.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  void updateLine(String id, PurchaseLine updatedLine) {
    final index = _lines.indexWhere((l) => l.id == id);
    if (index != -1) {
      _lines[index] = updatedLine;
      notifyListeners();
    }
  }

  // ── Deductions ────────────────────────────────────────────────
  void updateDeduction({
    double? transport,
    double? labour,
    double? commission,
    String? commissionType,
    double? storage,
    String? storageNote,
    double? returnDeduction,
    String? returnNote,
    double? advanceAdjusted,
    double? other,
    String? otherNote,
  }) {
    _deductions.transport = transport ?? _deductions.transport;
    _deductions.labour = labour ?? _deductions.labour;
    _deductions.commission = commission ?? _deductions.commission;
    _deductions.commissionType = commissionType ?? _deductions.commissionType;
    _deductions.storage = storage ?? _deductions.storage;
    _deductions.storageNote = storageNote ?? _deductions.storageNote;
    _deductions.returnDeduction = returnDeduction ?? _deductions.returnDeduction;
    _deductions.returnNote = returnNote ?? _deductions.returnNote;
    _deductions.advanceAdjusted = advanceAdjusted ?? _deductions.advanceAdjusted;
    _deductions.other = other ?? _deductions.other;
    _deductions.otherNote = otherNote ?? _deductions.otherNote;
    notifyListeners();
  }

  void updateAdvanceAdjusted(double value) {
    final maxAdv = _selectedFarmer?.advanceBalance ?? 0;
    _deductions.advanceAdjusted = value.clamp(0, maxAdv);
    notifyListeners();
  }

  void toggleRateLock(String lineId, bool locked) {
    final index = _lines.indexWhere((l) => l.id == lineId);
    if (index != -1) {
      _lines[index] = _lines[index].copyWith(rateLocked: locked);
      notifyListeners();
    }
  }

  // ── SAVE OR UPDATE ────────────────────────────────────────────
  Future<bool> savePurchase() async {
    if (_selectedFarmer == null) {
      setError('No farmer selected');
      return false;
    }

    setSaving(true);
    setError(null);

    try {
      if (isEditMode) {
        await _purchaseService.updatePurchase(
          purchaseId: _editingPurchaseId!,
          farmerId: _selectedFarmer!.id,
          lines: _lines,
          deductions: _deductions,
        );
        // In edit mode, savedPurchaseId = the existing purchase id
        savedPurchaseId = _editingPurchaseId;
      } else {
        // ── FIX: Store the returned purchaseId in savedPurchaseId ──
        final purchaseId = await _purchaseService.savePurchase(
          farmerId: _selectedFarmer!.id,
          lines: _lines,
          deductions: _deductions,
        );
        savedPurchaseId = purchaseId.isNotEmpty ? purchaseId : null;
        _editingPurchaseId = savedPurchaseId;
      }

      setSaving(false);
      return savedPurchaseId != null && savedPurchaseId!.isNotEmpty;
    } catch (e) {
      setError('Failed to save: $e');
      setSaving(false);
      return false;
    }
  }

  // ── DELETE ────────────────────────────────────────────────────
  Future<bool> deletePurchase({bool force = false}) async {
    if (_editingPurchaseId == null) {
      setError('No purchase to delete');
      return false;
    }

    _isDeleting = true;
    setError(null);
    notifyListeners();

    try {
      await _purchaseService.deletePurchase(
        purchaseId: _editingPurchaseId!,
        force: force,
      );
      _isDeleting = false;
      notifyListeners();
      return true;
    } catch (e) {
      setError('Failed to delete: $e');
      _isDeleting = false;
      notifyListeners();
      return false;
    }
  }

  // ── Reset ─────────────────────────────────────────────────────
  void reset() {
    _currentStep = 0;
    _selectedFarmer = null;
    _editingPurchaseId = null;
    savedPurchaseId = null;
    _lines.clear();
    _deductions.transport = 0;
    _deductions.labour = 0;
    _deductions.commission = 0;
    _deductions.commissionType = 'fixed';
    _deductions.storage = 0;
    _deductions.storageNote = '';
    _deductions.returnDeduction = 0;
    _deductions.returnNote = '';
    _deductions.advanceAdjusted = 0;
    _deductions.other = 0;
    _deductions.otherNote = '';
    _isSaving = false;
    _isDeleting = false;
    _errorMessage = null;
    _searchQuery = '';
    addLine();
    loadFarmers();
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────
  void setLoadingFarmers(bool v) {
    _loadingFarmers = v;
    notifyListeners();
  }

  void setSaving(bool v) {
    _isSaving = v;
    notifyListeners();
  }

  void setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }
}
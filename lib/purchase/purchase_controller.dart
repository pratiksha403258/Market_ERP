// ─────────────────────────────────────────────────────────────
// PURCHASE CONTROLLER
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../models/farmer_model.dart';
import '../../models/purchase_model.dart';
import '../../models/deduction_model.dart';
import '../../services/purchase_service.dart';

class PurchaseController extends ChangeNotifier {
  final PurchaseService _purchaseService = PurchaseService();
  
  // State
  int _currentStep = 0;
  FarmerModel? _selectedFarmer;
  List<FarmerModel> _farmers = [];
  bool _loadingFarmers = true;
  final List<PurchaseLine> _lines = [];
  final DeductionData _deductions = DeductionData();
  bool _isSaving = false;
  String? _errorMessage;

  // Getters
  int get currentStep => _currentStep;
  FarmerModel? get selectedFarmer => _selectedFarmer;
  List<FarmerModel> get farmers => _farmers;
  bool get loadingFarmers => _loadingFarmers;
  List<PurchaseLine> get lines => _lines;
  DeductionData get deductions => _deductions;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  // Computed values
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
  
  double get finalPayable => (grossTotal - totalDeductions).clamp(0, double.infinity);

  // Lifecycle
  PurchaseController() {
    loadFarmers();
    addLine(); // start with one empty line
  }

  // Farmer Management
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

  // Navigation
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
      // Pre-fill advance in deductions
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

  bool areLinesValid() {
    return _lines.every((l) => l.productName.isNotEmpty && l.rate > 0);
  }

  // Line Management
  void addLine() {
    _lines.add(PurchaseLine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    ));
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

  // Deduction Management
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

  // Rate Lock
  void toggleRateLock(String lineId, bool locked) {
    final index = _lines.indexWhere((l) => l.id == lineId);
    if (index != -1) {
      _lines[index] = _lines[index].copyWith(rateLocked: locked);
      notifyListeners();
    }
  }

  // Save Purchase
  Future<bool> savePurchase() async {
    if (_selectedFarmer == null) {
      setError('No farmer selected');
      return false;
    }
    
    setSaving(true);
    setError(null);
    
    try {
      await _purchaseService.savePurchase(
        farmerId: _selectedFarmer!.id,
        lines: _lines,
        deductions: _deductions,
      );
      setSaving(false);
      return true;
    } catch (e) {
      setError('Failed to save purchase: $e');
      setSaving(false);
      return false;
    }
  }

  // Reset
  void reset() {
    _currentStep = 0;
    _selectedFarmer = null;
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
    _errorMessage = null;
    addLine();
    notifyListeners();
  }

  // Private helpers
  void setLoadingFarmers(bool value) {
    _loadingFarmers = value;
    notifyListeners();
  }

  void setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
}
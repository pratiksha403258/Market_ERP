
import 'dart:convert';

import 'package:agr_market/sales/sales_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';
import '../../../services/sale_service.dart';
import 'package:dio/dio.dart';
import '../../../services/dio_client.dart';

// ──────────────────────────────────────────────────────────────
// Dropdown Models & Services
// ──────────────────────────────────────────────────────────────

class DropdownBuyer {
  final String id;
  final String name;
  final String displayName;
  final String mobile;
  final String city;
  final String businessName;
  final String fullAddress;

  const DropdownBuyer({
    required this.id,
    required this.name,
    required this.displayName,
    required this.mobile,
    required this.city,
    required this.businessName,
    required this.fullAddress,
  });

  factory DropdownBuyer.fromJson(Map<String, dynamic> j) => DropdownBuyer(
        id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        displayName: j['displayName']?.toString() ?? j['name']?.toString() ?? '',
        mobile: j['mobile']?.toString() ?? '',
        city: j['city']?.toString() ?? '',
        businessName: j['businessName']?.toString() ?? '',
        fullAddress: j['fullAddress']?.toString() ?? '',
      );
}

class _BuyerDropdownService {
  static final _dio = DioClient.instance.dio;

  static Future<List<DropdownBuyer>> fetch({String search = '', int limit = 100}) async {
    try {
      final params = <String, dynamic>{'limit': limit};
      if (search.isNotEmpty) params['search'] = search;

      final res = await _dio.get(
        '/buyers/dropdown',
        queryParameters: params,
        options: Options(validateStatus: (_) => true),
      );

      if (res.statusCode == 200) {
        final body = res.data as Map<String, dynamic>;
        if (body['success'] == true) {
          final list = body['data'] as List? ?? [];
          return list
              .map((e) => DropdownBuyer.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }
}

// NEW: Product dropdown model & service
class DropdownProduct {
  final String id;
  final String name;


  const DropdownProduct({
    required this.id,
    required this.name,
   
  });

  factory DropdownProduct.fromJson(Map<String, dynamic> j) => DropdownProduct(
        id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
        name: j['productName']?.toString() ?? j['name']?.toString() ?? '',
        // description: j['description']?.toString() ?? '',
      );
}

class _ProductDropdownService {
  static final _dio = DioClient.instance.dio;

  static Future<List<DropdownProduct>> fetch({String search = '', int limit = 100}) async {
    try {
      final params = <String, dynamic>{'limit': limit, 'isActive': true};
      if (search.isNotEmpty) params['search'] = search;

      final res = await _dio.get(
        '/products', // uses ApiRoutes.products
        queryParameters: params,
        options: Options(validateStatus: (_) => true),
      );

      if (res.statusCode == 200) {
        final body = res.data as Map<String, dynamic>;
        // Assuming API returns { success: true, data: [...] }
        if (body['success'] == true) {
          final list = body['data'] as List? ?? [];
          return list
              .map((e) => DropdownProduct.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        // Fallback if response is a direct array
        if (body['data'] == null && body is List) {
          // return body
              // .map((e) => DropdownProduct.fromJson(e as Map<String, dynamic>))
              // .toList();
        }
      }
    } catch (_) {}
    return [];
  }
}

// ──────────────────────────────────────────────────────────────
// SaleCreateScreen (main widget)
// ──────────────────────────────────────────────────────────────

class SaleCreateScreen extends StatefulWidget {
  const SaleCreateScreen({super.key});

  @override
  State<SaleCreateScreen> createState() => _SaleCreateScreenState();
}

class _SaleCreateScreenState extends State<SaleCreateScreen>
    with SingleTickerProviderStateMixin {
  // ── Step ──────────────────────────────────────────────────────
  int _step = 0;
  static const _stepLabels = ['Buyer', 'Product', 'Deductions', 'Review'];

  // ── Step 0: Buyer ─────────────────────────────────────────────
  List<DropdownBuyer> _allBuyers = [];
  List<DropdownBuyer> _filteredBuyers = [];
  bool _buyersLoading = false;
  bool _showBuyerDropdown = false;
  DropdownBuyer? _selectedBuyer;
  static const int _initialVisibleCount = 5;
  int _buyerVisibleCount = _initialVisibleCount;
  final _buyerSearchCtrl = TextEditingController();
  final _buyerSearchFocus = FocusNode();

  final _buyerNameCtrl = TextEditingController();
  final _buyerMobileCtrl = TextEditingController();
  final _buyerGstCtrl = TextEditingController();
  final _buyerAddressCtrl = TextEditingController();

  // ── Step 1: Product ───────────────────────────────────────────
  // NEW: Product dropdown state
  List<DropdownProduct> _allProducts = [];
  List<DropdownProduct> _filteredProducts = [];
  bool _productsLoading = false;
  bool _showProductDropdown = false;
  DropdownProduct? _selectedProduct;
  int _productVisibleCount = _initialVisibleCount;
  final _productSearchFocus = FocusNode();

  // The product name controller (existing) will also serve as search input
  final _productNameCtrl = TextEditingController();

  String _pricingType = 'kg';
  final _bagsCtrl = TextEditingController();
  final _weightPerBagCtrl = TextEditingController();
  final _qualityDeductionCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _productNotesCtrl = TextEditingController();

  // ── Step 2: Deductions ────────────────────────────────────────
  final _transportCtrl = TextEditingController();
  final _labourCtrl = TextEditingController();
  final _commissionCtrl = TextEditingController();
  String _commissionType = 'fixed';
  final _storageCtrl = TextEditingController();
  final _advanceAdjustedCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // ── Computed ──────────────────────────────────────────────────
  int get _bags => int.tryParse(_bagsCtrl.text.trim()) ?? 0;
  double get _weightPerBag => double.tryParse(_weightPerBagCtrl.text.trim()) ?? 0;
  double get _qualityDeduction => double.tryParse(_qualityDeductionCtrl.text.trim()) ?? 0;
  double get _rate => double.tryParse(_rateCtrl.text.trim()) ?? 0;
  double get _actualQty => _bags * _weightPerBag;
  double get _netQty => _actualQty - _qualityDeduction;
  double get _grossTotal => _netQty * _rate;

  double get _transport => double.tryParse(_transportCtrl.text.trim()) ?? 0;
  double get _labour => double.tryParse(_labourCtrl.text.trim()) ?? 0;
  double get _commission => double.tryParse(_commissionCtrl.text.trim()) ?? 0;
  double get _storage => double.tryParse(_storageCtrl.text.trim()) ?? 0;
  double get _advanceAdjusted => double.tryParse(_advanceAdjustedCtrl.text.trim()) ?? 0;
  double get _other => double.tryParse(_otherCtrl.text.trim()) ?? 0;

  double get _totalDeductions {
    double commission = _commission;
    if (_commissionType == 'percent') commission = (_grossTotal * _commission) / 100;
    return _transport + _labour + commission + _storage + _advanceAdjusted + _other;
  }

  double get _finalReceivable =>
      (_grossTotal - _totalDeductions).clamp(0, double.infinity);

  // ── Misc ──────────────────────────────────────────────────────
  bool _saving = false;
  String? _error;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  static const _pricingTypes = ['kg', 'quintal', 'fixed'];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    for (final c in [
      _bagsCtrl, _weightPerBagCtrl, _qualityDeductionCtrl, _rateCtrl,
      _transportCtrl, _labourCtrl, _commissionCtrl, _storageCtrl,
      _advanceAdjustedCtrl, _otherCtrl,
    ]) {
      c.addListener(_recalc);
    }

    // Buyer search listeners
    _buyerSearchCtrl.addListener(_onBuyerSearchChanged);
    _buyerSearchFocus.addListener(() {
      if (_buyerSearchFocus.hasFocus && _allBuyers.isNotEmpty) {
        setState(() => _showBuyerDropdown = true);
      }
    });

    // NEW: Product search listeners
    _productNameCtrl.addListener(_onProductSearchChanged);
    _productSearchFocus.addListener(() {
      if (_productSearchFocus.hasFocus && _allProducts.isNotEmpty) {
        setState(() => _showProductDropdown = true);
      }
    });

    _loadBuyers();
    _loadProducts(); // Load product master
  }

  // ── Buyer Dropdown Logic ──────────────────────────────────────
  Future<void> _loadBuyers({String search = ''}) async {
    setState(() => _buyersLoading = true);
    final buyers = await _BuyerDropdownService.fetch(search: search);
    if (mounted) {
      setState(() {
        _allBuyers = buyers;
        _filteredBuyers = buyers;
        _buyerVisibleCount = _initialVisibleCount;
        _buyersLoading = false;
      });
    }
  }

  void _onBuyerSearchChanged() {
    final query = _buyerSearchCtrl.text.trim().toLowerCase();
    setState(() {
      _showBuyerDropdown = true;
      _buyerVisibleCount = _initialVisibleCount;
      if (query.isEmpty) {
        _filteredBuyers = _allBuyers;
      } else {
        _filteredBuyers = _allBuyers.where((b) {
          return b.displayName.toLowerCase().contains(query) ||
              b.name.toLowerCase().contains(query) ||
              b.mobile.contains(query) ||
              b.businessName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _selectBuyer(DropdownBuyer buyer) {
    setState(() {
      _selectedBuyer = buyer;
      _showBuyerDropdown = false;
      _buyerSearchCtrl.text = buyer.displayName;
      _buyerNameCtrl.text = buyer.name;
      _buyerMobileCtrl.text = buyer.mobile;
      _buyerAddressCtrl.text = buyer.fullAddress;
      _buyerGstCtrl.clear();
    });
    _buyerSearchFocus.unfocus();
  }

  void _clearBuyerSelection() {
    setState(() {
      _selectedBuyer = null;
      _buyerSearchCtrl.clear();
      _buyerNameCtrl.clear();
      _buyerMobileCtrl.clear();
      _buyerAddressCtrl.clear();
      _buyerGstCtrl.clear();
      _showBuyerDropdown = false;
    });
  }

  // ── NEW: Product Dropdown Logic ───────────────────────────────
  Future<void> _loadProducts({String search = ''}) async {
    setState(() => _productsLoading = true);
    final products = await _ProductDropdownService.fetch(search: search);
    if (mounted) {
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _productVisibleCount = _initialVisibleCount;
        _productsLoading = false;
      });
    }
  }

  void _onProductSearchChanged() {
    final query = _productNameCtrl.text.trim().toLowerCase();
    setState(() {
      _showProductDropdown = true;
      _productVisibleCount = _initialVisibleCount;
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((p) {
          return p.name.toLowerCase().contains(query) ;
              // p.description.toLowerCase().contains(query);
         }).toList();
      }
    });
  }

  void _selectProduct(DropdownProduct product) {
    setState(() {
      _selectedProduct = product;
      _showProductDropdown = false;
      // Auto-fill product name (can still be edited manually)
      _productNameCtrl.text = product.name;
    });
    _productSearchFocus.unfocus();
  }

  void _clearProductSelection() {
    setState(() {
      _selectedProduct = null;
      _productNameCtrl.clear();
      _showProductDropdown = false;
    });
  }

  void _recalc() => setState(() {});

  @override
  void dispose() {
    _animCtrl.dispose();
    _buyerSearchCtrl.dispose();
    _buyerSearchFocus.dispose();
    _productNameCtrl.dispose();
    _productSearchFocus.dispose();
    for (final c in [
      _buyerNameCtrl, _buyerMobileCtrl, _buyerGstCtrl, _buyerAddressCtrl,
      _bagsCtrl, _weightPerBagCtrl, _qualityDeductionCtrl,
      _rateCtrl, _productNotesCtrl, _transportCtrl, _labourCtrl,
      _commissionCtrl, _storageCtrl, _advanceAdjustedCtrl, _otherCtrl,
      _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────
  void _next() {
    final err = _validateCurrent();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() => _error = null);
    if (_step < 3) {
      _step++;
      _animCtrl.reset();
      _animCtrl.forward();
      setState(() {});
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() {
        _step--;
        _error = null;
      });
      _animCtrl.reset();
      _animCtrl.forward();
    } else {
      Navigator.pop(context);
    }
  }

  void _goToSalesList() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SalesListScreen()),
      );
    } catch (e) {
      debugPrint('Error navigating to Sales List: $e');
    }
  }

  String? _validateCurrent() {
    switch (_step) {
      case 0:
        if (_buyerNameCtrl.text.trim().isEmpty) return 'Select or enter a buyer name';
        if (_buyerNameCtrl.text.trim().length < 2) {
          return 'Buyer name must be at least 2 characters';
        }
        if (_buyerMobileCtrl.text.trim().isNotEmpty &&
            _buyerMobileCtrl.text.trim().length != 10) {
          return 'Mobile number must be 10 digits';
        }
        return null;
      case 1:
        if (_productNameCtrl.text.trim().isEmpty) return 'Enter product name';
        if (_bags <= 0) return 'Enter number of bags (must be > 0)';
        if (_weightPerBag <= 0) return 'Enter weight per bag (must be > 0)';
        if (_rate <= 0) return 'Enter rate (must be > 0)';
        if (_qualityDeduction >= _actualQty)
          return 'Quality deduction cannot exceed actual quantity';
        return null;
      case 2:
        return null;
      default:
        return null;
    }
  }

  // ── Submit ────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final lines = [
      {
        'productName': _productNameCtrl.text.trim(),
        'pricingType': _pricingType,
        'bags': _bags,
        'weightPerBag': _weightPerBag,
        'actualQty': _actualQty,
        'qualityDeduction': _qualityDeduction,
        'rate': _rate,
        if (_productNotesCtrl.text.trim().isNotEmpty)
          'notes': _productNotesCtrl.text.trim(),
      }
    ];

    final deductions = <String, dynamic>{
      if (_transport > 0) 'transport': _transport,
      if (_labour > 0) 'labour': _labour,
      if (_commission > 0) 'commission': _commission,
      'commissionType': _commissionType,
      if (_storage > 0) 'storage': _storage,
      if (_advanceAdjusted > 0) 'advanceAdjusted': _advanceAdjusted,
      if (_other > 0) 'other': _other,
    };

    final payload = <String, dynamic>{
      'buyerName': _buyerNameCtrl.text.trim(),
      if (_selectedBuyer != null) 'buyerId': _selectedBuyer!.id,
      if (_buyerMobileCtrl.text.trim().isNotEmpty)
        'buyerMobile': _buyerMobileCtrl.text.trim(),
      if (_buyerGstCtrl.text.trim().isNotEmpty)
        'buyerGst': _buyerGstCtrl.text.trim().toUpperCase(),
      if (_buyerAddressCtrl.text.trim().isNotEmpty)
        'buyerAddress': _buyerAddressCtrl.text.trim(),
      'saleDate': DateTime.now().toIso8601String().split('T')[0],
      'lines': lines,
      'deductions': deductions,
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };

    debugPrint('=== SALE PAYLOAD ===');
    debugPrint(jsonEncode(payload));

    final result = await SaleService.instance.createSale(payload);
    setState(() => _saving = false);

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sale created successfully!',
            style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ));
      Navigator.pop(context, true);
    } else {
      debugPrint('=== SALE ERROR ===\n${result.message}');
      setState(() => _error = result.message ?? 'Failed to create sale');
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_showBuyerDropdown) setState(() => _showBuyerDropdown = false);
        if (_showProductDropdown) setState(() => _showProductDropdown = false);
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(children: [
          // Gradient header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.30,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text('New Sale',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins')),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildStepIndicator(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Scrollable body
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(
                        color: AppColors.primary.withOpacity(0.10),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      )],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: _buildCurrentStep(),
                    ),
                  ),
                ),

                // Error
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.errorSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                  fontFamily: 'Poppins')),
                        ),
                      ]),
                    ),
                  ),

                const SizedBox(height: 20),

                // Continue / Create Sale button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _step < 3 ? 'Continue' : 'Create Sale',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins'),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _step < 3
                                      ? Icons.arrow_forward_rounded
                                      : Icons.storefront_rounded,
                                  size: 18),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // View Sales List button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _goToSalesList,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                            color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('View Sales List',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins')),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Step Indicator ────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(_stepLabels.length, (i) {
        final active = i == _step;
        final done = i < _step;
        return Expanded(
          child: Row(children: [
            Expanded(
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: active ? 24 : 20,
                        height: active ? 24 : 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done || active
                              ? Colors.white
                              : Colors.white.withOpacity(0.35),
                        ),
                        child: Center(
                          child: done
                              ? const Icon(Icons.check_rounded,
                                  color: AppColors.primary, size: 13)
                              : Text('${i + 1}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      color: active
                                          ? AppColors.primary
                                          : Colors.white
                                              .withOpacity(0.6))),
                        ),
                      ),
                    ]),
                const SizedBox(height: 4),
                Text(_stepLabels[i],
                    style: TextStyle(
                        color: active || done
                            ? Colors.white
                            : Colors.white.withOpacity(0.55),
                        fontSize: 9,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500)),
              ]),
            ),
            if (i < _stepLabels.length - 1)
              Container(
                  width: 20,
                  height: 1,
                  color: Colors.white.withOpacity(0.35)),
          ]),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildStep0Buyer();
      case 1:
        return _buildStep1Product();
      case 2:
        return _buildStep2Deductions();
      case 3:
        return _buildStep3Review();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── STEP 0 — Buyer Info (unchanged except variable rename) ─────
  Widget _buildStep0Buyer() {
    final visible = _filteredBuyers.take(_buyerVisibleCount).toList();
    final hasMore = _filteredBuyers.length > _buyerVisibleCount;

    return Column(
      key: const ValueKey('s0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Buyer Details', 'Search or select a buyer'),
        const SizedBox(height: 20),
        const Text('Buyer *',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins')),
        const SizedBox(height: 4),
        TextFormField(
          controller: _buyerSearchCtrl,
          focusNode: _buyerSearchFocus,
          style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins'),
          decoration: InputDecoration(
            hintText: 'Search buyer by name or mobile…',
            hintStyle:
                const TextStyle(color: AppColors.textHint, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textHint, size: 18),
            suffixIcon: _selectedBuyer != null
                ? GestureDetector(
                    onTap: _clearBuyerSelection,
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textHint, size: 18),
                  )
                : _buyersLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary),
                        ),
                      )
                    : null,
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5)),
          ),
          onTap: () => setState(() => _showBuyerDropdown = true),
          onChanged: (_) => setState(() => _showBuyerDropdown = true),
        ),
        if (_showBuyerDropdown) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buyersLoading && _allBuyers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                  )
                : visible.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          const Icon(Icons.search_off_rounded,
                              color: AppColors.textHint, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _buyerSearchCtrl.text.isEmpty
                                ? 'No buyers found'
                                : 'No match for "${_buyerSearchCtrl.text}"',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontFamily: 'Poppins'),
                          ),
                        ]),
                      )
                    : Column(
                        children: [
                          ...visible.map((b) => _buildBuyerTile(b)),
                          if (hasMore || _buyerVisibleCount > _initialVisibleCount)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (hasMore) {
                                    _buyerVisibleCount += _initialVisibleCount;
                                  } else {
                                    _buyerVisibleCount = _initialVisibleCount;
                                  }
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 14),
                                decoration: const BoxDecoration(
                                  border: Border(
                                      top: BorderSide(
                                          color: AppColors.divider)),
                                ),
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        hasMore
                                            ? Icons.expand_more_rounded
                                            : Icons
                                                .expand_less_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        hasMore
                                            ? 'Show ${(_filteredBuyers.length - _buyerVisibleCount).clamp(0, _initialVisibleCount)} more'
                                            : 'Show less',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Poppins'),
                                      ),
                                    ]),
                              ),
                            ),
                        ],
                      ),
          ),
        ],
        if (_selectedBuyer != null && !_showBuyerDropdown) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedBuyer!.displayName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                              fontFamily: 'Poppins')),
                      if (_selectedBuyer!.mobile.isNotEmpty)
                        Text(_selectedBuyer!.mobile,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontFamily: 'Poppins')),
                    ]),
              ),
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 18),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        Row(children: [
          const Expanded(child: Divider(color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              _selectedBuyer != null
                  ? 'Auto-filled details'
                  : 'Or enter manually',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins'),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.divider)),
        ]),
        const SizedBox(height: 14),
        _field('Buyer Name *', _buyerNameCtrl,
            hint: 'e.g. Ramesh Trading Co.',
            icon: Icons.person_outline_rounded,
            caps: TextCapitalization.words),
        const SizedBox(height: 12),
        _field('Mobile Number', _buyerMobileCtrl,
            hint: '9876543210',
            icon: Icons.phone_outlined,
            inputType: TextInputType.phone,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10),
        const SizedBox(height: 12),
        _field('GST Number (optional)', _buyerGstCtrl,
            hint: '27AAPFU0939F1ZV',
            icon: Icons.receipt_long_outlined,
            caps: TextCapitalization.characters,
            maxLength: 15),
        const SizedBox(height: 12),
        _multiLineField('Address (optional)', _buyerAddressCtrl,
            hint: 'Shop / village address...'),
      ],
    );
  }

  Widget _buildBuyerTile(DropdownBuyer buyer) {
    final isSelected = _selectedBuyer?.id == buyer.id;
    return InkWell(
      onTap: () => _selectBuyer(buyer),
      borderRadius: BorderRadius.circular(0),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primarySurface
              : Colors.transparent,
          border: const Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                buyer.name.isNotEmpty
                    ? buyer.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(buyer.displayName,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primaryDark
                              : AppColors.textPrimary,
                          fontFamily: 'Poppins')),
                  if (buyer.mobile.isNotEmpty || buyer.city.isNotEmpty)
                    Text(
                      [
                        if (buyer.mobile.isNotEmpty) buyer.mobile,
                        if (buyer.city.isNotEmpty) buyer.city,
                      ].join(' · '),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins'),
                    ),
                ]),
          ),
          if (isSelected)
            const Icon(Icons.check_rounded,
                color: AppColors.primary, size: 16),
        ]),
      ),
    );
  }

  // ── STEP 1 — Product (with product dropdown) ───────────────────
  Widget _buildStep1Product() {
    final visible = _filteredProducts.take(_productVisibleCount).toList();
    final hasMore = _filteredProducts.length > _productVisibleCount;

    return Column(
      key: const ValueKey('s1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Product Details', 'Enter weight & rate'),
        const SizedBox(height: 20),

        // Product name field with dropdown
        const Text('Product Name *',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins')),
        const SizedBox(height: 4),
        TextFormField(
          controller: _productNameCtrl,
          focusNode: _productSearchFocus,
          style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins'),
          decoration: InputDecoration(
            hintText: 'Search or type product name…',
            hintStyle:
                const TextStyle(color: AppColors.textHint, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textHint, size: 18),
            suffixIcon: _selectedProduct != null
                ? GestureDetector(
                    onTap: _clearProductSelection,
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textHint, size: 18),
                  )
                : _productsLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary),
                        ),
                      )
                    : null,
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5)),
          ),
          onTap: () => setState(() => _showProductDropdown = true),
          onChanged: (_) => setState(() => _showProductDropdown = true),
        ),

        if (_showProductDropdown) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _productsLoading && _allProducts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                  )
                : visible.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          const Icon(Icons.search_off_rounded,
                              color: AppColors.textHint, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _productNameCtrl.text.isEmpty
                                ? 'No products found'
                                : 'No match for "${_productNameCtrl.text}"',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontFamily: 'Poppins'),
                          ),
                        ]),
                      )
                    : Column(
                        children: [
                          ...visible.map((p) => _buildProductTile(p)),
                          if (hasMore || _productVisibleCount > _initialVisibleCount)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (hasMore) {
                                    _productVisibleCount += _initialVisibleCount;
                                  } else {
                                    _productVisibleCount = _initialVisibleCount;
                                  }
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 14),
                                decoration: const BoxDecoration(
                                  border: Border(
                                      top: BorderSide(
                                          color: AppColors.divider)),
                                ),
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        hasMore
                                            ? Icons.expand_more_rounded
                                            : Icons
                                                .expand_less_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        hasMore
                                            ? 'Show ${(_filteredProducts.length - _productVisibleCount).clamp(0, _initialVisibleCount)} more'
                                            : 'Show less',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Poppins'),
                                      ),
                                    ]),
                              ),
                            ),
                        ],
                      ),
          ),
        ],

        // Selected product chip (optional)
        if (_selectedProduct != null && !_showProductDropdown) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.production_quantity_limits,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedProduct!.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                              fontFamily: 'Poppins')),
                      // if (_selectedProduct!.description.isNotEmpty)
                      //   Text(_selectedProduct!.description,
                      //       style: const TextStyle(
                                // fontSize: 11,
                                // color: AppColors.textSecondary,
                                // fontFamily: 'Poppins')),
                    ]),
              ),
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 18),
            ]),
          ),
        ],

        const SizedBox(height: 16),
        // Rest of the product fields unchanged...
        const Text('Pricing Type',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: _pricingTypes.map((t) {
              final sel = _pricingType == t;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _pricingType = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          sel ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(t.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? Colors.white
                                : AppColors.textSecondary)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: _field('Bags *', _bagsCtrl,
                hint: '10',
                icon: Icons.inventory_2_outlined,
                inputType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _field(
                'Weight/Bag (${_pricingType == 'quintal' ? 'qtl' : 'kg'}) *',
                _weightPerBagCtrl,
                hint: '50',
                icon: Icons.scale_outlined,
                inputType: TextInputType.number,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                ]),
          ),
        ]),
        const SizedBox(height: 12),
        if (_actualQty > 0)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child:
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total Weight',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins')),
              Text(
                  '${_actualQty.toStringAsFixed(1)} ${_pricingType == 'quintal' ? 'qtl' : 'kg'}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                      fontFamily: 'Poppins')),
            ]),
          ),
        const SizedBox(height: 12),
        _field(
            'Quality Deduction (${_pricingType == 'quintal' ? 'qtl' : 'kg'})',
            _qualityDeductionCtrl,
            hint: '0',
            icon: Icons.remove_circle_outline,
            inputType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ]),
        const SizedBox(height: 12),
        _field(
            'Rate per ${_pricingType == 'quintal' ? 'qtl' : 'kg'} (₹) *',
            _rateCtrl,
            hint: '2000',
            icon: Icons.currency_rupee_rounded,
            inputType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ]),
        const SizedBox(height: 12),
        _multiLineField('Product Notes (optional)', _productNotesCtrl,
            hint: 'e.g. Premium quality...'),
        if (_grossTotal > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              _calcRow('Bags × Weight/Bag', _actualQty, suffix: ' kg'),
              if (_qualityDeduction > 0)
                _calcRow('Quality Deduction', _qualityDeduction,
                    suffix: ' kg', negative: true),
              _calcRow('Net Qty', _netQty,
                  suffix:
                      ' ${_pricingType == 'quintal' ? 'qtl' : 'kg'}'),
              _calcRow('Rate', _rate,
                  prefix: '₹',
                  suffix:
                      '/${_pricingType == 'quintal' ? 'qtl' : 'kg'}'),
              const Divider(color: Colors.white24, height: 16),
              _calcRow('Gross Total', _grossTotal,
                  large: true, prefix: '₹'),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _buildProductTile(DropdownProduct product) {
    final isSelected = _selectedProduct?.id == product.id;
    return InkWell(
      onTap: () => _selectProduct(product),
      borderRadius: BorderRadius.circular(0),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primarySurface
              : Colors.transparent,
          border: const Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                product.name.isNotEmpty
                    ? product.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primaryDark
                              : AppColors.textPrimary,
                          fontFamily: 'Poppins')),
                  // if (product.description.isNotEmpty)
                  //   Text(product.description,
                  //       style: const TextStyle(
                  //           fontSize: 11,
                  //           color: AppColors.textSecondary,
                  //           fontFamily: 'Poppins')),
                ]),
          ),
          if (isSelected)
            const Icon(Icons.check_rounded,
                color: AppColors.primary, size: 16),
        ]),
      ),
    );
  }

  Widget _calcRow(String label, double value,
      {bool large = false,
      String prefix = '',
      String suffix = '',
      bool negative = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(
              color: Colors.white70,
              fontSize: large ? 13 : 12,
              fontFamily: 'Poppins')),
      Text(
          '${negative ? '-' : ''}$prefix${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}$suffix',
          style: TextStyle(
              color: Colors.white,
              fontSize: large ? 18 : 13,
              fontWeight: large ? FontWeight.w700 : FontWeight.w500,
              fontFamily: 'Poppins')),
    ]);
  }

  // ── STEP 2 — Deductions (unchanged) ───────────────────────────
  Widget _buildStep2Deductions() {
    return Column(
      key: const ValueKey('s2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Deductions', 'Enter charges & adjustments'),
        const SizedBox(height: 16),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Gross Total',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontFamily: 'Poppins')),
            Text('₹${_grossTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
          ]),
        ),
        const SizedBox(height: 14),
        _field('Transport (₹)', _transportCtrl,
            hint: '0',
            icon: Icons.local_shipping_outlined,
            inputType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ]),
        const SizedBox(height: 10),
        _field('Labour (₹)', _labourCtrl,
            hint: '0',
            icon: Icons.people_outline,
            inputType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            flex: 3,
            child: _field('Commission', _commissionCtrl,
                hint: '0',
                icon: Icons.percent_outlined,
                inputType: TextInputType.number,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Type',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: 'Poppins')),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: _miniToggle(
                              'Fixed',
                              _commissionType == 'fixed',
                              () => setState(
                                  () => _commissionType = 'fixed'))),
                      Expanded(
                          child: _miniToggle(
                              '%',
                              _commissionType == 'percent',
                              () => setState(
                                  () => _commissionType = 'percent'))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 10),
        _field('Storage (₹)', _storageCtrl,
            hint: '0',
            icon: Icons.warehouse_outlined,
            inputType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ]),
        const SizedBox(height: 10),
        _field('Advance Adjusted (₹)', _advanceAdjustedCtrl,
            hint: '0',
            icon: Icons.account_balance_wallet_outlined,
            inputType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ]),
        const SizedBox(height: 10),
        _field('Other Deductions (₹)', _otherCtrl,
            hint: '0',
            icon: Icons.remove_circle_outline,
            inputType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ]),
        if (_grossTotal > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              _calcRow('Gross Total', _grossTotal, prefix: '₹'),
              _calcRow('Total Deductions', _totalDeductions,
                  prefix: '-₹'),
              const Divider(color: Colors.white24, height: 16),
              _calcRow('Final Receivable', _finalReceivable,
                  large: true, prefix: '₹'),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        _multiLineField('Sale Notes (optional)', _notesCtrl,
            hint: 'Any remarks about this sale...'),
      ],
    );
  }

  Widget _miniToggle(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color:
                    selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  // ── STEP 3 — Review (unchanged) ───────────────────────────────
  Widget _buildStep3Review() {
    return Column(
      key: const ValueKey('s3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Review Sale', 'Confirm before creating'),
        const SizedBox(height: 16),
        _reviewSection('Buyer', [
          _reviewRow('Name', _buyerNameCtrl.text.trim()),
          if (_buyerMobileCtrl.text.trim().isNotEmpty)
            _reviewRow('Mobile', _buyerMobileCtrl.text.trim()),
          if (_buyerGstCtrl.text.trim().isNotEmpty)
            _reviewRow('GST', _buyerGstCtrl.text.trim().toUpperCase()),
          if (_buyerAddressCtrl.text.trim().isNotEmpty)
            _reviewRow('Address', _buyerAddressCtrl.text.trim()),
        ], Icons.person_outline_rounded),
        const SizedBox(height: 12),
        _reviewSection('Product', [
          _reviewRow('Name', _productNameCtrl.text.trim()),
          _reviewRow('Pricing Type', _pricingType.toUpperCase()),
          _reviewRow('Bags', '$_bags'),
          _reviewRow('Wt/Bag',
              '${_weightPerBag.toStringAsFixed(1)} ${_pricingType == 'quintal' ? 'qtl' : 'kg'}'),
          _reviewRow('Total Wt',
              '${_actualQty.toStringAsFixed(1)} ${_pricingType == 'quintal' ? 'qtl' : 'kg'}'),
          if (_qualityDeduction > 0)
            _reviewRow(
                'Quality Ded.', '-${_qualityDeduction.toStringAsFixed(1)}'),
          _reviewRow('Net Qty',
              '${_netQty.toStringAsFixed(1)} ${_pricingType == 'quintal' ? 'qtl' : 'kg'}'),
          _reviewRow('Rate',
              '₹${_rate.toStringAsFixed(2)}/${_pricingType == 'quintal' ? 'qtl' : 'kg'}'),
        ], Icons.eco_outlined),
        const SizedBox(height: 12),
        if (_totalDeductions > 0)
          _reviewSection('Deductions', [
            if (_transport > 0)
              _reviewRow('Transport', '₹${_transport.toStringAsFixed(2)}'),
            if (_labour > 0)
              _reviewRow('Labour', '₹${_labour.toStringAsFixed(2)}'),
            if (_commission > 0)
              _reviewRow(
                  'Commission',
                  _commissionType == 'percent'
                      ? '$_commission%'
                      : '₹${_commission.toStringAsFixed(2)}'),
            if (_storage > 0)
              _reviewRow('Storage', '₹${_storage.toStringAsFixed(2)}'),
            if (_advanceAdjusted > 0)
              _reviewRow('Advance Adj.',
                  '₹${_advanceAdjusted.toStringAsFixed(2)}'),
            if (_other > 0)
              _reviewRow('Other', '₹${_other.toStringAsFixed(2)}'),
            _reviewRow(
                'Total Ded.', '₹${_totalDeductions.toStringAsFixed(2)}'),
          ], Icons.remove_circle_outline),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            _calcRow('Gross Total', _grossTotal, prefix: '₹'),
            if (_totalDeductions > 0)
              _calcRow('Total Deductions', _totalDeductions, prefix: '-₹'),
            const Divider(color: Colors.white24, height: 16),
            _calcRow('Final Receivable', _finalReceivable,
                large: true, prefix: '₹'),
          ]),
        ),
        if (_notesCtrl.text.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _reviewSection('Notes', [
            _reviewRow('', _notesCtrl.text.trim()),
          ], Icons.notes_rounded),
        ],
      ],
    );
  }

  Widget _reviewSection(
      String title, List<Widget> rows, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppColors.primary, size: 15),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins')),
        ]),
        const Divider(color: AppColors.divider, height: 14),
        ...rows,
      ]),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins')),
            ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ──────────────────────────────────────────────
  Widget _stepHeader(String title, String sub) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins')),
        ],
      );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    required String hint,
    required IconData icon,
    TextCapitalization caps = TextCapitalization.none,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    int? maxLength,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins')),
      const SizedBox(height: 4),
      TextFormField(
        controller: ctrl,
        keyboardType: inputType,
        textCapitalization: caps,
        inputFormatters: formatters,
        maxLength: maxLength,
        style: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: AppColors.textHint, fontSize: 13),
          prefixIcon:
              Icon(icon, color: AppColors.textHint, size: 18),
          counterText: '',
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 1.5)),
        ),
        onChanged: (_) => setState(() {}),
      ),
    ]);
  }

  Widget _multiLineField(String label, TextEditingController ctrl,
      {required String hint}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins')),
      const SizedBox(height: 4),
      TextFormField(
        controller: ctrl,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: AppColors.textHint, fontSize: 13),
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 1.5)),
        ),
      ),
    ]);
  }
}
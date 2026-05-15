// lib/features/ledger/screens/LedgerScreen.dart
//
// Replace your existing LedgerScreen.dart with this file.
// Adds a "Buyers" tab alongside Farmers and Operators.

import 'package:agr_market/ledger/buyer_ledger_list_screen.dart';
import 'package:agr_market/services/constant_service.dart';
import 'package:agr_market/services/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../providers/language_provider.dart';
import '../models/ledger_models.dart';
import 'FarmerLedgerDetailScreen.dart';
import '../ledger/OperatorLedgerDetailScreen.dart';

// ──────────────────────────────────────────────────────────────────────────────
// ApiRoutes — add these two entries to your existing constant_service.dart:
//
//   static const String allBuyersLedger = '/api/ledger/all/buyers';
//   static const String buyerLedger     = '/api/ledger/buyer';  // + '/{id}'
// ──────────────────────────────────────────────────────────────────────────────

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // ← 3 tabs now
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProv, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
            ),
            title: Text(
              langProv.t('ledger_title'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            centerTitle: false,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
              ),
              tabs: [
                Tab(text: langProv.t('farmers_tab')),
                Tab(text: langProv.t('operators_tab')),
                Tab(text: langProv.t('buyers_tab')), // ← new tab
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              FarmerLedgerListScreen(),
              OperatorLedgerListScreen(),
              BuyerLedgerListScreen(), // ← new screen
            ],
          ),
        );
      },
    );
  }
}

// ==================== FARMER LEDGER LIST SCREEN ====================
// (unchanged — keep your existing FarmerLedgerListScreen here)
class FarmerLedgerListScreen extends StatefulWidget {
  const FarmerLedgerListScreen({super.key});

  @override
  State<FarmerLedgerListScreen> createState() => _FarmerLedgerListScreenState();
}

class _FarmerLedgerListScreenState extends State<FarmerLedgerListScreen> {
  List<FarmerLedgerItem> _farmers = [];
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadFarmersLedger();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _totalPages) {
      _loadMoreFarmers();
    }
  }

  Future<void> _loadFarmersLedger({bool reset = true}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _currentPage = 1;
        _farmers = [];
      });
    }

    try {
      final params = <String, dynamic>{
        'page': _currentPage,
        'limit': 20,
      };
      if (_searchQuery.isNotEmpty) params['search'] = _searchQuery;

      final res = await DioClient.instance.dio.get(
        ApiRoutes.allFarmersLedger,
        queryParameters: params,
      );

      final responseData = res.data as Map<String, dynamic>;
      if (responseData['success'] == true) {
        final data = AllFarmersLedgerData.fromJson(responseData['data']);
        setState(() {
          if (reset) {
            _farmers = data.farmers;
          } else {
            _farmers = [..._farmers, ...data.farmers];
          }
          _totalPages = data.pagination.pages;
          _loading = false;
        });
      } else {
        throw Exception('API returned success=false');
      }
    } catch (e) {
      debugPrint('Error loading farmers ledger: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMoreFarmers() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _loadFarmersLedger(reset: false);
    setState(() => _isLoadingMore = false);
  }

  List<FarmerLedgerItem> get _filteredFarmers {
    if (_searchQuery.isEmpty) return _farmers;
    final q = _searchQuery.toLowerCase();
    return _farmers.where((f) {
      final name = f.farmer.name.toLowerCase();
      final mobile = f.farmer.mobile;
      return name.contains(q) || mobile.contains(q);
    }).toList();
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'F';
  }

  String _fmtAmount(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProv, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  setState(() => _searchQuery = v);
                  _loadFarmersLedger(reset: true);
                },
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: langProv.t('search_hint_farmer_ledger'),
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textHint, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                            _loadFarmersLedger(reset: true);
                          },
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.textHint, size: 18),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _filteredFarmers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline,
                                  size: 56, color: AppColors.textHint),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? '${langProv.t('no_matching_farmers')} "$_searchQuery"'
                                    : langProv.t('no_farmers_found'),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadFarmersLedger(reset: true),
                          color: AppColors.primary,
                          child: ListView.builder(
                            controller: _scrollCtrl,
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: _filteredFarmers.length +
                                (_isLoadingMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == _filteredFarmers.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              final farmer = _filteredFarmers[i];
                              final name = farmer.farmer.name;
                              final mobile = farmer.farmer.mobile;
                              final pendingDues =
                                  farmer.financialSummary.closingBalance > 0
                                      ? farmer.financialSummary.closingBalance
                                      : 0;

                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FarmerLedgerDetailScreen(
                                      farmerId: farmer.farmer.id,
                                      farmerName: name,
                                      farmerMobile: mobile,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppColors.border),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: const BoxDecoration(
                                          gradient: AppColors.heroGradient,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            _initials(name),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              mobile,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppColors.textSecondary,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          if (pendingDues > 0)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color:
                                                    AppColors.warningSurface,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${langProv.t('due_short')} ${_fmtAmount(pendingDues.toDouble())}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.warning,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            )
                                          else
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color:
                                                    AppColors.successSurface,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                langProv.t('clear_short'),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.success,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 13,
                                            color: AppColors.textHint,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }
}

// ==================== OPERATOR LEDGER LIST SCREEN ====================
// (unchanged — keep your existing OperatorLedgerListScreen here)
class OperatorLedgerListScreen extends StatefulWidget {
  const OperatorLedgerListScreen({super.key});

  @override
  State<OperatorLedgerListScreen> createState() =>
      _OperatorLedgerListScreenState();
}

class _OperatorLedgerListScreenState extends State<OperatorLedgerListScreen> {
  List<OperatorLedgerItem> _operators = [];
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollCtrl = ScrollController();

  String _sortBy = 'name';
  String _sortOrder = 'asc';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadOperatorsLedger();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _totalPages) {
      _loadMoreOperators();
    }
  }

  Future<void> _loadOperatorsLedger({bool reset = true}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _currentPage = 1;
        _operators = [];
      });
    }

    try {
      final params = <String, dynamic>{
        'page': _currentPage,
        'limit': 20,
        'sortBy': _sortBy,
        'sortOrder': _sortOrder,
      };
      if (_searchQuery.isNotEmpty) params['search'] = _searchQuery;

      final res = await DioClient.instance.dio.get(
        ApiRoutes.allOperatorsLedger,
        queryParameters: params,
      );

      final responseData = res.data as Map<String, dynamic>;
      if (responseData['success'] == true) {
        final data = AllOperatorsLedgerData.fromJson(responseData['data']);
        setState(() {
          if (reset) {
            _operators = data.operators;
          } else {
            _operators = [..._operators, ...data.operators];
          }
          _totalPages = data.pagination.pages;
          _loading = false;
        });
      } else {
        throw Exception('API returned success=false');
      }
    } catch (e) {
      debugPrint('Error loading operators ledger: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMoreOperators() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _loadOperatorsLedger(reset: false);
    setState(() => _isLoadingMore = false);
  }

  void _toggleSortOrder() {
    setState(() => _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc');
    _loadOperatorsLedger(reset: true);
  }

  String _fmtAmount(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'O';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProv, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) {
                        setState(() => _searchQuery = v);
                        _loadOperatorsLedger(reset: true);
                      },
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: langProv.t('search_hint_operator_ledger'),
                        hintStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textHint,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textHint, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                  _loadOperatorsLedger(reset: true);
                                },
                                child: const Icon(Icons.close_rounded,
                                    color: AppColors.textHint, size: 18),
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleSortOrder,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        _sortOrder == 'asc'
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _operators.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_outline,
                                  size: 56, color: AppColors.textHint),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? '${langProv.t('no_matching_operators')} "$_searchQuery"'
                                    : langProv.t('no_operators_found'),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadOperatorsLedger(reset: true),
                          color: AppColors.primary,
                          child: ListView.builder(
                            controller: _scrollCtrl,
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: _operators.length +
                                (_isLoadingMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == _operators.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              final operator = _operators[i];
                              final name = operator.operator.name;
                              final email = operator.operator.email;
                              final phone = operator.operator.phone;
                              final netProfit =
                                  operator.financialSummary.netProfit;
                              final isProfitable = netProfit >= 0;

                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OperatorLedgerDetailScreen(
                                      operatorId: operator.operator.id,
                                      operatorName: name,
                                      operatorEmail: email,
                                      operatorPhone: phone,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppColors.border),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: const BoxDecoration(
                                          gradient: AppColors.heroGradient,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            _initials(name),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            if (email.isNotEmpty)
                                              Text(
                                                email,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            if (phone.isNotEmpty)
                                              Text(
                                                phone,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textHint,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isProfitable
                                              ? AppColors.successSurface
                                              : AppColors.warningSurface,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              langProv
                                                  .t('net_profit_short'),
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: isProfitable
                                                    ? AppColors.success
                                                    : AppColors.warning,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            Text(
                                              _fmtAmount(netProfit.abs()),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isProfitable
                                                    ? AppColors.success
                                                    : AppColors.warning,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 13,
                                        color: AppColors.textHint,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:agr_market/payment/payment_screen.dart';
import 'package:agr_market/providers/language_provider.dart';
import 'package:agr_market/purchase/purchase_screen.dart';
import 'package:agr_market/receipt/receipt_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../services/dio_client.dart';
import '../../../services/constant_service.dart';
import 'package:intl/intl.dart';

import '../models/deduction_model.dart';
import '../models/farmer_model.dart';
import '../models/purchase_model.dart';

// ── Data models ───────────────────────────────────────────────

class PurchaseListItem {
  final String id;
  final String receiptNumber;
  final String farmerName;
  final String farmerId;
  final String farmerMobile;
  final double grossTotal;
  final double totalDeductions;
  final double finalPayable;
  final double amountPaid;
  final double amountDue;
  final String status; // 'pending' | 'partial' | 'paid'
  final DateTime purchaseDate;
  final List<PurchaseLineItem> lines;
  final PurchaseDeductionSummary deductions;

  const PurchaseListItem({
    required this.id,
    required this.receiptNumber,
    required this.farmerName,
    required this.farmerId,
    required this.farmerMobile,
    required this.grossTotal,
    required this.totalDeductions,
    required this.finalPayable,
    required this.amountPaid,
    required this.amountDue,
    required this.status,
    required this.purchaseDate,
    required this.lines,
    required this.deductions,
  });

  factory PurchaseListItem.fromJson(Map<String, dynamic> j) {
    final farmer = j['farmer'];
    String farmerName = 'Unknown';
    String farmerId = '';
    String farmerMobile = '';
    if (farmer is Map) {
      farmerName = farmer['name']?.toString() ?? 'Unknown';
      farmerId = farmer['_id']?.toString() ?? farmer['id']?.toString() ?? '';
      farmerMobile = farmer['mobile']?.toString() ?? '';
    }

    final lines = (j['lines'] as List? ?? [])
        .map((l) => PurchaseLineItem.fromJson(l as Map<String, dynamic>))
        .toList();

    final ded = j['deductions'];
    final deductions = ded is Map
        ? PurchaseDeductionSummary.fromJson(ded as Map<String, dynamic>)
        : const PurchaseDeductionSummary();

    DateTime date = DateTime.now();
    final dateStr = j['purchaseDate'] ?? j['createdAt'] ?? '';
    if (dateStr.toString().isNotEmpty) {
      date = DateTime.tryParse(dateStr.toString())?.toLocal() ?? DateTime.now();
    }

    return PurchaseListItem(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      receiptNumber: j['receiptNumber']?.toString() ?? '',
      farmerName: farmerName,
      farmerId: farmerId,
      farmerMobile: farmerMobile,
      grossTotal: (j['grossTotal'] as num?)?.toDouble() ?? 0,
      totalDeductions: (j['totalDeductions'] as num?)?.toDouble() ?? 0,
      finalPayable: (j['finalPayable'] as num?)?.toDouble() ?? 0,
      amountPaid: (j['amountPaid'] as num?)?.toDouble() ?? 0,
      amountDue: (j['amountDue'] as num?)?.toDouble() ?? 0,
      status: j['status']?.toString() ?? 'pending',
      purchaseDate: date,
      lines: lines,
      deductions: deductions,
    );
  }

  String get initials {
    final parts = farmerName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return farmerName.isNotEmpty ? farmerName[0].toUpperCase() : 'F';
  }
}

class PurchaseLineItem {
  final String productName;
  final String pricingType;
  final double bags;
  final double weightPerBag;
  final double actualQty;
  final double qualityDeduction;
  final double billedQty;
  final String unit;
  final double rate;
  final double lineTotal;

  const PurchaseLineItem({
    this.productName = '',
    this.pricingType = 'kg',
    this.bags = 0,
    this.weightPerBag = 0,
    this.actualQty = 0,
    this.qualityDeduction = 0,
    this.billedQty = 0,
    this.unit = 'kg',
    this.rate = 0,
    this.lineTotal = 0,
  });

  factory PurchaseLineItem.fromJson(Map<String, dynamic> j) {
    return PurchaseLineItem(
      productName: j['productName']?.toString() ?? '',
      pricingType: j['pricingType']?.toString() ?? 'kg',
      bags: (j['bags'] as num?)?.toDouble() ?? 0,
      weightPerBag: (j['weightPerBag'] as num?)?.toDouble() ?? 0,
      actualQty: (j['actualQty'] as num?)?.toDouble() ?? 0,
      qualityDeduction: (j['qualityDeduction'] as num?)?.toDouble() ?? 0,
      billedQty: (j['billedQty'] as num?)?.toDouble() ?? 0,
      unit: j['unit']?.toString() ?? 'kg',
      rate: (j['rate'] as num?)?.toDouble() ?? 0,
      lineTotal: (j['lineTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PurchaseDeductionSummary {
  final double transport;
  final double labour;
  final double commission;
  final String commissionType;
  final double storage;
  final double returnDeduction;
  final double advanceAdjusted;
  final double other;

  const PurchaseDeductionSummary({
    this.transport = 0,
    this.labour = 0,
    this.commission = 0,
    this.commissionType = 'fixed',
    this.storage = 0,
    this.returnDeduction = 0,
    this.advanceAdjusted = 0,
    this.other = 0,
  });

  factory PurchaseDeductionSummary.fromJson(Map<String, dynamic> j) {
    return PurchaseDeductionSummary(
      transport: (j['transport'] as num?)?.toDouble() ?? 0,
      labour: (j['labour'] as num?)?.toDouble() ?? 0,
      commission: (j['commission'] as num?)?.toDouble() ?? 0,
      commissionType: j['commissionType']?.toString() ?? 'fixed',
      storage: (j['storage'] as num?)?.toDouble() ?? 0,
      returnDeduction: (j['returnDeduction'] as num?)?.toDouble() ?? 0,
      advanceAdjusted: (j['advanceAdjusted'] as num?)?.toDouble() ?? 0,
      other: (j['other'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ── Screen ────────────────────────────────────────────────────

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  // ── State ─────────────────────────────────────────────────────
  final List<PurchaseListItem> _purchases = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _limit = 20;

  String _selectedStatus = 'all'; // all | pending | partial | paid
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  // Summary totals from current loaded data
  double get _totalGross =>
      _purchases.fold(0, (s, p) => s + p.grossTotal);
  double get _totalDue =>
      _purchases.fold(0, (s, p) => s + p.amountDue);
  double get _totalPaid =>
      _purchases.fold(0, (s, p) => s + p.amountPaid);

  // ── Lifecycle ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetchPurchases(reset: true);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loading &&
        _hasMore) {
      _fetchPurchases();
    }
  }

  // ── API ───────────────────────────────────────────────────────
  Future<void> _fetchPurchases({bool reset = false}) async {
    if (_loading) return;
    if (reset) {
      setState(() {
        _purchases.clear();
        _page = 1;
        _hasMore = true;
      });
    }
    if (!_hasMore && !reset) return;

    setState(() => _loading = true);

    try {
      final params = <String, dynamic>{
        'page': _page,
        'limit': _limit,
        'sortOrder': 'desc',
      };

      if (_selectedStatus != 'all') params['status'] = _selectedStatus;
      if (_startDate != null) {
        params['startDate'] = DateFormat('yyyy-MM-dd').format(_startDate!);
      }
      if (_endDate != null) {
        params['endDate'] = DateFormat('yyyy-MM-dd').format(_endDate!);
      }

      final res = await DioClient.instance.dio.get(
        ApiRoutes.purchases,
        queryParameters: params,
      );

      final data = res.data;
      List rawList = [];

      if (data is List) {
        rawList = data;
      } else if (data is Map) {
        rawList = data['purchases'] as List? ??
            data['data'] as List? ??
            [];
      }

      final fetched =
          rawList.map((j) => PurchaseListItem.fromJson(j as Map<String, dynamic>)).toList();

      setState(() {
        _purchases.addAll(fetched);
        _page++;
        _hasMore = fetched.length == _limit;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ PurchaseListScreen fetch error: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load purchases: $e',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
         margin: const EdgeInsets.only(left: 6, right: 6, bottom: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
    
  }

  // ── Filtered list ─────────────────────────────────────────────
  List<PurchaseListItem> get _filtered {
    if (_searchQuery.isEmpty) return _purchases;
    final q = _searchQuery.toLowerCase();
    return _purchases.where((p) {
      return p.farmerName.toLowerCase().contains(q) ||
          p.receiptNumber.toLowerCase().contains(q) ||
          p.farmerMobile.contains(q);
    }).toList();
  }

  // ── Date range picker ─────────────────────────────────────────
  Future<void> _pickDateRange() async {
    FocusScope.of(context).unfocus();

    try {
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        useRootNavigator: true,
        barrierDismissible: true,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),

        initialDateRange:
        (_startDate != null && _endDate != null)
            ? DateTimeRange(
          start: _startDate!,
          end: _endDate!,
        )
            : null,

        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && mounted) {
        setState(() {
          _startDate = picked.start;
          _endDate = picked.end;
        });

        await _fetchPurchases(reset: true);
      }
    } catch (e) {
      debugPrint('❌ Date picker error: $e');
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _fetchPurchases(reset: true);
  }

  // ── Helpers ───────────────────────────────────────────────────
  String _fmtAmount(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  String _fmtDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return _fmtDate(d);
  }

  // ── Build ─────────────────────────────────────────────────────
  @override

  Widget build(BuildContext context) {
     final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [

          // ── Gradient Header ─────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              elevation: 20,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.32,
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

                        // ── Title Row ─────────────────────────────
                        Row(
                          children: [

                            const Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white,
                              size: 22,
                            ),

                            const SizedBox(width: 10),

                            const Text(
                              'All Purchases',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                            ),

                            const Spacer(),

                            // ── Date Button ───────────────────────
                            ElevatedButton(
                              onPressed: _pickDateRange,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                Colors.white.withOpacity(0.2),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [

                                  const Icon(
                                    Icons.date_range_rounded,
                                    size: 15,
                                  ),

                                  const SizedBox(width: 5),

                                  Text(
                                    _startDate != null
                                        ? '${_fmtDate(_startDate!)} – ${_fmtDate(_endDate!)}'
                                        : 'Date',
                                    style: const TextStyle(
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Clear Filter Button ───────────────
                            if (_startDate != null) ...[
                              const SizedBox(width: 8),

                              ElevatedButton(
                                onPressed: _clearDateFilter,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  Colors.white.withOpacity(0.2),
                                  foregroundColor: Colors.white70,
                                  elevation: 0,
                                  padding: const EdgeInsets.all(6),
                                  minimumSize: const Size(0, 0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(10),
                                    side: BorderSide(
                                      color:
                                      Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 15,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ── Summary Row ──────────────────────────
                        _buildSummaryRow(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Scrollable Content ─────────────────────────────────
          Positioned.fill(
  bottom: kBottomNavigationBarHeight,
  child: RefreshIndicator(
    onRefresh: () => _fetchPurchases(reset: true),
    color: AppColors.primary,
              child: CustomScrollView(
                controller: _scrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
                //  padding: const EdgeInsets.only(bottom: 80),
                 
                slivers: [

                  // IMPORTANT FIX
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                      MediaQuery.of(context).size.height * 0.34,
                    ),
                  ),

                  // ── Search + Filters Card ─────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      margin:
                      const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.fromLTRB(
                          16, 16, 16, 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withOpacity(0.10),
                            blurRadius: 24,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [

                          // ── Search Field ──────────────────────
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (v) =>
                                setState(() => _searchQuery = v),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText:
                              'Search by farmer name or receipt no.',
                              hintStyle: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: AppColors.textHint,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.textHint,
                                size: 20,
                              ),
                              suffixIcon:
                              _searchQuery.isNotEmpty
                                  ? GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() =>
                                  _searchQuery = '');
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  color:
                                  AppColors.textHint,
                                  size: 18,
                                ),
                              )
                                  : null,
                              filled: true,
                              fillColor:
                              AppColors.surfaceVariant,
                              contentPadding:
                              const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              enabledBorder:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              focusedBorder:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Status Chips ──────────────────────
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [

                                _FilterChip(
                                  label: 'All',
                                  count: _purchases.length,
                                  active:
                                  _selectedStatus == 'all',
                                  onTap: () =>
                                      _setStatus('all'),
                                ),

                                const SizedBox(width: 8),

                                _FilterChip(
                                  label: 'Pending',
                                  count: _purchases
                                      .where((p) =>
                                  p.status ==
                                      'pending')
                                      .length,
                                  color: AppColors.error,
                                  bgColor:
                                  AppColors.errorSurface,
                                  active:
                                  _selectedStatus ==
                                      'pending',
                                  onTap: () =>
                                      _setStatus('pending'),
                                ),

                                const SizedBox(width: 8),

                                _FilterChip(
                                  label: 'Partial',
                                  count: _purchases
                                      .where((p) =>
                                  p.status ==
                                      'partial')
                                      .length,
                                  color: AppColors.warning,
                                  bgColor: AppColors
                                      .warningSurface,
                                  active:
                                  _selectedStatus ==
                                      'partial',
                                  onTap: () =>
                                      _setStatus('partial'),
                                ),

                                const SizedBox(width: 8),

                                _FilterChip(
                                  label: 'Paid',
                                  count: _purchases
                                      .where((p) =>
                                  p.status ==
                                      'paid')
                                      .length,
                                  color: AppColors.success,
                                  bgColor: AppColors
                                      .successSurface,
                                  active:
                                  _selectedStatus ==
                                      'paid',
                                  onTap: () =>
                                      _setStatus('paid'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 12),
                  ),

                  // ── Empty State / List ────────────────────────
                  if (!_loading && _filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16),
                      sliver: SliverList(
                        delegate:
                        SliverChildBuilderDelegate(
                              (ctx, i) {

                            if (i == _filtered.length) {
                              return _loading
                                  ? const Padding(
                                padding:
                                EdgeInsets.all(20),
                                child: Center(
                                  child:
                                  CircularProgressIndicator(
                                    color:
                                    AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                                  : const SizedBox(
                                  height: 20);
                            }

                            return _PurchaseCard(
                              purchase: _filtered[i],
                              fmtAmount: _fmtAmount,
                              timeAgo: _timeAgo,
                              onTap: () =>
                                  _showDetail(_filtered[i]),
                            );
                          },
                          childCount:
                          _filtered.length + 1,
                        ),
                      ),
                    ),

                  // ── Shimmer Loader ────────────────────────────
                  if (_loading && _purchases.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16),
                      sliver: SliverList(
                        delegate:
                        SliverChildBuilderDelegate(
                              (_, __) => _buildShimmerCard(),
                          childCount: 5,
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(
      child: SizedBox(
        height: MediaQuery.of(context).padding.bottom + 80,
      ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setStatus(String status) {
    if (_selectedStatus == status) return;
    setState(() => _selectedStatus = status);
    _fetchPurchases(reset: true);
  }

  // ── Summary row ───────────────────────────────────────────────
  Widget _buildSummaryRow() {
    return Row(children: [
      _SummaryChip(
          label: 'Total Sales',
          value: _fmtAmount(_totalGross),
          icon: Icons.trending_up_rounded),
      const SizedBox(width: 10),
      _SummaryChip(
          label: 'Collected',
          value: _fmtAmount(_totalPaid),
          icon: Icons.check_circle_outline_rounded),
      const SizedBox(width: 10),
      _SummaryChip(
          label: 'Due',
          value: _fmtAmount(_totalDue),
          icon: Icons.pending_outlined,
          isWarning: _totalDue > 0),
    ]);
  }

  // ── Empty state ───────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.receipt_long_outlined,
              color: AppColors.primary, size: 34),
        ),
        const SizedBox(height: 16),
        Text(
          _searchQuery.isNotEmpty
              ? 'No purchases match "$_searchQuery"'
              : _selectedStatus != 'all'
                  ? 'No $_selectedStatus purchases found'
                  : 'No purchases yet',
          style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Purchases will appear here once recorded.',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        if (_searchQuery.isNotEmpty || _selectedStatus != 'all') ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              _searchCtrl.clear();
              setState(() {
                _searchQuery = '';
                _selectedStatus = 'all';
              });
              _fetchPurchases(reset: true);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Text('Clear Filters',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ]),
    );
  }

  // ── Shimmer placeholder card ───────────────────────────────────
  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
    );
  }

  // ── Detail bottom sheet ───────────────────────────────────────
  void _showDetail(PurchaseListItem purchase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PurchaseDetailSheet(
        purchase: purchase,
        fmtAmount: _fmtAmount,
        fmtDate: _fmtDate,
      ),
    );
  }
}

// ── Summary Chip (in header) ──────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isWarning;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon,
                color: isWarning
                    ? Colors.orange.shade200
                    : Colors.white70,
                size: 13),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: isWarning
                        ? Colors.orange.shade200
                        : Colors.white70,
                    fontSize: 10,
                    fontFamily: 'Poppins')),
          ]),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins'),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final Color? color;
  final Color? bgColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
    this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final effectiveBg = bgColor ?? AppColors.primarySurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? effectiveColor : effectiveBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? effectiveColor : AppColors.border, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                  color: active ? Colors.white : effectiveColor,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withOpacity(0.25)
                  : effectiveColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: TextStyle(
                    color: active ? Colors.white : effectiveColor,
                    fontSize: 10,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

// ── Purchase Card (list item) ─────────────────────────────────

class _PurchaseCard extends StatelessWidget {
  final PurchaseListItem purchase;
  final String Function(double) fmtAmount;
  final String Function(DateTime) timeAgo;
  final VoidCallback onTap;

  const _PurchaseCard({
    required this.purchase,
    required this.fmtAmount,
    required this.timeAgo,
    required this.onTap,
  });

  Color get _statusColor {
  switch (purchase.status) {
    case 'paid':                       return AppColors.success;
    case 'partial':                    return AppColors.warning;
    case 'saved':                      return AppColors.info;
    case 'draft':                      return AppColors.textHint;
    default:                           return AppColors.error;
  }
}
Color get _statusBg {
  switch (purchase.status) {
    case 'paid':    return AppColors.successSurface;
    case 'partial': return AppColors.warningSurface;
    case 'saved':   return AppColors.infoSurface;
    case 'draft':   return AppColors.surfaceVariant;
    default:        return AppColors.errorSurface;
  }
}

  String get _statusLabel {
  switch (purchase.status) {
    case 'paid':    return '✓ Paid';
    case 'partial': return 'Partial';
    case 'saved':   return 'Saved';
    case 'draft':   return 'Draft';
    default:        return 'Pending';
  }
}
  @override
  Widget build(BuildContext context) {
    final products = purchase.lines
        .map((l) => l.productName)
        .where((n) => n.isNotEmpty)
        .join(', ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Row 1: Avatar + Farmer + Status + Amount
          Row(children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(purchase.initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        fontFamily: 'Poppins')),
              ),
            ),
            const SizedBox(width: 12),

            // Farmer + receipt
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(purchase.farmerName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.receipt_outlined,
                          size: 11, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Text(
                        purchase.receiptNumber.isNotEmpty
                            ? purchase.receiptNumber
                            : 'No receipt',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                            fontFamily: 'Poppins'),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time_rounded,
                          size: 11, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Text(timeAgo(purchase.purchaseDate),
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                              fontFamily: 'Poppins')),
                    ]),
                  ]),
            ),

            // Amount + status
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(fmtAmount(purchase.finalPayable),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel,
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 10,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),

          const SizedBox(height: 10),

          // Divider
          const Divider(color: AppColors.divider, height: 1),

          const SizedBox(height: 10),

          // Row 2: Products + financial summary
          Row(children: [
            // Products
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Products',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                            fontFamily: 'Poppins')),
                    const SizedBox(height: 2),
                    Text(
                      products.isNotEmpty ? products : '—',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          fontFamily: 'Poppins'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
            ),

            const SizedBox(width: 12),

            // Financial chips
            Row(children: [
              _MiniStat(
                  label: 'Gross',
                  value: fmtAmount(purchase.grossTotal),
                  color: AppColors.textSecondary),
              const SizedBox(width: 8),
              if (purchase.amountDue > 0)
                _MiniStat(
                    label: 'Due',
                    value: fmtAmount(purchase.amountDue),
                    color: AppColors.error),
              if (purchase.amountDue == 0 && purchase.amountPaid > 0)
                _MiniStat(
                    label: 'Paid',
                    value: fmtAmount(purchase.amountPaid),
                    color: AppColors.success),
            ]),
          ]),

          // Due amount progress bar (only for partial)
          if (purchase.status == 'partial' && purchase.finalPayable > 0) ...[
            const SizedBox(height: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  'Collected: ${fmtAmount(purchase.amountPaid)} / ${fmtAmount(purchase.finalPayable)}',
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins'),
                ),
                Text(
                  '${((purchase.amountPaid / purchase.finalPayable) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.warning,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600),
                ),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (purchase.amountPaid / purchase.finalPayable)
                      .clamp(0.0, 1.0),
                  backgroundColor: AppColors.warningSurface,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.warning),
                  minHeight: 5,
                ),
              ),
            ]),
          ],
   if (purchase.status != 'paid' && purchase.amountDue > 0) ...[
  const SizedBox(height: 10),
  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () {
        // Navigate to your PaymentScreen (import it)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              purchaseId: purchase.id,
              farmerId: purchase.farmerId,
              farmerName: purchase.farmerName,
              finalPayable: purchase.finalPayable,
              amountPaid: purchase.amountPaid,
              amountDue: purchase.amountDue,
              receiptNumber: purchase.receiptNumber,
            ),
          ),
        ).then((paid) {
          if (paid == true) {
            // Optionally trigger a refresh (e.g., call a callback passed to _PurchaseCard)
          }
        });
      },
      icon: const Icon(Icons.payments_rounded, size: 16),
      label: Text(
        'Pay ₹${fmtAmount(purchase.amountDue)} Due',
        style: const TextStyle(
            fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    ),
  ),
],    ]),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 10, color: AppColors.textHint, fontFamily: 'Poppins')),
      Text(value,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'Poppins')),
    ]);
  }
}

// ── Purchase Detail Bottom Sheet ──────────────────────────────

class _PurchaseDetailSheet extends StatelessWidget {
  final PurchaseListItem purchase;
  final String Function(double) fmtAmount;
  final String Function(DateTime) fmtDate;

  const _PurchaseDetailSheet({
    required this.purchase,
    required this.fmtAmount,
    required this.fmtDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [
        // Handle
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 6),

        // Header
        Container(
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(purchase.initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          fontFamily: 'Poppins')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(purchase.farmerName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins')),
                      Text(
                        '${purchase.farmerMobile}  •  ${fmtDate(purchase.purchaseDate)}',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'Poppins'),
                      ),
                    ]),
              ),
              _statusBadge(purchase.status),
            ]),
            if (purchase.receiptNumber.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '📄 ${purchase.receiptNumber}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ]),
        ),

        // Scrollable body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product lines
                  _sectionTitle(' Product Lines'),
                  const SizedBox(height: 10),
                  ...purchase.lines.map((l) => _ProductLineDetailCard(line: l)),

                  // Deductions
                  const SizedBox(height: 16),
                  _sectionTitle('Deductions'),
                  const SizedBox(height: 10),
                  _DeductionDetailCard(
                      purchase: purchase, fmtAmount: fmtAmount),

                  // Final payable
                  const SizedBox(height: 16),
                  _FinalSummaryCard(
                      purchase: purchase, fmtAmount: fmtAmount),
const SizedBox(height: 16),
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: () {
      Navigator.pop(context); // close bottom sheet
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            purchaseId: purchase.id,
            farmerName: purchase.farmerName,
            farmerMobile: purchase.farmerMobile,
          ),
        ),
      );
    },
    icon: const Icon(Icons.receipt_long_rounded),
    label: const Text('View Full Receipt',
        style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12),
    ),
  ),
),


                  // Edit Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close bottom sheet

                        // Convert PurchaseLineItem to PurchaseLine
                        final editLines = purchase.lines.map((line) => PurchaseLine(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          productName: line.productName,
                          pricingType: line.pricingType,
                          bags: line.bags,
                          weightPerBag: line.weightPerBag,
                          actualQty: line.actualQty,
                          qualityDeduction: line.qualityDeduction,
                          rate: line.rate,
                          rateLocked: false,
                        )).toList();

                        // Create FarmerModel with ALL required fields
                        final farmer = FarmerModel(
                          id: purchase.farmerId,
                          operatorId: '', // Will be filled by backend if needed
                          name: purchase.farmerName,
                          mobile: purchase.farmerMobile,
                          totalPurchases: 0,
                          totalPaid: 0,
                          pendingDues: purchase.amountDue,
                          advanceBalance: 0,
                          isActive: true,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewPurchaseScreen(
                              isEditMode: true,
                              purchaseId: purchase.id,
                              existingFarmer: farmer,
                              existingLines: editLines,
                              existingDeductions: DeductionData(
                                transport: purchase.deductions.transport,
                                labour: purchase.deductions.labour,
                                commission: purchase.deductions.commission,
                                commissionType: purchase.deductions.commissionType,
                                storage: purchase.deductions.storage,
                                advanceAdjusted: purchase.deductions.advanceAdjusted,
                                other: purchase.deductions.other,
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit Purchase',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ]),
          ),
        ),
      ]),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins'));

  Widget _statusBadge(String status) {
    Color color;
    Color bg;
    String label;
    switch (status) {
      case 'paid':
        color = AppColors.success;
        bg = AppColors.successSurface;
        label = 'Paid';
        break;
      case 'partial':
        color = AppColors.warning;
        bg = AppColors.warningSurface;
        label = 'Partial';
        break;
      default:
        color = AppColors.error;
        bg = AppColors.errorSurface;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700)),
    );
  }
}

// ── Product Line Detail Card ──────────────────────────────────

class _ProductLineDetailCard extends StatelessWidget {
  final PurchaseLineItem line;
  const _ProductLineDetailCard({required this.line});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(line.productName.isNotEmpty ? line.productName : 'Product',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins')),
          Text('₹${line.lineTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                  fontFamily: 'Poppins')),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _chip(line.pricingType.toUpperCase()),
          if (line.pricingType == 'kg' && line.bags > 0) ...[
            _chip('${line.bags.toStringAsFixed(0)} bags'),
            _chip('${line.weightPerBag.toStringAsFixed(1)} kg/bag'),
            _chip('Gross: ${line.actualQty.toStringAsFixed(2)} kg'),
          ],
          if (line.qualityDeduction > 0)
            _chip('- ${line.qualityDeduction.toStringAsFixed(2)} ${line.unit} (qual.)'),
          _chip('Billed: ${line.billedQty.toStringAsFixed(2)} ${line.unit}'),
          _chip('₹${line.rate.toStringAsFixed(2)}/${line.unit}'),
        ]),
      ]),
    );
  }

  Widget _chip(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.primaryDark,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500)));
}

// ── Deduction Detail Card ─────────────────────────────────────

class _DeductionDetailCard extends StatelessWidget {
  final PurchaseListItem purchase;
  final String Function(double) fmtAmount;

  const _DeductionDetailCard(
      {required this.purchase, required this.fmtAmount});

  @override
  Widget build(BuildContext context) {
    final d = purchase.deductions;

    // Calculate commission amount
    double commAmt = d.commissionType == 'percent'
        ? (d.commission / 100) * purchase.grossTotal
        : d.commission;

    final rows = <_DeductionRow>[];
    if (d.transport > 0) rows.add(_DeductionRow('Transport', d.transport));
    if (d.labour > 0) rows.add(_DeductionRow('Labour', d.labour));
    if (commAmt > 0) {
      rows.add(_DeductionRow(
        d.commissionType == 'percent'
            ? 'Commission (${d.commission.toStringAsFixed(1)}%)'
            : 'Commission (fixed)',
        commAmt,
      ));
    }
    if (d.storage > 0) rows.add(_DeductionRow('Storage', d.storage));
    if (d.returnDeduction > 0) {
      rows.add(_DeductionRow('Return Deduction', d.returnDeduction));
    }
    if (d.advanceAdjusted > 0) {
      rows.add(_DeductionRow('Advance Adjusted', d.advanceAdjusted));
    }
    if (d.other > 0) rows.add(_DeductionRow('Other', d.other));

    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text('No deductions applied.',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        ...rows.map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.label,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontFamily: 'Poppins')),
                    Text('- ₹${r.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600)),
                  ]),
            )),
        const Divider(color: AppColors.divider),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total Deductions',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins')),
          Text('- ₹${purchase.totalDeductions.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                  fontFamily: 'Poppins')),
        ]),
      ]),
    );
  }
}

class _DeductionRow {
  final String label;
  final double amount;
  _DeductionRow(this.label, this.amount);
}

// ── Final Summary Card ────────────────────────────────────────

class _FinalSummaryCard extends StatelessWidget {
  final PurchaseListItem purchase;
  final String Function(double) fmtAmount;
  const _FinalSummaryCard(
      {required this.purchase, required this.fmtAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        _row('Gross Total', purchase.grossTotal, white: false),
        const SizedBox(height: 4),
        _row('Total Deductions', purchase.totalDeductions, isDeduction: true),
        const Divider(color: Colors.white24, height: 20),
        _row('Final Payable', purchase.finalPayable, large: true),
        const SizedBox(height: 8),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 8),
        _row('Amount Collected', purchase.amountPaid,
            color: Colors.greenAccent.shade100),
        if (purchase.amountDue > 0) ...[
          const SizedBox(height: 4),
          _row('Amount Due', purchase.amountDue,
              color: Colors.orange.shade200),
        ],
        // Payment progress
        if (purchase.finalPayable > 0) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (purchase.amountPaid / purchase.finalPayable)
                  .clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                  purchase.status == 'paid'
                      ? Colors.greenAccent
                      : Colors.orange),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${((purchase.amountPaid / purchase.finalPayable) * 100).clamp(0, 100).toStringAsFixed(0)}% collected',
            style: const TextStyle(
                color: Colors.white70, fontSize: 11, fontFamily: 'Poppins'),
            textAlign: TextAlign.center,
          ),
        ],
      ]),
    );
  }

  Widget _row(String label, double value,
      {bool large = false,
      bool isDeduction = false,
      bool white = true,
      Color? color}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(
              color: color ?? Colors.white70,
              fontSize: large ? 15 : 13,
              fontFamily: 'Poppins',
              fontWeight: large ? FontWeight.w600 : FontWeight.w400)),
      Text(
        isDeduction
            ? '- ₹${value.toStringAsFixed(2)}'
            : '₹${value.toStringAsFixed(2)}',
        style: TextStyle(
            color: color ?? Colors.white,
            fontSize: large ? 22 : 13,
            fontFamily: 'Poppins',
            fontWeight: large ? FontWeight.w700 : FontWeight.w600),
      ),
    ]);
  }
}
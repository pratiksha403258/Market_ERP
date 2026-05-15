// lib/features/ledger/screens/BuyerLedgerListScreen.dart

import 'package:agr_market/models/Buyer%20ledger%20model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../services/dio_client.dart';
import '../../../services/constant_service.dart';
import 'buyer_ledger_details_screen.dart';

class BuyerLedgerListScreen extends StatefulWidget {
  const BuyerLedgerListScreen({super.key});

  @override
  State<BuyerLedgerListScreen> createState() => _BuyerLedgerListScreenState();
}

class _BuyerLedgerListScreenState extends State<BuyerLedgerListScreen> {
  List<BuyerLedgerListItem> _buyers = [];
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
    _loadBuyersLedger();
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
      _loadMoreBuyers();
    }
  }

  Future<void> _loadBuyersLedger({bool reset = true}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _currentPage = 1;
        _buyers = [];
      });
    }

    try {
      final params = <String, dynamic>{
        'page': _currentPage,
        'limit': 20,
      };
      if (_searchQuery.isNotEmpty) params['search'] = _searchQuery;

      final res = await DioClient.instance.dio.get(
        ApiRoutes.allBuyersLedger,
        queryParameters: params,
      );

      print('API Response: ${res.data}'); // Debug print

      final responseData = res.data as Map<String, dynamic>;
      if (responseData['success'] == true) {
        final data = AllBuyersLedgerData.fromJson(
            responseData['data'] as Map<String, dynamic>);
        setState(() {
          if (reset) {
            _buyers = data.buyers;
          } else {
            _buyers = [..._buyers, ...data.buyers];
          }
          _totalPages = data.totalPages;
          _loading = false;
        });
      } else {
        throw Exception('API returned success=false');
      }
    } catch (e) {
      debugPrint('Error loading buyers ledger: $e');
      setState(() => _loading = false);
      _showError('Failed to load buyers: $e');
    }
  }

  Future<void> _loadMoreBuyers() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _loadBuyersLedger(reset: false);
    setState(() => _isLoadingMore = false);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'B';
  }

  String _fmtAmount(double v) {
    final absV = v.abs();
    if (absV >= 10000000) return '₹${(absV / 10000000).toStringAsFixed(1)}Cr';
    if (absV >= 100000) return '₹${(absV / 100000).toStringAsFixed(1)}L';
    if (absV >= 1000) return '₹${(absV / 1000).toStringAsFixed(1)}K';
    return '₹${NumberFormat('#,##0').format(absV)}';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Buyer Ledger',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Search Bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                setState(() => _searchQuery = v);
                _loadBuyersLedger(reset: true);
              },
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search by name, mobile or email...',
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
                          _loadBuyersLedger(reset: true);
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

          // ── Buyer List ────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _buyers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_cart_outlined,
                                size: 56, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No matching buyers found for "$_searchQuery"'
                                  : 'No buyers found',
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
                        onRefresh: () => _loadBuyersLedger(reset: true),
                        color: AppColors.primary,
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _buyers.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _buyers.length) {
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

                            final item = _buyers[i];
                            final name = item.buyer.name;
                            final mobile = item.buyer.mobile;
                            final balance = item.currentBalance;
                            // balance < 0 means buyer owes money (credit > debit)
                            final owes = balance < 0;
                            final absBalance = balance.abs();

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BuyerLedgerDetailScreen(
                                      buyerId: item.buyer.id,
                                      buyerName: name,
                                      buyerMobile: mobile,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
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

                                    // Name & Mobile
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
                                              color: AppColors.textSecondary,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          // if (item.businessDetails.name.isNotEmpty &&
                                          //     item.businessDetails.name != 'Super Admin')
                                          //   Text(
                                          //     item.businessDetails.name,
                                          //     style: const TextStyle(
                                          //       fontSize: 10,
                                          //       color: AppColors.textHint,
                                          //       fontFamily: 'Poppins',
                                          //     ),
                                          //   ),
                                        ],
                                      ),
                                    ),

                                    // Balance badge
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (balance == 0)
                                          _badge(
                                            'CLEAR',
                                            AppColors.successSurface,
                                            AppColors.success,
                                          )
                                        else
                                          _badge(
                                            '${owes ? 'DUE' : 'ADV'} ${_fmtAmount(absBalance)}',
                                            owes
                                                ? AppColors.warningSurface
                                                : AppColors.successSurface,
                                            owes
                                                ? AppColors.warning
                                                : AppColors.success,
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
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: fg,
            fontFamily: 'Poppins',
          ),
        ),
      );
}
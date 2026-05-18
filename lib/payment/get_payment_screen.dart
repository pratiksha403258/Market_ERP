import 'package:agr_market/payment/payment_screen.dart';
import 'package:agr_market/services/get_payment_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../models/get_payment_model.dart';
import '../services/constant_service.dart';
import '../services/dio_client.dart';


class GetPaymentScreen extends StatefulWidget {
  const GetPaymentScreen({super.key});

  @override
  State<GetPaymentScreen> createState() => _GetPaymentScreenState();
}

class _GetPaymentScreenState extends State<GetPaymentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── All Payments Tab ─────────────────────────────────────────
  List<GetPaymentModel> _payments = [];
  bool _loadingPayments = false;
  bool _hasMorePayments = true;
  int _paymentsPage = 1;
  static const int _paymentsLimit = 20;
  String _searchQuery = '';
  String? _selectedPaymentMode;
  String? _selectedStatus;
  GetPaymentSummaryModel? _summary;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // ── Due Summary Tab ──────────────────────────────────────────
  GetDueSummaryModel? _dueSummary;
  bool _loadingDueSummary = true;
  int _daysOverdue = 30;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadPayments();
    _loadDueSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_loadingPayments &&
        _hasMorePayments) {
      _loadPayments(loadMore: true);
    }
  }

  // ── Load All Payments ────────────────────────────────────────
  Future<void> _loadPayments({bool loadMore = false}) async {
    if (_loadingPayments) return;
    if (loadMore && !_hasMorePayments) return;

    setState(() => _loadingPayments = true);

    try {
      final response = await GetPaymentService.instance.getPayments(
        page: loadMore ? _paymentsPage : 1,
        limit: _paymentsLimit,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        paymentMode: _selectedPaymentMode,
        status: _selectedStatus,
        sortBy: 'paymentDate',
        sortOrder: 'desc',
      );

      // Debug print to see what's coming from API
      print('=== PAYMENTS RESPONSE ===');
      print('Total payments: ${response.payments.length}');
      for (var p in response.payments) {
        print('Payment: ID=${p.id}, Farmer=${p.farmerName}, Amount=${p.amount}, Mode=${p.paymentMode}');
      }
      print('========================');

      setState(() {
        if (loadMore) {
          _payments.addAll(response.payments);
          _paymentsPage++;
        } else {
          _payments = response.payments;
          _summary = response.summary;
          _paymentsPage = 2;
        }
        _hasMorePayments = response.payments.length == _paymentsLimit;
        _loadingPayments = false;
      });
    } catch (e) {
      setState(() => _loadingPayments = false);
      _showError('Failed to load payments: $e');
    }
  }

// Fetch purchase details to get current due amount
  Future<void> _fetchPurchaseAndNavigate(GetPaymentModel payment) async {
    if (payment.purchaseId.isEmpty) {
      _showError('Cannot record payment: Purchase ID not found');
      return;
    }

    _showLoadingDialog();

    try {
      // Fetch purchase details from API
      final response = await DioClient.instance.dio.get(
        '${ApiRoutes.purchases}/${payment.purchaseId}',
      );

      Navigator.pop(context); // Close loading dialog

      final data = response.data as Map<String, dynamic>;
      final purchase = data['data'] as Map<String, dynamic>? ?? data;

      // Extract farmer and payment info
      final farmer = purchase['farmer'] as Map<String, dynamic>? ?? {};
      final finalPayable = (purchase['finalPayable'] as num?)?.toDouble() ?? 0;
      final amountPaid = (purchase['amountPaid'] as num?)?.toDouble() ?? 0;
      final amountDue = (purchase['amountDue'] as num?)?.toDouble() ?? (finalPayable - amountPaid);
      final receiptNumber = purchase['receiptNumber']?.toString() ?? '';
      final farmerName = farmer['name']?.toString() ?? payment.farmerName;
      final farmerId = farmer['_id']?.toString() ?? payment.farmerId;

      // Navigate to PaymentScreen with actual due amount
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            purchaseId: payment.purchaseId,
            farmerId: farmerId,
            farmerName: farmerName,
            finalPayable: finalPayable,
            amountPaid: amountPaid,
            amountDue: amountDue,  // Now this will have the correct amount!
            receiptNumber: receiptNumber,
          ),
        ),
      ).then((paid) {
        if (paid == true) {
          _loadPayments();
          _loadDueSummary();
        }
      });

    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showError('Failed to load purchase details: $e');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
  // Navigate from All Payments tab to record a NEW payment for the same farmer/purchase
  void _navigateToPaymentFromPayment(GetPaymentModel payment) {
    print('=== TAPPED ON PAYMENT CARD ===');
    print('Payment ID: ${payment.id}');
    print('Farmer: ${payment.farmerName}');
    print('Purchase ID: ${payment.purchaseId}');

    if (payment.purchaseId.isEmpty) {
      _showError('Cannot record payment: Purchase information missing');
      return;
    }

    // Fetch purchase details and navigate
    _fetchPurchaseAndNavigate(payment);
  }
  // ── Load Due Summary ─────────────────────────────────────────
  Future<void> _loadDueSummary() async {
    setState(() => _loadingDueSummary = true);
    try {
      final response = await GetPaymentService.instance.getDueSummary(
        daysOverdue: _daysOverdue,
      );

      // Debug print - FULL RAW RESPONSE
      print('=== FULL DUE SUMMARY RAW RESPONSE ===');
      print('Response success: ${response.success}');
      print('DueSummary object: ${response.dueSummary}');

      // Print each purchase in detail
      for (var p in response.dueSummary.purchases) {
        print('--- PURCHASE DETAIL ---');
        print('ID: ${p.id}');
        print('Receipt: ${p.receiptNumber}');
        print('Farmer Name: ${p.farmerName}');
        print('Final Payable: ${p.finalPayable}');
        print('Amount Paid: ${p.amountPaid}');
        print('Amount Due: ${p.amountDue}');
        print('Is Overdue: ${p.isOverdue}');
        print('Purchase Date: ${p.purchaseDate}');
      }
      print('================================');

      setState(() {
        _dueSummary = response.dueSummary;
        _loadingDueSummary = false;
      });
    } catch (e) {
      print('Error loading due summary: $e');
      setState(() => _loadingDueSummary = false);
      _showError('Failed to load due summary: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _navigateToPayment(GetPurchaseDueModel? purchase) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          purchaseId: purchase?.id ?? '',
          farmerId: purchase?.farmerId ?? '',
          farmerName: purchase?.farmerName ?? '',
          finalPayable: purchase?.finalPayable ?? 0,
          amountPaid: purchase?.amountPaid ?? 0,
          amountDue: purchase?.amountDue ?? 0,
          receiptNumber: purchase?.receiptNumber ?? '',
        ),
      ),
    ).then((paid) {
      if (paid == true) {
        _loadPayments();
        _loadDueSummary();
      }
    });
  }

  String _formatAmount(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return _formatDate(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'All Payments', icon: Icon(Icons.payments)),
            Tab(text: 'Due Summary', icon: Icon(Icons.warning_amber_rounded)),
          ],
        ),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchDialog,
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllPaymentsTab(),
          _buildDueSummaryTab(),
        ],
      ),

    );
  }

  // ─────────────────────────────────────────────────────────────
  // ALL PAYMENTS TAB
  // ─────────────────────────────────────────────────────────────
  Widget _buildAllPaymentsTab() {
    return Column(
      children: [
        // Search Bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.10),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (v) {
              setState(() => _searchQuery = v);
              _loadPayments();
            },
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search by farmer name',
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
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                  _loadPayments();
                },
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textHint, size: 18),
              )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceVariant,
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
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),

        // Summary Card
        if (_summary != null) _buildSummaryCard(),

        // Payments List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadPayments(),
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (_payments.isEmpty && !_loadingPayments)
                  SliverToBoxAdapter(child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                          if (i == _payments.length) {
                            return _loadingPayments
                                ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                                : const SizedBox(height: 20);
                          }
                          return _PaymentCard(
                            payment: _payments[i],
                            formatAmount: _formatAmount,
                            formatDate: _formatDate,
                            timeAgo: _timeAgo,
                            onTap: () => _navigateToPaymentFromPayment(_payments[i]),
                          );
                        },
                        childCount: _payments.length + 1,
                      ),
                    ),
                  ),
                if (_loadingPayments && _payments.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (_, __) => _buildShimmerCard(),
                        childCount: 5,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text('Total Amount',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Poppins')),
                Text(_formatAmount(_summary!.totalAmount),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins')),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: Column(
              children: [
                const Text('Payments',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Poppins')),
                Text('${_summary!.totalPayments}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins')),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: Column(
              children: [
                const Text('Average',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Poppins')),
                Text(_formatAmount(_summary!.avgAmount),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payments_outlined,
                color: AppColors.primary, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No payments match "$_searchQuery"'
                : 'No payments yet',
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Payments will appear here once recorded.',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
                _loadPayments();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Text('Clear Search',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search Payments',
            style: TextStyle(fontFamily: 'Poppins')),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by farmer name',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            setState(() => _searchQuery = value);
            _loadPayments();
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
              _loadPayments();
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _searchQuery = _searchController.text);
              _loadPayments();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DUE SUMMARY TAB
  // ─────────────────────────────────────────────────────────────
  Widget _buildDueSummaryTab() {
    if (_loadingDueSummary) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_dueSummary == null || _dueSummary!.purchases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 34),
            ),
            const SizedBox(height: 16),
            const Text('No pending dues!',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 6),
            const Text('All purchases are fully paid.',
                style: TextStyle(fontFamily: 'Poppins')),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Due Summary Overview Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDueStatItem(
                      'Total Due',
                      _formatAmount(_dueSummary!.totalDue),
                      AppColors.warning,
                    ),
                  ),
                  Container(width: 1, height: 50, color: AppColors.border),
                  Expanded(
                    child: _buildDueStatItem(
                      'Overdue',
                      _formatAmount(_dueSummary!.totalOverdue),
                      AppColors.error,
                    ),
                  ),
                  Container(width: 1, height: 50, color: AppColors.border),
                  Expanded(
                    child: _buildDueStatItem(
                      'Purchases',
                      '${_dueSummary!.totalPurchases.toInt()}',
                      AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Days Overdue Slider
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Text('Overdue > ',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                  Expanded(
                    child: Slider(
                      value: _daysOverdue.toDouble(),
                      min: 7,
                      max: 90,
                      divisions: 11,
                      label: '$_daysOverdue days',
                      onChanged: (value) {
                        setState(() {
                          _daysOverdue = value.toInt();
                          _loadDueSummary();
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                  ),
                  Text('$_daysOverdue days',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          fontSize: 12)),
                ],
              ),
            ],
          ),
        ),

        // Due Purchases List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDueSummary,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _dueSummary!.purchases.length,
              itemBuilder: (context, index) {
                final purchase = _dueSummary!.purchases[index];
                return _DuePurchaseCard(
                  purchase: purchase,
                  formatAmount: _formatAmount,
                  formatDate: _formatDate,
                  onTap: () => _navigateToPayment(purchase),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDueStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins')),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Poppins')),
      ],
    );
  }
}

// ── Payment Card Widget ────────────────────────────────────────
// ── Payment Card Widget ────────────────────────────────────────
// ── Payment Card Widget (Tappable - navigates to PaymentScreen) ──
class _PaymentCard extends StatelessWidget {
  final GetPaymentModel payment;
  final String Function(double) formatAmount;
  final String Function(DateTime?) formatDate;
  final String Function(DateTime) timeAgo;
  final VoidCallback onTap;  // Add this

  const _PaymentCard({
    required this.payment,
    required this.formatAmount,
    required this.formatDate,
    required this.timeAgo,
    required this.onTap,  // Add this
  });

  Color get _modeColor {
    switch (payment.paymentMode.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'bank_transfer':
        return Colors.blue;
      case 'cheque':
        return Colors.orange;
      case 'upi':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData get _modeIcon {
    switch (payment.paymentMode.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'cheque':
        return Icons.description;
      case 'upi':
        return Icons.qr_code_scanner;
      default:
        return Icons.payment;
    }
  }

  String get _initials {
    final name = payment.farmerName.trim();
    if (name == 'Unknown Farmer') return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'F';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,  // Make the whole card tappable
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
        child: Row(
          children: [
            // Avatar with initials
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.farmerName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _modeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_modeIcon, size: 10, color: _modeColor),
                            const SizedBox(width: 2),
                            Text(
                              payment.paymentMode.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: _modeColor,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today_rounded,
                          size: 10, color: AppColors.textHint),
                      const SizedBox(width: 2),
                      Text(
                        timeAgo(payment.paymentDate),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  if (payment.referenceNumber != null && payment.referenceNumber!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Ref: ${payment.referenceNumber}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Amount and Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatAmount(payment.amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: payment.status == 'completed'
                        ? AppColors.successSurface
                        : AppColors.warningSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    payment.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: payment.status == 'completed'
                          ? AppColors.success
                          : AppColors.warning,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Due Purchase Card Widget ───────────────────────────────────
// ── Due Purchase Card Widget ───────────────────────────────────
class _DuePurchaseCard extends StatelessWidget {
  final GetPurchaseDueModel purchase;
  final String Function(double) formatAmount;
  final String Function(DateTime?) formatDate;
  final VoidCallback onTap;

  const _DuePurchaseCard({
    required this.purchase,
    required this.formatAmount,
    required this.formatDate,
    required this.onTap,
  });

  String get _initials {
    final name = purchase.farmerName.trim();
    if (name == 'Unknown' || name == 'Error') return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'F';
  }

  @override
  Widget build(BuildContext context) {
    final paidPercent = purchase.finalPayable > 0
        ? (purchase.amountPaid / purchase.finalPayable).clamp(0.0, 1.0)
        : 0.0;

    // Debug print
    print('Due Card - Farmer: ${purchase.farmerName}, Receipt: ${purchase.receiptNumber}, Due: ${purchase.amountDue}');

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
        child: Column(
          children: [
            Row(
              children: [
                // Avatar with initials
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Receipt Number
                      Text(
                        purchase.receiptNumber.isNotEmpty
                            ? purchase.receiptNumber
                            : 'No Receipt',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Farmer Name - Make sure this is visible
                      Text(
                        purchase.farmerName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Date
                      Text(
                        formatDate(purchase.purchaseDate),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                // Amounts
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Due: ${formatAmount(purchase.amountDue)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Paid: ${formatAmount(purchase.amountPaid)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(paidPercent * 100).toStringAsFixed(0)}% collected',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (purchase.isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.errorSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'OVERDUE',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: paidPercent,
                    backgroundColor: AppColors.border,
                    color: paidPercent >= 0.8 ? AppColors.success : AppColors.warning,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
            // Pay Button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.payments_rounded, size: 16),
                label: Text(
                  'Pay ${formatAmount(purchase.amountDue)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
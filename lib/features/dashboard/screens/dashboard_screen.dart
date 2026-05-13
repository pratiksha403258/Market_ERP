// ─────────────────────────────────────────────────────────────
//  DASHBOARD SCREEN — Real API Data
//  Replaces all hardcoded mock values with live API calls:
//    - GET /farmers          → total farmer count
//    - GET /purchases        → today's arrivals, sales total, recent list
//    - GET /purchases/summary → pending dues, weekly data
// ─────────────────────────────────────────────────────────────

import 'package:agr_market/features/auth/screens/language_selection_screen.dart';
import 'package:agr_market/features/auth/screens/profile_screen.dart';
import 'package:agr_market/features/dashboard/screens/reports_screen.dart';
import 'package:agr_market/inventory/inventory_list_screen.dart';
import 'package:agr_market/ledger/ledger_screen.dart';
import 'package:agr_market/payment/payment_screen.dart';      // ← NEW import
import 'package:agr_market/purchase/purchase_screen.dart';
import 'package:agr_market/sales/sale_create_screen.dart';
import 'package:agr_market/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/dio_client.dart';
import '../../../services/constant_service.dart';
import '../../farmers/screens/farmer_registration_screen.dart';

// ── Dashboard Data Model ──────────────────────────────────────

class _DashboardData {
  final int totalFarmers;
  final int todayPurchaseCount;
  final double thisMonthValue;
  final int thisMonthCount;
  final double totalPendingPayments;
  final int pendingExpenseApprovals;
  final List<Map<String, dynamic>> recentPurchases;
  final List<double> weeklyArrivals;

  const _DashboardData({
    this.totalFarmers = 0,
    this.todayPurchaseCount = 0,
    this.thisMonthValue = 0,
    this.thisMonthCount = 0,
    this.totalPendingPayments = 0,
    this.pendingExpenseApprovals = 0,
    this.recentPurchases = const [],
    this.weeklyArrivals = const [0.1,0.1,0.1,0.1,0.1,0.1,0.1],
  });
}

// ── Main Screen ───────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _DashboardData _data = const _DashboardData();
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ── NEW helper methods ─────────────────────────────────────
  bool _isToday(String dateStr) {
    if (dateStr.isEmpty) return false;
    final date = DateTime.tryParse(dateStr)?.toLocal();
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isThisWeek(String dateStr, DateTime weekStart) {
    if (dateStr.isEmpty) return false;
    final date = DateTime.tryParse(dateStr)?.toLocal();
    if (date == null) return false;
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day + 1);
    return date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
        date.isBefore(todayEnd);
  }
  // ───────────────────────────────────────────────────────────
Future<void> _loadDashboard() async {
  setState(() { _loading = true; _hasError = false; });
  try {

    // ── CALL 1: Dashboard KPIs ──────────────────────────────
    final dashRes = await DioClient.instance.dio
        .get(ApiRoutes.dashboard);
    final d = dashRes.data['data'] as Map<String, dynamic>;
    final monthly =
        d['thisMonthPurchases'] as Map<String, dynamic>;

    final totalFarmers =
        (d['totalActiveFarmers'] as num?)?.toInt() ?? 0;
    final todayCount =
        (d['todayPurchaseCount'] as num?)?.toInt() ?? 0;
    final monthValue =
        (monthly['value'] as num?)?.toDouble() ?? 0.0;
    final monthCount =
        (monthly['count'] as num?)?.toInt() ?? 0;
    final pendingPayments =
        (d['totalPendingPayments'] as num?)?.toDouble() ?? 0.0;
    final pendingExpenses =
        (d['pendingExpenseApprovals'] as num?)?.toInt() ?? 0;

    debugPrint('✅ Dashboard KPIs: Farmers=$totalFarmers '
        'Pending=₹$pendingPayments Month=₹$monthValue');

    // ── CALL 2: Purchases for weekly bars + recent list ─────
    // status filter skips draft records (which have ₹0 values)
   // ── CALL 2: Purchases for weekly bars (full week range) ─────
List allPurchases = [];
try {
  final now = DateTime.now();
  
  // Start of the week (Monday)
  final weekStart = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  
  // End of the week (next Monday, exclusive)
  final weekEnd = weekStart.add(const Duration(days: 7));

  // Format dates for API
  final startIso = weekStart.toIso8601String().split('T')[0];
  final endIso = weekEnd.toIso8601String().split('T')[0];

  final pRes = await DioClient.instance.dio.get(
    ApiRoutes.purchases,
    queryParameters: {
      'page': 1,
      'limit': 100,          // increase limit to capture all week purchases
      'sortOrder': 'desc',
      // 'status': 'saved,partial,paid',
      'startDate': startIso,
      'endDate': endIso,     // optional – but recommended if API supports it
    },
  );

  if (pRes.data is Map && pRes.data['data'] is List) {
    allPurchases = pRes.data['data'] as List;
  } else if (pRes.data is List) {
    allPurchases = pRes.data as List;
  }
  debugPrint('✅ Weekly purchases loaded: ${allPurchases.length}');
  
} catch (e) {
  debugPrint('⚠️ Weekly purchases error: $e');

}

    // ── Weekly bar calculation ──────────────────────────────
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final dayTotals = List<double>.filled(7, 0.0);
    for (final p in allPurchases) {
      final dateStr = p['purchaseDate']?.toString()
          ?? p['createdAt']?.toString() ?? '';
      final date = DateTime.tryParse(dateStr)?.toLocal();
      if (date == null) continue;
      final todayEnd =
          DateTime(now.year, now.month, now.day + 1);
      if (date.isBefore(weekStart) ||
          !date.isBefore(todayEnd)) continue;
      final idx = (date.weekday - 1).clamp(0, 6);
      dayTotals[idx] +=
          (p['finalPayable'] as num?)?.toDouble() ?? 0;
    }
    final maxDay = dayTotals.reduce((a, b) => a > b ? a : b);
    final weeklyNorm = maxDay > 0
        ? dayTotals
            .map((v) => (v / maxDay).clamp(0.1, 1.0))
            .toList()
        : List<double>.filled(7, 0.1);
  debugPrint('Weekly totals (₹): $dayTotals');
debugPrint('Normalized: $weeklyNorm');
    // ── Recent 3 purchases ──────────────────────────────────
    final recentList = allPurchases.take(3).map((p) {
      final lines = p['lines'] as List? ?? [];
      final product = lines.isNotEmpty
          ? (lines[0]['productName']?.toString() ?? 'Product')
          : 'Purchase';
      final farmer = p['farmer'];
      final farmerName = farmer is Map
          ? farmer['name']?.toString() ?? 'Unknown'
          : 'Unknown';
      return <String, dynamic>{
        'product': product,
        'farmer': farmerName,
        'amount':
            (p['finalPayable'] as num?)?.toDouble() ?? 0.0,
        'date': p['purchaseDate']?.toString()
            ?? p['createdAt']?.toString() ?? '',
        'status': p['status']?.toString() ?? '',
        'receiptNumber':
            p['receiptNumber']?.toString() ?? '',
      };
    }).toList();

    setState(() {
      _data = _DashboardData(
        totalFarmers: totalFarmers,
        todayPurchaseCount: todayCount,
        thisMonthValue: monthValue,
        thisMonthCount: monthCount,
        totalPendingPayments: pendingPayments,
        pendingExpenseApprovals: pendingExpenses,
        recentPurchases: recentList,
        weeklyArrivals: weeklyNorm,
      );
      _loading = false;
    });

  } catch (e) {
    debugPrint('❌ Dashboard failed: $e');
    setState(() { _loading = false; _hasError = true; });
  }
}
  List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      if (data['purchases'] is List) return data['purchases'];
      if (data['data'] is List) return data['data'];
    }
    return [];
  }

  String _formatAmount(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  String _formatKg(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}T';
    return '${v.toStringAsFixed(0)} kg';
  }

  String _timeAgo(String dateStr) {
    if (dateStr.isEmpty) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
Future<void> _addPayment() async {
  debugPrint('➡️ _addPayment() called');

  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
  );

  List<Map<String, dynamic>> purchases = [];
  try {
    final res = await DioClient.instance.dio.get(
      ApiRoutes.purchases,
      queryParameters: {
        'page': 1,
        'limit': 100,
        'sortOrder': 'desc',
        'status': 'saved,partial,paid',
      },
    );

    debugPrint('✅ Purchases API response: ${res.statusCode}');
    debugPrint('📦 Response data type: ${res.data.runtimeType}');
    debugPrint('🔍 Full response data: ${res.data}');

    List raw = [];
    if (res.data is List) {
      raw = res.data;
    } else if (res.data is Map && res.data['data'] is List) {
      raw = res.data['data'];
    } else if (res.data is Map && res.data['purchases'] is List) {
      raw = res.data['purchases'];
    }
    purchases = raw.cast<Map<String, dynamic>>();

    if (mounted) Navigator.pop(context); // close loader
    debugPrint('📋 Fetched ${purchases.length} purchases');
  } catch (e, stack) {
    if (mounted) Navigator.pop(context);
    debugPrint('❌ ERROR fetching purchases: $e');
    debugPrint(stack.toString());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load purchases. Check connection/authentication.')),
      );
    }
    return;
  }

  if (purchases.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No purchases available to pay against.')),
      );
    }
    return;
  }

  // Show bottom sheet to select a purchase
  final selected = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      String query = '';
      return StatefulBuilder(
        builder: (ctx, setStateSheet) {
          final filtered = query.isEmpty
              ? purchases
              : purchases.where((p) {
                  final farmer = p['farmer'];
                  final farmerName = farmer is Map
                      ? (farmer['name']?.toString() ?? '')
                      : '';
                  final receiptNum = p['receiptNumber']?.toString() ?? '';
                  return farmerName.toLowerCase().contains(query.toLowerCase()) ||
                      receiptNum.toLowerCase().contains(query.toLowerCase());
                }).toList();

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.7,
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    autofocus: false,
                    onChanged: (val) {
                      query = val;
                      setStateSheet(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Search farmer or receipt...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final p = filtered[idx];
                      final farmer = p['farmer'];
                      final farmerName = farmer is Map
                          ? (farmer['name']?.toString() ?? 'Unknown')
                          : 'Unknown';
                      final farmerId = farmer is Map
                          ? (farmer['_id']?.toString() ?? farmer['id']?.toString() ?? '')
                          : '';
                      final receiptNum = p['receiptNumber']?.toString() ?? '';
                      final finalPayable = (p['finalPayable'] as num?)?.toDouble() ?? 0;
                      final amountPaid = (p['amountPaid'] as num?)?.toDouble() ?? 0;
                      final amountDue = (p['amountDue'] as num?)?.toDouble() ?? 0;
                      final initials = farmerName.isNotEmpty
                          ? farmerName.trim().split(' ').map((s) => s[0]).take(2).join().toUpperCase()
                          : 'F';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(initials,
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(farmerName,
                            style: const TextStyle(fontFamily: 'Poppins')),
                        subtitle: Text(
                          '$receiptNum  •  Due: ₹${amountDue.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () => Navigator.pop(ctx, p),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  if (selected != null && mounted) {
    final farmer = selected['farmer'];
    final farmerName = farmer is Map ? (farmer['name']?.toString() ?? 'Unknown') : 'Unknown';
    final farmerId = farmer is Map ? (farmer['_id']?.toString() ?? farmer['id']?.toString() ?? '') : '';
    final purchaseId = selected['_id']?.toString() ?? selected['id']?.toString() ?? '';
    final finalPayable = (selected['finalPayable'] as num?)?.toDouble() ?? 0;
    final amountPaid = (selected['amountPaid'] as num?)?.toDouble() ?? 0;
    final amountDue = (selected['amountDue'] as num?)?.toDouble() ?? 0;
    final receiptNumber = selected['receiptNumber']?.toString() ?? '';

    if (purchaseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid purchase selected.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          purchaseId: purchaseId,
          farmerId: farmerId,
          farmerName: farmerName,
          finalPayable: finalPayable,
          amountPaid: amountPaid,
          amountDue: amountDue,
          receiptNumber: receiptNumber,
        ),
      ),
    ).then((_) {
      // Refresh dashboard after returning
      _loadDashboard();
    });
  }
}
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.name ?? 'User';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, ${userName.split(' ').first}!',
                            style: AppTextStyles.headingLarge),
                        const SizedBox(height: 3),
                        Text(_todayLabel(), style: AppTextStyles.bodyMedium),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Icon(Icons.notifications_none_rounded,
                              color: AppColors.primary, size: 22),
                        ),

                          GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LanguageSelectionScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: const Icon(Icons.language_rounded,
                color: AppColors.primary, size: 22),
          ),
        ),
                        const SizedBox(width: 10),
                        
                        PopupMenuButton<String>(
      offset: const Offset(0, 45),
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            auth.user?.initials ?? 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              fontFamily: 'Poppins'
            ),
          ),
        ),
      ),
      onSelected: (value) async {
        if (value == 'profile') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(user: auth.user!),
            ),
          );
        } else if (value == 'logout') {
          // Logout logic
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
          
          if (confirm == true) {
            await AuthService.instance.logout();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppConstants.routeLogin,
                (route) => false,
              );
            }
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20),
              SizedBox(width: 12),
              Text('Profile'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: AppColors.error),
              SizedBox(width: 12),
              Text('Logout', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    ),
    const SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Hero Banner ──────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.28),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Farming Made Simple,',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontFamily: 'Poppins')),
                            const Text('Smarter & Sustainable',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins')),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Market ERP ',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Poppins')),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          image: const DecorationImage(
                            image: AssetImage('assets/images/logo3.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── KPI Grid ─────────────────────────────────
                const Text("Today's Overview",
                    style: AppTextStyles.headingMedium),
                const SizedBox(height: 12),
                if (_loading)
                  _buildKpiShimmer()
                else
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: [
       _KpiCard(
  icon: Icons.local_shipping_rounded,
  label: "Today's Purchases",
  value: _data.todayPurchaseCount.toString(),
  change: _data.todayPurchaseCount > 0 ? 'Today' : 'None yet',
  positive: true,
),
_KpiCard(
  icon: Icons.people_rounded,
  label: 'Active Farmers',
  value: _data.totalFarmers.toString(),
  change: 'Registered',
  positive: true,
),
_KpiCard(
  icon: Icons.account_balance_wallet_rounded,
  label: 'Pending Dues',
  value: _formatAmount(_data.totalPendingPayments),
  change: _data.totalPendingPayments > 0 ? 'Unpaid' : 'All clear',
  positive: _data.totalPendingPayments == 0,
),
_KpiCard(
  icon: Icons.trending_up_rounded,
  label: 'This Month',
  value: _formatAmount(_data.thisMonthValue),
  change: '${_data.thisMonthCount} purchases',
  positive: true,
),
                    ],
                  ),
                const SizedBox(height: 20),

                
             // ── Quick Actions (including Add Payment) ───────
const Text('Quick Actions', style: AppTextStyles.headingMedium),
const SizedBox(height: 12),

// First row - 3 buttons: New Purchase, Add Payment, New Sale
Row(
  children: [
    Expanded(
      child: _QuickAction(
        icon: Icons.add_circle_rounded,
        label: 'New Purchase',
        color: AppColors.primary,
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewPurchaseScreen()),
          );
          if (result == true) _loadDashboard();
        },
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: _QuickAction(
        icon: Icons.payments_rounded,           // Payment icon
        label: 'Add Payment',
        color: const Color(0xFFFF9800),         // Orange color for distinction
        onTap: _addPayment,                     // ← NEW method
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: _QuickAction(
        icon: Icons.storefront_rounded,
        label: 'New Sale',
        color: const Color(0xFF00BCD4),
        onTap: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const SaleCreateScreen()),
          );
          if (created == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sale created successfully!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    ),
  ],
),

const SizedBox(height: 10),

// Second row - 3 buttons (unchanged: Inventory, Ledger, Reports)
Row(
  children: [
    Expanded(
      child: _QuickAction(
        icon: Icons.inventory_2_rounded,
        label: 'Inventory',
        color: AppColors.info,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InventoryListScreen()),
          );
        },
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: _QuickAction(
        icon: Icons.receipt_long_rounded,
        label: 'Ledger',
        color: AppColors.info,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LedgerScreen()),
          );
        },
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: _QuickAction(
        icon: Icons.assessment_rounded,
        label: 'Reports',
        color: const Color(0xFF9C27B0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportsScreen()),
          );
        },
      ),
    ),
  ],
),
                const SizedBox(height: 20),

                // ── Weekly Bar Chart ──────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Weekly Arrivals',
                                  style: AppTextStyles.headingSmall),
                              Text('This week',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.textHint)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.successSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.trending_up_rounded,
                                    color: AppColors.success, size: 13),
                                SizedBox(width: 4),
                                Text('Live',
                                    style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins')),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_loading)
                        Container(
                            height: 120, color: AppColors.surfaceVariant)
                      else
                        SizedBox(
                          height: 120,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _Bar(
                                  day: 'Mon', pct: _data.weeklyArrivals[0]),
                              _Bar(
                                  day: 'Tue', pct: _data.weeklyArrivals[1]),
                              _Bar(
                                  day: 'Wed', pct: _data.weeklyArrivals[2]),
                              _Bar(
                                  day: 'Thu', pct: _data.weeklyArrivals[3]),
                              _Bar(
                                  day: 'Fri', pct: _data.weeklyArrivals[4]),
                              _Bar(
                                  day: 'Sat', pct: _data.weeklyArrivals[5]),
                              _Bar(
                                day: 'Sun',
                                pct: _data.weeklyArrivals[6],
                                isToday: DateTime.now().weekday == 7,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total this week',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                  fontFamily: 'Poppins')),
                          Text(
                            _formatAmount(_data.thisMonthValue),
                            style: AppTextStyles.numberSmall
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Error state ──────────────────────────────
                if (_hasError)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Some data could not be loaded. Pull down to retry.',
                            style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                                fontFamily: 'Poppins'),
                          ),
                        ),
                        GestureDetector(
                          onTap: _loadDashboard,
                          child: const Text('Retry',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins')),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shimmer placeholders ──────────────────────────────────

  Widget _buildKpiShimmer() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2)),
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
    );
  }

  String _todayLabel() {
    final d = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${days[d.weekday % 7]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── KPI Card ──────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String change;
  final bool positive;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor =
        positive ? AppColors.successSurface : AppColors.warningSurface;
    final textColor = positive ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(change,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins')),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.numberSmall),
              Text(label, style: AppTextStyles.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick Action ──────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins'),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

// ── Bar Chart ─────────────────────────────────────────────────

class _Bar extends StatelessWidget {
  final String day;
  final double pct;
  final bool isToday;
  const _Bar({required this.day, required this.pct, this.isToday = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 34,
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isToday)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Now',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontFamily: 'Poppins')),
              ),
            const Spacer(),
            Container(
              width: 34,
              height: 100 * pct,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isToday
                      ? [AppColors.secondary, AppColors.primary]
                      : [AppColors.primaryLight, AppColors.primary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 6),
            Text(day,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textHint,
                    fontFamily: 'Poppins')),
          ],
        ),
      );
}

// ── Recent Purchase Tile (not currently used in UI) ──────────
// … omitted for brevity
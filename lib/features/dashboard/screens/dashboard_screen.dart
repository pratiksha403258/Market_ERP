// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../core/constants/colors.dart';
// import '../../../providers/auth_provider.dart';

// class DashboardScreen extends StatelessWidget {
//   const DashboardScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthProvider>();
//     final userName = auth.user?.name ?? 'User';

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [

//               // ── Header ───────────────────────────────────────
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Hello, ${userName.split(' ').first}! 👋',
//                           style: AppTextStyles.headingLarge),
//                       const SizedBox(height: 3),
//                       Text(
//                         _todayLabel(),
//                         style: AppTextStyles.bodyMedium,
//                       ),
//                     ],
//                   ),
//                   Row(children: [
//                     // Notification bell
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: AppColors.surface,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: AppColors.border),
//                         boxShadow: [BoxShadow(
//                           color: AppColors.shadowLight,
//                           blurRadius: 8, offset: const Offset(0, 2),
//                         )],
//                       ),
//                       child: const Icon(Icons.notifications_none_rounded,
//                           color: AppColors.primary, size: 22),
//                     ),
//                     const SizedBox(width: 10),
//                     // Avatar
//                     Container(
//                       width: 40, height: 40,
//                       decoration: BoxDecoration(
//                         gradient: AppColors.heroGradient,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Center(
//                         child: Text(auth.user?.initials ?? 'U',
//                             style: const TextStyle(color: Colors.white,
//                                 fontWeight: FontWeight.w700, fontSize: 14,
//                                 fontFamily: 'Poppins')),
//                       ),
//                     ),
//                   ]),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               // ── Hero Banner Card ──────────────────────────────
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   gradient: AppColors.heroGradient,
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [BoxShadow(
//                     color: AppColors.primary.withOpacity(0.28),
//                     blurRadius: 20, offset: const Offset(0, 6),
//                   )],
//                 ),
//                 child: Row(children: [
//                   Expanded(child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text('Farming Made Simple,',
//                           style: TextStyle(color: Colors.white70, fontSize: 12,
//                               fontFamily: 'Poppins')),
//                       const SizedBox(height: 2),
//                       const Text('Smarter & Sustainable',
//                           style: TextStyle(color: Colors.white, fontSize: 17,
//                               fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
//                       const SizedBox(height: 14),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.25),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: const Text('Market ERP v1.0',
//                             style: TextStyle(color: Colors.white, fontSize: 12,
//                                 fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
//                       ),
//                     ],
//                   )),
//                   const SizedBox(width: 12),
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.2),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(Icons.storefront_rounded,
//                         color: Colors.white, size: 36),
//                   ),
//                 ]),
//               ),

//               const SizedBox(height: 20),

//               // ── KPI Stats Grid ────────────────────────────────
//               const Text('Today\'s Overview',
//                   style: AppTextStyles.headingMedium),
//               const SizedBox(height: 12),

//               GridView.count(
//                 crossAxisCount: 2,
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 mainAxisSpacing: 12,
//                 crossAxisSpacing: 12,
//                 childAspectRatio: 1.45,
//                 children: const [
//                   _KpiCard(
//                     icon: Icons.local_shipping_rounded,
//                     label: "Today's Arrival",
//                     value: '2,450 kg',
//                     change: '+12%',
//                     positive: true,
//                   ),
//                   _KpiCard(
//                     icon: Icons.people_rounded,
//                     label: 'Total Farmers',
//                     value: '128',
//                     change: '+5',
//                     positive: true,
//                   ),
//                   _KpiCard(
//                     icon: Icons.account_balance_wallet_rounded,
//                     label: 'Pending Dues',
//                     value: '₹1,45,000',
//                     change: '8 entries',
//                     positive: false,
//                   ),
//                   _KpiCard(
//                     icon: Icons.trending_up_rounded,
//                     label: "Today's Sales",
//                     value: '₹78,500',
//                     change: '+15%',
//                     positive: true,
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               // ── Quick Actions ─────────────────────────────────
//               const Text('Quick Actions', style: AppTextStyles.headingMedium),
//               const SizedBox(height: 12),
//               Row(children: [
//                 Expanded(child: _QuickAction(
//                   icon: Icons.add_circle_rounded,
//                   label: 'New Purchase',
//                   color: AppColors.primary,
//                   onTap: () {},
//                 )),
//                 const SizedBox(width: 10),
//                 Expanded(child: _QuickAction(
//                   icon: Icons.person_add_rounded,
//                   label: 'Add Farmer',
//                   color: AppColors.secondary,
//                   onTap: () {},
//                 )),
//                 const SizedBox(width: 10),
//                 Expanded(child: _QuickAction(
//                   icon: Icons.payments_rounded,
//                   label: 'Payment',
//                   color: AppColors.info,
//                   onTap: () {},
//                 )),
//               ]),

//               const SizedBox(height: 20),

//               // ── Weekly Bar Chart ──────────────────────────────
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: AppColors.surface,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: AppColors.border),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text('Weekly Arrivals',
//                                 style: AppTextStyles.headingSmall),
//                             Text('Last 7 days',
//                                 style: AppTextStyles.bodySmall.copyWith(
//                                     color: AppColors.textHint)),
//                           ],
//                         ),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 10, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: AppColors.successSurface,
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: const Row(children: [
//                             Icon(Icons.trending_up_rounded,
//                                 color: AppColors.success, size: 13),
//                             SizedBox(width: 4),
//                             Text('+12%', style: TextStyle(
//                                 color: AppColors.success, fontSize: 11,
//                                 fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
//                           ]),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 20),
//                     SizedBox(
//                       height: 120,
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: const [
//                           _Bar(day: 'Mon', pct: 0.65),
//                           _Bar(day: 'Tue', pct: 0.72),
//                           _Bar(day: 'Wed', pct: 0.80),
//                           _Bar(day: 'Thu', pct: 0.78),
//                           _Bar(day: 'Fri', pct: 0.85),
//                           _Bar(day: 'Sat', pct: 0.92),
//                           _Bar(day: 'Sun', pct: 0.70, isToday: true),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 14),
//                     const Divider(color: AppColors.divider),
//                     const SizedBox(height: 10),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text('Total this week',
//                             style: TextStyle(fontSize: 12,
//                                 color: AppColors.textHint, fontFamily: 'Poppins')),
//                         Text('8,200 kg',
//                             style: AppTextStyles.numberSmall.copyWith(
//                                 color: AppColors.primary)),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // ── Recent Purchases ──────────────────────────────
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text('Recent Purchases',
//                       style: AppTextStyles.headingMedium),
//                   TextButton(
//                     onPressed: () {},
//                     child: const Text('View All',
//                         style: TextStyle(color: AppColors.primary,
//                             fontSize: 13, fontFamily: 'Poppins')),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),

//               ...List.generate(3, (i) => _PurchaseTile(index: i)),

//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   String _todayLabel() {
//     final d = DateTime.now();
//     const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
//     const days   = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
//     return '${days[d.weekday % 7]}, ${d.day} ${months[d.month - 1]} ${d.year}';
//   }
// }

// // ── KPI Card ──────────────────────────────────────────────────
// class _KpiCard extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   final String change;
//   final bool positive;

//   const _KpiCard({
//     required this.icon, required this.label,
//     required this.value, required this.change, required this.positive,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final badgeColor = positive ? AppColors.successSurface : AppColors.warningSurface;
//     final textColor  = positive ? AppColors.success : AppColors.warning;

//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: AppColors.border),
//         boxShadow: [BoxShadow(
//           color: AppColors.shadowLight, blurRadius: 8, offset: const Offset(0, 2),
//         )],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(7),
//                 decoration: BoxDecoration(
//                   color: AppColors.primarySurface,
//                   borderRadius: BorderRadius.circular(9),
//                 ),
//                 child: Icon(icon, color: AppColors.primary, size: 18),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
//                 decoration: BoxDecoration(
//                   color: badgeColor,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(change, style: TextStyle(
//                     color: textColor, fontSize: 10,
//                     fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
//               ),
//             ],
//           ),
//           Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             Text(value, style: AppTextStyles.numberSmall),
//             Text(label, style: AppTextStyles.labelSmall),
//           ]),
//         ],
//       ),
//     );
//   }
// }

// // ── Quick Action ──────────────────────────────────────────────
// class _QuickAction extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final VoidCallback onTap;
//   const _QuickAction({required this.icon, required this.label,
//       required this.color, required this.onTap});

//   @override
//   Widget build(BuildContext context) => GestureDetector(
//     onTap: onTap,
//     child: Container(
//       padding: const EdgeInsets.symmetric(vertical: 14),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: AppColors.border),
//       ),
//       child: Column(mainAxisSize: MainAxisSize.min, children: [
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.12),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(icon, color: color, size: 22),
//         ),
//         const SizedBox(height: 8),
//         Text(label, style: const TextStyle(fontSize: 11,
//             fontWeight: FontWeight.w600, color: AppColors.textPrimary,
//             fontFamily: 'Poppins'),
//             textAlign: TextAlign.center),
//       ]),
//     ),
//   );
// }

// // ── Bar Chart ─────────────────────────────────────────────────
// class _Bar extends StatelessWidget {
//   final String day;
//   final double pct;
//   final bool isToday;
//   const _Bar({required this.day, required this.pct, this.isToday = false});

//   @override
//   Widget build(BuildContext context) => Column(children: [
//     if (isToday)
//       Container(
//         margin: const EdgeInsets.only(bottom: 4),
//         padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
//         decoration: BoxDecoration(
//           color: AppColors.primary,
//           borderRadius: BorderRadius.circular(6),
//         ),
//         child: const Text('Now', style: TextStyle(color: Colors.white,
//             fontSize: 8, fontFamily: 'Poppins')),
//       )
//     else const SizedBox(height: 18),
//     Flexible(
//       child: Container(
//         width: 34,
//         height: 120 * pct,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: isToday
//                 ? [AppColors.secondary, AppColors.primary]
//                 : [AppColors.primaryLight, AppColors.primary],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     ),
//     const SizedBox(height: 6),
//     Text(day, style: const TextStyle(fontSize: 10,
//         color: AppColors.textHint, fontFamily: 'Poppins')),
//   ]);
// }

// // ── Purchase Tile ─────────────────────────────────────────────
// class _PurchaseTile extends StatelessWidget {
//   final int index;
//   const _PurchaseTile({required this.index});

//   static const _data = [
//     ['Onion', 'Ram Singh',   '₹24,500', 'Just now'],
//     ['Tomato','Suresh Patil','₹18,200', '2h ago'],
//     ['Potato','Laxman Jadhav','₹31,000','5h ago'],
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final d = _data[index];
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: AppColors.border),
//       ),
//       child: Row(children: [
//         Container(
//           width: 44, height: 44,
//           decoration: BoxDecoration(
//             color: AppColors.primarySurface,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: const Icon(Icons.agriculture_rounded,
//               color: AppColors.primary, size: 22),
//         ),
//         const SizedBox(width: 12),
//         Expanded(child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(d[0], style: AppTextStyles.labelLarge),
//             const SizedBox(height: 2),
//             Text('Farmer: ${d[1]}', style: AppTextStyles.bodySmall),
//           ],
//         )),
//         Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
//           Text(d[2], style: AppTextStyles.labelLarge.copyWith(
//               color: AppColors.primaryDark)),
//           const SizedBox(height: 2),
//           Text(d[3], style: AppTextStyles.bodySmall),
//         ]),
//       ]),
//     );
//   }
// }


// ─────────────────────────────────────────────────────────────
//  DASHBOARD SCREEN — Real API Data
//  Replaces all hardcoded mock values with live API calls:
//    - GET /farmers          → total farmer count
//    - GET /purchases        → today's arrivals, sales total, recent list
//    - GET /purchases/summary → pending dues, weekly data
// ─────────────────────────────────────────────────────────────

import 'package:agr_market/purchase/purchase_screen.dart';
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
  final double todayArrivalKg;
  final double todaySalesTotal;
  final double totalPendingDues;
  final List<Map<String, dynamic>> recentPurchases;
  final List<double> weeklyArrivals; // 7 values Mon–Sun

  const _DashboardData({
    this.totalFarmers = 0,
    this.todayArrivalKg = 0,
    this.todaySalesTotal = 0,
    this.totalPendingDues = 0,
    this.recentPurchases = const [],
    this.weeklyArrivals = const [0, 0, 0, 0, 0, 0, 0],
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

  Future<void> _loadDashboard() async {
    setState(() { _loading = true; _hasError = false; });
    try {
      // Today's date range
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final todayStartStr = todayStart.toIso8601String();
      final todayEndStr = todayEnd.toIso8601String();

      // Week start (Monday)
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

      // ── Run all API calls concurrently ────────────────────
      final results = await Future.wait([
        // 0 — Farmer count
        DioClient.instance.dio.get(ApiRoutes.farmers,
            queryParameters: {'limit': 1, 'page': 1}),

        // 1 — Today's purchases (for arrivals + sales)
        DioClient.instance.dio.get(ApiRoutes.purchases, queryParameters: {
          'startDate': todayStartStr,
          'endDate':   todayEndStr,
          'limit':     100,
        }),

        // 2 — Recent 3 purchases (any date)
        DioClient.instance.dio.get(ApiRoutes.purchases,
            queryParameters: {'limit': 3, 'sortOrder': 'desc'}),

        // 3 — Purchase summary for pending dues
        DioClient.instance.dio.get(ApiRoutes.purchases),

        // 4 — Weekly purchases (last 7 days)
        DioClient.instance.dio.get(ApiRoutes.purchases, queryParameters: {
          'startDate': weekStart.toIso8601String(),
          'endDate':   todayEndStr,
          'limit':     500,
        }),
      ]);

      // ── Parse farmer count ────────────────────────────────
      int farmerCount = 0;
      final farmerRes = results[0].data;
      if (farmerRes is Map) {
        farmerCount = (farmerRes['total'] as num?)?.toInt() ??
            (farmerRes['pagination']?['total'] as num?)?.toInt() ?? 0;
      }

      // ── Parse today's purchases ───────────────────────────
      double todayKg = 0;
      double todaySales = 0;
      final todayRes = results[1].data;
      List todayList = _extractList(todayRes);
      for (final p in todayList) {
        // Sum billed qty from all lines (kg type)
        final lines = p['lines'] as List? ?? [];
        for (final l in lines) {
          if ((l['pricingType'] ?? '') == 'kg') {
            todayKg += (l['billedQty'] as num?)?.toDouble() ?? 0;
          }
        }
        todaySales += (p['finalPayable'] as num?)?.toDouble() ?? 0;
      }

      // ── Parse recent 3 purchases ──────────────────────────
      final recentRes = results[2].data;
      final recentList = _extractList(recentRes).take(3).toList();
      final recentPurchases = recentList.map((p) {
        final lines = p['lines'] as List? ?? [];
        final firstProduct = lines.isNotEmpty
            ? (lines[0]['productName'] ?? 'Product')
            : 'Purchase';
        final farmer = p['farmer'];
        final farmerName = farmer is Map
            ? farmer['name'] ?? 'Unknown'
            : 'Unknown';
        return {
          'product': firstProduct,
          'farmer': farmerName,
          'amount': (p['finalPayable'] as num?)?.toDouble() ?? 0,
          'date': p['purchaseDate'] ?? p['createdAt'] ?? '',
          'receiptNumber': p['receiptNumber'] ?? '',
        };
      }).toList();

      // ── Parse pending dues from summary ───────────────────
      double pendingDues = 0;
      final summaryRes = results[3].data;
      if (summaryRes is Map) {
        final d = summaryRes['data'];
        if (d is Map) {
          pendingDues = (d['totalDue'] as num?)?.toDouble() ?? 0;
        }
      }

      // ── Parse weekly arrivals ─────────────────────────────
      final weeklyRes = results[4].data;
      final weeklyList = _extractList(weeklyRes);

      // Group by day of week (Mon=0 … Sun=6)
      final dayTotals = List<double>.filled(7, 0);
      for (final p in weeklyList) {
        final dateStr = p['purchaseDate'] ?? p['createdAt'] ?? '';
        if (dateStr.isEmpty) continue;
        final date = DateTime.tryParse(dateStr.toString());
        if (date == null) continue;
        final dayIdx = date.weekday - 1; // Mon=0
        dayTotals[dayIdx] += (p['grossTotal'] as num?)?.toDouble() ?? 0;
      }

      // Normalise to 0–1 for bar heights
      final maxDay = dayTotals.reduce((a, b) => a > b ? a : b);
      final weeklyNorm = maxDay > 0
          ? dayTotals.map((v) => (v / maxDay).clamp(0.1, 1.0)).toList()
          : List<double>.filled(7, 0.1);

      setState(() {
        _data = _DashboardData(
          totalFarmers:     farmerCount,
          todayArrivalKg:   todayKg,
          todaySalesTotal:  todaySales,
          totalPendingDues: pendingDues,
          recentPurchases:  recentPurchases,
          weeklyArrivals:   weeklyNorm,
        );
        _loading = false;
      });
    } catch (e) {
      debugPrint('Dashboard load error: $e');
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
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Hello, ${userName.split(' ').first}! 👋',
                          style: AppTextStyles.headingLarge),
                      const SizedBox(height: 3),
                      Text(_todayLabel(), style: AppTextStyles.bodyMedium),
                    ]),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [BoxShadow(
                            color: AppColors.shadowLight,
                            blurRadius: 8, offset: const Offset(0, 2),
                          )],
                        ),
                        child: const Icon(Icons.notifications_none_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(auth.user?.initials ?? 'U',
                              style: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w700, fontSize: 14,
                                  fontFamily: 'Poppins')),
                        ),
                      ),
                    ]),
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
                    boxShadow: [BoxShadow(
                      color: AppColors.primary.withOpacity(0.28),
                      blurRadius: 20, offset: const Offset(0, 6),
                    )],
                  ),
                  child: Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Farming Made Simple,',
                            style: TextStyle(color: Colors.white70, fontSize: 12,
                                fontFamily: 'Poppins')),
                        const Text('Smarter & Sustainable',
                            style: TextStyle(color: Colors.white, fontSize: 17,
                                fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Market ERP v1.0',
                              style: TextStyle(color: Colors.white, fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins')),
                        ),
                      ],
                    )),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: Colors.white, size: 36),
                    ),
                  ]),
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
                        label: "Today's Arrival",
                        value: _formatKg(_data.todayArrivalKg),
                        change: _data.todayArrivalKg > 0 ? 'Live' : '—',
                        positive: true,
                      ),
                      _KpiCard(
                        icon: Icons.people_rounded,
                        label: 'Total Farmers',
                        value: _data.totalFarmers.toString(),
                        change: 'Registered',
                        positive: true,
                      ),
                      _KpiCard(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Pending Dues',
                        value: _formatAmount(_data.totalPendingDues),
                        change: _data.totalPendingDues > 0 ? 'Unpaid' : 'Clear',
                        positive: _data.totalPendingDues == 0,
                      ),
                      _KpiCard(
                        icon: Icons.trending_up_rounded,
                        label: "Today's Sales",
                        value: _formatAmount(_data.todaySalesTotal),
                        change: _data.todaySalesTotal > 0 ? 'Live' : '—',
                        positive: true,
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                // ── Quick Actions ────────────────────────────
                const Text('Quick Actions', style: AppTextStyles.headingMedium),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _QuickAction(
                    icon: Icons.add_circle_rounded,
                    label: 'New Purchase',
                    color: AppColors.primary,
                    onTap: () async {
                      final result = await Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const NewPurchaseScreen()));
                      if (result == true) _loadDashboard();
                    },
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickAction(
                    icon: Icons.person_add_rounded,
                    label: 'Add Farmer',
                    color: AppColors.secondary,
                    onTap: () async {
                      final result = await Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const FarmerRegistrationScreen()));
                      if (result == true) _loadDashboard();
                    },
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickAction(
                    icon: Icons.payments_rounded,
                    label: 'Payment',
                    color: AppColors.info,
                    onTap: () {
                      // TODO: navigate to payment screen (M-09)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment screen coming soon'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  )),
                ]),

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
                          Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Weekly Arrivals',
                                  style: AppTextStyles.headingSmall),
                              Text('This week',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.textHint)),
                            ]),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.successSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(children: [
                              Icon(Icons.trending_up_rounded,
                                  color: AppColors.success, size: 13),
                              SizedBox(width: 4),
                              Text('Live',
                                  style: TextStyle(
                                      color: AppColors.success, fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins')),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_loading)
                        Container(height: 120,
                            color: AppColors.surfaceVariant)
                      else
                        SizedBox(
                          height: 120,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _Bar(day: 'Mon', pct: _data.weeklyArrivals[0]),
                              _Bar(day: 'Tue', pct: _data.weeklyArrivals[1]),
                              _Bar(day: 'Wed', pct: _data.weeklyArrivals[2]),
                              _Bar(day: 'Thu', pct: _data.weeklyArrivals[3]),
                              _Bar(day: 'Fri', pct: _data.weeklyArrivals[4]),
                              _Bar(day: 'Sat', pct: _data.weeklyArrivals[5]),
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
                              style: TextStyle(fontSize: 12,
                                  color: AppColors.textHint,
                                  fontFamily: 'Poppins')),
                          Text(
                            _formatAmount(_data.todaySalesTotal),
                            style: AppTextStyles.numberSmall
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Recent Purchases ─────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Purchases',
                        style: AppTextStyles.headingMedium),
                    TextButton(
                      onPressed: () {
                        // Navigate to purchase list tab
                      },
                      child: const Text('View All',
                          style: TextStyle(color: AppColors.primary,
                              fontSize: 13, fontFamily: 'Poppins')),
                    ),
                  ]),
                const SizedBox(height: 8),

                if (_loading)
                  ...List.generate(3, (_) => _buildPurchaseShimmer())
                else if (_data.recentPurchases.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 40, color: AppColors.textHint),
                      const SizedBox(height: 8),
                      const Text('No purchases yet today',
                          style: TextStyle(color: AppColors.textSecondary,
                              fontFamily: 'Poppins', fontSize: 13)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const NewPurchaseScreen()));
                          if (result == true) _loadDashboard();
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New Purchase',
                            style: TextStyle(fontFamily: 'Inter')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ]),
                  )
                else
                  ..._data.recentPurchases.map((p) => _RecentPurchaseTile(
                    productName: p['product'] as String,
                    farmerName: p['farmer'] as String,
                    amount: _formatAmount(p['amount'] as double),
                    timeAgo: _timeAgo(p['date'] as String),
                  )),

                const SizedBox(height: 20),

                // ── Error state ──────────────────────────────
                if (_hasError)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Some data could not be loaded. Pull down to retry.',
                          style: TextStyle(color: AppColors.error,
                              fontSize: 12, fontFamily: 'Poppins'),
                        ),
                      ),
                      GestureDetector(
                        onTap: _loadDashboard,
                        child: const Text('Retry',
                            style: TextStyle(color: AppColors.error,
                                fontSize: 12, fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins')),
                      ),
                    ]),
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
      children: List.generate(4, (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2)),
        ),
      )),
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
    required this.icon, required this.label,
    required this.value, required this.change, required this.positive,
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
        boxShadow: [BoxShadow(
          color: AppColors.shadowLight, blurRadius: 8,
          offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(change,
                  style: TextStyle(
                      color: textColor, fontSize: 10,
                      fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
            ),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: AppTextStyles.numberSmall),
            Text(label, style: AppTextStyles.labelSmall),
          ]),
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
    required this.icon, required this.label,
    required this.color, required this.onTap,
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
      child: Column(mainAxisSize: MainAxisSize.min, children: [
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
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary, fontFamily: 'Poppins'),
            textAlign: TextAlign.center),
      ]),
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
  Widget build(BuildContext context) => Column(children: [
    if (isToday)
      Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('Now',
            style: TextStyle(color: Colors.white, fontSize: 8,
                fontFamily: 'Poppins')),
      )
    else
      const SizedBox(height: 18),
    Flexible(
      child: Container(
        width: 34,
        height: 120 * pct,
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
    ),
    const SizedBox(height: 6),
    Text(day,
        style: const TextStyle(fontSize: 10, color: AppColors.textHint,
            fontFamily: 'Poppins')),
  ]);
}

// ── Recent Purchase Tile ──────────────────────────────────────

class _RecentPurchaseTile extends StatelessWidget {
  final String productName;
  final String farmerName;
  final String amount;
  final String timeAgo;
  const _RecentPurchaseTile({
    required this.productName,
    required this.farmerName,
    required this.amount,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.agriculture_rounded,
              color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(productName, style: AppTextStyles.labelLarge),
            const SizedBox(height: 2),
            Text('Farmer: $farmerName', style: AppTextStyles.bodySmall),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(amount,
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.primaryDark)),
          const SizedBox(height: 2),
          Text(timeAgo, style: AppTextStyles.bodySmall),
        ]),
      ]),
    );
  }
}
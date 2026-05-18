
// import 'package:agr_market/buyer/buyer_list_screen.dart';
// import 'package:agr_market/features/auth/screens/profile_screen.dart';
// import 'package:agr_market/features/dashboard/screens/reports_screen.dart';
// import 'package:agr_market/features/farmers/screens/farmer_list_screen.dart';
// import 'package:agr_market/inventory/inventory_list_screen.dart';
// import 'package:agr_market/ledger/ledger_screen.dart';
// import 'package:agr_market/payment/payment_screen.dart';
// import 'package:agr_market/payment/payment_selection_screen.dart';
// import 'package:agr_market/product/product_list_screen.dart';
// import 'package:agr_market/purchase/purchase_screen.dart';
// import 'package:agr_market/sales/sale_create_screen.dart';
// import 'package:agr_market/services/auth_service.dart';
// import 'package:agr_market/services/sale_service.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../core/constants/colors.dart';
// import '../../../providers/auth_provider.dart';
// import '../../../providers/language_provider.dart';
// import '../../../services/dio_client.dart';
// import '../../../services/constant_service.dart';

// // ── Profit/Loss snapshot ──────────────────────────────────────

// class _ProfitLossData {
//   final double totalSales;
//   final double totalPurchases;
//   final double totalExpenses;
//   final double grossProfit;
//   final double netProfit;
//   final String profitMargin;

//   const _ProfitLossData({
//     this.totalSales = 0,
//     this.totalPurchases = 0,
//     this.totalExpenses = 0,
//     this.grossProfit = 0,
//     this.netProfit = 0,
//     this.profitMargin = '0%',
//   });
// }

// // ── Dashboard Data Model ──────────────────────────────────────

// class _DashboardData {
//   final int totalFarmers;
//   final int todayPurchaseCount;
//   final double thisMonthValue;
//   final int thisMonthCount;
//   final double totalPendingPayments;
//   final int pendingExpenseApprovals;
//   final List<Map<String, dynamic>> recentPurchases;
//   final List<double> weeklyArrivals;
//   final _ProfitLossData profitLoss;

//   // ── NEW stat card fields ──────────────────────────────────
//   final double totalRevenue;        // from /reports/dashboard or derived
//   final int totalWarehouses;        // from /warehouse

//   const _DashboardData({
//     this.totalFarmers = 0,
//     this.todayPurchaseCount = 0,
//     this.thisMonthValue = 0,
//     this.thisMonthCount = 0,
//     this.totalPendingPayments = 0,
//     this.pendingExpenseApprovals = 0,
//     this.recentPurchases = const [],
//     this.weeklyArrivals = const [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
//     this.profitLoss = const _ProfitLossData(),
//     this.totalRevenue = 0,
//     this.totalWarehouses = 0,
//   });
// }

// // ── Main Screen ───────────────────────────────────────────────

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   _DashboardData _data = const _DashboardData();
//   bool _loading = true;
//   bool _hasError = false;
//   bool _plLoading = true;

//   // Loading states for individual stat cards
//   bool _warehouseLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadDashboard();
//   }

//   bool _isToday(String dateStr) {
//     if (dateStr.isEmpty) return false;
//     final date = DateTime.tryParse(dateStr)?.toLocal();
//     if (date == null) return false;
//     final now = DateTime.now();
//     return date.year == now.year &&
//         date.month == now.month &&
//         date.day == now.day;
//   }

//   bool _isThisWeek(String dateStr, DateTime weekStart) {
//     if (dateStr.isEmpty) return false;
//     final date = DateTime.tryParse(dateStr)?.toLocal();
//     if (date == null) return false;
//     final now = DateTime.now();
//     final todayEnd = DateTime(now.year, now.month, now.day + 1);
//     return date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
//         date.isBefore(todayEnd);
//   }

//   // ── Warehouse count loader ─────────────────────────────────
//   Future<void> _loadWarehouseCount() async {
//     try {
//       setState(() => _warehouseLoading = true);
//       final res = await DioClient.instance.dio.get(
//         ApiRoutes.warehouses,
//         queryParameters: {'page': 1, 'limit': 1},
//       );

//       int count = 0;
//       final body = res.data;
//       if (body is Map) {
//         // Try common pagination shapes: { total }, { data, total }, { count }
//         count = (body['total'] as num?)?.toInt() ??
//             (body['count'] as num?)?.toInt() ??
//             (body['data'] is List ? (body['data'] as List).length : 0);
//       } else if (body is List) {
//         count = body.length;
//       }

//       setState(() {
//         _data = _DashboardData(
//           totalFarmers: _data.totalFarmers,
//           todayPurchaseCount: _data.todayPurchaseCount,
//           thisMonthValue: _data.thisMonthValue,
//           thisMonthCount: _data.thisMonthCount,
//           totalPendingPayments: _data.totalPendingPayments,
//           pendingExpenseApprovals: _data.pendingExpenseApprovals,
//           recentPurchases: _data.recentPurchases,
//           weeklyArrivals: _data.weeklyArrivals,
//           profitLoss: _data.profitLoss,
//           totalRevenue: _data.totalRevenue,
//           totalWarehouses: count,
//         );
//         _warehouseLoading = false;
//       });
//     } catch (e) {
//       debugPrint('⚠️ Warehouse count error: $e');
//       setState(() => _warehouseLoading = false);
//     }
//   }

//   // ── P&L loader ───────────────────────────────────────────
//   Future<void> _loadProfitLoss() async {
//     try {
//       setState(() => _plLoading = true);
//       final now = DateTime.now();
//       final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
//       final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

//       final result = await SaleService.instance.getProfitLossReport(
//         startDate: start,
//         endDate: end,
//       );

//       if (result.isSuccess && result.data != null) {
//         final pl = result.data!;
//         setState(() {
//           _data = _DashboardData(
//             totalFarmers: _data.totalFarmers,
//             todayPurchaseCount: _data.todayPurchaseCount,
//             thisMonthValue: _data.thisMonthValue,
//             thisMonthCount: _data.thisMonthCount,
//             totalPendingPayments: _data.totalPendingPayments,
//             pendingExpenseApprovals: _data.pendingExpenseApprovals,
//             recentPurchases: _data.recentPurchases,
//             weeklyArrivals: _data.weeklyArrivals,
//             profitLoss: _ProfitLossData(
//               totalSales: pl.totalSales,
//               totalPurchases: pl.totalPurchaseCost,
//               totalExpenses: pl.totalExpenses,
//               grossProfit: pl.grossProfit,
//               netProfit: pl.netProfit,
//               profitMargin: pl.profitMargin,
//             ),
//             // Total revenue = today's total sales from P&L report
//             totalRevenue: pl.totalSales,
//             totalWarehouses: _data.totalWarehouses,
//           );
//           _plLoading = false;
//         });
//       } else {
//         debugPrint('⚠️ Today P&L failed: ${result.message}');
//         setState(() => _plLoading = false);
//       }
//     } catch (e) {
//       debugPrint('❌ Today P&L exception: $e');
//       setState(() => _plLoading = false);
//     }
//   }

//   // ── Navigate to All Products ──────────────────────────────
//   void _openAllProducts() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const ProductListScreen(),
//       ),
//     );
//   }

//   // ── Main loader ───────────────────────────────────────────
//   Future<void> _loadDashboard() async {
//     setState(() {
//       _loading = true;
//       _hasError = false;
//       _plLoading = true;
//       _warehouseLoading = true;
//     });

//     try {
//       final dashRes =
//           await DioClient.instance.dio.get(ApiRoutes.dashboard);
//       final d = dashRes.data['data'] as Map<String, dynamic>;
//       final monthly = d['thisMonthPurchases'] as Map<String, dynamic>;

//       final totalFarmers = (d['totalActiveFarmers'] as num?)?.toInt() ?? 0;
//       final todayCount = (d['todayPurchaseCount'] as num?)?.toInt() ?? 0;
//       final monthValue = (monthly['value'] as num?)?.toDouble() ?? 0.0;
//       final monthCount = (monthly['count'] as num?)?.toInt() ?? 0;
//       final pendingPayments =
//           (d['totalPendingPayments'] as num?)?.toDouble() ?? 0.0;
//       final pendingExpenses =
//           (d['pendingExpenseApprovals'] as num?)?.toInt() ?? 0;

//       // Try to extract total revenue from dashboard response directly
//       final totalRevenue =
//           (d['totalRevenue'] as num?)?.toDouble() ??
//           (d['totalSales'] as num?)?.toDouble() ??
//           monthValue;

//       debugPrint('✅ Dashboard KPIs loaded');

//       List allPurchases = [];
//       try {
//         final now = DateTime.now();
//         final weekStart = DateTime(now.year, now.month, now.day)
//             .subtract(Duration(days: now.weekday - 1));
//         final startIso = weekStart.toIso8601String().split('T')[0];
//         final endIso = weekStart
//             .add(const Duration(days: 7))
//             .toIso8601String()
//             .split('T')[0];

//         final pRes = await DioClient.instance.dio.get(
//           ApiRoutes.purchases,
//           queryParameters: {
//             'page': 1,
//             'limit': 100,
//             'sortOrder': 'desc',
//             'startDate': startIso,
//             'endDate': endIso,
//           },
//         );

//         if (pRes.data is Map && pRes.data['data'] is List) {
//           allPurchases = pRes.data['data'] as List;
//         } else if (pRes.data is List) {
//           allPurchases = pRes.data as List;
//         }
//       } catch (e) {
//         debugPrint('⚠️ Weekly purchases error: $e');
//       }

//       final now = DateTime.now();
//       final weekStart = DateTime(now.year, now.month, now.day)
//           .subtract(Duration(days: now.weekday - 1));
//       final dayTotals = List<double>.filled(7, 0.0);
//       for (final p in allPurchases) {
//         final dateStr = p['purchaseDate']?.toString() ??
//             p['createdAt']?.toString() ?? '';
//         final date = DateTime.tryParse(dateStr)?.toLocal();
//         if (date == null) continue;
//         final todayEnd = DateTime(now.year, now.month, now.day + 1);
//         if (date.isBefore(weekStart) || !date.isBefore(todayEnd)) continue;
//         final idx = (date.weekday - 1).clamp(0, 6);
//         dayTotals[idx] += (p['finalPayable'] as num?)?.toDouble() ?? 0;
//       }
//       final maxDay = dayTotals.reduce((a, b) => a > b ? a : b);
//       final weeklyNorm = maxDay > 0
//           ? dayTotals.map((v) => (v / maxDay).clamp(0.1, 1.0)).toList()
//           : List<double>.filled(7, 0.1);

//       final recentList = allPurchases.take(3).map((p) {
//         final lines = p['lines'] as List? ?? [];
//         final product = lines.isNotEmpty
//             ? (lines[0]['productName']?.toString() ?? 'Product')
//             : 'Purchase';
//         final farmer = p['farmer'];
//         final farmerName =
//             farmer is Map ? farmer['name']?.toString() ?? 'Unknown' : 'Unknown';
//         return <String, dynamic>{
//           'product': product,
//           'farmer': farmerName,
//           'amount': (p['finalPayable'] as num?)?.toDouble() ?? 0.0,
//           'date': p['purchaseDate']?.toString() ??
//               p['createdAt']?.toString() ?? '',
//           'status': p['status']?.toString() ?? '',
//           'receiptNumber': p['receiptNumber']?.toString() ?? '',
//         };
//       }).toList();

//       setState(() {
//         _data = _DashboardData(
//           totalFarmers: totalFarmers,
//           todayPurchaseCount: todayCount,
//           thisMonthValue: monthValue,
//           thisMonthCount: monthCount,
//           totalPendingPayments: pendingPayments,
//           pendingExpenseApprovals: pendingExpenses,
//           recentPurchases: recentList,
//           weeklyArrivals: weeklyNorm,
//           totalRevenue: totalRevenue,
//         );
//         _loading = false;
//       });

//       // Fire secondary loaders in parallel
//       await Future.wait([
//         _loadProfitLoss(),
//         _loadWarehouseCount(),
//       ]);
//     } catch (e) {
//       debugPrint('❌ Dashboard failed: $e');
//       setState(() {
//         _loading = false;
//         _plLoading = false;
//         _warehouseLoading = false;
//         _hasError = true;
//       });
//     }
//   }

//   String _formatAmount(double v) {
//     if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
//     if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
//     if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
//     return '₹${v.toStringAsFixed(0)}';
//   }

//   String _timeAgo(String dateStr) {
//     if (dateStr.isEmpty) return '';
//     final date = DateTime.tryParse(dateStr);
//     if (date == null) return '';
//     final diff = DateTime.now().difference(date);
//     if (diff.inMinutes < 1) return 'Just now';
//     if (diff.inHours < 1) return '${diff.inMinutes}m ago';
//     if (diff.inDays < 1) return '${diff.inHours}h ago';
//     return '${diff.inDays}d ago';
//   }

//   void _addBuyer() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const BuyerListScreen(),
//       ),
//     );
//   }

//   void _showLanguagePicker(BuildContext context, LanguageProvider lang) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (ctx) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: LanguageProvider.supportedLanguages
//               .map((l) => ListTile(
//                     leading:
//                         Text(l.flag, style: const TextStyle(fontSize: 28)),
//                     title: Text(l.nativeName,
//                         style: const TextStyle(
//                             fontFamily: 'Poppins',
//                             fontWeight: FontWeight.w500)),
//                     subtitle: Text(l.name,
//                         style: const TextStyle(
//                             fontFamily: 'Poppins', fontSize: 12)),
//                     trailing: lang.currentLanguage.code == l.code
//                         ? const Icon(Icons.check_circle,
//                             color: AppColors.primary)
//                         : null,
//                     onTap: () {
//                       lang.setLanguage(l.code);
//                       Navigator.pop(ctx);
//                     },
//                   ))
//               .toList(),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthProvider>();
//     final lang = Provider.of<LanguageProvider>(context);

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(
//         child: RefreshIndicator(
//           onRefresh: _loadDashboard,
//           color: AppColors.primary,
//           child: SingleChildScrollView(
//             physics: const AlwaysScrollableScrollPhysics(),
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // ── Header ──────────────────────────────────
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Hello !', style: AppTextStyles.headingLarge),
//                         const SizedBox(height: 3),
//                         Text(_todayLabel(), style: AppTextStyles.bodyMedium),
//                       ],
//                     ),
//                     Row(
//                       children: [
//                         GestureDetector(
//                           onTap: () {
//                             final newLang = lang.currentLanguage.code == 'en'
//                                 ? 'mr'
//                                 : 'en';
//                             lang.setLanguage(newLang);
//                           },
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 12, vertical: 8),
//                             decoration: BoxDecoration(
//                               color: AppColors.surface,
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(color: AppColors.border),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: AppColors.shadowLight,
//                                   blurRadius: 8,
//                                   offset: const Offset(0, 2),
//                                 ),
//                               ],
//                             ),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Icon(Icons.language_rounded,
//                                     size: 16, color: AppColors.primary),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   lang.currentLanguage.code == 'en'
//                                       ? 'EN'
//                                       : 'मर',
//                                   style: TextStyle(
//                                     fontSize: 13,
//                                     fontWeight: FontWeight.w600,
//                                     fontFamily: 'Poppins',
//                                     color: AppColors.primary,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         PopupMenuButton<String>(
//                           offset: const Offset(0, 45),
//                           icon: Container(
//                             width: 40,
//                             height: 40,
//                             decoration: BoxDecoration(
//                               gradient: AppColors.heroGradient,
//                               shape: BoxShape.circle,
//                             ),
//                             child: Center(
//                               child: Text(
//                                 auth.user?.initials ?? 'U',
//                                 style: const TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w700,
//                                     fontSize: 14,
//                                     fontFamily: 'Poppins'),
//                               ),
//                             ),
//                           ),
//                           onSelected: (value) async {
//                             if (value == 'profile') {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       ProfileScreen(user: auth.user!),
//                                 ),
//                               );
//                             } else if (value == 'logout') {
//                               final confirm = await showDialog<bool>(
//                                 context: context,
//                                 builder: (ctx) => AlertDialog(
//                                   title: const Text('Logout'),
//                                   content: const Text(
//                                       'Are you sure you want to logout?'),
//                                   actions: [
//                                     TextButton(
//                                       onPressed: () =>
//                                           Navigator.pop(ctx, false),
//                                       child: const Text('Cancel'),
//                                     ),
//                                     TextButton(
//                                       onPressed: () =>
//                                           Navigator.pop(ctx, true),
//                                       style: TextButton.styleFrom(
//                                           foregroundColor: AppColors.error),
//                                       child: const Text('Logout'),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                               if (confirm == true) {
//                                 await AuthService.instance.logout();
//                                 if (context.mounted) {
//                                   Navigator.of(context)
//                                       .pushNamedAndRemoveUntil(
//                                     AppConstants.routeLogin,
//                                     (route) => false,
//                                   );
//                                 }
//                               }
//                             }
//                           },
//                           itemBuilder: (context) => [
//                             const PopupMenuItem(
//                               value: 'profile',
//                               child: Row(children: [
//                                 Icon(Icons.person_outline, size: 20),
//                                 SizedBox(width: 12),
//                                 Text('Profile'),
//                               ]),
//                             ),
//                             const PopupMenuItem(
//                               value: 'logout',
//                               child: Row(children: [
//                                 Icon(Icons.logout,
//                                     size: 20, color: AppColors.error),
//                                 SizedBox(width: 12),
//                                 Text('Logout',
//                                     style:
//                                         TextStyle(color: AppColors.error)),
//                               ]),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(width: 8),
//                       ],
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),

//                 // ── Hero Banner ──────────────────────────────
//                 _buildHeroBanner(),
//                 const SizedBox(height: 20),

//                 // // ── KPI Grid ─────────────────────────────────
//                 // Text(lang.t('todays_overview'),
//                 //     style: AppTextStyles.headingMedium),
//                 // const SizedBox(height: 12),
//                 // if (_loading)
//                 //   _buildKpiShimmer()
//                 // else
//                 //   GridView.count(
//                 //     crossAxisCount: 2,
//                 //     shrinkWrap: true,
//                 //     physics: const NeverScrollableScrollPhysics(),
//                 //     mainAxisSpacing: 12,
//                 //     crossAxisSpacing: 12,
//                 //     childAspectRatio: 1.45,
//                 //     children: [
//                 //       _KpiCard(
//                 //         icon: Icons.local_shipping_rounded,
//                 //         label: lang.t('todays_purchases'),
//                 //         value: _data.todayPurchaseCount.toString(),
//                 //         change: _data.todayPurchaseCount > 0
//                 //             ? 'Today'
//                 //             : 'None yet',
//                 //         positive: true,
//                 //       ),
//                 //       _KpiCard(
//                 //         icon: Icons.people_rounded,
//                 //         label: lang.t('active_farmers'),
//                 //         value: _data.totalFarmers.toString(),
//                 //         change: 'Registered',
//                 //         positive: true,
//                 //       ),
//                 //       _KpiCard(
//                 //         icon: Icons.account_balance_wallet_rounded,
//                 //         label: lang.t('pending_dues'),
//                 //         value: _formatAmount(_data.totalPendingPayments),
//                 //         change: _data.totalPendingPayments > 0
//                 //             ? 'Unpaid'
//                 //             : 'All clear',
//                 //         positive: _data.totalPendingPayments == 0,
//                 //       ),
//                 //       _KpiCard(
//                 //         icon: Icons.trending_up_rounded,
//                 //         label: lang.t('this_month'),
//                 //         value: _formatAmount(_data.thisMonthValue),
//                 //         change: '${_data.thisMonthCount} purchases',
//                 //         positive: true,
//                 //       ),
//                 //     ],
//                 //   ),
//                 // const SizedBox(height: 20),

//                 // ── Stat Summary Cards (replaces Quick Actions) ──
//                 _buildStatCardsSection(lang),
//                 const SizedBox(height: 20),

//                 // ── Quick Actions header + All Products button ─
//             // ── Quick Actions header + pill buttons ─
// Row(
//   children: [
//     Text(lang.t('quick_actions'),
//         style: AppTextStyles.headingMedium),
//     const Spacer(),
//     // All Payments pill
//     GestureDetector(
//       onTap: () => Navigator.push(
//   context,
// MaterialPageRoute(builder: (_) => const PaymentSelectionScreen()),

//        ),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
//         decoration: BoxDecoration(
//           color: AppColors.primaryLight,          
//           borderRadius: BorderRadius.circular(30),
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.shadowMedium,      
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: const Row(
//           mainAxisSize: MainAxisSize.min,
          
//           children: [
//             Icon(Icons.payments_rounded, color: Colors.white, size: 15),
//             SizedBox(width: 5),
//             Text(
//               'Payments',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 fontFamily: 'Poppins',
                
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//     const SizedBox(width: 8),
//     // All Products pill
//     GestureDetector(
//       onTap: _openAllProducts,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
//        decoration: BoxDecoration(
//           color: AppColors.primaryButton,         // 37623D — theme primary button
//           borderRadius: BorderRadius.circular(30),
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.shadowMedium,
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: const Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.production_quantity_limits_rounded,
//                 color: Colors.white, size: 15),
//             SizedBox(width: 5),
//             Text(
//               'Products',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 fontFamily: 'Poppins',
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   ],
// ),
//                 const SizedBox(height: 12),

//                 // ── Quick Actions Row 1 ──
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _QuickAction(
//                         icon: Icons.add_circle_rounded,
//                         label: lang.t('new_purchase'),
//                         color: AppColors.primary,
//                         onTap: () async {
//                           final result = await Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (_) => const NewPurchaseScreen()),
//                           );
//                           if (result == true) _loadDashboard();
//                         },
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: _QuickAction(
//                         icon: Icons.people_rounded,
//                         label: lang.t('buyers'),
//                         color: const Color(0xFFFF9800),
//                         onTap: _addBuyer,
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: _QuickAction(
//                         icon: Icons.storefront_rounded,
//                         label: lang.t('new_sale'),
//                         color: const Color(0xFF00BCD4),
//                         onTap: () async {
//                           final created = await Navigator.push<bool>(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (_) => const SaleCreateScreen()),
//                           );
//                           if (created == true) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text('Sale created successfully!'),
//                                 backgroundColor: AppColors.success,
//                                 behavior: SnackBarBehavior.floating,
//                               ),
//                             );
//                           }
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),

//                 // ── Quick Actions Row 2 ──
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _QuickAction(
//                         icon: Icons.inventory_2_rounded,
//                         label: lang.t('inventory'),
//                         color: AppColors.info,
//                         onTap: () => Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (_) => const InventoryListScreen()),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: _QuickAction(
//                         icon: Icons.receipt_long_rounded,
//                         label: lang.t('ledger'),
//                         color: AppColors.info,
//                         onTap: () => Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (_) => const LedgerScreen()),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: _QuickAction(
//                         icon: Icons.assessment_rounded,
//                         label: lang.t('reports'),
//                         color: const Color(0xFF9C27B0),
//                         onTap: () => Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (_) => const ReportsScreen()),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),

            
//                 const SizedBox(height: 20),

//                 // ── Error state ──────────────────────────────
//                 if (_hasError)
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: AppColors.errorSurface,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                           color: AppColors.error.withOpacity(0.3)),
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(Icons.error_outline,
//                             color: AppColors.error, size: 18),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Text(
//                             lang.t('data_load_error'),
//                             style: const TextStyle(
//                                 color: AppColors.error,
//                                 fontSize: 12,
//                                 fontFamily: 'Poppins'),
//                           ),
//                         ),
//                         GestureDetector(
//                           onTap: _loadDashboard,
//                           child: Text(lang.t('retry'),
//                               style: const TextStyle(
//                                   color: AppColors.error,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w600,
//                                   fontFamily: 'Poppins')),
//                         ),
//                       ],
//                     ),
//                   ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────────────────────
//   //  STAT SUMMARY CARDS (2×2 grid with API data)
//   //  Replaces the old quick-action buttons
//   // ─────────────────────────────────────────────────────────────
//   Widget _buildStatCardsSection(LanguageProvider lang) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Business Overview', style: AppTextStyles.headingMedium),
//         const SizedBox(height: 12),
//         GridView.count(
//           crossAxisCount: 2,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           mainAxisSpacing: 12,
//           crossAxisSpacing: 12,
//           childAspectRatio: 1.6,
//           children: [
//             // ── Total Farmers ────────────────────────────────
//             _StatCard(
//               icon: Icons.agriculture_rounded,
//               label: 'Total Farmers',
//               value: _loading ? null : _data.totalFarmers.toString(),
//               accentColor: AppColors.primary,
//               bgColor: AppColors.primarySurface,
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const FarmerListScreen()),
//               ),
//             ),

//             // ── Total Pending Payments ───────────────────────
//             _StatCard(
//               icon: Icons.payments_rounded,
//               label: 'Total Payment',
//               value: _loading
//                   ? null
//                   : _formatAmount(_data.totalPendingPayments),
//               subtitle: _data.totalPendingPayments > 0 ? 'Pending' : 'Cleared',
//               accentColor: _data.totalPendingPayments > 0
//                   ? AppColors.warning
//                   : AppColors.success,
//               bgColor: _data.totalPendingPayments > 0
//                   ? AppColors.warningSurface
//                   : AppColors.successSurface,
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const LedgerScreen()),
//               ),
//             ),

//             // ── Total Warehouses ─────────────────────────────
//             _StatCard(
//               icon: Icons.warehouse_rounded,
//               label: 'Total Warehouses',
//               value: _warehouseLoading ? null : _data.totalWarehouses.toString(),
//               accentColor: AppColors.info,
//               bgColor: AppColors.infoSurface,
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (_) => const InventoryListScreen()),
//               ),
//             ),

//             // ── Total Revenue ────────────────────────────────
//             _StatCard(
//               icon: Icons.show_chart_rounded,
//               label: 'Total Revenue',
//               value: _plLoading
//                   ? null
//                   : _formatAmount(_data.profitLoss.totalSales > 0
//                       ? _data.profitLoss.totalSales
//                       : _data.totalRevenue),
//               subtitle: 'Today\'s sales',
//               accentColor: const Color(0xFF9C27B0),
//               bgColor: const Color(0xFFF3E5F5),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const ReportsScreen()),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   // ─────────────────────────────────────────────────────────────
//   //  HERO BANNER
//   // ─────────────────────────────────────────────────────────────
//   Widget _buildHeroBanner() {
//     final pl = _data.profitLoss;
//     final isProfit = pl.netProfit >= 0;
//     final netColor =
//         isProfit ? const Color(0xFF69F0AE) : const Color(0xFFFF6B6B);
//     final netLabel = isProfit ? 'Net Profit' : 'Net Loss';

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
//       decoration: BoxDecoration(
//         gradient: AppColors.heroGradient,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primary.withOpacity(0.28),
//             blurRadius: 18,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 9, vertical: 3),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.18),
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                             color: Colors.white.withOpacity(0.28), width: 1),
//                       ),
//                       child: const Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(Icons.bar_chart_rounded,
//                               color: Colors.white70, size: 12),
//                           SizedBox(width: 5),
//                           Text(
//                             'Market ERP',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 10,
//                               fontWeight: FontWeight.w600,
//                               fontFamily: 'Poppins',
//                               letterSpacing: 0.3,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     const Text(
//                       "Today's P&L Overview",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w700,
//                         fontFamily: 'Poppins',
//                       ),
//                     ),
//                     Text(
//                       _todayLabel(),
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.6),
//                         fontSize: 10,
//                         fontFamily: 'Poppins',
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Container(
//                 width: 52,
//                 height: 52,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Colors.white.withOpacity(0.15),
//                   border: Border.all(
//                       color: Colors.white.withOpacity(0.4), width: 2),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.12),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: ClipOval(
//                   child: Image.asset(
//                     'assets/images/logo3.png',
//                     fit: BoxFit.cover,
//                     errorBuilder: (_, __, ___) => const Icon(
//                         Icons.agriculture_rounded,
//                         color: Colors.white70,
//                         size: 26),
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 12),
//           Container(height: 1, color: Colors.white.withOpacity(0.15)),
//           const SizedBox(height: 12),

//           if (_plLoading)
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               child: Center(
//                 child: SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     color: Colors.white.withOpacity(0.8),
//                     strokeWidth: 2,
//                   ),
//                 ),
//               ),
//             )
//           else
//             Row(
//               children: [
//                 Expanded(
//                   child: _HeroStat(
//              label: 'Total Sales',
//              value: _formatAmount(pl.totalSales),
//             valueColor: Colors.white,
//         ),
//                 ),
//                 Container(
//                     width: 1,
//                     height: 44,
//                     color: Colors.white.withOpacity(0.2)),
//                 Expanded(
//                   child: _HeroStat(
//                     label: netLabel,
//                    value: _formatAmount(pl.netProfit.abs()),
//                    valueColor: netColor,
//                ),
//                 ),
//                 Container(
//                     width: 1,
//                     height: 44,
//                     color: Colors.white.withOpacity(0.2)),
//                 Expanded(
//                   child:_HeroStat(
//                      label: 'Margin',
//                    value: pl.profitMargin,
//                  valueColor: isProfit
//                   ? const Color(0xFFA5D6A7)
//                  : const Color(0xFFFF6B6B),
// ),
//                 ),
//               ],
//             ),

//           if (!_plLoading) ...[
//             const SizedBox(height: 10),
//             Container(height: 1, color: Colors.white.withOpacity(0.12)),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 const Icon(Icons.shopping_cart_outlined,
//                     color: Colors.white54, size: 12),
//                 const SizedBox(width: 4),
//                 Text(
//                   'Purchases: ${_formatAmount(pl.totalPurchases)}',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.7),
//                     fontSize: 11,
//                     fontFamily: 'Poppins',
//                   ),
//                 ),
//                 const SizedBox(width: 14),
//                 const Icon(Icons.receipt_outlined,
//                     color: Colors.white54, size: 12),
//                 const SizedBox(width: 4),
//                 Text(
//                   'Expenses: ${_formatAmount(pl.totalExpenses)}',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.7),
//                     fontSize: 11,
//                     fontFamily: 'Poppins',
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildKpiShimmer() {
//     return GridView.count(
//       crossAxisCount: 2,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       mainAxisSpacing: 12,
//       crossAxisSpacing: 12,
//       childAspectRatio: 1.45,
//       children: List.generate(
//         4,
//         (_) => Container(
//           decoration: BoxDecoration(
//             color: AppColors.surfaceVariant,
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: AppColors.border),
//           ),
//           child: const Center(
//             child: SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(
//                   color: AppColors.primary, strokeWidth: 2),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   String _todayLabel() {
//     final d = DateTime.now();
//     const months = [
//       'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
//     ];
//     const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
//     return '${days[d.weekday % 7]}, ${d.day} ${months[d.month - 1]} ${d.year}';
//   }
// }

// // ── Stat Card (new) ───────────────────────────────────────────
// /// Tappable card with icon, label, value and optional subtitle.
// /// Shows a spinner when [value] is null (loading state).
// class _StatCard extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String? value;
//   final String? subtitle;
//   final Color accentColor;
//   final Color bgColor;
//   final VoidCallback onTap;

//   const _StatCard({
//     required this.icon,
//     required this.label,
//     required this.value,
//     required this.accentColor,
//     required this.bgColor,
//     required this.onTap,
//     this.subtitle,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: AppColors.surface,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: AppColors.border),
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.shadowLight,
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             // ── Icon badge ──────────────────────────────
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: bgColor,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Icon(icon, color: accentColor, size: 20),
//             ),
//             const SizedBox(width: 10),
//             // ── Value + label ───────────────────────────
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (value == null)
//                     SizedBox(
//                       width: 18,
//                       height: 18,
//                       child: CircularProgressIndicator(
//                         color: accentColor,
//                         strokeWidth: 2,
//                       ),
//                     )
//                   else
//                     Text(
//                       value!,
//                       style: const TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w700,
//                         fontFamily: 'Poppins',
//                         color: AppColors.textPrimary,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   const SizedBox(height: 2),
//                   Text(
//                     label,
//                     style: const TextStyle(
//                       fontSize: 11,
//                       color: AppColors.textSecondary,
//                       fontFamily: 'Poppins',
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   if (subtitle != null) ...[
//                     const SizedBox(height: 3),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 6, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: bgColor,
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Text(
//                         subtitle!,
//                         style: TextStyle(
//                           color: accentColor,
//                           fontSize: 9,
//                           fontWeight: FontWeight.w600,
//                           fontFamily: 'Poppins',
//                         ),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Hero Stat Cell ────────────────────────────────────────────
// class _HeroStat extends StatelessWidget {
//   final String label;
//   final String value;
//   final Color valueColor;
 
//   const _HeroStat({
//     required this.label,
//     required this.value,
//     required this.valueColor,
//   });
 
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Text(
//           value,
//           style: TextStyle(
//             color: valueColor,
//             fontSize: 14,
//             fontWeight: FontWeight.w700,
//             fontFamily: 'Poppins',
//           ),
//           textAlign: TextAlign.center,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//         const SizedBox(height: 3),
//         Text(
//           label,
//           style: TextStyle(
//             color: Colors.white.withOpacity(0.58),
//             fontSize: 9,
//             fontFamily: 'Poppins',
//           ),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
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
//     required this.icon,
//     required this.label,
//     required this.value,
//     required this.change,
//     required this.positive,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final badgeColor =
//         positive ? AppColors.successSurface : AppColors.warningSurface;
//     final textColor = positive ? AppColors.success : AppColors.warning;

//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: AppColors.border),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.shadowLight,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           )
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
//                 decoration: BoxDecoration(
//                   color: badgeColor,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(change,
//                     style: TextStyle(
//                         color: textColor,
//                         fontSize: 10,
//                         fontWeight: FontWeight.w600,
//                         fontFamily: 'Poppins')),
//               ),
//             ],
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(value, style: AppTextStyles.numberSmall),
//               Text(label, style: AppTextStyles.labelSmall),
//             ],
//           ),
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

//   const _QuickAction({
//     required this.icon,
//     required this.label,
//     required this.color,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) => GestureDetector(
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 14),
//           decoration: BoxDecoration(
//             color: AppColors.surface,
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: AppColors.border),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.12),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(icon, color: color, size: 22),
//               ),
//               const SizedBox(height: 8),
//               Text(label,
//                   style: const TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.textPrimary,
//                       fontFamily: 'Poppins'),
//                   textAlign: TextAlign.center),
//             ],
//           ),
//         ),
//       );
// }

// // ── Bar Chart ─────────────────────────────────────────────────

// class _Bar extends StatelessWidget {
//   final String day;
//   final double pct;
//   final bool isToday;

//   const _Bar({required this.day, required this.pct, this.isToday = false});

//   @override
//   Widget build(BuildContext context) => SizedBox(
//         width: 34,
//         height: 120,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.end,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             if (isToday)
//               Container(
//                 margin: const EdgeInsets.only(bottom: 4),
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: AppColors.primary,
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 child: const Text('Now',
//                     style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 8,
//                         fontFamily: 'Poppins')),
//               ),
//             const Spacer(),
//             Container(
//               width: 34,
//               height: 100 * pct,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: isToday
//                       ? [AppColors.secondary, AppColors.primary]
//                       : [AppColors.primaryLight, AppColors.primary],
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                 ),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             const SizedBox(height: 6),
//             Text(day,
//                 style: const TextStyle(
//                     fontSize: 10,
//                     color: AppColors.textHint,
//                     fontFamily: 'Poppins')),
//           ],
//         ),
//       );
// }

import 'package:agr_market/buyer/buyer_list_screen.dart';
import 'package:agr_market/features/auth/screens/profile_screen.dart';
import 'package:agr_market/features/dashboard/screens/reports_screen.dart';
import 'package:agr_market/features/farmers/screens/farmer_list_screen.dart';
import 'package:agr_market/inventory/inventory_list_screen.dart';
import 'package:agr_market/ledger/ledger_screen.dart';
import 'package:agr_market/payment/get_payment_screen.dart';
import 'package:agr_market/product/product_list_screen.dart';
import 'package:agr_market/purchase/purchase_screen.dart';
import 'package:agr_market/sales/sale_create_screen.dart';
import 'package:agr_market/services/auth_service.dart';
import 'package:agr_market/services/sale_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../services/dio_client.dart';
import '../../../services/constant_service.dart';

// ── Profit/Loss snapshot ──────────────────────────────────────

class _ProfitLossData {
  final double totalSales;
  final double totalPurchases;
  final double totalExpenses;
  final double grossProfit;
  final double netProfit;
  final String profitMargin;

  const _ProfitLossData({
    this.totalSales = 0,
    this.totalPurchases = 0,
    this.totalExpenses = 0,
    this.grossProfit = 0,
    this.netProfit = 0,
    this.profitMargin = '0%',
  });
}

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
  final _ProfitLossData profitLoss;
  final double totalRevenue;
  final int totalWarehouses;

  const _DashboardData({
    this.totalFarmers = 0,
    this.todayPurchaseCount = 0,
    this.thisMonthValue = 0,
    this.thisMonthCount = 0,
    this.totalPendingPayments = 0,
    this.pendingExpenseApprovals = 0,
    this.recentPurchases = const [],
    this.weeklyArrivals = const [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
    this.profitLoss = const _ProfitLossData(),
    this.totalRevenue = 0,
    this.totalWarehouses = 0,
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
  bool _plLoading = true;
  bool _warehouseLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ── Warehouse count loader ─────────────────────────────────
  Future<void> _loadWarehouseCount() async {
    try {
      setState(() => _warehouseLoading = true);
      final res = await DioClient.instance.dio.get(
        ApiRoutes.warehouses,
        queryParameters: {'page': 1, 'limit': 1},
      );

      int count = 0;
      final body = res.data;
      if (body is Map) {
        count = (body['total'] as num?)?.toInt() ??
            (body['count'] as num?)?.toInt() ??
            (body['data'] is List ? (body['data'] as List).length : 0);
      } else if (body is List) {
        count = body.length;
      }

      setState(() {
        _data = _DashboardData(
          totalFarmers: _data.totalFarmers,
          todayPurchaseCount: _data.todayPurchaseCount,
          thisMonthValue: _data.thisMonthValue,
          thisMonthCount: _data.thisMonthCount,
          totalPendingPayments: _data.totalPendingPayments,
          pendingExpenseApprovals: _data.pendingExpenseApprovals,
          recentPurchases: _data.recentPurchases,
          weeklyArrivals: _data.weeklyArrivals,
          profitLoss: _data.profitLoss,
          totalRevenue: _data.totalRevenue,
          totalWarehouses: count,
        );
        _warehouseLoading = false;
      });
    } catch (e) {
      debugPrint('⚠️ Warehouse count error: $e');
      setState(() => _warehouseLoading = false);
    }
  }

  // ── P&L loader ───────────────────────────────────────────
  Future<void> _loadProfitLoss() async {
    try {
      setState(() => _plLoading = true);
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final result = await SaleService.instance.getProfitLossReport(
        startDate: start,
        endDate: end,
      );

      if (result.isSuccess && result.data != null) {
        final pl = result.data!;
        setState(() {
          _data = _DashboardData(
            totalFarmers: _data.totalFarmers,
            todayPurchaseCount: _data.todayPurchaseCount,
            thisMonthValue: _data.thisMonthValue,
            thisMonthCount: _data.thisMonthCount,
            totalPendingPayments: _data.totalPendingPayments,
            pendingExpenseApprovals: _data.pendingExpenseApprovals,
            recentPurchases: _data.recentPurchases,
            weeklyArrivals: _data.weeklyArrivals,
            profitLoss: _ProfitLossData(
              totalSales: pl.totalSales,
              totalPurchases: pl.totalPurchaseCost,
              totalExpenses: pl.totalExpenses,
              grossProfit: pl.grossProfit,
              netProfit: pl.netProfit,
              profitMargin: pl.profitMargin,
            ),
            totalRevenue: pl.totalSales,
            totalWarehouses: _data.totalWarehouses,
          );
          _plLoading = false;
        });
      } else {
        debugPrint('⚠️ Today P&L failed: ${result.message}');
        setState(() => _plLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Today P&L exception: $e');
      setState(() => _plLoading = false);
    }
  }

  void _openAllProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductListScreen()),
    );
  }

  // ── Main loader ───────────────────────────────────────────
  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _hasError = false;
      _plLoading = true;
      _warehouseLoading = true;
    });

    try {
      final dashRes = await DioClient.instance.dio.get(ApiRoutes.dashboard);
      final d = dashRes.data['data'] as Map<String, dynamic>;
      final monthly = d['thisMonthPurchases'] as Map<String, dynamic>;

      final totalFarmers = (d['totalActiveFarmers'] as num?)?.toInt() ?? 0;
      final todayCount = (d['todayPurchaseCount'] as num?)?.toInt() ?? 0;
      final monthValue = (monthly['value'] as num?)?.toDouble() ?? 0.0;
      final monthCount = (monthly['count'] as num?)?.toInt() ?? 0;
      final pendingPayments =
          (d['totalPendingPayments'] as num?)?.toDouble() ?? 0.0;
      final pendingExpenses =
          (d['pendingExpenseApprovals'] as num?)?.toInt() ?? 0;
      final totalRevenue = (d['totalRevenue'] as num?)?.toDouble() ??
          (d['totalSales'] as num?)?.toDouble() ??
          monthValue;

      List allPurchases = [];
      try {
        final now = DateTime.now();
        final weekStart = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final startIso = weekStart.toIso8601String().split('T')[0];
        final endIso = weekStart
            .add(const Duration(days: 7))
            .toIso8601String()
            .split('T')[0];

        final pRes = await DioClient.instance.dio.get(
          ApiRoutes.purchases,
          queryParameters: {
            'page': 1,
            'limit': 100,
            'sortOrder': 'desc',
            'startDate': startIso,
            'endDate': endIso,
          },
        );

        if (pRes.data is Map && pRes.data['data'] is List) {
          allPurchases = pRes.data['data'] as List;
        } else if (pRes.data is List) {
          allPurchases = pRes.data as List;
        }
      } catch (e) {
        debugPrint('⚠️ Weekly purchases error: $e');
      }

      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final dayTotals = List<double>.filled(7, 0.0);
      for (final p in allPurchases) {
        final dateStr =
            p['purchaseDate']?.toString() ?? p['createdAt']?.toString() ?? '';
        final date = DateTime.tryParse(dateStr)?.toLocal();
        if (date == null) continue;
        final todayEnd = DateTime(now.year, now.month, now.day + 1);
        if (date.isBefore(weekStart) || !date.isBefore(todayEnd)) continue;
        final idx = (date.weekday - 1).clamp(0, 6);
        dayTotals[idx] += (p['finalPayable'] as num?)?.toDouble() ?? 0;
      }
      final maxDay = dayTotals.reduce((a, b) => a > b ? a : b);
      final weeklyNorm = maxDay > 0
          ? dayTotals.map((v) => (v / maxDay).clamp(0.1, 1.0)).toList()
          : List<double>.filled(7, 0.1);

      final recentList = allPurchases.take(3).map((p) {
        final lines = p['lines'] as List? ?? [];
        final product = lines.isNotEmpty
            ? (lines[0]['productName']?.toString() ?? 'Product')
            : 'Purchase';
        final farmer = p['farmer'];
        final farmerName =
            farmer is Map ? farmer['name']?.toString() ?? 'Unknown' : 'Unknown';
        return <String, dynamic>{
          'product': product,
          'farmer': farmerName,
          'amount': (p['finalPayable'] as num?)?.toDouble() ?? 0.0,
          'date': p['purchaseDate']?.toString() ??
              p['createdAt']?.toString() ??
              '',
          'status': p['status']?.toString() ?? '',
          'receiptNumber': p['receiptNumber']?.toString() ?? '',
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
          totalRevenue: totalRevenue,
        );
        _loading = false;
      });

      await Future.wait([
        _loadProfitLoss(),
        _loadWarehouseCount(),
      ]);
    } catch (e) {
      debugPrint('❌ Dashboard failed: $e');
      setState(() {
        _loading = false;
        _plLoading = false;
        _warehouseLoading = false;
        _hasError = true;
      });
    }
  }

  String _formatAmount(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
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

  void _addBuyer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BuyerListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // ✅ listen: true so widget rebuilds when language changes
    final lang = Provider.of<LanguageProvider>(context, listen: true);

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
                _buildHeader(auth, lang),
                const SizedBox(height: 20),

                // ── Hero Banner ──────────────────────────────
                _buildHeroBanner(lang),
                const SizedBox(height: 20),

                // ── Stat Summary Cards ───────────────────────
                _buildStatCardsSection(lang),
                const SizedBox(height: 20),

                // ── Quick Actions header + pill buttons ──────
                _buildQuickActionsHeader(lang),
                const SizedBox(height: 12),

                // ── Quick Actions Row 1 ──────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_circle_rounded,
                        label: lang.t('new_purchase'),
                        color: AppColors.primary,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NewPurchaseScreen()),
                          );
                          if (result == true) _loadDashboard();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.people_rounded,
                        label: lang.t('buyers'),
                        color: const Color(0xFFFF9800),
                        onTap: _addBuyer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.storefront_rounded,
                        label: lang.t('new_sale'),
                        color: const Color(0xFF00BCD4),
                        onTap: () async {
                          final created = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SaleCreateScreen()),
                          );
                          if (created == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text(lang.t('purchase_saved_message')),
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

                // ── Quick Actions Row 2 ──────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.inventory_2_rounded,
                        label: lang.t('inventory'),
                        color: AppColors.info,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const InventoryListScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.receipt_long_rounded,
                        label: lang.t('ledger'),
                        color: AppColors.info,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LedgerScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.assessment_rounded,
                        label: lang.t('reports'),
                        color: const Color(0xFF9C27B0),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ReportsScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Error state ──────────────────────────────
                if (_hasError) _buildErrorBanner(lang),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader(AuthProvider auth, LanguageProvider lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ "Hello !" — use lang.t() with key
            Text(lang.t('hello'), style: AppTextStyles.headingLarge),
            const SizedBox(height: 3),
            Text(_todayLabel(lang), style: AppTextStyles.bodyMedium),
          ],
        ),
        Row(
          children: [
            // ── Language toggle ──────────────────────────────
            GestureDetector(
              onTap: () {
                final newLang =
                    lang.currentLanguage.code == 'en' ? 'mr' : 'en';
                lang.setLanguage(newLang);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.language_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      lang.currentLanguage.code == 'en' ? 'EN' : 'मर',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // ── Avatar + popup menu ──────────────────────────
            PopupMenuButton<String>(
              offset: const Offset(0, 45),
              icon: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
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
                        fontFamily: 'Poppins'),
                  ),
                ),
              ),
              onSelected: (value) async {
                if (value == 'profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileScreen(user: auth.user!),
                    ),
                  );
                } else if (value == 'logout') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      // ✅ translated
                      title: Text(lang.t('logout')),
                      content: Text(lang.t('logout_confirm')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(lang.t('cancel')),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.error),
                          child: Text(lang.t('logout')),
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
                PopupMenuItem(
                  value: 'profile',
                  child: Row(children: [
                    const Icon(Icons.person_outline, size: 20),
                    const SizedBox(width: 12),
                    // ✅ translated
                    Text(lang.t('profile')),
                  ]),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(children: [
                    const Icon(Icons.logout, size: 20, color: AppColors.error),
                    const SizedBox(width: 12),
                    Text(lang.t('logout'),
                        style: const TextStyle(color: AppColors.error)),
                  ]),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  QUICK ACTIONS HEADER ROW (with pill buttons)
  // ─────────────────────────────────────────────────────────────
  Widget _buildQuickActionsHeader(LanguageProvider lang) {
    return Row(
      children: [
        Text(lang.t('quick_actions'), style: AppTextStyles.headingMedium),
        const Spacer(),

        // ── Payments pill ──────────────────────────────────
      // ── Payments pill ──────────────────────────────────
GestureDetector(
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const GetPaymentScreen()), 
  ),
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
       color: AppColors.primaryButton, 
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
           color: AppColors.shadowMedium,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.payments_rounded, color: Colors.white, size: 15),
        const SizedBox(width: 5),
        Text(
          lang.t('payments'),// Or use lang.t('add_payment') for translation
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    ),
  ),
),
        const SizedBox(width: 8),

        // ── Products pill ──────────────────────────────────
        GestureDetector(
          onTap: _openAllProducts,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primaryButton,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.production_quantity_limits_rounded,
                    color: Colors.white, size: 15),
                const SizedBox(width: 5),
                // ✅ translated
                Text(
                  lang.t('products'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STAT SUMMARY CARDS
  // ─────────────────────────────────────────────────────────────
  Widget _buildStatCardsSection(LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ translated
        Text(lang.t('business_overview'), style: AppTextStyles.headingMedium),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _StatCard(
              icon: Icons.agriculture_rounded,
              // ✅ translated
              label: lang.t('total_farmers'),
              value: _loading ? null : _data.totalFarmers.toString(),
              accentColor: AppColors.primary,
              bgColor: AppColors.primarySurface,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FarmerListScreen()),
              ),
            ),
            _StatCard(
              icon: Icons.payments_rounded,
              // ✅ translated
              label: lang.t('pending_dues'),
              value: _loading
                  ? null
                  : _formatAmount(_data.totalPendingPayments),
              // ✅ translated subtitle
              subtitle: _data.totalPendingPayments > 0
                  ? lang.t('pending')
                  : lang.t('cleared'),
              accentColor: _data.totalPendingPayments > 0
                  ? AppColors.warning
                  : AppColors.success,
              bgColor: _data.totalPendingPayments > 0
                  ? AppColors.warningSurface
                  : AppColors.successSurface,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LedgerScreen()),
              ),
            ),
            _StatCard(
              icon: Icons.warehouse_rounded,
              // ✅ translated
              label: lang.t('warehouse'),
              value: _warehouseLoading
                  ? null
                  : _data.totalWarehouses.toString(),
              accentColor: AppColors.info,
              bgColor: AppColors.infoSurface,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const InventoryListScreen()),
              ),
            ),
            _StatCard(
              icon: Icons.show_chart_rounded,
              // ✅ translated
              label: lang.t('total_sales'),
              value: _plLoading
                  ? null
                  : _formatAmount(_data.profitLoss.totalSales > 0
                      ? _data.profitLoss.totalSales
                      : _data.totalRevenue),
              // ✅ translated subtitle
              subtitle: lang.t('today'),
              accentColor: const Color(0xFF9C27B0),
              bgColor: const Color(0xFFF3E5F5),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  HERO BANNER
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeroBanner(LanguageProvider lang) {
    final pl = _data.profitLoss;
    final isProfit = pl.netProfit >= 0;
    final netColor =
        isProfit ? const Color(0xFF69F0AE) : const Color(0xFFFF6B6B);
    // ✅ translated net label
    final netLabel = isProfit ? lang.t('net_profit') : lang.t('net_loss');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top row: title + logo ───────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.28), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bar_chart_rounded,
                              color: Colors.white70, size: 12),
                          const SizedBox(width: 5),
                          // ✅ translated
                          Text(
                            lang.t('market_erp'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    // ✅ translated
                    Text(
                      lang.t('todays_pl_overview'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      _todayLabel(lang),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo3.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.agriculture_rounded,
                        color: Colors.white70,
                        size: 26),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 12),

          // ── P&L Stats ───────────────────────────────────
          if (_plLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white.withOpacity(0.8),
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _HeroStat(
                    // ✅ translated
                    label: lang.t('total_sales'),
                    value: _formatAmount(pl.totalSales),
                    valueColor: Colors.white,
                  ),
                ),
                Container(
                    width: 1,
                    height: 44,
                    color: Colors.white.withOpacity(0.2)),
                Expanded(
                  child: _HeroStat(
                    // ✅ translated (net profit / net loss)
                    label: netLabel,
                    value: _formatAmount(pl.netProfit.abs()),
                    valueColor: netColor,
                  ),
                ),
                Container(
                    width: 1,
                    height: 44,
                    color: Colors.white.withOpacity(0.2)),
                Expanded(
                  child: _HeroStat(
                    // ✅ translated
                    label: lang.t('margin'),
                    value: pl.profitMargin,
                    valueColor: isProfit
                        ? const Color(0xFFA5D6A7)
                        : const Color(0xFFFF6B6B),
                  ),
                ),
              ],
            ),

          // ── Bottom row: purchases + expenses ───────────
          if (!_plLoading) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: Colors.white.withOpacity(0.12)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    color: Colors.white54, size: 12),
                const SizedBox(width: 4),
                Text(
                  // ✅ translated label
                  '${lang.t('purchase')}: ${_formatAmount(pl.totalPurchases)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.receipt_outlined,
                    color: Colors.white54, size: 12),
                const SizedBox(width: 4),
                Text(
                  // ✅ translated label
                  '${lang.t('expense')}: ${_formatAmount(pl.totalExpenses)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  ERROR BANNER
  // ─────────────────────────────────────────────────────────────
  Widget _buildErrorBanner(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              lang.t('data_load_error'),
              style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontFamily: 'Poppins'),
            ),
          ),
          GestureDetector(
            onTap: _loadDashboard,
            child: Text(lang.t('retry'),
                style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

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
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Pass lang so day/month names can be translated if needed
  String _todayLabel(LanguageProvider lang) {
    final d = DateTime.now();
    if (lang.isMarathi) {
      // Marathi month and day names
      const months = [
        'जानेवारी', 'फेब्रुवारी', 'मार्च', 'एप्रिल', 'मे', 'जून',
        'जुलै', 'ऑगस्ट', 'सप्टेंबर', 'ऑक्टोबर', 'नोव्हेंबर', 'डिसेंबर'
      ];
      const days = [
        'रविवार', 'सोमवार', 'मंगळवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार'
      ];
      return '${days[d.weekday % 7]}, ${d.day} ${months[d.month - 1]} ${d.year}';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${days[d.weekday % 7]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Stat Card ─────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? subtitle;
  final Color accentColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.bgColor,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value == null)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: accentColor, strokeWidth: 2),
                    )
                  else
                    Text(
                      value!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Stat Cell ────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.58),
            fontSize: 9,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
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
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2))
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
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
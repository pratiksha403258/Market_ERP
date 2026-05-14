// // ─────────────────────────────────────────────────────────────
// //  DASHBOARD SCREEN — Real API Data
// //  Replaces all hardcoded mock values with live API calls:
// //    - GET /farmers          → total farmer count
// //    - GET /purchases        → today's arrivals, sales total, recent list
// //    - GET /purchases/summary → pending dues, weekly data
// // ─────────────────────────────────────────────────────────────

// import 'package:agr_market/features/auth/screens/profile_screen.dart';
// import 'package:agr_market/features/dashboard/screens/reports_screen.dart';
// import 'package:agr_market/inventory/inventory_list_screen.dart';
// import 'package:agr_market/ledger/ledger_screen.dart';
// import 'package:agr_market/payment/payment_screen.dart';
// import 'package:agr_market/purchase/purchase_screen.dart';
// import 'package:agr_market/sales/sale_create_screen.dart';
// import 'package:agr_market/services/auth_service.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../core/constants/colors.dart';
// import '../../../providers/auth_provider.dart';
// import '../../../providers/language_provider.dart';   // <-- added
// import '../../../services/dio_client.dart';
// import '../../../services/constant_service.dart';
// import '../../farmers/screens/farmer_registration_screen.dart';

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

//   const _DashboardData({
//     this.totalFarmers = 0,
//     this.todayPurchaseCount = 0,
//     this.thisMonthValue = 0,
//     this.thisMonthCount = 0,
//     this.totalPendingPayments = 0,
//     this.pendingExpenseApprovals = 0,
//     this.recentPurchases = const [],
//     this.weeklyArrivals = const [0.1,0.1,0.1,0.1,0.1,0.1,0.1],
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

//   @override
//   void initState() {
//     super.initState();
//     _loadDashboard();
//   }

//   // ── NEW helper methods ─────────────────────────────────────
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
//   // ───────────────────────────────────────────────────────────
// Future<void> _loadDashboard() async {
//   setState(() { _loading = true; _hasError = false; });
//   try {

//     // ── CALL 1: Dashboard KPIs ──────────────────────────────
//     final dashRes = await DioClient.instance.dio
//         .get(ApiRoutes.dashboard);
//     final d = dashRes.data['data'] as Map<String, dynamic>;
//     final monthly =
//         d['thisMonthPurchases'] as Map<String, dynamic>;

//     final totalFarmers =
//         (d['totalActiveFarmers'] as num?)?.toInt() ?? 0;
//     final todayCount =
//         (d['todayPurchaseCount'] as num?)?.toInt() ?? 0;
//     final monthValue =
//         (monthly['value'] as num?)?.toDouble() ?? 0.0;
//     final monthCount =
//         (monthly['count'] as num?)?.toInt() ?? 0;
//     final pendingPayments =
//         (d['totalPendingPayments'] as num?)?.toDouble() ?? 0.0;
//     final pendingExpenses =
//         (d['pendingExpenseApprovals'] as num?)?.toInt() ?? 0;

//     debugPrint('✅ Dashboard KPIs: Farmers=$totalFarmers '
//         'Pending=₹$pendingPayments Month=₹$monthValue');

//     // ── CALL 2: Purchases for weekly bars + recent list ─────
//     // status filter skips draft records (which have ₹0 values)
//    // ── CALL 2: Purchases for weekly bars (full week range) ─────
// List allPurchases = [];
// try {
//   final now = DateTime.now();
  
//   // Start of the week (Monday)
//   final weekStart = DateTime(now.year, now.month, now.day)
//       .subtract(Duration(days: now.weekday - 1));
  
//   // End of the week (next Monday, exclusive)
//   final weekEnd = weekStart.add(const Duration(days: 7));

//   // Format dates for API
//   final startIso = weekStart.toIso8601String().split('T')[0];
//   final endIso = weekEnd.toIso8601String().split('T')[0];

//   final pRes = await DioClient.instance.dio.get(
//     ApiRoutes.purchases,
//     queryParameters: {
//       'page': 1,
//       'limit': 100,          // increase limit to capture all week purchases
//       'sortOrder': 'desc',
//       // 'status': 'saved,partial,paid',
//       'startDate': startIso,
//       'endDate': endIso,     // optional – but recommended if API supports it
//     },
//   );

//   if (pRes.data is Map && pRes.data['data'] is List) {
//     allPurchases = pRes.data['data'] as List;
//   } else if (pRes.data is List) {
//     allPurchases = pRes.data as List;
//   }
//   debugPrint('✅ Weekly purchases loaded: ${allPurchases.length}');
  
// } catch (e) {
//   debugPrint('⚠️ Weekly purchases error: $e');

// }

//     // ── Weekly bar calculation ──────────────────────────────
//     final now = DateTime.now();
//     final weekStart = DateTime(now.year, now.month, now.day)
//         .subtract(Duration(days: now.weekday - 1));
//     final dayTotals = List<double>.filled(7, 0.0);
//     for (final p in allPurchases) {
//       final dateStr = p['purchaseDate']?.toString()
//           ?? p['createdAt']?.toString() ?? '';
//       final date = DateTime.tryParse(dateStr)?.toLocal();
//       if (date == null) continue;
//       final todayEnd =
//           DateTime(now.year, now.month, now.day + 1);
//       if (date.isBefore(weekStart) ||
//           !date.isBefore(todayEnd)) continue;
//       final idx = (date.weekday - 1).clamp(0, 6);
//       dayTotals[idx] +=
//           (p['finalPayable'] as num?)?.toDouble() ?? 0;
//     }
//     final maxDay = dayTotals.reduce((a, b) => a > b ? a : b);
//     final weeklyNorm = maxDay > 0
//         ? dayTotals
//             .map((v) => (v / maxDay).clamp(0.1, 1.0))
//             .toList()
//         : List<double>.filled(7, 0.1);
//   debugPrint('Weekly totals (₹): $dayTotals');
// debugPrint('Normalized: $weeklyNorm');
//     // ── Recent 3 purchases ──────────────────────────────────
//     final recentList = allPurchases.take(3).map((p) {
//       final lines = p['lines'] as List? ?? [];
//       final product = lines.isNotEmpty
//           ? (lines[0]['productName']?.toString() ?? 'Product')
//           : 'Purchase';
//       final farmer = p['farmer'];
//       final farmerName = farmer is Map
//           ? farmer['name']?.toString() ?? 'Unknown'
//           : 'Unknown';
//       return <String, dynamic>{
//         'product': product,
//         'farmer': farmerName,
//         'amount':
//             (p['finalPayable'] as num?)?.toDouble() ?? 0.0,
//         'date': p['purchaseDate']?.toString()
//             ?? p['createdAt']?.toString() ?? '',
//         'status': p['status']?.toString() ?? '',
//         'receiptNumber':
//             p['receiptNumber']?.toString() ?? '',
//       };
//     }).toList();

//     setState(() {
//       _data = _DashboardData(
//         totalFarmers: totalFarmers,
//         todayPurchaseCount: todayCount,
//         thisMonthValue: monthValue,
//         thisMonthCount: monthCount,
//         totalPendingPayments: pendingPayments,
//         pendingExpenseApprovals: pendingExpenses,
//         recentPurchases: recentList,
//         weeklyArrivals: weeklyNorm,
//       );
//       _loading = false;
//     });

//   } catch (e) {
//     debugPrint('❌ Dashboard failed: $e');
//     setState(() { _loading = false; _hasError = true; });
//   }
// }
//   List _extractList(dynamic data) {
//     if (data is List) return data;
//     if (data is Map) {
//       if (data['purchases'] is List) return data['purchases'];
//       if (data['data'] is List) return data['data'];
//     }
//     return [];
//   }

//   String _formatAmount(double v) {
//     if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
//     if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
//     return '₹${v.toStringAsFixed(0)}';
//   }

//   String _formatKg(double v) {
//     if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}T';
//     return '${v.toStringAsFixed(0)} kg';
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
// Future<void> _addPayment() async {
//   debugPrint('➡️ _addPayment() called');

//   // Show loading dialog
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (ctx) => const Center(child: CircularProgressIndicator()),
//   );

//   List<Map<String, dynamic>> purchases = [];
//   try {
//     final res = await DioClient.instance.dio.get(
//       ApiRoutes.purchases,
//       queryParameters: {
//         'page': 1,
//         'limit': 100,
//         'sortOrder': 'desc',
//         'status': 'saved,partial,paid',
//       },
//     );

//     debugPrint('✅ Purchases API response: ${res.statusCode}');
//     debugPrint('📦 Response data type: ${res.data.runtimeType}');
//     debugPrint('🔍 Full response data: ${res.data}');

//     List raw = [];
//     if (res.data is List) {
//       raw = res.data;
//     } else if (res.data is Map && res.data['data'] is List) {
//       raw = res.data['data'];
//     } else if (res.data is Map && res.data['purchases'] is List) {
//       raw = res.data['purchases'];
//     }
//     purchases = raw.cast<Map<String, dynamic>>();

//     if (mounted) Navigator.pop(context); // close loader
//     debugPrint('📋 Fetched ${purchases.length} purchases');
//   } catch (e, stack) {
//     if (mounted) Navigator.pop(context);
//     debugPrint('❌ ERROR fetching purchases: $e');
//     debugPrint(stack.toString());
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to load purchases. Check connection/authentication.')),
//       );
//     }
//     return;
//   }

//   if (purchases.isEmpty) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No purchases available to pay against.')),
//       );
//     }
//     return;
//   }

//   // Show bottom sheet to select a purchase
//   final selected = await showModalBottomSheet<Map<String, dynamic>>(
//     context: context,
//     isScrollControlled: true,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     builder: (ctx) {
//       String query = '';
//       return StatefulBuilder(
//         builder: (ctx, setStateSheet) {
//           final filtered = query.isEmpty
//               ? purchases
//               : purchases.where((p) {
//                   final farmer = p['farmer'];
//                   final farmerName = farmer is Map
//                       ? (farmer['name']?.toString() ?? '')
//                       : '';
//                   final receiptNum = p['receiptNumber']?.toString() ?? '';
//                   return farmerName.toLowerCase().contains(query.toLowerCase()) ||
//                       receiptNum.toLowerCase().contains(query.toLowerCase());
//                 }).toList();

//           return Container(
//             height: MediaQuery.of(ctx).size.height * 0.7,
//             padding: const EdgeInsets.only(top: 12),
//             child: Column(
//               children: [
//                 // Drag handle
//                 Container(
//                   width: 40,
//                   height: 4,
//                   margin: const EdgeInsets.only(bottom: 12),
//                   decoration: BoxDecoration(
//                     color: AppColors.border,
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: TextField(
//                     autofocus: false,
//                     onChanged: (val) {
//                       query = val;
//                       setStateSheet(() {});
//                     },
//                     decoration: InputDecoration(
//                       hintText: 'Search farmer or receipt...',
//                       prefixIcon: const Icon(Icons.search_rounded),
//                       filled: true,
//                       fillColor: AppColors.surfaceVariant,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: filtered.length,
//                     itemBuilder: (ctx, idx) {
//                       final p = filtered[idx];
//                       final farmer = p['farmer'];
//                       final farmerName = farmer is Map
//                           ? (farmer['name']?.toString() ?? 'Unknown')
//                           : 'Unknown';
//                       final farmerId = farmer is Map
//                           ? (farmer['_id']?.toString() ?? farmer['id']?.toString() ?? '')
//                           : '';
//                       final receiptNum = p['receiptNumber']?.toString() ?? '';
//                       final finalPayable = (p['finalPayable'] as num?)?.toDouble() ?? 0;
//                       final amountPaid = (p['amountPaid'] as num?)?.toDouble() ?? 0;
//                       final amountDue = (p['amountDue'] as num?)?.toDouble() ?? 0;
//                       final initials = farmerName.isNotEmpty
//                           ? farmerName.trim().split(' ').map((s) => s[0]).take(2).join().toUpperCase()
//                           : 'F';

//                       return ListTile(
//                         leading: CircleAvatar(
//                           backgroundColor: AppColors.primary,
//                           child: Text(initials,
//                               style: const TextStyle(color: Colors.white)),
//                         ),
//                         title: Text(farmerName,
//                             style: const TextStyle(fontFamily: 'Poppins')),
//                         subtitle: Text(
//                           '$receiptNum  •  Due: ₹${amountDue.toStringAsFixed(2)}',
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                         trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
//                         onTap: () => Navigator.pop(ctx, p),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       );
//     },
//   );

//   if (selected != null && mounted) {
//     final farmer = selected['farmer'];
//     final farmerName = farmer is Map ? (farmer['name']?.toString() ?? 'Unknown') : 'Unknown';
//     final farmerId = farmer is Map ? (farmer['_id']?.toString() ?? farmer['id']?.toString() ?? '') : '';
//     final purchaseId = selected['_id']?.toString() ?? selected['id']?.toString() ?? '';
//     final finalPayable = (selected['finalPayable'] as num?)?.toDouble() ?? 0;
//     final amountPaid = (selected['amountPaid'] as num?)?.toDouble() ?? 0;
//     final amountDue = (selected['amountDue'] as num?)?.toDouble() ?? 0;
//     final receiptNumber = selected['receiptNumber']?.toString() ?? '';

//     if (purchaseId.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Invalid purchase selected.')),
//       );
//       return;
//     }

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => PaymentScreen(
//           purchaseId: purchaseId,
//           farmerId: farmerId,
//           farmerName: farmerName,
//           finalPayable: finalPayable,
//           amountPaid: amountPaid,
//           amountDue: amountDue,
//           receiptNumber: receiptNumber,
//         ),
//       ),
//     ).then((_) {
//       // Refresh dashboard after returning
//       _loadDashboard();
//     });
//   }
// }

//   void _showLanguagePicker(BuildContext context, LanguageProvider lang) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (ctx) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: LanguageProvider.supportedLanguages.map((l) => ListTile(
//             leading: Text(l.flag, style: const TextStyle(fontSize: 28)),
//             title: Text(l.nativeName, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
//             subtitle: Text(l.name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
//             trailing: lang.currentLanguage.code == l.code
//                 ? const Icon(Icons.check_circle, color: AppColors.primary)
//                 : null,
//             onTap: () {
//               lang.setLanguage(l.code);
//               Navigator.pop(ctx);
//             },
//           )).toList(),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthProvider>();
//     final lang = Provider.of<LanguageProvider>(context);
//     final userName = auth.user?.name ?? 'User';

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(
//         child: RefreshIndicator(
//           onRefresh: _loadDashboard,
//           color: AppColors.primary,
//           child: SingleChildScrollView(
//             physics: const AlwaysScrollableScrollPhysics(),
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
//                         Text('Hello, ${userName.split(' ').first}!',
//                             style: AppTextStyles.headingLarge),
//                         const SizedBox(height: 3),
//                         Text(_todayLabel(), style: AppTextStyles.bodyMedium),
//                       ],
//                     ),
//                     Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(10),
//                           decoration: BoxDecoration(
//                             color: AppColors.surface,
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(color: AppColors.border),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: AppColors.shadowLight,
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 2),
//                               )
//                             ],
//                           ),
//                           child: const Icon(Icons.notifications_none_rounded,
//                               color: AppColors.primary, size: 22),
//                         ),

//                         // ── LANGUAGE BUTTON (replaces globe) ──
//                         GestureDetector(
//                           onTap: () => _showLanguagePicker(context, lang),
//                           child: Container(
//                             padding: const EdgeInsets.all(10),
//                             decoration: BoxDecoration(
//                               color: AppColors.surface,
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(color: AppColors.border),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: AppColors.shadowLight,
//                                   blurRadius: 8,
//                                   offset: const Offset(0, 2),
//                                 )
//                               ],
//                             ),
//                             child: Text(lang.currentLanguage.flag,
//                                 style: const TextStyle(fontSize: 20)),
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
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.w700,
//                                   fontSize: 14,
//                                   fontFamily: 'Poppins'
//                                 ),
//                               ),
//                             ),
//                           ),
//                           onSelected: (value) async {
//                             if (value == 'profile') {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => ProfileScreen(user: auth.user!),
//                                 ),
//                               );
//                             } else if (value == 'logout') {
//                               final confirm = await showDialog<bool>(
//                                 context: context,
//                                 builder: (ctx) => AlertDialog(
//                                   title: const Text('Logout'),
//                                   content: const Text('Are you sure you want to logout?'),
//                                   actions: [
//                                     TextButton(
//                                       onPressed: () => Navigator.pop(ctx, false),
//                                       child: const Text('Cancel'),
//                                     ),
//                                     TextButton(
//                                       onPressed: () => Navigator.pop(ctx, true),
//                                       style: TextButton.styleFrom(foregroundColor: AppColors.error),
//                                       child: const Text('Logout'),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                               if (confirm == true) {
//                                 await AuthService.instance.logout();
//                                 if (context.mounted) {
//                                   Navigator.of(context).pushNamedAndRemoveUntil(
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
//                               child: Row(
//                                 children: [
//                                   Icon(Icons.person_outline, size: 20),
//                                   SizedBox(width: 12),
//                                   Text('Profile'),
//                                 ],
//                               ),
//                             ),
//                             const PopupMenuItem(
//                               value: 'logout',
//                               child: Row(
//                                 children: [
//                                   Icon(Icons.logout, size: 20, color: AppColors.error),
//                                   SizedBox(width: 12),
//                                   Text('Logout', style: TextStyle(color: AppColors.error)),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(width: 8),
//                       ],
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),

//                 // ── Hero Banner (unchanged) ─────────────────
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     gradient: AppColors.heroGradient,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: AppColors.primary.withOpacity(0.28),
//                         blurRadius: 20,
//                         offset: const Offset(0, 6),
//                       )
//                     ],
//                   ),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text('Farming Made Simple,',
//                                 style: TextStyle(
//                                     color: Colors.white70,
//                                     fontSize: 12,
//                                     fontFamily: 'Poppins')),
//                             const Text('Smarter & Sustainable',
//                                 style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 17,
//                                     fontWeight: FontWeight.w700,
//                                     fontFamily: 'Poppins')),
//                             const SizedBox(height: 14),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 12, vertical: 6),
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withOpacity(0.25),
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               child: const Text('Market ERP ',
//                                   style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.w500,
//                                       fontFamily: 'Poppins')),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Container(
//                         width: 68,
//                         height: 68,
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           shape: BoxShape.circle,
//                           image: const DecorationImage(
//                             image: AssetImage('assets/images/logo3.png'),
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // ── KPI Grid ─────────────────────────────────
//                 Text(lang.t('todays_overview'), style: AppTextStyles.headingMedium),
//                 const SizedBox(height: 12),
//                 if (_loading)
//                   _buildKpiShimmer()
//                 else
//                   GridView.count(
//                     crossAxisCount: 2,
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     mainAxisSpacing: 12,
//                     crossAxisSpacing: 12,
//                     childAspectRatio: 1.45,
//                     children: [
//                       _KpiCard(
//                         icon: Icons.local_shipping_rounded,
//                         label: lang.t('todays_purchases'),
//                         value: _data.todayPurchaseCount.toString(),
//                         change: _data.todayPurchaseCount > 0 ? 'Today' : 'None yet',
//                         positive: true,
//                       ),
//                       _KpiCard(
//                         icon: Icons.people_rounded,
//                         label: lang.t('active_farmers'),
//                         value: _data.totalFarmers.toString(),
//                         change: 'Registered',
//                         positive: true,
//                       ),
//                       _KpiCard(
//                         icon: Icons.account_balance_wallet_rounded,
//                         label: lang.t('pending_dues'),
//                         value: _formatAmount(_data.totalPendingPayments),
//                         change: _data.totalPendingPayments > 0 ? 'Unpaid' : 'All clear',
//                         positive: _data.totalPendingPayments == 0,
//                       ),
//                       _KpiCard(
//                         icon: Icons.trending_up_rounded,
//                         label: lang.t('this_month'),
//                         value: _formatAmount(_data.thisMonthValue),
//                         change: '${_data.thisMonthCount} purchases',
//                         positive: true,
//                       ),
//                     ],
//                   ),
//                 const SizedBox(height: 20),

//                 // ── Quick Actions ───────────────────────────
//                 Text(lang.t('quick_actions'), style: AppTextStyles.headingMedium),
//                 const SizedBox(height: 12),

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
//                             MaterialPageRoute(builder: (_) => const NewPurchaseScreen()),
//                           );
//                           if (result == true) _loadDashboard();
//                         },
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: _QuickAction(
//                         icon: Icons.payments_rounded,
//                         label: lang.t('add_payment'),
//                         color: const Color(0xFFFF9800),
//                         onTap: _addPayment,
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
//                             MaterialPageRoute(builder: (_) => const SaleCreateScreen()),
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

//                 Row(
//                   children: [
//                     Expanded(
//                       child: _QuickAction(
//                         icon: Icons.inventory_2_rounded,
//                         label: lang.t('inventory'),
//                         color: AppColors.info,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (_) => const InventoryListScreen()),
//                           );
//                         },
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: _QuickAction(
//                         icon: Icons.receipt_long_rounded,
//                         label: lang.t('ledger'),
//                         color: AppColors.info,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (_) => const LedgerScreen()),
//                           );
//                         },
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: _QuickAction(
//                         icon: Icons.assessment_rounded,
//                         label: lang.t('reports'),
//                         color: const Color(0xFF9C27B0),
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (_) => const ReportsScreen()),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),

//                 // ── Weekly Bar Chart ──────────────────────────
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: AppColors.surface,
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(color: AppColors.border),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(lang.t('weekly_arrivals'),
//                                   style: AppTextStyles.headingSmall),
//                               Text(lang.t('this_week'),
//                                   style: AppTextStyles.bodySmall
//                                       .copyWith(color: AppColors.textHint)),
//                             ],
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 10, vertical: 4),
//                             decoration: BoxDecoration(
//                               color: AppColors.successSurface,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Row(
//                               children: [
//                                 const Icon(Icons.trending_up_rounded,
//                                     color: AppColors.success, size: 13),
//                                 const SizedBox(width: 4),
//                                 Text('Live',
//                                     style: const TextStyle(
//                                         color: AppColors.success,
//                                         fontSize: 11,
//                                         fontWeight: FontWeight.w600,
//                                         fontFamily: 'Poppins')),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                       if (_loading)
//                         Container(
//                             height: 120, color: AppColors.surfaceVariant)
//                       else
//                         SizedBox(
//                           height: 120,
//                           child: Row(
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                             children: [
//                               _Bar(day: 'Mon', pct: _data.weeklyArrivals[0]),
//                               _Bar(day: 'Tue', pct: _data.weeklyArrivals[1]),
//                               _Bar(day: 'Wed', pct: _data.weeklyArrivals[2]),
//                               _Bar(day: 'Thu', pct: _data.weeklyArrivals[3]),
//                               _Bar(day: 'Fri', pct: _data.weeklyArrivals[4]),
//                               _Bar(day: 'Sat', pct: _data.weeklyArrivals[5]),
//                               _Bar(
//                                 day: 'Sun',
//                                 pct: _data.weeklyArrivals[6],
//                                 isToday: DateTime.now().weekday == 7,
//                               ),
//                             ],
//                           ),
//                         ),
//                       const SizedBox(height: 14),
//                       const Divider(color: AppColors.divider),
//                       const SizedBox(height: 10),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(lang.t('total_this_week'),
//                               style: const TextStyle(
//                                   fontSize: 12,
//                                   color: AppColors.textHint,
//                                   fontFamily: 'Poppins')),
//                           Text(
//                             _formatAmount(_data.thisMonthValue),
//                             style: AppTextStyles.numberSmall
//                                 .copyWith(color: AppColors.primary),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
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

//   // ── Shimmer placeholders ──────────────────────────────────

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
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                     color: AppColors.primary, strokeWidth: 2)),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPurchaseShimmer() {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       height: 64,
//       decoration: BoxDecoration(
//         color: AppColors.surfaceVariant,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: AppColors.border),
//       ),
//     );
//   }

//   String _todayLabel() {
//     final d = DateTime.now();
//     const months = [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec'
//     ];
//     const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
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
//                 padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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

// // ── Recent Purchase Tile (not currently used in UI) ──────────
// // … omitted for brevity



// ─────────────────────────────────────────────────────────────
//  DASHBOARD SCREEN — Real API Data
//  - GET /dashboard          → KPI cards
//  - GET /purchases          → weekly bars + recent list
//  - GET /reports/profit-loss → hero banner P&L data
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
//  DASHBOARD SCREEN — Real API Data
//  - GET /dashboard          → KPI cards
//  - GET /purchases          → weekly bars + recent list
//  - GET /reports/profit-loss → hero banner P&L data
// ─────────────────────────────────────────────────────────────

import 'package:agr_market/buyer/buyer_list_screen.dart';
import 'package:agr_market/features/auth/screens/profile_screen.dart';
import 'package:agr_market/features/dashboard/screens/reports_screen.dart';
import 'package:agr_market/inventory/inventory_list_screen.dart';
import 'package:agr_market/ledger/ledger_screen.dart';
// import 'package:agr_market/payment/payment_screen.dart';
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
// import '../../farmers/screens/farmer_registration_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

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
            totalSales: pl.totalSalesRevenue,
            totalPurchases: pl.totalPurchaseCost,
            totalExpenses: pl.totalExpenses,
            grossProfit: pl.grossProfit,
            netProfit: pl.netProfit,
            profitMargin: pl.profitMargin,
          ),
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

  // ── Main loader ───────────────────────────────────────────
  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _hasError = false;
      _plLoading = true;
    });

    try {
      final dashRes =
          await DioClient.instance.dio.get(ApiRoutes.dashboard);
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

      debugPrint('✅ Dashboard KPIs loaded');

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
        final dateStr = p['purchaseDate']?.toString() ??
            p['createdAt']?.toString() ?? '';
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
              p['createdAt']?.toString() ?? '',
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
        );
        _loading = false;
      });

      _loadProfitLoss();
    } catch (e) {
      debugPrint('❌ Dashboard failed: $e');
      setState(() {
        _loading = false;
        _plLoading = false;
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
    MaterialPageRoute(
      builder: (_) => const BuyerListScreen(),
    ),
  );
}

  void _showLanguagePicker(BuildContext context, LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: LanguageProvider.supportedLanguages
              .map((l) => ListTile(
                    leading:
                        Text(l.flag, style: const TextStyle(fontSize: 28)),
                    title: Text(l.nativeName,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500)),
                    subtitle: Text(l.name,
                        style: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 12)),
                    trailing: lang.currentLanguage.code == l.code
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
                        : null,
                    onTap: () {
                      lang.setLanguage(l.code);
                      Navigator.pop(ctx);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final lang = Provider.of<LanguageProvider>(context);
    final userName = auth.user?.name ?? 'User';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                        Text(_todayLabel(),
                            style: AppTextStyles.bodyMedium),
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
                          child: const Icon(
                              Icons.notifications_none_rounded,
                              color: AppColors.primary,
                              size: 22),
                        ),
                        GestureDetector(
                          onTap: () =>
                              _showLanguagePicker(context, lang),
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
                            child: Text(lang.currentLanguage.flag,
                                style: const TextStyle(fontSize: 20)),
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
                                  title: const Text('Logout'),
                                  content: const Text(
                                      'Are you sure you want to logout?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      style: TextButton.styleFrom(
                                          foregroundColor: AppColors.error),
                                      child: const Text('Logout'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await AuthService.instance.logout();
                                if (context.mounted) {
                                  Navigator.of(context)
                                      .pushNamedAndRemoveUntil(
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
                              child: Row(children: [
                                Icon(Icons.person_outline, size: 20),
                                SizedBox(width: 12),
                                Text('Profile'),
                              ]),
                            ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(children: [
                                Icon(Icons.logout,
                                    size: 20, color: AppColors.error),
                                SizedBox(width: 12),
                                Text('Logout',
                                    style: TextStyle(
                                        color: AppColors.error)),
                              ]),
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
                _buildHeroBanner(),
                const SizedBox(height: 20),

                // ── KPI Grid ─────────────────────────────────
                Text(lang.t('todays_overview'),
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
                        label: lang.t('todays_purchases'),
                        value: _data.todayPurchaseCount.toString(),
                        change: _data.todayPurchaseCount > 0
                            ? 'Today'
                            : 'None yet',
                        positive: true,
                      ),
                      _KpiCard(
                        icon: Icons.people_rounded,
                        label: lang.t('active_farmers'),
                        value: _data.totalFarmers.toString(),
                        change: 'Registered',
                        positive: true,
                      ),
                      _KpiCard(
                        icon: Icons.account_balance_wallet_rounded,
                        label: lang.t('pending_dues'),
                        value: _formatAmount(_data.totalPendingPayments),
                        change: _data.totalPendingPayments > 0
                            ? 'Unpaid'
                            : 'All clear',
                        positive: _data.totalPendingPayments == 0,
                      ),
                      _KpiCard(
                        icon: Icons.trending_up_rounded,
                        label: lang.t('this_month'),
                        value: _formatAmount(_data.thisMonthValue),
                        change: '${_data.thisMonthCount} purchases',
                        positive: true,
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // ── Quick Actions ────────────────────────────
                Text(lang.t('quick_actions'),
                    style: AppTextStyles.headingMedium),
                const SizedBox(height: 12),
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
                                builder: (_) =>
                                    const NewPurchaseScreen()),
                          );
                          if (result == true) _loadDashboard();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // In the build method, replace the "Add Payment" button with:
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
                                builder: (_) =>
                                    const SaleCreateScreen()),
                          );
                          if (created == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Sale created successfully!'),
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
                              builder: (_) =>
                                  const InventoryListScreen()),
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
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(lang.t('weekly_arrivals'),
                                  style: AppTextStyles.headingSmall),
                              Text(lang.t('this_week'),
                                  style: AppTextStyles.bodySmall
                                      .copyWith(
                                          color: AppColors.textHint)),
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
                            height: 120,
                            color: AppColors.surfaceVariant)
                      else
                        SizedBox(
                          height: 120,
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            children: [
                              _Bar(
                                  day: 'Mon',
                                  pct: _data.weeklyArrivals[0]),
                              _Bar(
                                  day: 'Tue',
                                  pct: _data.weeklyArrivals[1]),
                              _Bar(
                                  day: 'Wed',
                                  pct: _data.weeklyArrivals[2]),
                              _Bar(
                                  day: 'Thu',
                                  pct: _data.weeklyArrivals[3]),
                              _Bar(
                                  day: 'Fri',
                                  pct: _data.weeklyArrivals[4]),
                              _Bar(
                                  day: 'Sat',
                                  pct: _data.weeklyArrivals[5]),
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
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(lang.t('total_this_week'),
                              style: const TextStyle(
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
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  HERO BANNER  (compact, professional)
  //
  //  ┌────────────────────────────────────────────────────────┐
  //  │  [📊 Market ERP]                          [● logo]    │
  //  │  Monthly P&L Overview                                  │
  //  │  May 2026                                              │
  //  │ ────────────────────────────────────────────────────   │
  //  │  ↑ icon    ↓ icon       ⊕ icon                        │
  //  │  ₹31.6L   ₹1.2Cr     -368.43%                        │
  //  │  Sales    Net Loss     Margin                          │
  //  │ ────────────────────────────────────────────────────   │
  //  │  🛒 Purchases: ₹1.47Cr   🧾 Expenses: ₹33.8K          │
  //  └────────────────────────────────────────────────────────┘
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    final pl = _data.profitLoss;
    final isProfit = pl.netProfit >= 0;
    final netColor =
        isProfit ? const Color(0xFF69F0AE) : const Color(0xFFFF6B6B);
    final netLabel = isProfit ? 'Net Profit' : 'Net Loss';

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
          // ── Row 1: title + circular logo ─────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ERP badge pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.28),
                            width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bar_chart_rounded,
                              color: Colors.white70, size: 12),
                          SizedBox(width: 5),
                          Text(
                            'Market ERP',
                            style: TextStyle(
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
                   const Text(
                     "Today's P&L Overview",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      _todayLabel(),
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
              // Circular logo — small & on the side
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

          // ── Row 2: 3 P&L stats ────────────────────────────
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
                // Sales
                Expanded(
                  child: _HeroStat(
                    label: 'Total Sales',
                    value: _formatAmount(pl.totalSales),
                    icon: Icons.trending_up_rounded,
                    iconBg: Colors.white.withOpacity(0.12),
                    iconColor: const Color(0xFFA5D6A7),
                    valueColor: Colors.white,
                  ),
                ),
                Container(
                    width: 1,
                    height: 44,
                    color: Colors.white.withOpacity(0.2)),
                // Net profit/loss
                Expanded(
                  child: _HeroStat(
                    label: netLabel,
                    value: _formatAmount(pl.netProfit.abs()),
                    icon: isProfit
                        ? Icons.arrow_circle_up_rounded
                        : Icons.arrow_circle_down_rounded,
                    iconBg: netColor.withOpacity(0.15),
                    iconColor: netColor,
                    valueColor: netColor,
                  ),
                ),
                Container(
                    width: 1,
                    height: 44,
                    color: Colors.white.withOpacity(0.2)),
                // Margin
                Expanded(
                  child: _HeroStat(
                    label: 'Margin',
                    value: pl.profitMargin,
                    icon: Icons.donut_small_rounded,
                    iconBg: Colors.white.withOpacity(0.12),
                    iconColor: const Color(0xFFFFCC80),
                    valueColor: isProfit
                        ? const Color(0xFFA5D6A7)
                        : const Color(0xFFFF6B6B),
                  ),
                ),
              ],
            ),

          // ── Row 3: secondary stats (only when loaded) ─────
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
                  'Purchases: ${_formatAmount(pl.totalPurchases)}',
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
                  'Expenses: ${_formatAmount(pl.totalExpenses)}',
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
String _todayLabelForHero() {
  final now = DateTime.now();
  return 'Today, ${now.day} ${_monthName(now.month)} ${now.year}';
}

String _monthName(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return months[month - 1];
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
            border: Border.all(color: AppColors.border),
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

  String _todayLabel() {
    final d = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${days[d.weekday % 7]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Hero Stat Cell ────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color valueColor;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
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
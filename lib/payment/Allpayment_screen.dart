// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../../core/constants/colors.dart';
// import '../../../models/payment_model.dart';
// import '../../../services/payment_service.dart';

// class AllPaymentsScreen extends StatefulWidget {
//   const AllPaymentsScreen({super.key, required purchaseId});

//   @override
//   State<AllPaymentsScreen> createState() => _AllPaymentsScreenState();
// }

// class _AllPaymentsScreenState extends State<AllPaymentsScreen> {
//   // ── Data ─────────────────────────────────────────────────────
//   List<PaymentModel> _payments = [];
//   bool _loading = true;
//   bool _loadingMore = false;
//   bool _hasMore = true;
//   String? _error;

//   // ── Pagination ───────────────────────────────────────────────
//   int _page = 1;
//   static const int _limit = 20;

//   // ── Filters ──────────────────────────────────────────────────
//   PaymentMode? _selectedMode;
//   String _searchQuery = '';
//   final _searchCtrl = TextEditingController();
//   final _scrollCtrl = ScrollController();

//   // ── Summary totals (computed from loaded list) ───────────────
//   double get _totalAmount =>
//       _payments.fold(0, (sum, p) => sum + p.amount);

//   @override
//   void initState() {
//     super.initState();
//     _loadPayments(reset: true);
//     _scrollCtrl.addListener(_onScroll);
//   }

//   @override
//   void dispose() {
//     _searchCtrl.dispose();
//     _scrollCtrl.dispose();
//     super.dispose();
//   }

//   void _onScroll() {
//     if (_scrollCtrl.position.pixels >=
//             _scrollCtrl.position.maxScrollExtent - 200 &&
//         !_loadingMore &&
//         _hasMore) {
//       _loadMore();
//     }
//   }

//   // ── Load / refresh ───────────────────────────────────────────
//   Future<void> _loadPayments({bool reset = false}) async {
//     if (reset) {
//       setState(() {
//         _loading = true;
//         _error = null;
//         _page = 1;
//         _hasMore = true;
//         _payments = [];
//       });
//     }

//     try {
//       final results = await PaymentService().getPayments(
//         page: _page,
//         limit: _limit,
//         // Pass filters if your getPayments supports them;
//         // extend the service method as needed.
//       );

//       setState(() {
//         _payments = reset ? results : [..._payments, ...results];
//         _hasMore = results.length == _limit;
//         _loading = false;
//         _loadingMore = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString().replaceAll('Exception: ', '');
//         _loading = false;
//         _loadingMore = false;
//       });
//     }
//   }

//   Future<void> _loadMore() async {
//     if (_loadingMore || !_hasMore) return;
//     setState(() {
//       _loadingMore = true;
//       _page++;
//     });
//     await _loadPayments();
//   }

//   // ── Filtered list ────────────────────────────────────────────
//   List<PaymentModel> get _filtered {
//     var list = _payments;

//     // Filter by payment mode
//     if (_selectedMode != null) {
//       list = list.where((p) => p.paymentMode == _selectedMode).toList();
//     }

//     // Filter by search query (farmer ID or reference number)
//     if (_searchQuery.isNotEmpty) {
//       final q = _searchQuery.toLowerCase();
//       list = list.where((p) {
//         return p.farmerId.toLowerCase().contains(q) ||
//             (p.referenceNumber?.toLowerCase().contains(q) ?? false) ||
//             p.purchaseId.toLowerCase().contains(q);
//       }).toList();
//     }

//     return list;
//   }

//   // ── Helpers ──────────────────────────────────────────────────
//   String _formatAmount(double v) {
//     if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
//     if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
//     if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
//     return '₹${v.toStringAsFixed(2)}';
//   }

//   String _timeAgo(DateTime date) {
//     final diff = DateTime.now().difference(date);
//     if (diff.inMinutes < 1) return 'Just now';
//     if (diff.inHours < 1) return '${diff.inMinutes}m ago';
//     if (diff.inDays < 1) return '${diff.inHours}h ago';
//     if (diff.inDays == 1) return 'Yesterday';
//     return DateFormat('dd MMM yyyy').format(date);
//   }

//   // ── Build ─────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: const Text(
//           'All Payments',
//           style: TextStyle(
//             fontFamily: 'Poppins',
//             fontWeight: FontWeight.w600,
//             fontSize: 17,
//           ),
//         ),
//         backgroundColor: AppColors.surface,
//         elevation: 0,
//         centerTitle: false,
//         actions: [
//           // Total badge
//           if (!_loading && _payments.isNotEmpty)
//             Center(
//               child: Container(
//                 margin: const EdgeInsets.only(right: 16),
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                 decoration: BoxDecoration(
//                   color: AppColors.primarySurface,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   _formatAmount(_totalAmount),
//                   style: const TextStyle(
//                     fontFamily: 'Poppins',
//                     fontSize: 12,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.primary,
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // ── Search + Filter bar ──────────────────────────────
//           _buildSearchAndFilter(),

//           // ── Summary strip ────────────────────────────────────
//           if (!_loading && _payments.isNotEmpty) _buildSummaryStrip(),

//           // ── List ─────────────────────────────────────────────
//           Expanded(child: _buildBody()),
//         ],
//       ),
//     );
//   }

//   // ── Search & Filter ──────────────────────────────────────────
//   Widget _buildSearchAndFilter() {
//     return Container(
//       color: AppColors.surface,
//       padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
//       child: Column(
//         children: [
//           // Search field
//           TextField(
//             controller: _searchCtrl,
//             style:
//                 const TextStyle(fontFamily: 'Poppins', fontSize: 14),
//             decoration: InputDecoration(
//               hintText: 'Search by farmer, purchase, reference...',
//               hintStyle: const TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 13,
//                   color: AppColors.textHint),
//               prefixIcon:
//                   const Icon(Icons.search_rounded, color: AppColors.textHint),
//               suffixIcon: _searchQuery.isNotEmpty
//                   ? IconButton(
//                       icon: const Icon(Icons.close_rounded,
//                           color: AppColors.textHint),
//                       onPressed: () {
//                         _searchCtrl.clear();
//                         setState(() => _searchQuery = '');
//                       },
//                     )
//                   : null,
//               filled: true,
//               fillColor: AppColors.surfaceVariant,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide.none,
//               ),
//               contentPadding:
//                   const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//             ),
//             onChanged: (v) => setState(() => _searchQuery = v),
//           ),

//           const SizedBox(height: 10),

//           // Payment mode chips
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: [
//                 _FilterChip(
//                   label: 'All',
//                   selected: _selectedMode == null,
//                   onTap: () => setState(() => _selectedMode = null),
//                 ),
//                 const SizedBox(width: 8),
//                 ...PaymentMode.values.map((mode) => Padding(
//                       padding: const EdgeInsets.only(right: 8),
//                       child: _FilterChip(
//                         label: mode.displayName,
//                         icon: mode.icon,
//                         selected: _selectedMode == mode,
//                         onTap: () => setState(() =>
//                             _selectedMode =
//                                 _selectedMode == mode ? null : mode),
//                       ),
//                     )),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Summary strip ────────────────────────────────────────────
//   Widget _buildSummaryStrip() {
//     final filtered = _filtered;
//     final total = filtered.fold(0.0, (s, p) => s + p.amount);
//     final cashAmt = filtered
//         .where((p) => p.paymentMode == PaymentMode.cash)
//         .fold(0.0, (s, p) => s + p.amount);
//     final upiAmt = filtered
//         .where((p) => p.paymentMode == PaymentMode.upi)
//         .fold(0.0, (s, p) => s + p.amount);
//     final chequeAmt = filtered
//         .where((p) => p.paymentMode == PaymentMode.cheque)
//         .fold(0.0, (s, p) => s + p.amount);

//     return Container(
//       margin: const EdgeInsets.all(12),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         gradient: AppColors.heroGradient,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primary.withOpacity(0.2),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // Total row
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Total Payments',
//                 style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 12,
//                     fontFamily: 'Poppins'),
//               ),
//               Text(
//                 '${filtered.length} transactions',
//                 style: const TextStyle(
//                     color: Colors.white54,
//                     fontSize: 11,
//                     fontFamily: 'Poppins'),
//               ),
//             ],
//           ),
//           const SizedBox(height: 4),
//           Align(
//             alignment: Alignment.centerLeft,
//             child: Text(
//               _formatAmount(total),
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 22,
//                 fontWeight: FontWeight.w800,
//                 fontFamily: 'Poppins',
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Container(height: 1, color: Colors.white.withOpacity(0.15)),
//           const SizedBox(height: 10),
//           // Breakdown row
//           Row(
//             children: [
//               _SummaryChip(
//                   icon: Icons.money_rounded,
//                   label: 'Cash',
//                   value: _formatAmount(cashAmt)),
//               const SizedBox(width: 8),
//               _SummaryChip(
//                   icon: Icons.qr_code_scanner_rounded,
//                   label: 'UPI',
//                   value: _formatAmount(upiAmt)),
//               const SizedBox(width: 8),
//               _SummaryChip(
//                   icon: Icons.description_rounded,
//                   label: 'Cheque',
//                   value: _formatAmount(chequeAmt)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Body ─────────────────────────────────────────────────────
//   Widget _buildBody() {
//     if (_loading) {
//       return const Center(
//           child: CircularProgressIndicator(color: AppColors.primary));
//     }

//     if (_error != null) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(32),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.cloud_off_rounded,
//                   size: 56, color: AppColors.textHint.withOpacity(0.5)),
//               const SizedBox(height: 16),
//               Text(
//                 _error!,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                     fontFamily: 'Poppins',
//                     fontSize: 13,
//                     color: AppColors.textSecondary),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton.icon(
//                 onPressed: () => _loadPayments(reset: true),
//                 icon: const Icon(Icons.refresh_rounded),
//                 label: const Text('Retry',
//                     style: TextStyle(fontFamily: 'Poppins')),
//                 style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primary,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10))),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     final list = _filtered;

//     if (list.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.receipt_long_rounded,
//                 size: 64,
//                 color: AppColors.textHint.withOpacity(0.4)),
//             const SizedBox(height: 16),
//             const Text(
//               'No payments found',
//               style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.textSecondary),
//             ),
//             const SizedBox(height: 6),
//             const Text(
//               'Try adjusting your filters',
//               style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 13,
//                   color: AppColors.textHint),
//             ),
//           ],
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: () => _loadPayments(reset: true),
//       color: AppColors.primary,
//       child: ListView.builder(
//         controller: _scrollCtrl,
//         padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
//         itemCount: list.length + (_loadingMore ? 1 : 0),
//         itemBuilder: (context, index) {
//           if (index == list.length) {
//             return const Padding(
//               padding: EdgeInsets.all(16),
//               child: Center(
//                 child: CircularProgressIndicator(
//                     color: AppColors.primary, strokeWidth: 2),
//               ),
//             );
//           }
//           return _PaymentCard(
//             payment: list[index],
//             formatAmount: _formatAmount,
//             timeAgo: _timeAgo,
//           );
//         },
//       ),
//     );
//   }
// }

// // ── Payment Card ──────────────────────────────────────────────
// class _PaymentCard extends StatelessWidget {
//   final PaymentModel payment;
//   final String Function(double) formatAmount;
//   final String Function(DateTime) timeAgo;

//   const _PaymentCard({
//     required this.payment,
//     required this.formatAmount,
//     required this.timeAgo,
//   });

//   Color get _modeColor {
//     switch (payment.paymentMode) {
//       case PaymentMode.cash:
//         return AppColors.success;
//       case PaymentMode.upi:
//         return const Color(0xFF5B4FCF);
//       case PaymentMode.bank:
//         return AppColors.info;
//       case PaymentMode.cheque:
//         return AppColors.warning;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: AppColors.border),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // ── Top row ──────────────────────────────────────
//             Row(
//               children: [
//                 // Mode icon badge
//                 Container(
//                   width: 42,
//                   height: 42,
//                   decoration: BoxDecoration(
//                     color: _modeColor.withOpacity(0.12),
//                     borderRadius: BorderRadius.circular(11),
//                   ),
//                   child: Icon(
//                     payment.paymentMode.icon,
//                     color: _modeColor,
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 12),

//                 // Purchase / farmer info
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Purchase: ${payment.purchaseId.length > 10 ? payment.purchaseId.substring(payment.purchaseId.length - 8) : payment.purchaseId}',
//                         style: const TextStyle(
//                           fontFamily: 'Poppins',
//                           fontSize: 13,
//                           fontWeight: FontWeight.w600,
//                           color: AppColors.textPrimary,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 7, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: _modeColor.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(6),
//                             ),
//                             child: Text(
//                               payment.paymentMode.displayName,
//                               style: TextStyle(
//                                 fontFamily: 'Poppins',
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.w600,
//                                 color: _modeColor,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 6),
//                           Text(
//                             timeAgo(payment.paymentDate),
//                             style: const TextStyle(
//                               fontFamily: 'Poppins',
//                               fontSize: 11,
//                               color: AppColors.textHint,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Amount
//                 Text(
//                   formatAmount(payment.amount),
//                   style: const TextStyle(
//                     fontFamily: 'Poppins',
//                     fontSize: 16,
//                     fontWeight: FontWeight.w800,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//               ],
//             ),

//             // ── Reference / cheque info ───────────────────────
//             if (payment.referenceNumber != null &&
//                 payment.referenceNumber!.isNotEmpty) ...[
//               const SizedBox(height: 10),
//               Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//                 decoration: BoxDecoration(
//                   color: AppColors.surfaceVariant,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.tag_rounded,
//                         size: 13, color: AppColors.textHint),
//                     const SizedBox(width: 6),
//                     Text(
//                       payment.paymentMode.referenceLabel,
//                       style: const TextStyle(
//                         fontFamily: 'Poppins',
//                         fontSize: 11,
//                         color: AppColors.textHint,
//                       ),
//                     ),
//                     const Spacer(),
//                     Text(
//                       payment.referenceNumber!,
//                       style: const TextStyle(
//                         fontFamily: 'Poppins',
//                         fontSize: 11,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.textPrimary,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],

//             // ── Cheque status badge ───────────────────────────
//             if (payment.chequeStatus != null) ...[
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: payment.chequeStatus!.color.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(6),
//                       border: Border.all(
//                           color:
//                               payment.chequeStatus!.color.withOpacity(0.3)),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Container(
//                           width: 6,
//                           height: 6,
//                           decoration: BoxDecoration(
//                             color: payment.chequeStatus!.color,
//                             shape: BoxShape.circle,
//                           ),
//                         ),
//                         const SizedBox(width: 6),
//                         Text(
//                           payment.chequeStatus!.displayName,
//                           style: TextStyle(
//                             fontFamily: 'Poppins',
//                             fontSize: 10,
//                             fontWeight: FontWeight.w600,
//                             color: payment.chequeStatus!.color,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ],

//             // ── Notes ─────────────────────────────────────────
//             if (payment.notes != null && payment.notes!.isNotEmpty) ...[
//               const SizedBox(height: 8),
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Icon(Icons.notes_rounded,
//                       size: 13, color: AppColors.textHint),
//                   const SizedBox(width: 6),
//                   Expanded(
//                     child: Text(
//                       payment.notes!,
//                       style: const TextStyle(
//                         fontFamily: 'Poppins',
//                         fontSize: 11,
//                         color: AppColors.textSecondary,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Filter Chip ───────────────────────────────────────────────
// class _FilterChip extends StatelessWidget {
//   final String label;
//   final IconData? icon;
//   final bool selected;
//   final VoidCallback onTap;

//   const _FilterChip({
//     required this.label,
//     required this.selected,
//     required this.onTap,
//     this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 160),
//         padding:
//             const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
//         decoration: BoxDecoration(
//           color: selected ? AppColors.primary : AppColors.surfaceVariant,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: selected
//                 ? AppColors.primary
//                 : AppColors.border,
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (icon != null) ...[
//               Icon(
//                 icon,
//                 size: 13,
//                 color: selected ? Colors.white : AppColors.textSecondary,
//               ),
//               const SizedBox(width: 5),
//             ],
//             Text(
//               label,
//               style: TextStyle(
//                 fontFamily: 'Poppins',
//                 fontSize: 12,
//                 fontWeight:
//                     selected ? FontWeight.w600 : FontWeight.w400,
//                 color:
//                     selected ? Colors.white : AppColors.textSecondary,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Summary Chip (inside gradient banner) ────────────────────
// class _SummaryChip extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;

//   const _SummaryChip({
//     required this.icon,
//     required this.label,
//     required this.value,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Container(
//         padding:
//             const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.12),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, color: Colors.white70, size: 14),
//             const SizedBox(height: 4),
//             Text(
//               value,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w700,
//                 fontFamily: 'Poppins',
//               ),
//             ),
//             Text(
//               label,
//               style: const TextStyle(
//                 color: Colors.white60,
//                 fontSize: 10,
//                 fontFamily: 'Poppins',
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// import 'package:agr_market/models/sale_model.dart';

// class SaleSummary {
//   final double totalRevenue;
//   final double totalGst;
//   final double totalPaid;
//   final double totalDue;
//   final int totalCount;
//   final int paidCount;
//   final int partialCount;
//   final int pendingCount;
 
//   const SaleSummary({
//     required this.totalRevenue,
//     required this.totalGst,
//     required this.totalPaid,
//     required this.totalDue,
//     required this.totalCount,
//     required this.paidCount,
//     required this.partialCount,
//     required this.pendingCount,
//   });
 
//   factory SaleSummary.fromJson(Map<String, dynamic> j) {
//     double toD(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
//     return SaleSummary(
//       totalRevenue: toD(j['totalRevenue']),
//       totalGst: toD(j['totalGst']),
//       totalPaid: toD(j['totalPaid']),
//       totalDue: toD(j['totalDue']),
//       totalCount: (j['totalCount'] as num?)?.toInt() ?? 0,
//       paidCount: (j['paidCount'] as num?)?.toInt() ?? 0,
//       partialCount: (j['partialCount'] as num?)?.toInt() ?? 0,
//       pendingCount: (j['pendingCount'] as num?)?.toInt() ?? 0,
//     );
//   }
 
//   /// Compute from a list of sales (when API doesn't return summary)
//   factory SaleSummary.fromSales(List<SaleModel> sales) {
//     double rev = 0, gst = 0, paid = 0, due = 0;
//     int paidC = 0, partC = 0, pendC = 0;
//     for (final s in sales) {
//       rev += s.totalAmount;
//       gst += s.gstAmount;
//       paid += s.amountPaid;
//       due += s.amountDue;
//       if (s.isPaid) paidC++;
//       else if (s.isPartial) partC++;
//       else pendC++;
//     }
//     return SaleSummary(
//       totalRevenue: rev,
//       totalGst: gst,
//       totalPaid: paid,
//       totalDue: due,
//       totalCount: sales.length,
//       paidCount: paidC,
//       partialCount: partC,
//       pendingCount: pendC,
//     );
//   }
// }
 
// // ── Profit/Loss Report Model ──────────────────────────────────
// class ProfitLossReport {
//   final DateTime periodStart;
//   final DateTime periodEnd;
 
//   // Revenue side (Sales)
//   final double totalSalesRevenue;
//   final double totalGstCollected;
//   final double netRevenue; // revenue - gst
 
//   // Cost side (Purchases from farmers)
//   final double totalPurchaseCost;
//   final double totalPurchaseDeductions; // transport, labour etc. already deducted
 
//   // Operating expenses
//   final double totalExpenses;
 
//   // Gross profit = netRevenue - totalPurchaseCost
//   double get grossProfit => netRevenue - totalPurchaseCost;
 
//   // Net profit = grossProfit - totalExpenses
//   double get netProfit => grossProfit - totalExpenses;
 
//   // Gross margin %
//   double get grossMarginPercent =>
//       netRevenue > 0 ? (grossProfit / netRevenue) * 100 : 0;
 
//   // Net margin %
//   double get netMarginPercent =>
//       netRevenue > 0 ? (netProfit / netRevenue) * 100 : 0;
 
//   bool get isProfit => netProfit >= 0;
 
//   const ProfitLossReport({
//     required this.periodStart,
//     required this.periodEnd,
//     required this.totalSalesRevenue,
//     required this.totalGstCollected,
//     required this.netRevenue,
//     required this.totalPurchaseCost,
//     required this.totalPurchaseDeductions,
//     required this.totalExpenses,
//   });
// }
 
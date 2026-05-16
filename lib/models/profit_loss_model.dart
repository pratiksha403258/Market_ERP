// profit_loss_model.dart
class ProfitLossReport {
  final double totalSales;
  final double totalGstCollected;
  final double netRevenue;
  final double totalPurchaseCost;
  final double totalPurchaseDeductions;
  final double totalExpenses;
  final double grossProfit;
  final double netProfit;
  final String profitMargin;
  final DateTime periodStart;
  final DateTime periodEnd;

  ProfitLossReport({
    required this.totalSales,
    required this.totalGstCollected,
    required this.netRevenue,
    required this.totalPurchaseCost,
    required this.totalPurchaseDeductions,
    required this.totalExpenses,
    required this.grossProfit,
    required this.netProfit,
    required this.profitMargin,
    required this.periodStart,
    required this.periodEnd,
  });

  factory ProfitLossReport.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>? ?? {};
    
    return ProfitLossReport(
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0.0,
      totalGstCollected: (json['totalGstCollected'] as num?)?.toDouble() ?? 0.0,
      netRevenue: (json['totalSales'] as num?)?.toDouble() ?? 0.0,
      totalPurchaseCost: (json['totalPurchases'] as num?)?.toDouble() ?? 0.0,
      totalPurchaseDeductions: (json['totalPurchaseDeductions'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      grossProfit: (json['grossProfit'] as num?)?.toDouble() ?? 0.0,
      netProfit: (json['netProfit'] as num?)?.toDouble() ?? 0.0,
      profitMargin: json['profitMargin']?.toString() ?? '0%',
      periodStart: DateTime.tryParse(period['startDate']?.toString() ?? '') ?? DateTime.now(),
      periodEnd: DateTime.tryParse(period['endDate']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
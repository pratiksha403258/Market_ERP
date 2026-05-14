// ─────────────────────────────────────────────────────────────
//  PROFIT / LOSS MODEL
//  Matches GET /api/reports/profit-loss response
// ─────────────────────────────────────────────────────────────

class ProfitLossReport {
  final DateTime periodStart;
  final DateTime periodEnd;

  // Revenue
  final double totalSalesRevenue;
  final double totalGstCollected;
  final double netRevenue;

  // Costs
  final double totalPurchaseCost;
  final double totalPurchaseDeductions;
  final double totalExpenses;

  // Computed by API
  final double grossProfit;
  final double netProfit;
  final String profitMargin;

  const ProfitLossReport({
    required this.periodStart,
    required this.periodEnd,
    required this.totalSalesRevenue,
    required this.totalGstCollected,
    required this.netRevenue,
    required this.totalPurchaseCost,
    required this.totalPurchaseDeductions,
    required this.totalExpenses,
    this.grossProfit = 0,
    this.netProfit = 0,
    this.profitMargin = '0%',
  });
}
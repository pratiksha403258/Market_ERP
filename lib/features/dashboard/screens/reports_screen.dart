// lib/reports/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:agr_market/core/constants/colors.dart';
import 'package:agr_market/services/report_service.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportService _reportService = ReportService.instance;

  int _selectedProductTab = 0;
  
  // Date range pickers
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  
  // Data
  Map<String, dynamic>? _profitLossData;
  Map<String, dynamic>? _inventorySummaryData;
  Map<String, dynamic>? _productPerformanceData;
  bool _loading = false;
  bool _loadingInventory = false;
  bool _loadingProducts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfitLoss();
    _loadInventorySummary();
    _loadProductPerformance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfitLoss() async {
    setState(() => _loading = true);
    try {
      final data = await _reportService.getProfitLoss(
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _profitLossData = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Failed to load P&L report: $e');
    }
  }

  Future<void> _loadInventorySummary() async {
    setState(() => _loadingInventory = true);
    try {
      final response = await _reportService.getInventorySummary(days: 90);
      setState(() {
        _inventorySummaryData = response;
        _loadingInventory = false;
      });
    } catch (e) {
      setState(() => _loadingInventory = false);
      _showError('Failed to load inventory summary: $e');
    }
  }

  Future<void> _loadProductPerformance() async {
    setState(() => _loadingProducts = true);
    try {
      final data = await _reportService.getProductPerformance(
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _productPerformanceData = data;
        _loadingProducts = false;
      });
    } catch (e) {
      setState(() => _loadingProducts = false);
      _showError('Failed to load product performance: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  // Fixed: Convert num to double safely
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _formatCurrency(dynamic value) {
    final doubleAmount = _toDouble(value);
    if (doubleAmount >= 10000000) return '₹${(doubleAmount / 10000000).toStringAsFixed(2)}Cr';
    if (doubleAmount >= 100000) return '₹${(doubleAmount / 100000).toStringAsFixed(2)}L';
    if (doubleAmount >= 1000) return '₹${(doubleAmount / 1000).toStringAsFixed(2)}K';
    return '₹${doubleAmount.toStringAsFixed(2)}';
  }

  String _formatNumber(dynamic value) {
    final numAmount = value is num ? value : 0;
    if (numAmount >= 10000000) return '${(numAmount / 10000000).toStringAsFixed(2)}Cr';
    if (numAmount >= 100000) return '${(numAmount / 100000).toStringAsFixed(2)}L';
    if (numAmount >= 1000) return '${(numAmount / 1000).toStringAsFixed(2)}K';
    return numAmount.toString();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        toolbarHeight: 60, // Reduce toolbar height
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40), // Reduce TabBar height
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textHint,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), // Smaller font
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(text: 'Profit & Loss', icon: Icon(Icons.show_chart_rounded, size: 18)),
              Tab(text: 'Inventory', icon: Icon(Icons.inventory_2_rounded, size: 18)),
              Tab(text: 'Products', icon: Icon(Icons.production_quantity_limits_rounded, size: 18)),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfitLossTab(),
          _buildInventoryTab(),
          _buildProductPerformanceTab(),
        ],
      ),
    );
  }

  Widget _buildProfitLossTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          // Date Range Selector
          _buildDateRangeSelector(onRefresh: () {
            _loadProfitLoss();
            _loadProductPerformance();
          }),
          const SizedBox(height: 16),
          
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (_profitLossData == null)
            const Center(child: Text('No data available'))
          else
            Column(
              children: [
                // Summary Cards
                _buildReportCard(
                  title: 'Period',
                  value: '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                  icon: Icons.calendar_today_rounded,
                  color: AppColors.info,
                ),
                const SizedBox(height: 12),
                
                _buildReportCard(
                  title: 'Total Sales',
                  value: _formatCurrency(_profitLossData?['totalSales']),
                  icon: Icons.shopping_cart_rounded,
                  color: AppColors.success,
                  subtitle: 'Revenue from sales',
                ),
                const SizedBox(height: 12),
                
                _buildReportCard(
                  title: 'Total Purchases',
                  value: _formatCurrency(_profitLossData?['totalPurchases']),
                  icon: Icons.add_shopping_cart_rounded,
                  color: AppColors.warning,
                  subtitle: 'Cost of goods purchased',
                ),
                const SizedBox(height: 12),
                
                _buildReportCard(
                  title: 'Total Expenses',
                  value: _formatCurrency(_profitLossData?['totalExpenses']),
                  icon: Icons.receipt_rounded,
                  color: AppColors.error,
                  subtitle: 'Operational expenses',
                ),
                const SizedBox(height: 12),
                
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _toDouble(_profitLossData?['netProfit']) >= 0 
                          ? [AppColors.success, AppColors.success.withOpacity(0.7)]
                          : [AppColors.error, AppColors.error.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Net Profit / Loss',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(_formatCurrency(_profitLossData?['netProfit']),
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Margin: ${_profitLossData?['profitMargin'] ?? '0%'}',
                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    final data = _inventorySummaryData?['data'] as List? ?? [];
    
    return RefreshIndicator(
      onRefresh: _loadInventorySummary,
      color: AppColors.primary,
      child: _loadingInventory
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : data.isEmpty
              ? const Center(child: Text('No inventory data available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    final recentMovements = item['recentMovements'] as List? ?? [];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.inventory, color: AppColors.primary),
                        ),
                        title: Text(item['productName'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                       subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      'Warehouse: ${item['warehouse'] ?? 'N/A'}',
      style: const TextStyle(fontSize: 12),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    ),
    const SizedBox(height: 4),
    Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _toDouble(item['currentStock']) > 0 
                ? AppColors.successSurface 
                : AppColors.warningSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Stock: ${_formatNumber(item['currentStock'])} ${item['unit'] ?? ''}',
            style: TextStyle(
              fontSize: 11,
              color: _toDouble(item['currentStock']) > 0 
                  ? AppColors.success 
                  : AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.infoSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Net Change: ${_formatNumber(item['netChange'])}',
            style: const TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  ],
),
                        children: [
                          if (recentMovements.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Divider(),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text('Recent Movements',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                            ...recentMovements.map((movement) => ListTile(
                                  leading: Icon(
                                    movement['movementType']?.toString().contains('ADD') == true 
                                        ? Icons.add_circle_outline 
                                        : Icons.remove_circle_outline,
                                    color: movement['movementType']?.toString().contains('ADD') == true 
                                        ? AppColors.success 
                                        : AppColors.error,
                                  ),
                                  title: Text(movement['movementType'] ?? 'Unknown',
                                      style: const TextStyle(fontSize: 14)),
                                  subtitle: Text(movement['reason'] ?? '',
                                      style: const TextStyle(fontSize: 12)),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${_formatNumber(movement['quantity'])} ${item['unit'] ?? ''}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: movement['movementType']?.toString().contains('ADD') == true 
                                                  ? AppColors.success 
                                                  : AppColors.error)),
                                      Text(
                                        DateFormat('dd MMM').format(DateTime.parse(movement['createdAt'] ?? DateTime.now().toIso8601String())),
                                        style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildProductPerformanceTab() {
    final purchased = _productPerformanceData?['purchased'] as List? ?? [];
    final sold = _productPerformanceData?['sold'] as List? ?? [];
    final currentStock = _productPerformanceData?['currentStock'] as List? ?? [];

    if (_loadingProducts) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Column(
      children: [
        // Compact tab buttons - reduced padding
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4), // Reduced top/bottom padding from 8 to 4
          child: Row(
            children: [
              _buildProductTabButton('Purchased', 0, Icons.add_shopping_cart),
              const SizedBox(width: 4), // Reduced from 6 to 4
              _buildProductTabButton('Sold', 1, Icons.shopping_cart_checkout),
              const SizedBox(width: 4),
              _buildProductTabButton('Stock', 2, Icons.inventory),
            ],
          ),
        ),
        const SizedBox(height: 4), // Reduced space between tabs and content
        Expanded(
          child: IndexedStack(
            index: _selectedProductTab,
            children: [
              _buildProductList(purchased, 'purchased'),
              _buildProductList(sold, 'sold'),
              _buildStockList(currentStock),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductTabButton(String label, int index, IconData icon) {
    final isSelected = _selectedProductTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedProductTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), // Increased from 5 to 8
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(10), // Increased from 8 to 10
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 16, // Increased from 13 to 16
              ),
              const SizedBox(width: 6), // Increased from 3 to 6
              Text(
                label,
                style: TextStyle(
                  fontSize: 13, // Increased from 10 to 13
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(List<dynamic> products, String type) {
  if (_loadingProducts) {
    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
  }
  
  if (products.isEmpty) {
    return const Center(child: Text('No data available'));
  }
  
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: products.length,
    itemBuilder: (context, index) {
      final product = products[index];
      final productName = product['_id'] ?? 'Unknown';
      final quantity = _formatNumber(product['totalQty']);
      final costOrRevenue = type == 'purchased' 
          ? 'Cost: ${_formatCurrency(product['totalCost'])}' 
          : 'Revenue: ${_formatCurrency(product['totalRevenue'])}';
      final avgValue = _formatCurrency(type == 'purchased' 
          ? (product['avgRate'] ?? 0) 
          : (product['avgPrice'] ?? 0));
      
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: type == 'purchased' ? AppColors.primarySurface : AppColors.successSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${product['count']} ${type == 'purchased' ? 'Purchases' : 'Sales'}',
                    style: TextStyle(
                      fontSize: 10, 
                      color: type == 'purchased' ? AppColors.primary : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity: $quantity',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        costOrRevenue,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 80),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Avg',
                        style: TextStyle(fontSize: 9, color: AppColors.textHint),
                      ),
                      Text(
                        avgValue,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
Widget _buildStockList(List<dynamic> stocks) {
  if (_loadingProducts) {
    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
  }
  
  if (stocks.isEmpty) {
    return const Center(child: Text('No stock data available'));
  }
  
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: stocks.length,
    itemBuilder: (context, index) {
      final stock = stocks[index];
      final stockValue = _formatNumber(stock['currentStock']);
      final unit = stock['unit'] ?? '';
      final displayText = '$stockValue $unit';
      
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            // Expanded wrapper for the middle column to take available space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stock['productName'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Warehouse: ${stock['warehouse'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Right column - fixed width to prevent overflow
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayText,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Updated: ${DateFormat('dd MMM').format(DateTime.parse(stock['lastUpdated'] ?? DateTime.now().toIso8601String()))}',
                    style: const TextStyle(fontSize: 9, color: AppColors.textHint),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
  Widget _buildDateRangeSelector({required VoidCallback onRefresh}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _startDate = date);
                  onRefresh();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(DateFormat('dd MMM yyyy').format(_startDate)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 16, color: AppColors.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _endDate = date);
                  onRefresh();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(DateFormat('dd MMM yyyy').format(_endDate)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textHint)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
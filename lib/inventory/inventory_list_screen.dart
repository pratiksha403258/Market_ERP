import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../services/inventory_service.dart';
import '../../../models/inventory_model.dart';
import 'adjust_stock_screen.dart';
import 'transfer_stock_screen.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final InventoryService _service = InventoryService.instance;
  List<InventoryItem> _items = [];
  bool _loading = true;
  String _searchQuery = '';
  String? _selectedWarehouse;
  bool _lowStockOnly = false;
  List<String> _warehouses = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final items = await _service.getInventory(
        warehouse: _selectedWarehouse,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        lowStock: _lowStockOnly,
      );
      final warehouses = await _service.getWarehouseNames();
      setState(() {
        _items = items;
        _warehouses = warehouses;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnackBar('Failed to load inventory: $e', isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showActionSheet(InventoryItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: AppColors.success),
              title: const Text('Add Stock'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAdjust(item, true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: AppColors.error),
              title: const Text('Remove Stock'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAdjust(item, false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: AppColors.primary),
              title: const Text('Transfer to Another Warehouse'),
              onTap: () {
                Navigator.pop(context);
                _navigateToTransfer(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAdjust(InventoryItem item, bool isAdd) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdjustStockScreen(
          productName: item.productName,
          currentWarehouse: item.warehouse,
          isAdd: isAdd,
        ),
      ),
    );
    if (result == true) _loadData();
  }

  void _navigateToTransfer(InventoryItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransferStockScreen(
          productName: item.productName,
          fromWarehouse: item.warehouse,
        ),
      ),
    );
    if (result == true) _loadData();
  }

  String _formatStock(double qty, String unit) {
    if (qty >= 1000) return '${(qty / 1000).toStringAsFixed(1)}K $unit';
    return '${qty.toStringAsFixed(2)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      const Text('Inventory', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text('${_items.length}', style: const TextStyle(color: Colors.white)),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // Search
                    TextField(
                      controller: _searchController,
                      onChanged: (v) {
                        setState(() => _searchQuery = v);
                        _loadData();
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by product name...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  _loadData();
                                },
                                child: const Icon(Icons.close, color: Colors.white70),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Filters row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        // Warehouse dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedWarehouse,
                              hint: const Text('All Warehouses', style: TextStyle(color: Colors.white70)),
                              dropdownColor: AppColors.surface,
                              style: const TextStyle(color: AppColors.textPrimary),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                              onChanged: (val) {
                                setState(() => _selectedWarehouse = val);
                                _loadData();
                              },
                              items: [
                                const DropdownMenuItem(value: null, child: Text('All Warehouses')),
                                ..._warehouses.map((w) => DropdownMenuItem(value: w, child: Text(w))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Low stock toggle
                        GestureDetector(
                          onTap: () {
                            setState(() => _lowStockOnly = !_lowStockOnly);
                            _loadData();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _lowStockOnly ? Colors.orange : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: _lowStockOnly ? Colors.white : Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              Text('Low Stock',
                                  style: TextStyle(color: _lowStockOnly ? Colors.white : Colors.white70)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _items.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          itemBuilder: (ctx, i) => _InventoryCard(
                            item: _items[i],
                            formatStock: _formatStock,
                            onTap: () => _showActionSheet(_items[i]),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textHint),
      const SizedBox(height: 16),
      Text(_searchQuery.isNotEmpty ? 'No matching products' : 'No inventory items',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      const Text('Stock will appear after purchases or adjustments',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textHint)),
    ]),
  );
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final String Function(double, String) formatStock;
  final VoidCallback onTap;

  const _InventoryCard({required this.item, required this.formatStock, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.isLowStock ? AppColors.warning : AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.productName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(item.warehouse,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),
            if (item.isLowStock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.warningSurface, borderRadius: BorderRadius.circular(12)),
                child: const Text('Low Stock',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning)),
              ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.inventory, size: 14, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(formatStock(item.currentStock, item.unit),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textHint),
          ]),
        ]),
      ),
    );
  }
}
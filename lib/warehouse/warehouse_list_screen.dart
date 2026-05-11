import 'package:agr_market/warehouse/edit_warehouse_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../services/warehouse_service.dart';
import '../../../models/warehouse_model.dart';

class WarehouseListScreen extends StatefulWidget {
  const WarehouseListScreen({super.key});

  @override
  State<WarehouseListScreen> createState() => _WarehouseListScreenState();
}

class _WarehouseListScreenState extends State<WarehouseListScreen> {
  final WarehouseService _service = WarehouseService.instance;
  List<WarehouseModel> _warehouses = [];
  bool _loading = true;
  String _searchQuery = '';
  bool? _activeFilter; // null = all, true = active, false = inactive
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWarehouses() async {
    setState(() => _loading = true);
    try {
      final warehouses = await _service.getAll(
        isActive: _activeFilter,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      setState(() {
        _warehouses = warehouses;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnackBar('Failed to load warehouses: $e', isError: true);
    }
  }

  Future<void> _deleteWarehouse(WarehouseModel warehouse) async {
    // First check if warehouse is empty via API
    final bool isEmpty = await _service.isWarehouseEmpty(warehouse.id);
    
    String content = isEmpty
        ? 'This warehouse is empty and can be permanently deleted. Are you sure?'
        : 'This warehouse contains inventory. Deleting will mark it as inactive (soft delete). Are you sure?';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEmpty ? 'Permanently Delete Warehouse' : 'Deactivate Warehouse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content),
            if (!isEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Soft deleted warehouses can be restored later',
                        style: TextStyle(fontSize: 12, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isEmpty ? AppColors.error : AppColors.warning,
            ),
            child: Text(isEmpty ? 'Permanently Delete' : 'Deactivate'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      final result = await _service.delete(warehouse.id);
      
      final action = result['action'];
      final message = result['message'];
      
      if (action == 'hard_delete') {
        _showSnackBar('Warehouse permanently deleted', isError: false);
      } else {
        _showSnackBar('Warehouse deactivated (soft delete)', isError: false);
      }
      
      _loadWarehouses();
    } catch (e) {
      setState(() => _loading = false);
      _showSnackBar('Delete failed: $e', isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditWarehouseScreen()),
          );
          if (result == true) _loadWarehouses();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Warehouse'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Gradient header with search and filters
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.warehouse_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      const Text('Warehouses', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text('${_warehouses.length}', style: const TextStyle(color: Colors.white)),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // Search field
                    TextField(
                      controller: _searchController,
                      onChanged: (v) {
                        setState(() => _searchQuery = v);
                        _loadWarehouses();
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by name or code...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  _loadWarehouses();
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
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        _FilterChip(label: 'All', active: _activeFilter == null, onTap: () => _setActiveFilter(null)),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Active', active: _activeFilter == true, onTap: () => _setActiveFilter(true), color: AppColors.success),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Inactive', active: _activeFilter == false, onTap: () => _setActiveFilter(false), color: AppColors.textHint),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // List content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadWarehouses,
              color: AppColors.primary,
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _warehouses.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _warehouses.length,
                          itemBuilder: (ctx, i) => _WarehouseCard(
                            warehouse: _warehouses[i],
                            onDelete: () => _deleteWarehouse(_warehouses[i]),
                            onEdit: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddEditWarehouseScreen(warehouse: _warehouses[i]),
                                ),
                              );
                              if (result == true) _loadWarehouses();
                            },
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  void _setActiveFilter(bool? value) {
    if (_activeFilter == value) return;
    setState(() => _activeFilter = value);
    _loadWarehouses();
  }

  Widget _buildEmptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.warehouse_outlined, size: 64, color: AppColors.textHint),
      const SizedBox(height: 16),
      Text(_searchQuery.isNotEmpty ? 'No matching warehouses' : 'No warehouses yet',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      const Text('Tap + to add your first warehouse', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textHint)),
    ]),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? color;
  const _FilterChip({required this.label, required this.active, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final bgColor = active ? (color ?? AppColors.primary) : AppColors.surfaceVariant;
    final textColor = active ? Colors.white : (color ?? AppColors.primary);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(30), border: Border.all(color: (color ?? AppColors.primary).withOpacity(0.3))),
        child: Text(label, style: TextStyle(color: textColor, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  final WarehouseModel warehouse;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _WarehouseCard({required this.warehouse, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final location = warehouse.location;
    final city = location['city']?.toString() ?? 'N/A';
    final capacity = warehouse.capacity;
    final capacityStr = '${capacity['total']} ${capacity['unit']}';
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(warehouse.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('Code: ${warehouse.code}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: warehouse.isActive ? AppColors.successSurface : AppColors.errorSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(warehouse.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: warehouse.isActive ? AppColors.success : AppColors.error)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.location_city, size: 14, color: AppColors.textHint),
            const SizedBox(width: 4),
            Expanded(child: Text('City: $city', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.area_chart, size: 14, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text('Capacity: $capacityStr', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ]),
      ),
    );
  }
}
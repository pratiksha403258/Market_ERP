import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../services/inventory_service.dart';

class TransferStockScreen extends StatefulWidget {
  final String productName;
  final String fromWarehouse;

  const TransferStockScreen({
    super.key,
    required this.productName,
    required this.fromWarehouse,
  });

  @override
  State<TransferStockScreen> createState() => _TransferStockScreenState();
}

class _TransferStockScreenState extends State<TransferStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  String? _selectedToWarehouse;
  List<String> _warehouses = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    final all = await InventoryService.instance.getWarehouseNames();
    setState(() {
      _warehouses = all.where((w) => w != widget.fromWarehouse).toList();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      _showSnackBar('Enter valid quantity', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await InventoryService.instance.transferStock(
        productName: widget.productName,
        fromWarehouse: widget.fromWarehouse,
        toWarehouse: _selectedToWarehouse!,
        qty: qty,
      );
      if (mounted) {
        _showSnackBar('Transfer successful');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _loading = false);
      _showSnackBar('Transfer failed: $e', isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Transfer Stock'), elevation: 0),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                _infoRow('Product', widget.productName),
                const SizedBox(height: 8),
                _infoRow('From Warehouse', widget.fromWarehouse),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _qtyController,
              label: 'Quantity to Transfer *',
              hint: 'Enter quantity',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('To Warehouse *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedToWarehouse,
                    hint: const Text('Select warehouse'),
                    isExpanded: true,
                    onChanged: (v) => setState(() => _selectedToWarehouse = v),
                    items: _warehouses.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Transfer Stock'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ],
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    ]);
  }
}
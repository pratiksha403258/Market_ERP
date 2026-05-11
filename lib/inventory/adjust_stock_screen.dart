import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../services/inventory_service.dart';

class AdjustStockScreen extends StatefulWidget {
  final String productName;
  final String currentWarehouse;
  final bool isAdd;

  const AdjustStockScreen({
    super.key,
    required this.productName,
    required this.currentWarehouse,
    required this.isAdd,
  });

  @override
  State<AdjustStockScreen> createState() => _AdjustStockScreenState();
}

class _AdjustStockScreenState extends State<AdjustStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      _showSnackBar('Enter a valid quantity', isError: true);
      return;
    }
    final adjustment = widget.isAdd ? qty : -qty;
    setState(() => _loading = true);
    try {
      await InventoryService.instance.adjustStock(
        productName: widget.productName,
        warehouse: widget.currentWarehouse,
        adjustment: adjustment,
        reason: _reasonController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (mounted) {
        _showSnackBar(widget.isAdd ? 'Stock added successfully' : 'Stock removed successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _loading = false);
      _showSnackBar('Failed: $e', isError: true);
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
      appBar: AppBar(
        title: Text(widget.isAdd ? 'Add Stock' : 'Remove Stock'),
        elevation: 0,
      ),
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
                _infoRow('Warehouse', widget.currentWarehouse),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _qtyController,
              label: 'Quantity *',
              hint: widget.isAdd ? 'Enter quantity to add' : 'Enter quantity to remove',
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _reasonController,
              label: 'Reason *',
              hint: 'e.g., Physical count correction, Damaged goods',
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _notesController,
              label: 'Notes (Optional)',
              hint: 'Additional details',
              maxLines: 2,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.isAdd ? 'Add Stock' : 'Remove Stock'),
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator,
      ),
    ]);
  }
}
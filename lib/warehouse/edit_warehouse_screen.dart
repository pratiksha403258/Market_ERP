import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../services/warehouse_service.dart';
import '../../../models/warehouse_model.dart';

class AddEditWarehouseScreen extends StatefulWidget {
  final WarehouseModel? warehouse;
  const AddEditWarehouseScreen({super.key, this.warehouse});

  @override
  State<AddEditWarehouseScreen> createState() => _AddEditWarehouseScreenState();
}

class _AddEditWarehouseScreenState extends State<AddEditWarehouseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _managerNameCtrl = TextEditingController();
  final _managerPhoneCtrl = TextEditingController();
  final _managerEmailCtrl = TextEditingController();
  final _capacityTotalCtrl = TextEditingController();
  final _capacityUsedCtrl = TextEditingController();
  final _capacityUnitCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.warehouse != null) {
      final w = widget.warehouse!;
      _nameCtrl.text = w.name;
      _codeCtrl.text = w.code;
      _addressCtrl.text = w.location['address'] ?? '';
      _cityCtrl.text = w.location['city'] ?? '';
      _stateCtrl.text = w.location['state'] ?? '';
      _pincodeCtrl.text = w.location['pincode'] ?? '';
      _managerNameCtrl.text = w.manager['name'] ?? '';
      _managerPhoneCtrl.text = w.manager['phone'] ?? '';
      _managerEmailCtrl.text = w.manager['email'] ?? '';
      _capacityTotalCtrl.text = (w.capacity['total'] ?? 0).toString();
      _capacityUsedCtrl.text = (w.capacity['used'] ?? 0).toString();
      _capacityUnitCtrl.text = w.capacity['unit'] ?? 'sq ft';
      _notesCtrl.text = w.notes;
      _isActive = w.isActive;
    } else {
      _capacityUnitCtrl.text = 'sq ft';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _managerNameCtrl.dispose();
    _managerPhoneCtrl.dispose();
    _managerEmailCtrl.dispose();
    _capacityTotalCtrl.dispose();
    _capacityUsedCtrl.dispose();
    _capacityUnitCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'code': _codeCtrl.text.trim(),
      'location': {
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
      },
      'manager': {
        'name': _managerNameCtrl.text.trim(),
        'phone': _managerPhoneCtrl.text.trim(),
        'email': _managerEmailCtrl.text.trim(),
      },
      'capacity': {
        'total': int.tryParse(_capacityTotalCtrl.text) ?? 0,
        'used': int.tryParse(_capacityUsedCtrl.text) ?? 0,
        'unit': _capacityUnitCtrl.text.trim(),
      },
      'notes': _notesCtrl.text.trim(),
      'isActive': _isActive,
    };

    try {
      if (widget.warehouse == null) {
        await WarehouseService.instance.create(data);
      } else {
        await WarehouseService.instance.update(widget.warehouse!.id, data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Warehouse saved successfully'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.warehouse != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Warehouse' : 'Add Warehouse'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _section('Basic Info', [
              _buildTextField(_nameCtrl, 'Warehouse Name *', Icons.warehouse),
              _buildTextField(_codeCtrl, 'Warehouse Code *', Icons.code),
            ]),
            const SizedBox(height: 16),
            _section('Location', [
              _buildTextField(_addressCtrl, 'Address', Icons.location_on),
              _buildTextField(_cityCtrl, 'City', Icons.location_city),
              _buildTextField(_stateCtrl, 'State', Icons.map),
              _buildTextField(_pincodeCtrl, 'Pincode', Icons.mail, keyboardType: TextInputType.number),
            ]),
            const SizedBox(height: 16),
            _section('Manager Details', [
              _buildTextField(_managerNameCtrl, 'Manager Name', Icons.person),
              _buildTextField(_managerPhoneCtrl, 'Phone', Icons.phone, keyboardType: TextInputType.phone),
              _buildTextField(_managerEmailCtrl, 'Email', Icons.email, keyboardType: TextInputType.emailAddress),
            ]),
            const SizedBox(height: 16),
            _section('Capacity', [
              _buildTextField(_capacityTotalCtrl, 'Total Capacity', Icons.storage, keyboardType: TextInputType.number),
              _buildTextField(_capacityUsedCtrl, 'Used Capacity', Icons.speed, keyboardType: TextInputType.number),
              _buildTextField(_capacityUnitCtrl, 'Unit (e.g., KG, sq ft)', Icons.abc),
            ]),
            const SizedBox(height: 16),
            _section('Additional', [
              _buildTextField(_notesCtrl, 'Notes', Icons.note, maxLines: 2),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeColor: AppColors.success,
              ),
            ]),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(isEdit ? 'Update Warehouse' : 'Create Warehouse'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ),
      ...children,
    ]),
  );

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontFamily: 'Poppins'),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (label.contains('*') && (value == null || value.isEmpty)) return 'Required';
          return null;
        },
      ),
    );
  }
}
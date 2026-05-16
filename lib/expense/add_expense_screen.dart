// add_expense_screen.dart
import 'package:agr_market/services/expense_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _descriptionController = TextEditingController();
  final _paidToController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  // Selected values
  String _selectedCategory = ExpenseCategory.all.first['value']!;
  double _amount = 0;
  DateTime _expenseDate = DateTime.now();
  String _selectedPaidBy = 'cash';

  // Loading state
  bool _isSubmitting = false;

  // Category dropdown items (without icons)
  List<DropdownMenuItem<String>> get _categoryItems {
    final validCategories = ExpenseCategory.all
        .where((category) =>
            category != null &&
            category['value'] != null &&
            category['label'] != null)
        .toList();

    if (validCategories.isEmpty) {
      return [
        const DropdownMenuItem<String>(
          value: '',
          child: Text('No categories available'),
        ),
      ];
    }

    return validCategories.map((category) {
      return DropdownMenuItem<String>(
        value: category['value']!,
        child: Text(
          category['label']!,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        ),
      );
    }).toList();
  }

  // Payment method items
  final List<Map<String, dynamic>> _paymentMethods = [
    {'value': 'cash', 'label': 'Cash', 'icon': Icons.money_rounded},
    {'value': 'upi', 'label': 'UPI', 'icon': Icons.qr_code_scanner_rounded},
    {
      'value': 'bank',
      'label': 'Bank Transfer',
      'icon': Icons.account_balance_rounded
    },
    {'value': 'cheque', 'label': 'Cheque', 'icon': Icons.receipt_rounded},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _paidToController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _expenseDate) {
      setState(() => _expenseDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_amount <= 0) {
      _showSnackBar('Please enter a valid amount', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ExpenseService.instance.createExpense(
      category: _selectedCategory,
      amount: _amount,
      description: _descriptionController.text.trim(),
      expenseDate: _expenseDate,
      paidBy: _selectedPaidBy,
      paidTo: _paidToController.text.trim().isEmpty
          ? null
          : _paidToController.text.trim(),
      referenceNumber: _referenceController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      _showSnackBar('Expense added successfully', isError: false);
      Navigator.pop(context, true);
    } else {
      _showSnackBar(result.message ?? 'Failed to add expense', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 6, right: 6, bottom: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Expense'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Card
              _buildSectionCard(
                title: 'Amount *',
                icon: Icons.currency_rupee_rounded,
                child: TextFormField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                    hintText: '0.00',
                    border: InputBorder.none,
                    filled: false,
                  ),
                  onChanged: (value) {
                    _amount = double.tryParse(value) ?? 0;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final amt = double.tryParse(value);
                    if (amt == null || amt <= 0) return 'Enter valid amount';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              _buildSectionCard(
                title: 'Category *',
                icon: Icons.category_rounded,
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categoryItems,
                  decoration: const InputDecoration(border: InputBorder.none),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedCategory = value);
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Description
              _buildSectionCard(
                title: 'Description *',
                icon: Icons.description_rounded,
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Truck transportation from farm to market',
                    border: InputBorder.none,
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Description required' : null,
                ),
              ),
              const SizedBox(height: 16),

              // Date and Payment Method Row
              Row(
                children: [
                  Expanded(
                    child: _buildSectionCard(
                      title: 'Date *',
                      icon: Icons.calendar_today_rounded,
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(_expenseDate),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSectionCard(
                      title: 'Paid By *',
                      icon: Icons.payment_rounded,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPaidBy,
                          isExpanded: true,
                          items: _paymentMethods.map((method) {
                            return DropdownMenuItem<String>(
                              value: method['value'],
                              child: Row(
                                children: [
                                  Icon(method['icon'],
                                      size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    method['label'],
                                    style: const TextStyle(
                                        fontFamily: 'Poppins'),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _selectedPaidBy = value);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Paid To (Optional)
              _buildSectionCard(
                title: 'Paid To (Optional)',
                icon: Icons.business_rounded,
                child: TextFormField(
                  controller: _paidToController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Sharma Transport Co.',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reference Number (Required with validation)
              _buildSectionCard(
                title: 'Reference Number *',
                icon: Icons.numbers_rounded,
                child: TextFormField(
                  controller: _referenceController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: 'e.g., TRANS123456',
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Reference number is required';
                    }
                    // Allow only alphanumeric, hyphen, underscore (basic pattern)
                    final RegExp alphanumericRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
                    if (!alphanumericRegex.hasMatch(value.trim())) {
                      return 'Use only letters, numbers, - or _';
                    }
                    if (value.trim().length < 3) {
                      return 'Minimum 3 characters';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Notes (Optional)
              _buildSectionCard(
                title: 'Notes (Optional)',
                icon: Icons.note_alt_rounded,
                child: TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Additional details...',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Add Expense',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
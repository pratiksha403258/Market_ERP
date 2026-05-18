// import 'package:agr_market/services/expense_service.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../../core/constants/colors.dart';

// class EditExpenseScreen extends StatefulWidget {
//   final ExpenseModel expense;
//   const EditExpenseScreen({super.key, required this.expense});

//   @override
//   State<EditExpenseScreen> createState() => _EditExpenseScreenState();
// }

// class _EditExpenseScreenState extends State<EditExpenseScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late String _selectedCategory;
//   late double _amount;
//   late DateTime _expenseDate;
//   late String _selectedPaidBy;
//   late TextEditingController _descriptionController;
//   late TextEditingController _paidToController;
//   late TextEditingController _referenceController;
//   late TextEditingController _notesController;
//   bool _isSubmitting = false;

//   final List<Map<String, dynamic>> _paymentMethods = [
//     {'value': 'cash', 'label': 'Cash', 'icon': Icons.money_rounded},
//     {'value': 'upi', 'label': 'UPI', 'icon': Icons.qr_code_scanner_rounded},
//     {'value': 'bank', 'label': 'Bank Transfer', 'icon': Icons.account_balance_rounded},
//     {'value': 'cheque', 'label': 'Cheque', 'icon': Icons.receipt_rounded},
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _selectedCategory = widget.expense.category;
//     _amount = widget.expense.amount;
//     _expenseDate = widget.expense.expenseDate;
//     _selectedPaidBy = widget.expense.paidBy;
//     _descriptionController = TextEditingController(text: widget.expense.description);
//     _paidToController = TextEditingController(text: widget.expense.paidTo);
//     _referenceController = TextEditingController(text: widget.expense.referenceNumber);
//     _notesController = TextEditingController(text: widget.expense.notes);
//   }

//   @override
//   void dispose() {
//     _descriptionController.dispose();
//     _paidToController.dispose();
//     _referenceController.dispose();
//     _notesController.dispose();
//     super.dispose();
//   }

//   List<DropdownMenuItem<String>> get _categoryItems {
//     return ExpenseCategory.all.map((c) => DropdownMenuItem<String>(
//       value: c['value']!,
//       child: Text(c['label']!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
//     )).toList();
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _expenseDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//       builder: (ctx, child) => Theme(
//         data: Theme.of(ctx).copyWith(
//           colorScheme: ColorScheme.light(primary: AppColors.primary),
//         ),
//         child: child!,
//       ),
//     );
//     if (picked != null && picked != _expenseDate) setState(() => _expenseDate = picked);
//   }

//   Future<void> _submitUpdate() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (_amount <= 0) {
//       _showSnackBar('Please enter a valid amount', isError: true);
//       return;
//     }

//     setState(() => _isSubmitting = true);

//     final result = await ExpenseService.instance.updateExpense(
//       id: widget.expense.id,
//       category: _selectedCategory,
//       amount: _amount,
//       description: _descriptionController.text.trim(),
//       expenseDate: _expenseDate,
//       paidBy: _selectedPaidBy,
//       paidTo: _paidToController.text.trim().isEmpty ? null : _paidToController.text.trim(),
//       referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
//       notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
//     );

//     setState(() => _isSubmitting = false);

//     if (result.isSuccess) {
//       _showSnackBar('Expense updated successfully', isError: false);
//       Navigator.pop(context, true);
//     } else {
//       _showSnackBar(result.message ?? 'Failed to update expense', isError: true);
//     }
//   }

//   void _showSnackBar(String message, {bool isError = false}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
//       backgroundColor: isError ? AppColors.error : AppColors.success,
//       behavior: SnackBarBehavior.floating,
//       margin: const EdgeInsets.only(left: 6, right: 6, bottom: 2),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//     ));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: const Text('Edit Expense'),
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         foregroundColor: AppColors.textPrimary,
//       ),
//       body: Form(
//         key: _formKey,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             _buildSectionCard(
//               title: 'Amount *',
//               icon: Icons.currency_rupee_rounded,
//               child: TextFormField(
//                 initialValue: _amount.toString(),
//                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                 style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//                 decoration: const InputDecoration(
//                   prefixText: '₹ ',
//                   prefixStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//                   hintText: '0.00',
//                   border: InputBorder.none,
//                 ),
//                 onChanged: (v) => _amount = double.tryParse(v) ?? 0,
//                 validator: (v) => (v == null || v.isEmpty) ? 'Required' : (double.tryParse(v) ?? 0) <= 0 ? 'Enter valid amount' : null,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildSectionCard(
//               title: 'Category *',
//               icon: Icons.category_rounded,
//               child: DropdownButtonFormField<String>(
//                 value: _selectedCategory,
//                 items: _categoryItems,
//                 decoration: const InputDecoration(border: InputBorder.none),
//                 onChanged: (v) => setState(() => _selectedCategory = v!),
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildSectionCard(
//               title: 'Description *',
//               icon: Icons.description_rounded,
//               child: TextFormField(
//                 controller: _descriptionController,
//                 maxLines: 2,
//                 decoration: const InputDecoration(hintText: 'e.g., Truck transportation', border: InputBorder.none),
//                 validator: (v) => v == null || v.isEmpty ? 'Description required' : null,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(children: [
//               Expanded(
//                 child: _buildSectionCard(
//                   title: 'Date *',
//                   icon: Icons.calendar_today_rounded,
//                   child: InkWell(
//                     onTap: () => _selectDate(context),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       child: Text(DateFormat('dd MMM yyyy').format(_expenseDate),
//                           style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500)),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildSectionCard(
//                   title: 'Paid By *',
//                   icon: Icons.payment_rounded,
//                   child: DropdownButtonHideUnderline(
//                     child: DropdownButton<String>(
//                       value: _selectedPaidBy,
//                       isExpanded: true,
//                       items: _paymentMethods.map<DropdownMenuItem<String>>((m) => DropdownMenuItem<String>(
//                         value: m['value'] as String,
//                         child: Row(children: [Icon(m['icon'], size: 18, color: AppColors.primary), const SizedBox(width: 8), Text(m['label'], style: const TextStyle(fontFamily: 'Poppins'))]),
//                       )).toList(),
//                       onChanged: (v) => setState(() => _selectedPaidBy = v!),
//                     ),
//                   ),
//                 ),
//               ),
//             ]),
//             const SizedBox(height: 16),
//             _buildSectionCard(
//               title: 'Paid To (Optional)',
//               icon: Icons.business_rounded,
//               child: TextFormField(
//                 controller: _paidToController,
//                 decoration: const InputDecoration(hintText: 'e.g., Sharma Transport Co.', border: InputBorder.none),
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildSectionCard(
//               title: 'Reference Number',
//               icon: Icons.numbers_rounded,
//               child: TextFormField(
//                 controller: _referenceController,
//                 decoration: const InputDecoration(hintText: 'e.g., TRANS123456', border: InputBorder.none),
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildSectionCard(
//               title: 'Notes (Optional)',
//               icon: Icons.note_alt_rounded,
//               child: TextFormField(
//                 controller: _notesController,
//                 maxLines: 2,
//                 decoration: const InputDecoration(hintText: 'Additional details...', border: InputBorder.none),
//               ),
//             ),
//             const SizedBox(height: 32),
//             SizedBox(
//               width: double.infinity,
//               height: 56,
//               child: ElevatedButton(
//                 onPressed: _isSubmitting ? null : _submitUpdate,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                 ),
//                 child: _isSubmitting
//                     ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
//                     : const Text('Update Expense', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ]),
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppColors.border),
//         boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
//       ),
//       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
//           child: Row(children: [Icon(icon, size: 18, color: AppColors.primary), const SizedBox(width: 8), Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary))]),
//         ),
//         Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child),
//         const SizedBox(height: 8),
//       ]),
//     );
//   }
// }


// edit_expense_screen.dart
import 'package:agr_market/services/expense_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../providers/language_provider.dart';

class EditExpenseScreen extends StatefulWidget {
  final ExpenseModel expense;
  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  late String   _selectedCategory;
  late double   _amount;
  late DateTime _expenseDate;
  late String   _selectedPaidBy;
  late TextEditingController _descriptionController;
  late TextEditingController _paidToController;
  late TextEditingController _referenceController;
  late TextEditingController _notesController;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'value': 'cash',   'labelKey': 'pm_cash',   'icon': Icons.money_rounded},
    {'value': 'upi',    'labelKey': 'pm_upi',    'icon': Icons.qr_code_scanner_rounded},
    {'value': 'bank',   'labelKey': 'pm_bank',   'icon': Icons.account_balance_rounded},
    {'value': 'cheque', 'labelKey': 'pm_cheque', 'icon': Icons.receipt_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory    = widget.expense.category;
    _amount              = widget.expense.amount;
    _expenseDate         = widget.expense.expenseDate;
    _selectedPaidBy      = widget.expense.paidBy;
    _descriptionController = TextEditingController(text: widget.expense.description);
    _paidToController      = TextEditingController(text: widget.expense.paidTo);
    _referenceController   = TextEditingController(text: widget.expense.referenceNumber);
    _notesController       = TextEditingController(text: widget.expense.notes);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _paidToController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> _categoryItems(LanguageProvider lang) {
    return ExpenseCategory.all.map((c) => DropdownMenuItem<String>(
      value: c['value']!,
      child: Text(
        lang.t('cat_${c['value']}').startsWith('cat_') ? c['label']! : lang.t('cat_${c['value']}'),
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
      ),
    )).toList();
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

  Future<void> _submitUpdate(LanguageProvider lang) async {
    if (!_formKey.currentState!.validate()) return;
    if (_amount <= 0) {
      _showSnackBar(lang.t('enter_valid_amount'), isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ExpenseService.instance.updateExpense(
      id:              widget.expense.id,
      category:        _selectedCategory,
      amount:          _amount,
      description:     _descriptionController.text.trim(),
      expenseDate:     _expenseDate,
      paidBy:          _selectedPaidBy,
      paidTo:          _paidToController.text.trim().isEmpty ? null : _paidToController.text.trim(),
      referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
      notes:           _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      _showSnackBar(lang.t('expense_updated'), isError: false);
      Navigator.pop(context, true);
    } else {
      _showSnackBar(result.message ?? lang.t('expense_update_failed'), isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(left: 6, right: 6, bottom: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // ✅ listen: true — rebuilds on language change
    final lang = Provider.of<LanguageProvider>(context, listen: true);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // ✅ translated title
        title: Text(lang.t('edit_expense')),
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
              // ── Amount ────────────────────────────────────
              _buildSectionCard(
                title: lang.t('amount_required'),
                icon: Icons.currency_rupee_rounded,
                child: TextFormField(
                  initialValue: _amount.toString(),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    hintText: '0.00',
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => _amount = double.tryParse(v) ?? 0,
                  validator: (v) {
                    if (v == null || v.isEmpty) return lang.t('required_field');
                    if ((double.tryParse(v) ?? 0) <= 0)
                      return lang.t('enter_valid_amount');
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // ── Category ──────────────────────────────────
              _buildSectionCard(
                title: lang.t('category_required'),
                icon: Icons.category_rounded,
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categoryItems(lang),
                  decoration: const InputDecoration(border: InputBorder.none),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
              ),
              const SizedBox(height: 16),

              // ── Description ───────────────────────────────
              _buildSectionCard(
                title: lang.t('description_required'),
                icon: Icons.description_rounded,
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: lang.t('description_hint'),
                    border: InputBorder.none,
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? lang.t('description_required_msg')
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // ── Date + Paid By ────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _buildSectionCard(
                      title: lang.t('date_required'),
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
                      title: lang.t('paid_by_required'),
                      icon: Icons.payment_rounded,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPaidBy,
                          isExpanded: true,
                          items: _paymentMethods
                              .map<DropdownMenuItem<String>>((m) =>
                                  DropdownMenuItem<String>(
                                    value: m['value'] as String,
                                    child: Row(children: [
                                      Icon(m['icon'] as IconData,
                                          size: 18, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      // ✅ translated
                                      Text(lang.t(m['labelKey'] as String),
                                          style: const TextStyle(
                                              fontFamily: 'Poppins')),
                                    ]),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedPaidBy = v!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Paid To ───────────────────────────────────
              _buildSectionCard(
                title: lang.t('paid_to_optional'),
                icon: Icons.business_rounded,
                child: TextFormField(
                  controller: _paidToController,
                  decoration: InputDecoration(
                    hintText: lang.t('paid_to_hint'),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Reference Number ──────────────────────────
              _buildSectionCard(
                title: lang.t('reference_optional'),
                icon: Icons.numbers_rounded,
                child: TextFormField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    hintText: lang.t('reference_hint'),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Notes ─────────────────────────────────────
              _buildSectionCard(
                title: lang.t('notes_optional'),
                icon: Icons.note_alt_rounded,
                child: TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: lang.t('notes_hint'),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Update Button ─────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submitUpdate(lang),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
                      // ✅ translated button text
                      : Text(
                          lang.t('update_expense'),
                          style: const TextStyle(
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
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2)),
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
              child: child),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
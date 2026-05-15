// sale_payment_screen.dart
import 'package:agr_market/services/sales_payment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../providers/language_provider.dart';

class SalePaymentScreen extends StatefulWidget {
  final String saleId;
  final String invoiceNumber;
  final String buyerName;
  final double totalAmount;
  final double amountDue;

  const SalePaymentScreen({
    super.key,
    required this.saleId,
    required this.invoiceNumber,
    required this.buyerName,
    required this.totalAmount,
    required this.amountDue,
  });

  @override
  State<SalePaymentScreen> createState() => _SalePaymentScreenState();
}

class _SalePaymentScreenState extends State<SalePaymentScreen> {
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _chequeNumberCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _paymentMode = 'cash';
  DateTime _paymentDate = DateTime.now();
  DateTime? _chequeDate;
  bool _saving = false;
  String? _error;

  static const List<String> _paymentModes = [
    'cash',
    'upi',
    'bank',
    'cheque',
    'credit',
  ];

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.amountDue.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _chequeNumberCtrl.dispose();
    _bankNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String? _validate(LanguageProvider lang) {
    final amountStr = _amountCtrl.text.trim();
    if (amountStr.isEmpty) return lang.t('payment_amount_required');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      return lang.t('payment_amount_invalid');
    }
    if (amount > widget.amountDue) {
      return 'Amount cannot exceed due amount (${_formatCurrency(widget.amountDue)})';
    }

    if (_paymentMode == 'upi' && _referenceCtrl.text.trim().isEmpty) {
      return lang.t('payment_ref_required');
    }
    if (_paymentMode == 'bank' && _referenceCtrl.text.trim().isEmpty) {
      return lang.t('payment_ref_required');
    }
    if (_paymentMode == 'cheque') {
      if (_chequeNumberCtrl.text.trim().isEmpty) {
        return lang.t('payment_cheque_num_required');
      }
      if (_chequeDate == null) return lang.t('payment_cheque_date_required');
    }
    return null;
  }

  Future<void> _submit(LanguageProvider lang) async {
    final err = _validate(lang);
    if (err != null) {
      setState(() => _error = err);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final result = await SalePaymentService.instance.recordPayment(
        saleId: widget.saleId,
        amount: double.parse(_amountCtrl.text.trim()),
        paymentMode: _paymentMode,
        paymentDate: _paymentDate,
        referenceNumber: _referenceCtrl.text.trim().isEmpty
            ? null
            : _referenceCtrl.text.trim(),
        chequeNumber: _chequeNumberCtrl.text.trim().isEmpty
            ? null
            : _chequeNumberCtrl.text.trim(),
        chequeDate: _chequeDate,
        bankName: _bankNameCtrl.text.trim().isEmpty
            ? null
            : _bankNameCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      if (!mounted) return;

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang.t('payment_recorded_success'),
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() => _error = result.message ?? lang.t('payment_failed'));
      }
    } catch (e) {
      setState(() => _error = '${lang.t('payment_failed')}: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPaymentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _pickChequeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _chequeDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _chequeDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              'Record Payment – ${widget.invoiceNumber}',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Buyer info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 24, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.buyerName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    fontFamily: 'Poppins')),
                            const SizedBox(height: 4),
                            Text(
                              'Invoice: ${widget.invoiceNumber}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Total Amount',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textHint)),
                          Text(_formatCurrency(widget.totalAmount),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.primaryDark)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Due amount chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount Due',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error)),
                      Text(_formatCurrency(widget.amountDue),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Payment Mode
                Text(lang.t('payment_mode'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildPaymentModePicker(lang),

                const SizedBox(height: 16),

                // Amount
                _buildLabel('${lang.t('payment_amount')} *'),
                _buildTextField(
                  controller: _amountCtrl,
                  hint: '0',
                  icon: Icons.currency_rupee_rounded,
                  inputType: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),

                const SizedBox(height: 12),

                // Payment Date
                _buildLabel(lang.t('payment_date')),
                _buildDateTile(
                  date: _paymentDate,
                  onTap: _pickPaymentDate,
                  lang: lang,
                ),

                // Mode-specific fields
                ..._buildModeSpecificFields(lang),

                const SizedBox(height: 12),

                // Notes
                _buildLabel(lang.t('payment_notes_optional')),
                _buildTextField(
                  controller: _notesCtrl,
                  hint: lang.t('payment_notes_hint'),
                  icon: Icons.note_outlined,
                  maxLines: 2,
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_error!,
                              style: const TextStyle(color: AppColors.error))),
                    ]),
                  ),
                ],

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _submit(lang),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded),
                              const SizedBox(width: 8),
                              Text(lang.t('record_payment'),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentModePicker(LanguageProvider lang) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _paymentModes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final mode = _paymentModes[i];
          final selected = mode == _paymentMode;
          return GestureDetector(
            onTap: () => setState(() {
              _paymentMode = mode;
              _error = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_modeIcon(mode),
                      size: 14,
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    lang.t('payment_mode_$mode'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _modeIcon(String mode) {
    switch (mode) {
      case 'cash':
        return Icons.money_rounded;
      case 'upi':
        return Icons.qr_code_rounded;
      case 'bank':
        return Icons.account_balance_outlined;
      case 'cheque':
        return Icons.article_outlined;
      case 'credit':
        return Icons.credit_score_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  List<Widget> _buildModeSpecificFields(LanguageProvider lang) {
    final fields = <Widget>[];

    if (_paymentMode == 'upi') {
      fields.addAll([
        const SizedBox(height: 12),
        _buildLabel('${lang.t('payment_upi_ref')} *'),
        _buildTextField(
          controller: _referenceCtrl,
          hint: lang.t('payment_upi_ref_hint'),
          icon: Icons.tag_rounded,
        ),
      ]);
    }

    if (_paymentMode == 'bank') {
      fields.addAll([
        const SizedBox(height: 12),
        _buildLabel('${lang.t('payment_ref_num')} *'),
        _buildTextField(
          controller: _referenceCtrl,
          hint: lang.t('payment_ref_hint'),
          icon: Icons.tag_rounded,
        ),
        const SizedBox(height: 12),
        _buildLabel(lang.t('payment_bank_name')),
        _buildTextField(
          controller: _bankNameCtrl,
          hint: lang.t('payment_bank_name_hint'),
          icon: Icons.account_balance_outlined,
          caps: TextCapitalization.words,
        ),
      ]);
    }

    if (_paymentMode == 'cheque') {
      fields.addAll([
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('${lang.t('payment_cheque_num')} *'),
                  _buildTextField(
                    controller: _chequeNumberCtrl,
                    hint: lang.t('payment_cheque_num_hint'),
                    icon: Icons.confirmation_number_outlined,
                    inputType: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 12,
                  ),
                ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('${lang.t('payment_cheque_date')} *'),
                  _buildDateTile(
                    date: _chequeDate,
                    onTap: _pickChequeDate,
                    lang: lang,
                    placeholder: lang.t('payment_select_date'),
                    allowFuture: true,
                  ),
                ]),
          ),
        ]),
        const SizedBox(height: 12),
        _buildLabel(lang.t('payment_bank_name')),
        _buildTextField(
          controller: _bankNameCtrl,
          hint: lang.t('payment_bank_name_hint'),
          icon: Icons.account_balance_outlined,
          caps: TextCapitalization.words,
        ),
      ]);
    }

    return fields;
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    TextCapitalization caps = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
    int? maxLength,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      textCapitalization: caps,
      inputFormatters: formatters,
      maxLength: maxLength,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 18),
        counterText: '',
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildDateTile({
    required DateTime? date,
    required VoidCallback onTap,
    required LanguageProvider lang,
    String? placeholder,
    bool allowFuture = false,
  }) {
    final label = date != null
        ? DateFormat('dd/MM/yyyy').format(date)
        : (placeholder ?? lang.t('payment_select_date'));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined,
              size: 16, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: date != null ? AppColors.textPrimary : AppColors.textHint,
                  fontFamily: 'Poppins')),
        ]),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final f = NumberFormat('#,##,##0', 'en_IN');
    return '₹${f.format(amount)}';
  }
}
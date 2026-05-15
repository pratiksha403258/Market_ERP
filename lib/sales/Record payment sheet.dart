import 'package:agr_market/services/sales_payment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../providers/language_provider.dart';

// ─────────────────────────────────────────────────────────────
//  RECORD PAYMENT SHEET
//  Dynamic fields based on payment mode:
//    cash    → amount, date, notes
//    upi     → amount, date, referenceNumber, notes
//    bank    → amount, date, referenceNumber, bankName, notes
//    cheque  → amount, date, chequeNumber, chequeDate, bankName, notes
//    credit  → amount, date, notes
// ─────────────────────────────────────────────────────────────

class RecordPaymentSheet extends StatefulWidget {
  final String saleId;
  final String invoiceNumber;
  final double amountDue;

  const RecordPaymentSheet({
    super.key,
    required this.saleId,
    required this.invoiceNumber,
    required this.amountDue,
  });

  /// Show as a modal bottom sheet and return true if payment was recorded.
  static Future<bool?> show(
    BuildContext context, {
    required String saleId,
    required String invoiceNumber,
    required double amountDue,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordPaymentSheet(
        saleId: saleId,
        invoiceNumber: invoiceNumber,
        amountDue: amountDue,
      ),
    );
  }

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  // ── Controllers ───────────────────────────────────────────
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _chequeNumberCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // ── State ─────────────────────────────────────────────────
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
    // Pre-fill amount with the full due amount
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

  // ── Validation ────────────────────────────────────────────
  String? _validate(LanguageProvider lang) {
    final amountStr = _amountCtrl.text.trim();
    if (amountStr.isEmpty) return lang.t('payment_amount_required');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return lang.t('payment_amount_invalid');

    if (_paymentMode == 'upi') {
      if (_referenceCtrl.text.trim().isEmpty) {
        return lang.t('payment_ref_required');
      }
    }
    if (_paymentMode == 'bank') {
      if (_referenceCtrl.text.trim().isEmpty) {
        return lang.t('payment_ref_required');
      }
    }
    if (_paymentMode == 'cheque') {
      if (_chequeNumberCtrl.text.trim().isEmpty) {
        return lang.t('payment_cheque_num_required');
      }
      if (_chequeDate == null) return lang.t('payment_cheque_date_required');
    }
    return null;
  }

  // ── Submit ────────────────────────────────────────────────
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
        notes:
            _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      if (!mounted) return;

      if (result.isSuccess) {
        // Show success feedback
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
        Navigator.pop(context, true); // return true → caller can refresh
      } else {
        setState(() => _error = result.message ?? lang.t('payment_failed'));
      }
    } catch (e) {
      setState(() => _error = '${lang.t('payment_failed')}: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Date picker ───────────────────────────────────────────
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

  // ── UI ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.t('record_payment'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            widget.invoiceNumber,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Due amount chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.errorSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            lang.t('payment_due'),
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.error,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            _formatCurrency(widget.amountDue),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Payment Mode selector ──────────────────
                Text(
                  lang.t('payment_mode'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                _buildPaymentModePicker(lang),

                const SizedBox(height: 16),

                // ── Amount ────────────────────────────────
                _buildLabel(lang.t('payment_amount')),
                _buildTextField(
                  controller: _amountCtrl,
                  hint: '0',
                  icon: Icons.currency_rupee_rounded,
                  inputType: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Payment Date ──────────────────────────
                _buildLabel(lang.t('payment_date')),
                _buildDateTile(
                  date: _paymentDate,
                  onTap: _pickPaymentDate,
                  lang: lang,
                ),

                // ── Mode-specific fields ──────────────────
                ..._buildModeSpecificFields(lang),

                const SizedBox(height: 12),

                // ── Notes ─────────────────────────────────
                _buildLabel(lang.t('payment_notes_optional')),
                _buildTextField(
                  controller: _notesCtrl,
                  hint: lang.t('payment_notes_hint'),
                  icon: Icons.note_outlined,
                  maxLines: 2,
                ),

                // ── Error ─────────────────────────────────
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Submit button ─────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _submit(lang),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withOpacity(0.5),
                      elevation: 0,
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
                              const Icon(Icons.check_circle_outline_rounded,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(
                                lang.t('record_payment'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
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

  // ── Payment Mode Pill Selector ────────────────────────────
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
                  color: selected
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _modeIcon(mode),
                    size: 14,
                    color:
                        selected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    lang.t('payment_mode_$mode'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontFamily: 'Poppins',
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

  // ── Dynamic fields per mode ───────────────────────────────
  List<Widget> _buildModeSpecificFields(LanguageProvider lang) {
    final fields = <Widget>[];

    // UPI: reference number
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

    // Bank: reference + bank name
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

    // Cheque: cheque number, cheque date, bank name
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

  // ── Shared field builders ─────────────────────────────────
  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
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
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.textPrimary,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textHint, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 18),
        counterText: '',
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined,
              size: 16, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: date != null
                  ? AppColors.textPrimary
                  : AppColors.textHint,
              fontFamily: 'Poppins',
            ),
          ),
        ]),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final f = NumberFormat('#,##,##0', 'en_IN');
    return '₹${f.format(amount)}';
  }
}
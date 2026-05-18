// ─────────────────────────────────────────────────────────────
//  PAYMENT SCREEN
//  POST /api/payments
//
//  After successful payment → navigates to ReceiptScreen
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../receipt/receipt_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String purchaseId;
  final String farmerId;
  final String farmerName;
  final double finalPayable;
  final double amountPaid;
  final double amountDue;
  final String receiptNumber;

  const PaymentScreen({
    super.key,
    required this.purchaseId,
    required this.farmerId,
    required this.farmerName,
    required this.finalPayable,
    required this.amountPaid,
    required this.amountDue,
    required this.receiptNumber,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _amountCtrl       = TextEditingController();
  final _referenceCtrl    = TextEditingController();
  final _notesCtrl        = TextEditingController();
  final _chequeNumberCtrl = TextEditingController();
  final _bankNameCtrl     = TextEditingController();
  final _chequeDateCtrl   = TextEditingController();
  DateTime? _chequeDate;

  PaymentMode  _selectedMode  = PaymentMode.cash;
  bool         _isProcessing  = false;
  ChequeStatus _chequeStatus  = ChequeStatus.pendingClearance;

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.amountDue.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    _chequeNumberCtrl.dispose();
    _bankNameCtrl.dispose();
    _chequeDateCtrl.dispose();
    super.dispose();
  }

  // ── Computed values ───────────────────────────────────────────
  double get _enteredAmount => double.tryParse(_amountCtrl.text.trim()) ?? 0;
  double get _newTotalPaid  => widget.amountPaid + _enteredAmount;
  double get _remainingDue  =>
      (widget.amountDue - _enteredAmount).clamp(0, double.infinity);
  bool   get _isFullPayment => _remainingDue == 0 && _enteredAmount > 0;

  // ── Submit payment ────────────────────────────────────────────
  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final amount = _enteredAmount;
    if (amount <= 0) {
      _snack('Please enter a valid amount', isError: true);
      return;
    }
    if (amount > widget.amountDue + 0.01) {
      _snack(
        'Amount (₹${amount.toStringAsFixed(2)}) exceeds due amount (₹${widget.amountDue.toStringAsFixed(2)})',
        isError: true,
      );
      return;
    }
    if (_selectedMode.requiresReference && _referenceCtrl.text.trim().isEmpty) {
      _snack('Please enter ${_selectedMode.referenceLabel}', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      String? chequeNumber;
      DateTime? chequeDate;
      String? bankName;

      if (_selectedMode == PaymentMode.cheque) {
        chequeNumber = _chequeNumberCtrl.text.trim();
        if (chequeNumber.isEmpty) {
          _snack('Cheque number is required', isError: true);
          setState(() => _isProcessing = false);
          return;
        }
        chequeDate = _chequeDate;
        bankName = _bankNameCtrl.text.trim().isEmpty
            ? null
            : _bankNameCtrl.text.trim();
      }

      final request = PaymentRequest(
        purchaseId: widget.purchaseId,
        farmerId: widget.farmerId,
        amount: amount,
        paymentMode: _selectedMode,
        referenceNumber:
            _selectedMode != PaymentMode.cheque && _selectedMode.requiresReference
                ? _referenceCtrl.text.trim()
                : null,
        paymentDate: DateTime.now(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        chequeStatus: _selectedMode == PaymentMode.cheque ? _chequeStatus : null,
        chequeNumber: chequeNumber,
        chequeDate: chequeDate,
        bankName: bankName,
      );

      await PaymentService().recordPayment(request);

      if (mounted) {
        _snack(
          _isFullPayment
              ? '✅ Full payment of ₹${amount.toStringAsFixed(2)} recorded!'
              : 'Partial payment of ₹${amount.toStringAsFixed(2)} recorded. Remaining: ₹${_remainingDue.toStringAsFixed(2)}',
          isError: false,
        );

        await Future.delayed(const Duration(milliseconds: 600));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ReceiptScreen(
                purchaseId:   widget.purchaseId,
                farmerName:   widget.farmerName,
                farmerMobile: '',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(left: 6, right: 6, bottom: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Record Payment',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Purchase info card ──────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(children: [
                      Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.heroGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              widget.farmerName.isNotEmpty
                                  ? widget.farmerName[0].toUpperCase()
                                  : 'F',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  fontFamily: 'Poppins'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.farmerName,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                      color: AppColors.textPrimary)),
                              if (widget.receiptNumber.isNotEmpty)
                                Text('Receipt: ${widget.receiptNumber}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textHint,
                                        fontFamily: 'Poppins')),
                            ],
                          ),
                        ),
                      ]),
                      const Divider(height: 24, color: AppColors.divider),
                      _infoRow('Total Payable',
                          '₹${widget.finalPayable.toStringAsFixed(2)}',
                          valueColor: AppColors.textPrimary),
                      const SizedBox(height: 6),
                      _infoRow('Already Paid',
                          '₹${widget.amountPaid.toStringAsFixed(2)}',
                          valueColor: AppColors.success),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.warningSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Remaining Due',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                    color: AppColors.warning)),
                            Text('₹${widget.amountDue.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Poppins',
                                    color: AppColors.warning)),
                          ],
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 24),

                  // ── Payment Method ──────────────────────────
                  _sectionLabel('Payment Method'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: PaymentMode.values.map((mode) {
                        final isSelected = _selectedMode == mode;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedMode = mode;
                              _referenceCtrl.clear();
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(children: [
                                Icon(mode.icon,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    size: 20),
                                const SizedBox(height: 4),
                                Text(mode.displayName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        fontFamily: 'Poppins',
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textSecondary)),
                              ]),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Amount ──────────────────────────────────
                  _sectionLabel('Payment Amount *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'))
                    ],
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 14, right: 6),
                        child: Text('₹',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                      ),
                      prefixIconConstraints: const BoxConstraints(),
                      suffixText:
                          'of ₹${widget.amountDue.toStringAsFixed(2)} due',
                      suffixStyle: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                          fontFamily: 'Poppins'),
                      hintText: widget.amountDue.toStringAsFixed(2),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.divider)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.divider)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5)),
                      errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.error)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 16),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter amount';
                      final amt = double.tryParse(v);
                      if (amt == null || amt <= 0) return 'Enter valid amount';
                      if (amt > widget.amountDue + 0.01) {
                        return 'Cannot exceed due amount ₹${widget.amountDue.toStringAsFixed(2)}';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),

                  // ── Quick amount buttons ────────────────────
                  const SizedBox(height: 10),
                  Row(children: [
                    _quickAmtBtn('Full Due', widget.amountDue),
                    const SizedBox(width: 8),
                    _quickAmtBtn('₹10,000', 10000),
                    const SizedBox(width: 8),
                    _quickAmtBtn('₹50,000', 50000),
                  ]),

                  // ── UPI / Bank reference ─────────────────────
                  if (_selectedMode == PaymentMode.upi ||
                      _selectedMode == PaymentMode.bank) ...[
                    const SizedBox(height: 18),
                    _sectionLabel('${_selectedMode.referenceLabel} *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _referenceCtrl,
                      style: const TextStyle(fontFamily: 'Poppins'),
                      decoration: InputDecoration(
                        hintText: 'Enter ${_selectedMode.referenceLabel}',
                        prefixIcon: const Icon(Icons.tag_rounded),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.divider),
                        ),
                      ),
                    ),
                  ],

                  // ── Cheque fields ─────────────────────────────
                  if (_selectedMode == PaymentMode.cheque) ...[
                    const SizedBox(height: 18),
                    _sectionLabel('Cheque Number *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _chequeNumberCtrl,
                      style: const TextStyle(fontFamily: 'Poppins'),
                      decoration: InputDecoration(
                        hintText: 'e.g. 123456',
                        prefixIcon: const Icon(Icons.description_rounded),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.divider),
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Cheque number required'
                          : null,
                    ),

                    const SizedBox(height: 12),
                    _sectionLabel('Bank Name (Optional)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bankNameCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. State Bank of India',
                        prefixIcon: const Icon(Icons.account_balance_rounded),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.divider),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    _sectionLabel('Cheque Date (Optional)'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() {
                            _chequeDate = date;
                            _chequeDateCtrl.text =
                                DateFormat('dd MMM yyyy').format(date);
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _chequeDateCtrl,
                          decoration: InputDecoration(
                            hintText: 'Select date',
                            suffixIcon:
                                const Icon(Icons.calendar_today_rounded),
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.divider),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    _sectionLabel('Cheque Status'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ChequeStatus>(
                          value: _chequeStatus,
                          isExpanded: true,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: AppColors.textPrimary),
                          onChanged: (v) =>
                              setState(() => _chequeStatus = v!),
                          items: ChequeStatus.values
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Row(children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: s.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(s.displayName,
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: s.color)),
                                    ]),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    if (_chequeStatus == ChequeStatus.pendingClearance) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warningSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.warning.withOpacity(0.3)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppColors.warning, size: 14),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cheque will be tracked until cleared. Amount will be counted when cheque clears.',
                              style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 11,
                                  fontFamily: 'Poppins'),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ],

                  // ── Notes ────────────────────────────────────
                  const SizedBox(height: 18),
                  _sectionLabel('Notes (Optional)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Add any remarks...',
                      hintStyle: const TextStyle(
                          color: AppColors.textHint, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.divider)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.divider)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5)),
                    ),
                  ),

                  // ── After-payment preview ────────────────────
                  if (_enteredAmount > 0 &&
                      _enteredAmount <= widget.amountDue) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(children: [
                        const Text('After This Payment',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontFamily: 'Poppins')),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _paymentPreviewItem(
                              'Total Paid',
                              '₹${_newTotalPaid.toStringAsFixed(2)}',
                              Colors.greenAccent,
                            ),
                            Container(
                                width: 1,
                                height: 40,
                                color: Colors.white24),
                            _isFullPayment
                                ? _paymentPreviewItem('Status',
                                    '✅ FULLY PAID', Colors.greenAccent)
                                : _paymentPreviewItem(
                                    'Remaining Due',
                                    '₹${_remainingDue.toStringAsFixed(2)}',
                                    Colors.orangeAccent),
                          ],
                        ),
                        if (_isFullPayment) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      Colors.greenAccent.withOpacity(0.5)),
                            ),
                            child: const Text(
                              'This will clear all dues!',
                              style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ]),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Confirm Button ────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withOpacity(0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            _enteredAmount > 0
                                ? 'Confirm Payment ₹${_enteredAmount.toStringAsFixed(2)} via ${_selectedMode.displayName}'
                                : 'Confirm Payment',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
          color: AppColors.textPrimary));

  Widget _infoRow(String label, String value, {Color? valueColor}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: valueColor ?? AppColors.textPrimary)),
        ],
      );

  Widget _quickAmtBtn(String label, double amount) {
    final canUse = amount <= widget.amountDue + 0.01;
    final useAmt = amount > widget.amountDue ? widget.amountDue : amount;
    return Expanded(
      child: GestureDetector(
        onTap: canUse
            ? () =>
                setState(() => _amountCtrl.text = useAmt.toStringAsFixed(2))
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: canUse
                ? AppColors.primarySurface
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: canUse
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.border),
          ),
          child: Text(
            label == 'Full Due'
                ? 'Full ₹${widget.amountDue.toStringAsFixed(0)}'
                : label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: canUse ? AppColors.primary : AppColors.textHint),
          ),
        ),
      ),
    );
  }

  Widget _paymentPreviewItem(String label, String value, Color color) {
    return Column(children: [
      Text(label,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontFamily: 'Poppins')),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins')),
    ]);
  }
}
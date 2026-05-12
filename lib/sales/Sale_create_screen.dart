import 'package:agr_market/sales/sales_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';
import '../../../services/sale_service.dart';

class SaleCreateScreen extends StatefulWidget {
  const SaleCreateScreen({super.key});

  @override
  State<SaleCreateScreen> createState() => _SaleCreateScreenState();
}

class _SaleCreateScreenState extends State<SaleCreateScreen>
    with SingleTickerProviderStateMixin {
  // ── Step ──────────────────────────────────────────────────────
  int _step = 0;
  static const _stepLabels = ['Buyer', 'Product', 'Payment', 'Review'];

  // ── Step 0: Buyer ─────────────────────────────────────────────
  final _buyerNameCtrl = TextEditingController();
  final _buyerMobileCtrl = TextEditingController();
  final _buyerGstCtrl = TextEditingController();
  final _buyerAddressCtrl = TextEditingController();

  // ── Step 1: Product ───────────────────────────────────────────
  final _productNameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  String _unit = 'kg';
  final _priceCtrl = TextEditingController();
  double _gstPercent = 0;

  // ── Step 2: Payment ───────────────────────────────────────────
  String _paymentStatus = 'pending'; // pending | partial | paid
  final _amountPaidCtrl = TextEditingController();
  String _paymentMode = 'cash';
  final _notesCtrl = TextEditingController();

  // ── Computed ──────────────────────────────────────────────────
  double get _qty => double.tryParse(_qtyCtrl.text) ?? 0;
  double get _price => double.tryParse(_priceCtrl.text) ?? 0;
  double get _subtotal => _qty * _price;
  double get _gstAmount => (_subtotal * _gstPercent) / 100;
  double get _totalAmount => _subtotal + _gstAmount;
  double get _amountPaid =>
      double.tryParse(_amountPaidCtrl.text.trim()) ?? 0;
  double get _amountDue => (_totalAmount - _amountPaid).clamp(0, double.infinity);

  // ── Misc ──────────────────────────────────────────────────────
  bool _saving = false;
  String? _error;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  static const _units = ['kg', 'qtl', 'pcs', 'bunch', 'crate', 'doz', 'bag', 'ltr', 'ton'];
  static const _gstOptions = [0.0, 5.0, 12.0, 18.0, 28.0];
  static const _paymentModes = ['cash', 'upi', 'bank', 'cheque'];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    _qtyCtrl.addListener(_recalc);
    _priceCtrl.addListener(_recalc);
  }

  void _recalc() => setState(() {});

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [
      _buyerNameCtrl, _buyerMobileCtrl, _buyerGstCtrl, _buyerAddressCtrl,
      _productNameCtrl, _qtyCtrl, _priceCtrl, _amountPaidCtrl, _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────
  void _next() {
    final err = _validateCurrent();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() => _error = null);
    if (_step == 1 && _paymentStatus == 'paid') {
      _amountPaidCtrl.text = _totalAmount.toStringAsFixed(2);
    }
    if (_step < 3) {
      _step++;
      _animCtrl.reset();
      _animCtrl.forward();
      setState(() {});
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() {
        _step--;
        _error = null;
      });
      _animCtrl.reset();
      _animCtrl.forward();
    } else {
      Navigator.pop(context);
    }
  }

  void _goToSalesList() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SalesListScreen()),
      );
      
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sales list updated'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to Sales List: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening sales list: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String? _validateCurrent() {
    switch (_step) {
      case 0:
        if (_buyerNameCtrl.text.trim().isEmpty) return 'Enter buyer name';
        if (_buyerNameCtrl.text.trim().length < 2) return 'Enter buyer name (min 2 chars)';
        if (_buyerMobileCtrl.text.trim().isNotEmpty &&
            _buyerMobileCtrl.text.trim().length != 10) {
          return 'Mobile must be 10 digits';
        }
        return null;
      case 1:
        if (_productNameCtrl.text.trim().isEmpty) return 'Enter product name';
        if (_qty <= 0) return 'Enter valid quantity';
        if (_qtyCtrl.text.trim().isEmpty) return 'Quantity is required';
        if (_price <= 0) return 'Enter valid selling price';
        if (_priceCtrl.text.trim().isEmpty) return 'Price is required';
        return null;
      case 2:
        if (_paymentStatus == 'partial') {
          final paid = double.tryParse(_amountPaidCtrl.text.trim()) ?? 0;
          if (paid <= 0) return 'Enter amount paid for partial payment';
          if (paid >= _totalAmount) return 'Partial amount must be less than total';
          if (_amountPaidCtrl.text.trim().isEmpty) return 'Amount paid is required for partial payment';
        }
        if (_paymentStatus == 'paid' && _totalAmount <= 0) {
          return 'Cannot mark as paid with zero amount';
        }
        return null;
      default:
        return null;
    }
  }

  // ── Submit ────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    double paid = _amountPaid;
    if (_paymentStatus == 'paid') paid = _totalAmount;
    if (_paymentStatus == 'pending') paid = 0;

    final payload = {
      'buyerName': _buyerNameCtrl.text.trim(),
      if (_buyerMobileCtrl.text.trim().isNotEmpty)
        'buyerMobile': _buyerMobileCtrl.text.trim(),
      if (_buyerGstCtrl.text.trim().isNotEmpty)
        'buyerGst': _buyerGstCtrl.text.trim().toUpperCase(),
      'saleDate': DateTime.now().toIso8601String().split('T')[0],
      'lines': [
        {
          'productName': _productNameCtrl.text.trim(),
          'qty': _qty,
          'sellingPrice': _price,
        }
      ],
      'gstPercent': _gstPercent,
      'paymentMode': _paymentMode,
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };

    if (_paymentStatus != 'pending' && _paymentMode != 'cash') {
      payload['referenceNumber'] = 'REF${DateTime.now().millisecondsSinceEpoch}';
    }

    debugPrint('=== SALE PAYLOAD ===');
    payload.forEach((key, value) {
      debugPrint('$key: $value');
    });

    final result = await SaleService.instance.createSale(payload);
    setState(() => _saving = false);

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sale created successfully!',
            style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ));
      Navigator.pop(context, true);
    } else {
      debugPrint('=== SALE ERROR ===');
      debugPrint('Message: ${result.message}');
      setState(() => _error = result.message ?? 'Failed to create sale');
    }
  }

  String _fmtMoney(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(2)}';
  }

  // ── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        // Gradient header
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.30,
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      GestureDetector(
                        onTap: _back,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text('New Sale',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins')),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildStepIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Scrollable body
        Positioned.fill(
          child: SingleChildScrollView(
            child: Column(children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
              FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(
                      color: AppColors.primary.withOpacity(0.10),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    )],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: _buildCurrentStep(),
                  ),
                ),
              ),

              // Error message
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                                fontFamily: 'Poppins')),
                      ),
                    ]),
                  ),
                ),

              const SizedBox(height: 20),

              // Action button - Continue/Create Sale
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _step < 3 ? 'Continue' : 'Create Sale',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins'),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _step < 3
                                    ? Icons.arrow_forward_rounded
                                    : Icons.storefront_rounded,
                                size: 18),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // NEW: View Sales List Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _goToSalesList,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'View Sales List',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Step Indicator ────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(_stepLabels.length, (i) {
        final active = i == _step;
        final done = i < _step;
        return Expanded(
          child: Row(children: [
            Expanded(
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: active ? 24 : 20,
                    height: active ? 24 : 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done || active
                          ? Colors.white
                          : Colors.white.withOpacity(0.35),
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.primary, size: 13)
                          : Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? AppColors.primary
                                      : Colors.white.withOpacity(0.6))),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(_stepLabels[i],
                    style: TextStyle(
                        color: active || done
                            ? Colors.white
                            : Colors.white.withOpacity(0.55),
                        fontSize: 9,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500)),
              ]),
            ),
            if (i < _stepLabels.length - 1)
              Container(width: 20, height: 1, color: Colors.white.withOpacity(0.35)),
          ]),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: return _buildStep0Buyer();
      case 1: return _buildStep1Product();
      case 2: return _buildStep2Payment();
      case 3: return _buildStep3Review();
      default: return const SizedBox.shrink();
    }
  }

  // ── STEP 0 — Buyer Info ───────────────────────────────────────
  Widget _buildStep0Buyer() {
    return Column(
      key: const ValueKey('s0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Buyer Details', 'Who are you selling to?'),
        const SizedBox(height: 20),
        _field('Buyer Name *', _buyerNameCtrl,
            hint: 'e.g. Ramesh Trading Co.',
            icon: Icons.person_outline_rounded,
            caps: TextCapitalization.words),
        const SizedBox(height: 12),
        _field('Mobile Number', _buyerMobileCtrl,
            hint: '9876543210',
            icon: Icons.phone_outlined,
            inputType: TextInputType.phone,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10),
        const SizedBox(height: 12),
        _field('GST Number (optional)', _buyerGstCtrl,
            hint: '27AAPFU0939F1ZV',
            icon: Icons.receipt_long_outlined,
            caps: TextCapitalization.characters,
            maxLength: 15),
        const SizedBox(height: 12),
        _multiLineField('Address (optional)', _buyerAddressCtrl,
            hint: 'Shop / village address...'),
      ],
    );
  }

  // ── STEP 1 — Product ──────────────────────────────────────────
  Widget _buildStep1Product() {
    return Column(
      key: const ValueKey('s1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Product Details', 'What are you selling?'),
        const SizedBox(height: 20),
        _field('Product Name *', _productNameCtrl,
            hint: 'e.g. Tomato',
            icon: Icons.eco_outlined,
            caps: TextCapitalization.words),
        const SizedBox(height: 12),

        // Qty + Unit row
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 2,
            child: _field('Quantity *', _qtyCtrl,
                hint: '0',
                icon: Icons.straighten_outlined,
                inputType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Unit',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: 'Poppins')),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _unit,
                      isExpanded: true,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textPrimary),
                      onChanged: (v) => setState(() => _unit = v!),
                      items: _units
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 12),
        _field('Selling Price per $_unit (₹) *', _priceCtrl,
            hint: '0.00',
            icon: Icons.currency_rupee_rounded,
            inputType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]),
        const SizedBox(height: 16),

        // GST
        const Text('GST %',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _gstOptions.map((g) {
            final sel = _gstPercent == g;
            return GestureDetector(
              onTap: () => setState(() => _gstPercent = g),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? AppColors.primary : AppColors.border),
                ),
                child: Text(
                  g == 0 ? 'No GST' : '${g.toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: sel ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600)),
              ),
            );
          }).toList(),
        ),

        // Live calculation
        if (_subtotal > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              _calcRow('Subtotal', _subtotal),
              if (_gstPercent > 0) _calcRow('GST (${_gstPercent.toStringAsFixed(0)}%)', _gstAmount),
              const Divider(color: Colors.white24, height: 16),
              _calcRow('Total Amount', _totalAmount, large: true),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _calcRow(String label, double value, {bool large = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(
              color: Colors.white70,
              fontSize: large ? 13 : 12,
              fontFamily: 'Poppins')),
      Text('₹${value.toStringAsFixed(2)}',
          style: TextStyle(
              color: Colors.white,
              fontSize: large ? 18 : 13,
              fontWeight: large ? FontWeight.w700 : FontWeight.w500,
              fontFamily: 'Poppins')),
    ]);
  }

  // ── STEP 2 — Payment ──────────────────────────────────────────
  Widget _buildStep2Payment() {
    return Column(
      key: const ValueKey('s2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Payment Details', 'How much was collected?'),
        const SizedBox(height: 16),

        // Total amount display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total Sale Amount',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontFamily: 'Poppins')),
            Text('₹${_totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
          ]),
        ),

        const SizedBox(height: 16),
        const Text('Payment Status *',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins')),
        const SizedBox(height: 8),

        // Status selector
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _statusChip('pending', 'Pending', AppColors.error),
              _statusChip('partial', 'Partial', AppColors.warning),
              _statusChip('paid', 'Paid', AppColors.success),
            ],
          ),
        ),

        // Amount paid field (for partial)
        if (_paymentStatus == 'partial') ...[
          const SizedBox(height: 14),
          _field('Amount Paid (₹) *', _amountPaidCtrl,
              hint: '0.00',
              icon: Icons.currency_rupee_rounded,
              inputType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]),
          if (_amountPaid > 0 && _amountPaid < _totalAmount)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Balance due: ₹${_amountDue.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],

        // Payment mode (not for pending)
        if (_paymentStatus != 'pending') ...[
          const SizedBox(height: 16),
          const Text('Payment Mode',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: _paymentModes.map((m) {
                final sel = _paymentMode == m;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentMode = m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(m.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : AppColors.textSecondary)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        const SizedBox(height: 14),
        _multiLineField('Notes (optional)', _notesCtrl,
            hint: 'Any remarks about this sale...'),
      ],
    );
  }

  Widget _statusChip(String value, String label, Color color) {
    final sel = _paymentStatus == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _paymentStatus = value;
            if (value == 'paid') {
              _amountPaidCtrl.text = _totalAmount.toStringAsFixed(2);
            } else if (value == 'pending') {
              _amountPaidCtrl.clear();
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : AppColors.textSecondary)),
        ),
      ),
    );
  }

  // ── STEP 3 — Review ───────────────────────────────────────────
  Widget _buildStep3Review() {
    final paid = _paymentStatus == 'paid'
        ? _totalAmount
        : _paymentStatus == 'pending'
            ? 0.0
            : _amountPaid;
    final due = (_totalAmount - paid).clamp(0, double.infinity);

    return Column(
      key: const ValueKey('s3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Review Sale', 'Confirm before creating'),
        const SizedBox(height: 16),

        // Buyer section
        _reviewSection('Buyer', [
          _reviewRow('Name', _buyerNameCtrl.text.trim()),
          if (_buyerMobileCtrl.text.trim().isNotEmpty)
            _reviewRow('Mobile', _buyerMobileCtrl.text.trim()),
          if (_buyerGstCtrl.text.trim().isNotEmpty)
            _reviewRow('GST', _buyerGstCtrl.text.trim().toUpperCase()),
          if (_buyerAddressCtrl.text.trim().isNotEmpty)
            _reviewRow('Address', _buyerAddressCtrl.text.trim()),
        ], Icons.person_outline_rounded),
        const SizedBox(height: 12),

        // Product section
        _reviewSection('Product', [
          _reviewRow('Name', _productNameCtrl.text.trim()),
          _reviewRow('Quantity', '${_qty.toStringAsFixed(2)} $_unit'),
          _reviewRow('Rate', '₹${_price.toStringAsFixed(2)} / $_unit'),
          _reviewRow('Subtotal', '₹${_subtotal.toStringAsFixed(2)}'),
          if (_gstPercent > 0)
            _reviewRow('GST (${_gstPercent.toStringAsFixed(0)}%)',
                '₹${_gstAmount.toStringAsFixed(2)}'),
        ], Icons.eco_outlined),
        const SizedBox(height: 12),

        // Financial summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            _calcRow('Total Amount', _totalAmount, large: true),
            const SizedBox(height: 6),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Status',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Poppins')),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _paymentStatus == 'paid' 
                          ? Colors.greenAccent.withOpacity(0.2)
                          : _paymentStatus == 'partial'
                              ? Colors.orangeAccent.withOpacity(0.2)
                              : Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _paymentStatus[0].toUpperCase() + _paymentStatus.substring(1),
                      style: TextStyle(
                          color: _paymentStatus == 'paid'
                              ? Colors.greenAccent
                              : _paymentStatus == 'partial'
                                  ? Colors.orangeAccent
                                  : Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                ],
              ),
            ),
            _calcRow('Amount Paid', paid),
            if (due == 0 && _paymentStatus == 'paid')
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 14),
                  SizedBox(width: 6),
                  Text('Fully Paid',
                      style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600)),
                ]),
              ),
          ]),
        ),

        if (_notesCtrl.text.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _reviewSection('Notes', [
            _reviewRow('', _notesCtrl.text.trim()),
          ], Icons.notes_rounded),
        ],
      ],
    );
  }

  Widget _reviewSection(String title, List<Widget> rows, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppColors.primary, size: 15),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins')),
        ]),
        const Divider(color: AppColors.divider, height: 14),
        ...rows,
      ]),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins')),
            ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  // ── Shared input widgets ──────────────────────────────────────
  Widget _stepHeader(String title, String sub) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins')),
        ],
      );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    required String hint,
    required IconData icon,
    TextCapitalization caps = TextCapitalization.none,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    int? maxLength,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins')),
      const SizedBox(height: 4),
      TextFormField(
        controller: ctrl,
        keyboardType: inputType,
        textCapitalization: caps,
        inputFormatters: formatters,
        maxLength: maxLength,
        style: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.textHint, size: 18),
          counterText: '',
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
        onChanged: (_) => setState(() {}),
      ),
    ]);
  }

  Widget _multiLineField(String label, TextEditingController ctrl,
      {required String hint}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins')),
      const SizedBox(height: 4),
      TextFormField(
        controller: ctrl,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
            fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    ]);
  }
}
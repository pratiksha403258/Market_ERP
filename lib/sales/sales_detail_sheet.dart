// sale_detail_screen.dart
import 'package:agr_market/sales/sales_invoice_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../services/dio_client.dart';
import '../../../services/constant_service.dart';
import '../../../providers/language_provider.dart';
import '../../../models/sale_model.dart';

class SaleDetailScreen extends StatefulWidget {
  final String saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  SaleModel? _sale;
  bool _loading = true;
  String? _error;
  bool _generatingInvoice = false;

  @override
  void initState() {
    super.initState();
    _loadSaleDetail();
  }

  Future<void> _loadSaleDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await DioClient.instance.dio.get(
        ApiRoutes.saleById(widget.saleId),
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] != true) {
        throw Exception(responseData['message'] ?? 'Failed to load sale');
      }

      final data = responseData['data'] ?? responseData['sale'] ?? responseData;

      setState(() {
        _sale = SaleModel.fromJson(data as Map<String, dynamic>);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _fmtCurrency(double amount) {
    final formatter = NumberFormat('#,##,##0', 'en_IN');
    return '₹${formatter.format(amount)}';
  }

  String _fmtDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // ── Generate Invoice ─────────────────────────────────────────
  Future<void> _generateInvoice(LanguageProvider lang) async {
    if (_sale == null) return;
    setState(() => _generatingInvoice = true);
    try {
      await SalesInvoicePrinter.openPrintDialog(
        context,
        widget.saleId,
        languageCode: lang.locale.languageCode,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingInvoice = false);
    }
  }

  // ── Language toggle ──────────────────────────────────────────
  Widget _buildLanguageToggle(LanguageProvider lang) {
    final isMr = lang.isMarathi;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _langTab(label: 'EN', selected: !isMr, onTap: () => lang.setLanguage('en')),
          _langTab(label: 'मर', selected: isMr, onTap: () => lang.setLanguage('mr')),
        ],
      ),
    );
  }

  Widget _langTab({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: selected ? AppColors.primary : Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lang.t('sale_detail_title'),
            style: const TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [_buildLanguageToggle(lang)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildErrorWidget(lang)
              : _sale == null
                  ? const Center(child: Text('Sale not found'))
                  : _buildSaleDetail(lang),
    );
  }

  Widget _buildSaleDetail(LanguageProvider lang) {
    final sale = _sale!;
    final lines = sale.lines;
    final ded = sale.deductions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lang.t('invoice_label'),
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontFamily: 'Poppins')),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(sale.invoiceNumber,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              fontFamily: 'Poppins')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(lang.t('date_label'),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(_fmtDate(sale.saleDate),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              fontFamily: 'Poppins')),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('Final Receivable',
                          style: TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        _fmtCurrency(
                            sale.finalReceivable > 0
                                ? sale.finalReceivable
                                : sale.grandTotal),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            fontFamily: 'Poppins'),
                      ),
                    ]),
                  ],
                ),
                const SizedBox(height: 10),
                // Payment status row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statusBadge(sale.status),
                    if (sale.amountDue > 0)
                      Text('Due: ${_fmtCurrency(sale.amountDue)}',
                          style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins')),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Buyer ────────────────────────────────────────────
          _buildSection(
            title: lang.t('buyer_details'),
            icon: Icons.person_outline,
            child: Column(children: [
              _infoRow(lang.t('name_label'), sale.buyerName),
              if ((sale.buyerMobile ?? '').isNotEmpty)
                _infoRow(lang.t('mobile_label'), sale.buyerMobile!),
              if ((sale.buyerGst ?? '').isNotEmpty)
                _infoRow(lang.t('gst_label'), sale.buyerGst!),
              if ((sale.buyerAddress ?? '').isNotEmpty)
                _infoRow('Address', sale.buyerAddress!),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Products ─────────────────────────────────────────
          _buildSection(
            title: lang.t('products_section'),
            icon: Icons.shopping_bag_outlined,
            child: Column(children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  _th('Product', flex: 3),
                  _th('Bags', flex: 1, center: true),
                  _th('Net Qty', flex: 2, center: true),
                  _th('Rate', flex: 2, right: true),
                  _th('Total', flex: 2, right: true),
                ]),
              ),
              const SizedBox(height: 8),
              ...lines.map((line) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.productName,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins')),
                            if (line.qualityDeduction > 0)
                              Text(
                                  'Ded: ${line.qualityDeduction.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.error,
                                      fontFamily: 'Poppins')),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          line.bags > 0 ? '${line.bags}' : '-',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, fontFamily: 'Poppins'),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${line.netQty.toStringAsFixed(1)} ${line.unit.isNotEmpty ? line.unit : 'kg'}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'Poppins'),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _fmtCurrency(line.effectiveRate),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'Poppins'),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _fmtCurrency(line.lineTotal),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins'),
                        ),
                      ),
                    ]),
                  )),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Deductions (only if any) ──────────────────────────
          if (ded != null && ded.total > 0)
            _buildSection(
              title: 'Deductions',
              icon: Icons.remove_circle_outline,
              child: Column(children: [
                if (ded.transport > 0)
                  _infoRow('Transport', _fmtCurrency(ded.transport)),
                if (ded.labour > 0)
                  _infoRow('Labour', _fmtCurrency(ded.labour)),
                if (ded.commission > 0)
                  _infoRow(
                      'Commission (${ded.commissionType})',
                      ded.commissionType == 'percent'
                          ? '${ded.commission}%'
                          : _fmtCurrency(ded.commission)),
                if (ded.storage > 0)
                  _infoRow('Storage', _fmtCurrency(ded.storage)),
                if (ded.returnDeduction > 0)
                  _infoRow('Return', _fmtCurrency(ded.returnDeduction)),
                if (ded.advanceAdjusted > 0)
                  _infoRow(
                      'Advance Adj.', _fmtCurrency(ded.advanceAdjusted)),
                if (ded.other > 0)
                  _infoRow('Other', _fmtCurrency(ded.other)),
                const Divider(height: 14),
                _infoRow('Total Deductions', _fmtCurrency(ded.total),
                    isBold: true),
              ]),
            ),

          if (ded != null && ded.total > 0) const SizedBox(height: 12),

          // ── Financial summary ─────────────────────────────────
          _buildSection(
            title: lang.t('payment_summary'),
            icon: Icons.payment_outlined,
            child: Column(children: [
              if (sale.grossTotal > 0)
                _infoRow('Gross Total', _fmtCurrency(sale.grossTotal)),
              if (sale.totalDeductions > 0)
                _infoRow('Total Deductions',
                    '-${_fmtCurrency(sale.totalDeductions)}'),
              if (sale.gstPercent > 0)
                _infoRow('GST (${sale.gstPercent.toStringAsFixed(0)}%)',
                    _fmtCurrency(sale.gstAmount)),
              const Divider(height: 16),
              _infoRow('Final Receivable',
                  _fmtCurrency(sale.finalReceivable > 0
                      ? sale.finalReceivable
                      : sale.grandTotal),
                  isBold: true, isHighlight: true),
              if (sale.amountReceived > 0)
                _infoRow('Amount Received',
                    _fmtCurrency(sale.amountReceived)),
              if (sale.amountDue > 0)
                _infoRow('Amount Due', _fmtCurrency(sale.amountDue),
                    isBold: true, isDue: true),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.successSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mode: ${sale.paymentMode.toUpperCase()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          fontFamily: 'Poppins'),
                    ),
                    _statusBadge(sale.status),
                  ],
                ),
              ),
            ]),
          ),

          // ── Notes ─────────────────────────────────────────────
          if ((sale.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSection(
              title: lang.t('notes_section'),
              icon: Icons.note_outlined,
              child: Text(sale.notes!,
                  style:
                      const TextStyle(fontSize: 13, fontFamily: 'Poppins')),
            ),
          ],

          const SizedBox(height: 20),

          // ── Generate Invoice button ────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _generatingInvoice ? null : () => _generateInvoice(lang),
              icon: _generatingInvoice
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.receipt_long_outlined, size: 20),
              label: Text(
                _generatingInvoice
                    ? 'Preparing PDF...'
                    : lang.t('generate_invoice_btn'),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  Widget _th(String label,
      {int flex = 1, bool center = false, bool right = false}) {
    return Expanded(
      flex: flex,
      child: Text(label,
          textAlign: right
              ? TextAlign.right
              : center
                  ? TextAlign.center
                  : TextAlign.left,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              fontFamily: 'Poppins')),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = AppColors.success;
        break;
      case 'partial':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            fontFamily: 'Poppins'),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
          ]),
        ),
        const Divider(height: 1, color: AppColors.divider),
        Padding(padding: const EdgeInsets.all(12), child: child),
      ]),
    );
  }

  Widget _infoRow(String label, String value,
      {bool isBold = false, bool isHighlight = false, bool isDue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: isHighlight
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight:
                      isBold ? FontWeight.w600 : FontWeight.normal,
                  fontFamily: 'Poppins')),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: isDue
                      ? AppColors.error
                      : isHighlight
                          ? AppColors.success
                          : AppColors.textPrimary,
                  fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(LanguageProvider lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error ?? lang.t('network_error'),
                style:
                    const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSaleDetail,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: Text(lang.t('retry')),
            ),
          ],
        ),
      ),
    );
  }
}
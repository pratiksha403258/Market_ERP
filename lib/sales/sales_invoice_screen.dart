// ─────────────────────────────────────────────────────────────
//  SALE INVOICE SCREEN
//  Renders a printable invoice for a sale.
//
//  API: GET /sales/:id  → SaleModel (already have full data)
//       The screen uses the SaleModel passed to it directly
//       so no extra API call is needed.
//
//  Features:
//    • Formatted invoice layout (business header, buyer, product,
//      GST, totals, payment status)
//    • WhatsApp share (text receipt)
//    • PDF download via `printing` package
//    • Print button (thermal / system print dialog)
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../models/sale_model.dart';

class SaleInvoiceScreen extends StatefulWidget {
  final SaleModel sale;

  const SaleInvoiceScreen({super.key, required this.sale});

  @override
  State<SaleInvoiceScreen> createState() => _SaleInvoiceScreenState();
}

class _SaleInvoiceScreenState extends State<SaleInvoiceScreen> {
  bool _exportingPdf = false;

  // ── Formatting helpers ────────────────────────────────────────
  String _fmtDate(DateTime d) =>
      DateFormat('dd MMM yyyy').format(d.toLocal());

  String _fmtDateFull(DateTime d) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(d.toLocal());

  String _fmtMoney(double v) => '₹${v.toStringAsFixed(2)}';

  String _fmtMoneyShort(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(2)}';
  }

  // ── WhatsApp Share ────────────────────────────────────────────
  Future<void> _shareWhatsApp() async {
    final s = widget.sale;
    final buf = StringBuffer();
    buf.writeln('🧾 *SALE INVOICE*');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('Invoice: *${s.invoiceNumber}*');
    buf.writeln('Date: ${_fmtDate(s.saleDate)}');
    buf.writeln('');
    buf.writeln('*BUYER*');
    buf.writeln('Name: ${s.buyerName}');
    if (s.buyerMobile != null && s.buyerMobile!.isNotEmpty) {
      buf.writeln('Mobile: ${s.buyerMobile}');
    }
    if (s.buyerGst != null && s.buyerGst!.isNotEmpty) {
      buf.writeln('GST: ${s.buyerGst}');
    }
    buf.writeln('');
    buf.writeln('*PRODUCT*');
    buf.writeln(
        '${s.productName}: ${s.quantity.toStringAsFixed(2)} ${s.unit} × ${_fmtMoney(s.sellingPricePerUnit)}');
    buf.writeln('Subtotal: ${_fmtMoney(s.subtotal)}');
    if (s.gstPercentage > 0) {
      buf.writeln(
          'GST (${s.gstPercentage.toStringAsFixed(0)}%): ${_fmtMoney(s.gstAmount)}');
    }
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('*TOTAL: ${_fmtMoney(s.totalAmount)}*');
    buf.writeln('Amount Paid: ${_fmtMoney(s.amountPaid)}');
    if (s.hasDue) {
      buf.writeln('*Balance Due: ${_fmtMoney(s.amountDue)}*');
    } else {
      buf.writeln('✅ FULLY PAID');
    }
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('Thank you for your business!');

    final mobile = s.buyerMobile?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final phone = mobile.length == 10 ? '91$mobile' : mobile;
    final text = buf.toString();
    final uri = phone.isNotEmpty
        ? Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(text)}')
        : Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final fallback =
          Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  // ── PDF Generation ────────────────────────────────────────────
  Future<pw.Document> _buildPdf() async {
    final s = widget.sale;
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    pw.TextStyle ts({double sz = 9, bool bold = false, PdfColor color = PdfColors.black}) =>
        pw.TextStyle(
            font: bold ? boldFont : regularFont,
            fontSize: sz,
            color: color);

    const grey300 = PdfColor.fromInt(0xFFEEEEEE);
    const grey600 = PdfColor.fromInt(0xFF555555);
    const primary = PdfColor.fromInt(0xFF2D7A4F); // match AppColors.primary roughly

    final doc = pw.Document();

    doc.addPage(pw.Page(
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('FARM ERP', style: ts(sz: 18, bold: true, color: primary)),
              pw.Text('Agricultural Market System', style: ts(sz: 9, color: grey600)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('TAX INVOICE', style: ts(sz: 14, bold: true)),
              pw.Text('Invoice No: ${s.invoiceNumber}', style: ts(sz: 9)),
              pw.Text('Date: ${_fmtDate(s.saleDate)}', style: ts(sz: 9)),
            ]),
          ]),

          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.black, thickness: 1.5),
          pw.SizedBox(height: 10),

          // ── Buyer info ─────────────────────────────────────────
          pw.Text('BILL TO', style: ts(sz: 8, bold: true, color: grey600)),
          pw.SizedBox(height: 4),
          pw.Text(s.buyerName, style: ts(sz: 11, bold: true)),
          if (s.buyerMobile != null && s.buyerMobile!.isNotEmpty)
            pw.Text('Mobile: ${s.buyerMobile}', style: ts(sz: 9)),
          if (s.buyerGst != null && s.buyerGst!.isNotEmpty)
            pw.Text('GSTIN: ${s.buyerGst}', style: ts(sz: 9)),
          if (s.buyerAddress != null && s.buyerAddress!.isNotEmpty)
            pw.Text(s.buyerAddress!, style: ts(sz: 9)),

          pw.SizedBox(height: 14),

          // ── Product table ───────────────────────────────────────
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3.5),
              1: const pw.FixedColumnWidth(60),
              2: const pw.FixedColumnWidth(60),
              3: const pw.FixedColumnWidth(70),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: grey300),
                children: [
                  _tCell('Description', ts: ts(sz: 8, bold: true)),
                  _tCell('Qty', ts: ts(sz: 8, bold: true), align: pw.TextAlign.center),
                  _tCell('Rate (₹)', ts: ts(sz: 8, bold: true), align: pw.TextAlign.right),
                  _tCell('Amount (₹)', ts: ts(sz: 8, bold: true), align: pw.TextAlign.right),
                ],
              ),
              // Product row
              pw.TableRow(children: [
                _tCell('${s.productName}  (${s.unit})', ts: ts(sz: 9)),
                _tCell(s.quantity.toStringAsFixed(2), ts: ts(sz: 9), align: pw.TextAlign.center),
                _tCell(s.sellingPricePerUnit.toStringAsFixed(2), ts: ts(sz: 9), align: pw.TextAlign.right),
                _tCell(s.subtotal.toStringAsFixed(2), ts: ts(sz: 9, bold: true), align: pw.TextAlign.right),
              ]),
            ],
          ),

          pw.SizedBox(height: 12),

          // ── Totals ──────────────────────────────────────────────
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.SizedBox(
              width: 200,
              child: pw.Column(children: [
                _totalsRow('Subtotal', s.subtotal.toStringAsFixed(2), ts: ts),
                if (s.gstPercentage > 0)
                  _totalsRow(
                      'GST @ ${s.gstPercentage.toStringAsFixed(0)}%',
                      s.gstAmount.toStringAsFixed(2),
                      ts: ts),
                pw.Divider(color: PdfColors.grey400, height: 8, thickness: 0.5),
                _totalsRow('TOTAL', s.totalAmount.toStringAsFixed(2),
                    ts: ts, bold: true),
                pw.SizedBox(height: 4),
                _totalsRow('Amount Paid', s.amountPaid.toStringAsFixed(2),
                    ts: ts, valueColor: PdfColors.green700),
                if (s.hasDue)
                  _totalsRow('Balance Due', s.amountDue.toStringAsFixed(2),
                      ts: ts, valueColor: PdfColors.orange700)
                else
                  pw.Row(children: [
                    pw.Spacer(),
                    pw.Text('✓ FULLY PAID',
                        style: ts(sz: 9, bold: true, color: PdfColors.green700)),
                  ]),
              ]),
            ),
          ]),

          pw.SizedBox(height: 20),

          // ── Notes ───────────────────────────────────────────────
          if (s.notes != null && s.notes!.isNotEmpty) ...[
            pw.Text('Notes:', style: ts(sz: 8, bold: true)),
            pw.Text(s.notes!, style: ts(sz: 8, color: grey600)),
            pw.SizedBox(height: 16),
          ],

          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.SizedBox(height: 6),

          // ── Footer ──────────────────────────────────────────────
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Generated by Farm ERP', style: ts(sz: 7, color: grey600)),
            pw.Text(_fmtDateFull(DateTime.now()), style: ts(sz: 7, color: grey600)),
          ]),
          pw.SizedBox(height: 20),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('For FARM ERP', style: ts(sz: 8)),
              pw.SizedBox(height: 24),
              pw.Text('Authorised Signatory', style: ts(sz: 8)),
            ]),
          ]),
        ],
      ),
    ));

    return doc;
  }

  pw.Widget _tCell(String text,
      {required pw.TextStyle ts,
      pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(text, textAlign: align, style: ts),
    );
  }

  pw.Widget _totalsRow(String label, String value,
      {required pw.TextStyle Function({double sz, bool bold, PdfColor color}) ts,
      bool bold = false,
      PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
        pw.Text(label, style: ts(sz: 9, bold: bold)),
        pw.Text('₹$value',
            style: ts(
                sz: bold ? 11 : 9,
                bold: bold,
                color: valueColor ?? PdfColors.black)),
      ]),
    );
  }

  Future<void> _downloadPdf() async {
    setState(() => _exportingPdf = true);
    try {
      final doc = await _buildPdf();
      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'Invoice_${widget.sale.invoiceNumber}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PDF error: $e',
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _printInvoice() async {
    try {
      final doc = await _buildPdf();
      await Printing.layoutPdf(
        onLayout: (_) async => await doc.save(),
        name:
            'Invoice_${widget.sale.invoiceNumber}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Print error: $e',
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final s = widget.sale;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Header ────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Tax Invoice',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins')),
                  ),
                  // PDF button
                  GestureDetector(
                    onTap: _exportingPdf ? null : _downloadPdf,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _exportingPdf
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  color: AppColors.primary, strokeWidth: 2))
                          : const Row(children: [
                              Icon(Icons.picture_as_pdf_rounded,
                                  color: AppColors.primary, size: 15),
                              SizedBox(width: 5),
                              Text('PDF',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins')),
                            ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // Summary KPI chips
                Row(children: [
                  _chip('Total', _fmtMoneyShort(s.totalAmount),
                      Icons.storefront_rounded),
                  const SizedBox(width: 8),
                  _chip('Paid', _fmtMoneyShort(s.amountPaid),
                      Icons.check_circle_outline_rounded,
                      color: Colors.greenAccent.shade100),
                  if (s.hasDue) ...[
                    const SizedBox(width: 8),
                    _chip('Due', _fmtMoneyShort(s.amountDue),
                        Icons.pending_outlined,
                        color: Colors.orangeAccent.shade100),
                  ],
                ]),
              ]),
            ),
          ),
        ),

        // ── Invoice Body ─────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            child: Column(children: [
              // Invoice card
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  )],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company header
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('FARM ERP',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0.5)),
                          const Text('Agricultural Market System',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'Poppins')),
                        ]),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          const Text('TAX INVOICE',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Poppins')),
                          const SizedBox(height: 2),
                          Text(
                            s.invoiceNumber.isNotEmpty
                                ? '#${s.invoiceNumber}'
                                : '—',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins'),
                          ),
                          Text(_fmtDate(s.saleDate),
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textHint,
                                  fontFamily: 'Poppins')),
                        ]),
                      ]),

                      const Divider(
                          color: AppColors.divider, height: 24, thickness: 1.5),

                      // Bill to
                      const Text('BILL TO',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHint,
                              fontFamily: 'Poppins',
                              letterSpacing: 1)),
                      const SizedBox(height: 6),
                      Text(s.buyerName,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Poppins')),
                      if (s.buyerMobile != null && s.buyerMobile!.isNotEmpty)
                        _contactRow(Icons.phone_outlined, s.buyerMobile!),
                      if (s.buyerGst != null && s.buyerGst!.isNotEmpty)
                        _contactRow(Icons.receipt_long_outlined,
                            'GSTIN: ${s.buyerGst}'),
                      if (s.buyerAddress != null && s.buyerAddress!.isNotEmpty)
                        _contactRow(Icons.location_on_outlined, s.buyerAddress!),

                      const Divider(color: AppColors.divider, height: 24),

                      // Product table header
                      const Text('PRODUCTS',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHint,
                              fontFamily: 'Poppins',
                              letterSpacing: 1)),
                      const SizedBox(height: 8),

                      // Column headers
                      Row(children: [
                        Expanded(
                            flex: 3,
                            child: _colHead('Description')),
                        Expanded(
                            child: _colHead('Qty',
                                align: TextAlign.center)),
                        Expanded(
                            child: _colHead('Rate',
                                align: TextAlign.right)),
                        Expanded(
                            child: _colHead('Amount',
                                align: TextAlign.right)),
                      ]),
                      const SizedBox(height: 6),

                      // Product row
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 0),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: Row(children: [
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(s.productName,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Poppins')),
                                  Text('per ${s.unit}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textHint,
                                          fontFamily: 'Poppins')),
                                ]),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                  s.quantity.toStringAsFixed(2),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Poppins')),
                            ),
                            Expanded(
                              child: Text(
                                  '₹${s.sellingPricePerUnit.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Poppins')),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Text(
                                    '₹${s.subtotal.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        fontFamily: 'Poppins')),
                              ),
                            ),
                          ]),
                        ),
                      ),

                      const SizedBox(height: 14),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 8),

                      // Totals
                      _totalsRowWidget('Subtotal', _fmtMoney(s.subtotal)),
                      if (s.gstPercentage > 0) ...[
                        const SizedBox(height: 4),
                        _totalsRowWidget(
                            'GST @ ${s.gstPercentage.toStringAsFixed(0)}%',
                            _fmtMoney(s.gstAmount)),
                      ],
                      const SizedBox(height: 8),

                      // Total amount highlight
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                          const Text('TOTAL AMOUNT',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5)),
                          Text(_fmtMoney(s.totalAmount),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins')),
                        ]),
                      ),

                      const SizedBox(height: 12),

                      // Payment section
                      _totalsRowWidget(
                          'Amount Paid', _fmtMoney(s.amountPaid),
                          valueColor: AppColors.success),
                      if (s.hasDue) ...[
                        const SizedBox(height: 4),
                        _totalsRowWidget(
                            'Balance Due', _fmtMoney(s.amountDue),
                            valueColor: AppColors.warning,
                            bold: true),
                      ] else ...[
                        const SizedBox(height: 8),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.successSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.success.withOpacity(0.4)),
                            ),
                            child: const Row(children: [
                              Icon(Icons.check_circle_rounded,
                                  color: AppColors.success, size: 14),
                              SizedBox(width: 6),
                              Text('FULLY PAID',
                                  style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ]),
                      ],

                      // Notes
                      if (s.notes != null && s.notes!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Divider(color: AppColors.divider),
                        const SizedBox(height: 8),
                        const Text('NOTES',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHint,
                                fontFamily: 'Poppins',
                                letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(s.notes!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'Poppins')),
                      ],

                      const SizedBox(height: 20),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 8),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                        const Text('FARM ERP',
                            style: TextStyle(
                                fontSize: 9,
                                color: AppColors.textHint,
                                fontFamily: 'Poppins')),
                        Text(_fmtDateFull(s.createdAt),
                            style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textHint,
                                fontFamily: 'Poppins')),
                      ]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shareWhatsApp,
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('WhatsApp',
                            style: TextStyle(
                                fontFamily: 'Poppins', fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _printInvoice,
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: const Text('Print',
                            style: TextStyle(
                                fontFamily: 'Poppins', fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exportingPdf ? null : _downloadPdf,
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('PDF',
                            style: TextStyle(
                                fontFamily: 'Poppins', fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.textSecondary)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _chip(String label, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color ?? Colors.white70, size: 11),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color ?? Colors.white70,
                    fontSize: 9,
                    fontFamily: 'Poppins')),
          ]),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins'),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(children: [
        Icon(icon, size: 12, color: AppColors.textHint),
        const SizedBox(width: 5),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins')),
        ),
      ]),
    );
  }

  Widget _colHead(String text, {TextAlign align = TextAlign.left}) {
    return Text(text,
        textAlign: align,
        style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.textHint,
            fontFamily: 'Poppins',
            letterSpacing: 0.5));
  }

  Widget _totalsRowWidget(String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(
              fontSize: 13,
              fontFamily: 'Poppins',
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: AppColors.textSecondary)),
      Text(value,
          style: TextStyle(
              fontSize: 13,
              fontFamily: 'Poppins',
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary)),
    ]);
  }
}
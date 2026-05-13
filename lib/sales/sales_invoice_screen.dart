// sales_invoice_screen.dart
// ─────────────────────────────────────────────────────────────
//  SALES INVOICE SCREEN
//  • Matches "Jai Shivrai Vegetable Co." sample invoice design
//  • Language toggle (EN / MR) in AppBar — uses LanguageProvider
//  • Print, PDF download, WhatsApp share
//  • PDF mirrors the on-screen invoice exactly
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../providers/language_provider.dart';
import '../../../services/dio_client.dart';
import '../../../services/constant_service.dart';

// =============================================================
//  MODELS
// =============================================================

class SalesInvoiceData {
  final String id;
  final String invoiceNumber;
  final String buyerName;
  final String? buyerMobile;
  final String? buyerGst;
  final String? buyerAddress;
  final DateTime saleDate;
  final List<InvoiceLine> lines;
  final double subTotal;
  final double gstPercent;
  final double gstAmount;
  final double grandTotal;
  final String paymentMode;
  final String? referenceNumber;
  final String? notes;
  final Map<String, dynamic>? createdBy;
  final DateTime createdAt;

  SalesInvoiceData({
    required this.id,
    required this.invoiceNumber,
    required this.buyerName,
    this.buyerMobile,
    this.buyerGst,
    this.buyerAddress,
    required this.saleDate,
    required this.lines,
    required this.subTotal,
    required this.gstPercent,
    required this.gstAmount,
    required this.grandTotal,
    required this.paymentMode,
    this.referenceNumber,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  factory SalesInvoiceData.fromJson(Map<String, dynamic> json) {
    final linesList = (json['lines'] as List? ?? [])
        .map((e) => InvoiceLine.fromJson(e as Map<String, dynamic>))
        .toList();

    return SalesInvoiceData(
      id: json['_id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      buyerName: json['buyerName']?.toString() ?? '',
      buyerMobile: json['buyerMobile']?.toString(),
      buyerGst: json['buyerGst']?.toString(),
      buyerAddress: json['buyerAddress']?.toString(),
      saleDate: DateTime.tryParse(json['saleDate']?.toString() ?? '') ?? DateTime.now(),
      lines: linesList,
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0,
      gstPercent: (json['gstPercent'] as num?)?.toDouble() ?? 0,
      gstAmount: (json['gstAmount'] as num?)?.toDouble() ?? 0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      paymentMode: json['paymentMode']?.toString() ?? '',
      referenceNumber: json['referenceNumber']?.toString(),
      notes: json['notes']?.toString(),
      createdBy: json['createdBy'] is Map
          ? json['createdBy'] as Map<String, dynamic>
          : null,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class InvoiceLine {
  final String productName;
  final String warehouse;
  final double qty;
  final String unit;
  final double sellingPrice;
  final double lineTotal;

  InvoiceLine({
    required this.productName,
    required this.warehouse,
    required this.qty,
    required this.unit,
    required this.sellingPrice,
    required this.lineTotal,
  });

  factory InvoiceLine.fromJson(Map<String, dynamic> json) {
    return InvoiceLine(
      productName: json['productName']?.toString() ?? '',
      warehouse: json['warehouse']?.toString() ?? '',
      qty: (json['qty'] as num?)?.toDouble() ?? 0,
      unit: json['unit']?.toString() ?? '',
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

// =============================================================
//  SCREEN
// =============================================================

class SalesInvoiceScreen extends StatefulWidget {
  final String saleId;

  const SalesInvoiceScreen({super.key, required this.saleId});

  @override
  State<SalesInvoiceScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  SalesInvoiceData? _invoice;
  bool _loading = true;
  String? _error;
  bool _exportingPdf = false;

  // ── Colour constants matching the sample invoice ─────────────
  static const Color _invoicePrimary = Color(0xFF1A6B3C); // dark green
  static const Color _invoiceAccent = Color(0xFF2D8653);
  static const Color _invoiceBorder = Color(0xFFD4E8DC);
  static const Color _invoiceHeaderBg = Color(0xFFF0F7F3);
  static const Color _invoiceTableAlt = Color(0xFFFAFDFB);

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
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
        throw Exception(responseData['message'] ?? 'Failed to load invoice');
      }
      setState(() {
        _invoice = SalesInvoiceData.fromJson(responseData['data']);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────────

  String _fmtDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  String _fmtDateTime(DateTime d) => DateFormat('dd/MM/yyyy, hh:mm a').format(d);

  String _fmtCurrency(double amount) {
    final f = NumberFormat('#,##,##0.00', 'en_IN');
    return '₹${f.format(amount)}';
  }

  String _numberToWords(double amount) {
    final intAmount = amount.toInt();
    if (intAmount == 0) return 'Zero Rupees Only';

    const ones = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];
    const tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
      'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String conv(int n) {
      if (n < 20) return ones[n];
      if (n < 100) return '${tens[n ~/ 10]} ${ones[n % 10]}'.trim();
      if (n < 1000) return '${ones[n ~/ 100]} Hundred ${conv(n % 100)}'.trim();
      if (n < 100000) return '${conv(n ~/ 1000)} Thousand ${conv(n % 1000)}'.trim();
      if (n < 10000000) return '${conv(n ~/ 100000)} Lakh ${conv(n % 100000)}'.trim();
      return '${conv(n ~/ 10000000)} Crore ${conv(n % 10000000)}'.trim();
    }

    final paise = ((amount - intAmount) * 100).round();
    final wordRupees = conv(intAmount);
    if (paise > 0) return '$wordRupees Rupees and $paise Paise Only';
    return '$wordRupees Rupees Only';
  }

  // ─────────────────────────────────────────────────────────────
  //  LANGUAGE TOGGLE PILL (reused in AppBar)
  // ─────────────────────────────────────────────────────────────

  Widget _buildLanguageToggle(LanguageProvider lang) {
    final isMr = lang.isMarathi;
    return Container(
      margin: const EdgeInsets.only(right: 8),
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

  Widget _langTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
            color: selected ? AppColors.primary : Colors.white,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  WHATSAPP SHARE
  // ─────────────────────────────────────────────────────────────

  Future<void> _shareWhatsApp(LanguageProvider lang) async {
    if (_invoice == null) return;
    final inv = _invoice!;
    final buf = StringBuffer();

    buf.writeln('🧾 *${lang.t('tax_invoice_badge')}*');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('*${lang.t('company_name')}*');
    buf.writeln(lang.t('company_address'));
    buf.writeln('');
    buf.writeln('${lang.t('invoice_no_label')} ${inv.invoiceNumber}');
    buf.writeln('${lang.t('date_label_inv')} ${_fmtDate(inv.saleDate)}');
    buf.writeln('');
    buf.writeln('*${lang.t('buyer_details')}*');
    buf.writeln('${lang.t('name_label')}: ${inv.buyerName}');
    if (inv.buyerMobile != null && inv.buyerMobile!.isNotEmpty) {
      buf.writeln('${lang.t('mobile_label')}: ${inv.buyerMobile}');
    }
    if (inv.buyerGst != null && inv.buyerGst!.isNotEmpty) {
      buf.writeln('${lang.t('gst_label')}: ${inv.buyerGst}');
    }
    buf.writeln('');
    buf.writeln('*${lang.t('products_section')}*');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    for (final line in inv.lines) {
      buf.writeln(
          '${line.productName} (${line.warehouse}) — ${line.qty} ${line.unit} × ${_fmtCurrency(line.sellingPrice)}');
      buf.writeln('  ${lang.t('col_amount_inv')}: ${_fmtCurrency(line.lineTotal)}');
    }
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('${lang.t('sub_total_label')}: ${_fmtCurrency(inv.subTotal)}');
    if (inv.gstPercent > 0) {
      buf.writeln('GST (${inv.gstPercent.toStringAsFixed(0)}%): ${_fmtCurrency(inv.gstAmount)}');
    }
    buf.writeln('*${lang.t('grand_total_label')}: ${_fmtCurrency(inv.grandTotal)}*');
    buf.writeln('');
    buf.writeln('${lang.t('payment_mode_label')}: ${inv.paymentMode.toUpperCase()}');
    if (inv.referenceNumber != null && inv.referenceNumber!.isNotEmpty) {
      buf.writeln('${lang.t('ref_label')}: ${inv.referenceNumber}');
    }
    buf.writeln('');
    buf.writeln('_${_numberToWords(inv.grandTotal)}_');
    buf.writeln('');
    buf.writeln('Thank you for your business! 🙏');

    final phone = inv.buyerMobile?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final waPhone = phone.length == 10 ? '91$phone' : phone;
    final text = buf.toString();
    final uri = waPhone.isNotEmpty
        ? Uri.parse('https://wa.me/$waPhone?text=${Uri.encodeComponent(text)}')
        : Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(
          Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'),
          mode: LaunchMode.externalApplication);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  PDF GENERATION
  // ─────────────────────────────────────────────────────────────

  Future<pw.Document> _buildPdfDocument(LanguageProvider lang) async {
    final inv = _invoice!;

    // Use Google Fonts Noto Sans — correct method names
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    // PDF colour palette matching the sample invoice
    const pdfGreen = PdfColor.fromInt(0xFF1A6B3C);
    const pdfLightGreen = PdfColor.fromInt(0xFF2D8653);
    const pdfBorder = PdfColor.fromInt(0xFFD4E8DC);
    const pdfHeaderBg = PdfColor.fromInt(0xFFF0F7F3);
    const pdfAlt = PdfColor.fromInt(0xFFFAFDFB);

    pw.TextStyle ts({
      double size = 9,
      bool bold = false,
      PdfColor color = PdfColors.black,
    }) =>
        pw.TextStyle(
            font: bold ? boldFont : regularFont, fontSize: size, color: color);

    pw.Widget cell(String text,
        {required pw.TextStyle style,
        pw.TextAlign align = pw.TextAlign.left}) {
      return pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        child: pw.Text(text, textAlign: align, style: style),
      );
    }

    pw.Widget totalsRow(String label, String value, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: ts(size: 9, bold: bold)),
            pw.Text('₹$value', style: ts(size: bold ? 11 : 9, bold: bold)),
          ],
        ),
      );
    }

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Company Header ──────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 10),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                    bottom: pw.BorderSide(color: pdfGreen, width: 1.5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left — company
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('जय शिवराय कैलिटेबल',
                          style: ts(size: 18, bold: true, color: pdfGreen)),
                      pw.SizedBox(height: 2),
                      pw.Text('वेसराणे, ता. कळवण, जि. नाशिक',
                          style: ts(size: 9, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                          'Prop. Rakesh Hire | Mob: 9021699991 / 9623956396',
                          style: ts(size: 7.5, color: PdfColors.grey600)),
                    ],
                  ),
                  // Right — invoice meta
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(lang.t('tax_invoice_badge'),
                          style: ts(size: 14, bold: true, color: pdfGreen)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                          '${lang.t('invoice_no_label')} ${inv.invoiceNumber}',
                          style: ts(size: 9, bold: true)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                          '${lang.t('date_label_inv')} ${_fmtDate(inv.saleDate)}',
                          style: ts(size: 9)),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // ── Buyer Details ───────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: pdfHeaderBg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                border: pw.Border.all(color: pdfBorder, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(lang.t('pdf_buyer_label'),
                      style: ts(size: 8, bold: true, color: PdfColors.grey700)),
                  pw.SizedBox(height: 4),
                  pw.Text(inv.buyerName, style: ts(size: 11, bold: true)),
                  if (inv.buyerMobile != null && inv.buyerMobile!.isNotEmpty)
                    pw.Text('${lang.t('mobile_prefix')} ${inv.buyerMobile}',
                        style: ts(size: 8.5)),
                  if (inv.buyerGst != null && inv.buyerGst!.isNotEmpty)
                    pw.Text('${lang.t('gst_prefix')} ${inv.buyerGst}',
                        style: ts(size: 8.5)),
                  if (inv.buyerAddress != null && inv.buyerAddress!.isNotEmpty)
                    pw.Text('${lang.t('address_prefix')} ${inv.buyerAddress}',
                        style: ts(size: 8.5)),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // ── Product Table ────────────────────────────────
            pw.Table(
              border: pw.TableBorder.all(color: pdfBorder, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.8),
                1: const pw.FlexColumnWidth(1.8),
                2: const pw.FixedColumnWidth(52),
                3: const pw.FixedColumnWidth(62),
                4: const pw.FixedColumnWidth(68),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: pdfHeaderBg),
                  children: [
                    cell(lang.t('pdf_col_product'),
                        style: ts(size: 8, bold: true, color: pdfGreen)),
                    cell(lang.t('pdf_col_warehouse'),
                        style: ts(size: 8, bold: true, color: pdfGreen)),
                    cell(lang.t('pdf_col_qty'),
                        style: ts(size: 8, bold: true, color: pdfGreen),
                        align: pw.TextAlign.center),
                    cell(lang.t('pdf_col_rate'),
                        style: ts(size: 8, bold: true, color: pdfGreen),
                        align: pw.TextAlign.right),
                    cell(lang.t('pdf_col_amount'),
                        style: ts(size: 8, bold: true, color: pdfGreen),
                        align: pw.TextAlign.right),
                  ],
                ),
                // Data rows — alternate background
                ...inv.lines.asMap().entries.map((entry) {
                  final i = entry.key;
                  final line = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: i.isEven ? PdfColors.white : pdfAlt,
                    ),
                    children: [
                      cell(line.productName, style: ts(size: 9)),
                      cell(line.warehouse, style: ts(size: 9)),
                      cell('${line.qty.toStringAsFixed(2)} ${line.unit}',
                          style: ts(size: 9), align: pw.TextAlign.center),
                      cell(line.sellingPrice.toStringAsFixed(2),
                          style: ts(size: 9), align: pw.TextAlign.right),
                      cell(line.lineTotal.toStringAsFixed(2),
                          style: ts(size: 9, bold: true),
                          align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 12),

            // ── Totals ──────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 230,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: pdfHeaderBg,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: pdfBorder, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      totalsRow(lang.t('pdf_sub_total'),
                          inv.subTotal.toStringAsFixed(2)),
                      if (inv.gstPercent > 0)
                        totalsRow(
                            'GST (${inv.gstPercent.toStringAsFixed(0)}%)',
                            inv.gstAmount.toStringAsFixed(2)),
                      pw.Divider(
                          thickness: 0.5, color: pdfLightGreen),
                      totalsRow(lang.t('pdf_grand_total'),
                          inv.grandTotal.toStringAsFixed(2),
                          bold: true),
                      pw.SizedBox(height: 6),
                      pw.Text(
                          '${lang.t('pdf_amount_words')} ${_numberToWords(inv.grandTotal)}',
                          style: ts(size: 7.5, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 12),

            // ── Payment Details ──────────────────────────────
            if (inv.paymentMode.isNotEmpty) ...[
              pw.Row(
                children: [
                  pw.Text('${lang.t('pdf_payment_mode')} ',
                      style: ts(size: 9, bold: true)),
                  pw.Text(inv.paymentMode.toUpperCase(), style: ts(size: 9)),
                  if (inv.referenceNumber != null &&
                      inv.referenceNumber!.isNotEmpty) ...[
                    pw.SizedBox(width: 16),
                    pw.Text('${lang.t('pdf_ref_no')} ',
                        style: ts(size: 9, bold: true)),
                    pw.Text(inv.referenceNumber!, style: ts(size: 9)),
                  ],
                ],
              ),
              pw.SizedBox(height: 8),
            ],

            // ── Notes ───────────────────────────────────────
            if (inv.notes != null && inv.notes!.isNotEmpty) ...[
              pw.Text('${lang.t('pdf_notes')} ',
                  style: ts(size: 8, bold: true)),
              pw.Text(inv.notes!,
                  style: ts(size: 8, color: PdfColors.grey600)),
              pw.SizedBox(height: 8),
            ],

            pw.Divider(thickness: 0.5, color: PdfColors.grey300),
            pw.SizedBox(height: 12),

            // ── Signature Footer ─────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(lang.t('pdf_buyers_sig'),
                        style: ts(size: 8, color: PdfColors.grey600)),
                    pw.SizedBox(height: 20),
                    pw.Text('___________________', style: ts(size: 8)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(lang.t('pdf_for_company'),
                        style: ts(size: 8, bold: true)),
                    pw.SizedBox(height: 20),
                    pw.Text('___________________', style: ts(size: 8)),
                    pw.Text(lang.t('pdf_auth_sig'), style: ts(size: 8)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(lang.t('pdf_footer'),
                  style: ts(size: 9, color: PdfColors.grey600)),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                  '${lang.t('pdf_generated')} ${_fmtDateTime(DateTime.now())}',
                  style: ts(size: 7, color: PdfColors.grey500)),
            ),
          ],
        ),
      ),
    );

    return doc;
  }

  // ─────────────────────────────────────────────────────────────
  //  PDF ACTIONS
  // ─────────────────────────────────────────────────────────────

  Future<void> _downloadPdf(LanguageProvider lang) async {
    if (_invoice == null) return;
    setState(() => _exportingPdf = true);
    try {
      final doc = await _buildPdfDocument(lang);
      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'Invoice_${_invoice!.invoiceNumber}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('PDF error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _printInvoice(LanguageProvider lang) async {
    if (_invoice == null) return;
    try {
      final doc = await _buildPdfDocument(lang);
      await Printing.layoutPdf(
        onLayout: (_) => doc.save(),
        name: 'Invoice_${_invoice!.invoiceNumber}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Print error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: AppBar(
        title: Text(
          lang.t('invoice_screen_title'),
          style: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: _invoicePrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Language toggle
          _buildLanguageToggle(lang),
          // Action icons
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: _loading ? null : () => _printInvoice(lang),
            tooltip: 'Print',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: (_loading || _exportingPdf) ? null : () => _downloadPdf(lang),
            tooltip: 'Download PDF',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _loading ? null : () => _shareWhatsApp(lang),
            tooltip: 'Share on WhatsApp',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _invoicePrimary))
          : _error != null
              ? _buildErrorWidget(lang)
              : _invoice == null
                  ? _buildEmptyWidget(lang)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildInvoiceCard(lang),
                    ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  INVOICE CARD (matches sample PDF design)
  // ─────────────────────────────────────────────────────────────

  Widget _buildInvoiceCard(LanguageProvider lang) {
    final inv = _invoice!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Invoice Header (green top border + company row) ──
          Container(
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: _invoicePrimary, width: 4)),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left — company details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t('company_name'),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: _invoicePrimary,
                          fontFamily: 'Poppins',
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lang.t('company_address'),
                        style: const TextStyle(
                            fontSize: 11.5, color: Color(0xFF4A7A60)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lang.t('company_prop'),
                        style: const TextStyle(
                            fontSize: 10.5, color: Color(0xFF7A9E8A)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right — invoice badge + number + date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _invoicePrimary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        lang.t('tax_invoice_badge'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 11.5, color: Color(0xFF1A1A1A)),
                        children: [
                          TextSpan(
                            text: '${lang.t('invoice_no_label')} ',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: inv.invoiceNumber),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF555555)),
                        children: [
                          TextSpan(
                            text: '${lang.t('date_label_inv')} ',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500),
                          ),
                          TextSpan(text: _fmtDate(inv.saleDate)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Green divider ────────────────────────────────────
          Container(height: 1.5, color: _invoiceBorder),

          // ── Buyer section ────────────────────────────────────
          Container(
            color: _invoiceHeaderBg,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.t('buyer_section_label'),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A7A60),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  inv.buyerName,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
                if (inv.buyerMobile != null && inv.buyerMobile!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: _buyerRow(Icons.phone_outlined,
                        '${lang.t('mobile_prefix')} ${inv.buyerMobile}'),
                  ),
                if (inv.buyerGst != null && inv.buyerGst!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: _buyerRow(Icons.receipt_long_outlined,
                        '${lang.t('gst_prefix')} ${inv.buyerGst}'),
                  ),
                if (inv.buyerAddress != null && inv.buyerAddress!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: _buyerRow(Icons.location_on_outlined,
                        '${lang.t('address_prefix')} ${inv.buyerAddress}',
                        expand: true),
                  ),
              ],
            ),
          ),

          Container(height: 1, color: _invoiceBorder),

          // ── Product Table ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Table header row
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 9, horizontal: 10),
                  decoration: BoxDecoration(
                    color: _invoicePrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      _thCell(lang.t('col_product_inv'), flex: 3),
                      _thCell(lang.t('col_warehouse_inv'), flex: 2),
                      _thCell(lang.t('col_qty_inv'),
                          flex: 2, align: TextAlign.center),
                      _thCell(lang.t('col_rate_inv'),
                          flex: 2, align: TextAlign.right),
                      _thCell(lang.t('col_amount_inv'),
                          flex: 2, align: TextAlign.right),
                    ],
                  ),
                ),
                // Data rows
                ...inv.lines.asMap().entries.map((entry) {
                  final i = entry.key;
                  final line = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    decoration: BoxDecoration(
                      color: i.isEven ? Colors.white : _invoiceTableAlt,
                      border: const Border(
                          bottom: BorderSide(
                              color: _invoiceBorder, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(line.productName,
                              style: const TextStyle(fontSize: 12.5)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(line.warehouse,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF555555))),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${line.qty.toStringAsFixed(2)} ${line.unit}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _fmtCurrency(line.sellingPrice),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _fmtCurrency(line.lineTotal),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _invoicePrimary),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          Container(height: 1, color: _invoiceBorder),

          // ── Totals ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 260,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _invoiceHeaderBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _invoiceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _totalRow(lang.t('sub_total_inv'),
                          _fmtCurrency(inv.subTotal)),
                      if (inv.gstPercent > 0)
                        _totalRow(
                            'GST (${inv.gstPercent.toStringAsFixed(0)}%)',
                            _fmtCurrency(inv.gstAmount)),
                      const Divider(height: 14, color: _invoiceBorder),
                      _totalRow(
                        lang.t('grand_total_inv'),
                        _fmtCurrency(inv.grandTotal),
                        bold: true,
                        largeValue: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${lang.t('amount_words_prefix')} ${_numberToWords(inv.grandTotal)}',
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF4A7A60)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(height: 1, color: _invoiceBorder),

          // ── Payment Details ──────────────────────────────────
          if (inv.paymentMode.isNotEmpty) ...[
            Container(
              color: _invoiceHeaderBg,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              child: Wrap(
                spacing: 20,
                runSpacing: 6,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF1A1A1A)),
                      children: [
                        TextSpan(
                          text: '${lang.t('payment_mode_inv')} ',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: inv.paymentMode.toUpperCase()),
                      ],
                    ),
                  ),
                  if (inv.referenceNumber != null &&
                      inv.referenceNumber!.isNotEmpty)
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF1A1A1A)),
                        children: [
                          TextSpan(
                            text: '${lang.t('ref_no_inv')} ',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: inv.referenceNumber!),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(height: 1, color: _invoiceBorder),
          ],

          // ── Notes ────────────────────────────────────────────
          if (inv.notes != null && inv.notes!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.t('notes_inv'),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _invoicePrimary)),
                  const SizedBox(height: 4),
                  Text(inv.notes!,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF555555))),
                ],
              ),
            ),
            Container(height: 1, color: _invoiceBorder),
          ],

          // ── Signature Footer ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang.t('buyers_signature'),
                        style: const TextStyle(
                            fontSize: 10.5, color: Color(0xFF888888))),
                    const SizedBox(height: 26),
                    Container(
                        width: 130,
                        height: 1,
                        color: const Color(0xFFCCCCCC)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(lang.t('for_company'),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 26),
                    Container(
                        width: 130,
                        height: 1,
                        color: const Color(0xFFCCCCCC)),
                    const SizedBox(height: 3),
                    Text(lang.t('auth_signatory'),
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF888888))),
                  ],
                ),
              ],
            ),
          ),

          // ── Footer text ──────────────────────────────────────
          Container(
            width: double.infinity,
            color: _invoiceHeaderBg,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Text(
                  lang.t('footer_company'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF4A7A60)),
                ),
                const SizedBox(height: 3),
                Text(
                  '${lang.t('generated_on')} ${_fmtDateTime(DateTime.now())}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 9, color: Color(0xFF9AAAA2)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Small helpers ────────────────────────────────────────────

  Widget _buyerRow(IconData icon, String text, {bool expand = false}) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF7A9E8A)),
        const SizedBox(width: 5),
        expand
            ? Expanded(
                child: Text(text,
                    style: const TextStyle(fontSize: 12)))
            : Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
    return expand ? Row(children: [Expanded(child: content)]) : content;
  }

  Widget _thCell(String text,
      {required int flex, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value,
      {bool bold = false, bool largeValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: bold ? const Color(0xFF1A1A1A) : const Color(0xFF555555),
              )),
          Text(value,
              style: TextStyle(
                fontSize: largeValue ? 16 : 12,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: bold ? _invoicePrimary : const Color(0xFF1A1A1A),
              )),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(LanguageProvider lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error ?? lang.t('network_error'),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadInvoice,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _invoicePrimary),
              child: Text(lang.t('retry'),
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(LanguageProvider lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 64, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(lang.t('no_data')),
        ],
      ),
    );
  }
}
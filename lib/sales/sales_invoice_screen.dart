// sales_invoice_screen.dart
// ─────────────────────────────────────────────────────────────
//  SALES INVOICE SCREEN
//  • Matches the red "Jai Shivrai Vegetable Co." sample invoice
//  • Plain (no red bg) table header — matches the paper sample
//  • SalesInvoicePrinter.openPrintDialog() — call from anywhere
//    to skip the invoice screen and go straight to print / PDF
//  • Language toggle (EN / MR) in AppBar
//  • Print, PDF download, WhatsApp share
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
import '../models/sale_model.dart';


// =============================================================
//  STATIC HELPER
//  Call SalesInvoicePrinter.openPrintDialog(context, saleId)
//  from SaleDetailScreen (or anywhere) to fetch the invoice
//  and open the native print / save-as-PDF sheet directly —
//  no separate invoice screen needed.
// =============================================================

// sales_invoice_screen.dart (updated openPrintDialog and PDF builder)

// Update the openPrintDialog method to accept languageCode:

// =============================================================
//  INVOICE DATA MODEL - Fixed to match API response
// =============================================================

class SalesInvoiceLine {
  final String productName;
  final String warehouse;
  final double qty;
  final double sellingPrice;
  final double lineTotal;
  final String unit;

  SalesInvoiceLine({
    required this.productName,
    required this.warehouse,
    required this.qty,
    required this.sellingPrice,
    required this.lineTotal,
    required this.unit,
  });

  factory SalesInvoiceLine.fromJson(Map<String, dynamic> json) {
    return SalesInvoiceLine(
      productName: json['productName'] ?? json['product_name'] ?? 'Unknown',
      warehouse: json['warehouse'] ?? json['warehouseName'] ?? 'Main',
      qty: (json['netQty'] ?? json['quantity'] ?? 0).toDouble(),
      sellingPrice: (json['effectiveRate'] ?? json['rate'] ?? 0).toDouble(),
      lineTotal: (json['lineTotal'] ?? json['total'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'kg',
    );
  }
}

class SalesInvoiceData {
  final String invoiceNumber;
  final DateTime saleDate;
  final String buyerName;
  final String? buyerMobile;
  final String? buyerGst;
  final String? buyerAddress;
  final String paymentMode;
  final String? referenceNumber;
  final String? notes;
  final double subTotal;
  final double gstPercent;
  final double gstAmount;
  final double grandTotal;
  final List<SalesInvoiceLine> lines;

  SalesInvoiceData({
    required this.invoiceNumber,
    required this.saleDate,
    required this.buyerName,
    this.buyerMobile,
    this.buyerGst,
    this.buyerAddress,
    required this.paymentMode,
    this.referenceNumber,
    this.notes,
    required this.subTotal,
    required this.gstPercent,
    required this.gstAmount,
    required this.grandTotal,
    required this.lines,
  });

  factory SalesInvoiceData.fromJson(Map<String, dynamic> json) {
    // Log the response for debugging
    print('=== INVOICE DATA PARSING ===');
    print('Raw JSON: $json');
    
    // Handle different response structures
    final data = json['data'] ?? json;
    final sale = data['sale'] ?? data;
    
    // Parse sale lines - handle multiple possible structures
    List<SalesInvoiceLine> parseLines() {
      // Try different possible paths for lines
      List<dynamic> linesList = [];
      
      if (sale['lines'] != null && sale['lines'] is List) {
        linesList = sale['lines'] as List<dynamic>;
      } else if (sale['items'] != null && sale['items'] is List) {
        linesList = sale['items'] as List<dynamic>;
      } else if (sale['products'] != null && sale['products'] is List) {
        linesList = sale['products'] as List<dynamic>;
      } else if (data['lines'] != null && data['lines'] is List) {
        linesList = data['lines'] as List<dynamic>;
      }
      
      print('Found ${linesList.length} line items');
      
      if (linesList.isEmpty) {
        print('WARNING: No line items found in response');
      }
      
      return linesList.map((line) => SalesInvoiceLine.fromJson(line as Map<String, dynamic>)).toList();
    }
    
    // Parse numeric values safely
    double parseDouble(dynamic value, {double defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }
    
    // Get sale lines
    final lines = parseLines();
    
    // Calculate totals from lines if needed
    double calculatedSubTotal = lines.fold(0, (sum, line) => sum + line.lineTotal);
    double calculatedGrandTotal = sale['finalReceivable'] != null 
        ? parseDouble(sale['finalReceivable'])
        : (sale['grandTotal'] != null ? parseDouble(sale['grandTotal']) : calculatedSubTotal);
    
    // Parse GST (might be in different fields)
    double gstPercent = parseDouble(sale['gstPercent'] ?? sale['gst_rate'] ?? 0);
    double gstAmount = parseDouble(sale['gstAmount'] ?? sale['gst_amount'] ?? 0);
    
    // If GST amount is 0 but GST percent > 0, calculate it
    if (gstAmount == 0 && gstPercent > 0 && calculatedSubTotal > 0) {
      gstAmount = calculatedSubTotal * (gstPercent / 100);
    }
    
    // Parse date
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is DateTime) return dateValue;
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          // Try alternative date formats
          final formats = [
            'yyyy-MM-dd',
            'dd/MM/yyyy',
            'MM/dd/yyyy',
          ];
          for (var format in formats) {
            try {
              return DateFormat(format).parse(dateValue);
            } catch (_) {}
          }
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    
    final invoiceData = SalesInvoiceData(
      invoiceNumber: sale['invoiceNumber'] ?? sale['invoice_number'] ?? 'INV-${DateTime.now().millisecondsSinceEpoch}',
      saleDate: parseDate(sale['saleDate'] ?? sale['sale_date'] ?? sale['date']),
      buyerName: sale['buyerName'] ?? sale['buyer_name'] ?? sale['buyer']?['name'] ?? 'Unknown Buyer',
      buyerMobile: sale['buyerMobile'] ?? sale['buyer_mobile'] ?? sale['buyer']?['mobile'],
      buyerGst: sale['buyerGst'] ?? sale['buyer_gst'] ?? sale['buyer']?['gst'],
      buyerAddress: sale['buyerAddress'] ?? sale['buyer_address'] ?? sale['buyer']?['address'],
      paymentMode: sale['paymentMode'] ?? sale['payment_mode'] ?? 'cash',
      referenceNumber: sale['referenceNumber'] ?? sale['reference_number'] ?? sale['chequeNumber'],
      notes: sale['notes'] ?? sale['remarks'],
      subTotal: calculatedSubTotal,
      gstPercent: gstPercent,
      gstAmount: gstAmount,
      grandTotal: calculatedGrandTotal,
      lines: lines,
    );
    
    print('=== PARSED INVOICE DATA ===');
    print('Invoice No: ${invoiceData.invoiceNumber}');
    print('Sub Total: ${invoiceData.subTotal}');
    print('Grand Total: ${invoiceData.grandTotal}');
    print('Lines Count: ${invoiceData.lines.length}');
    
    return invoiceData;
  }
}
class SalesInvoicePrinter {
  static Future<void> openPrintDialog(
    BuildContext context,
    String saleId, {
    required String languageCode,
  }) async {
    // Show a blocking loading overlay
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (_) => const ColoredBox(
        color: Colors.black38,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
    overlayState.insert(overlayEntry);

    try {
      print('=== FETCHING INVOICE DATA FOR SALE: $saleId ===');
      
      // 1 ── Fetch invoice data
      final response = await DioClient.instance.dio.get(
        ApiRoutes.saleById(saleId),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      
      final responseData = response.data as Map<String, dynamic>;
      
      if (responseData['success'] != true) {
        throw Exception(responseData['message'] ?? 'Failed to load invoice');
      }
      
      // 2 ── Parse invoice data
      final inv = SalesInvoiceData.fromJson(responseData);
      
      // Validate we have data
      if (inv.lines.isEmpty) {
        throw Exception('No products found in this sale');
      }
      
      if (inv.grandTotal <= 0) {
        print('WARNING: Grand total is ${inv.grandTotal}, check calculations');
      }
      
      // 3 ── Build PDF
      final doc = await _InvoicePdfBuilder.build(inv, languageCode: languageCode);

      // 4 ── Open native print / download sheet
      overlayEntry.remove();
      await Printing.layoutPdf(
        onLayout: (_) => doc.save(),
        name: 'Invoice_${inv.invoiceNumber}.pdf',
      );
    } catch (e, stackTrace) {
      print('=== ERROR GENERATING INVOICE ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      
      overlayEntry.remove();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

// =============================================================
//  SCREEN  (available for standalone invoice view if needed)
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

  // ── Colour palette ────────────────────────────────────────────
  static const Color _red = Color(0xFFC8002D);
  static const Color _redBorder = Color(0xFFC8002D);
  static const Color _tableBg = Color(0xFFFFF5F7);
  static const Color _tableHeaderBg = Color(0xFFF7F7F7);
  static const Color _tableHeaderText = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await DioClient.instance.dio.get(
        ApiRoutes.saleById(widget.saleId),
      );
      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] != true) {
        throw Exception(responseData['message'] ?? 'Failed to load invoice');
      }
      setState(() {
        _invoice = SalesInvoiceData.fromJson(
            responseData['data'] as Map<String, dynamic>);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Helpers ──────────────────────────────────────────────────
  String _fmtDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  String _fmtCurrency(double amount) {
    return '₹ ${NumberFormat('#,##,##0', 'en_IN').format(amount)}';
  }
  String _fmtCurrencyFull(double amount) {
    return '₹ ${NumberFormat('#,##,##0.00', 'en_IN').format(amount)}';
  }
  String _numberToWords(double a) => _InvoicePdfBuilder.numberToWords(a);

  // ── Language toggle ──────────────────────────────────────────
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
                color: selected ? _red : Colors.white)),
      ),
    );
  }

  // ── WhatsApp ─────────────────────────────────────────────────
  Future<void> _shareWhatsApp(LanguageProvider lang) async {
    if (_invoice == null) return;
    final inv = _invoice!;
    final buf = StringBuffer();
    buf.writeln('🧾 *TAX INVOICE*');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('*Jai Shivrai Vegetable Co.*');
    buf.writeln('Vesarane, Tal. Kalwan, Dist. Nashik');
    buf.writeln('Invoice No.: ${inv.invoiceNumber}');
    buf.writeln('Date: ${_fmtDate(inv.saleDate)}');
    buf.writeln('');
    buf.writeln('*Buyer:* ${inv.buyerName}');
    if (inv.buyerMobile != null && inv.buyerMobile!.isNotEmpty) {
      buf.writeln('Mobile: ${inv.buyerMobile}');
    }
    buf.writeln('');
    for (final line in inv.lines) {
      buf.writeln('${line.productName} — ${line.qty} ${line.unit} × ${_fmtCurrencyFull(line.sellingPrice)} = ${_fmtCurrency(line.lineTotal)}');
    }
    buf.writeln('Sub Total: ${_fmtCurrency(inv.subTotal)}');
    if (inv.gstPercent > 0) {
      buf.writeln('GST (${inv.gstPercent.toStringAsFixed(0)}%): ${_fmtCurrency(inv.gstAmount)}');
    }
    buf.writeln('*Grand Total: ${_fmtCurrency(inv.grandTotal)}*');
    buf.writeln(_numberToWords(inv.grandTotal));
    buf.writeln('Payment: ${inv.paymentMode.toUpperCase()}');
    if (inv.referenceNumber != null && inv.referenceNumber!.isNotEmpty) {
      buf.writeln('Ref: ${inv.referenceNumber}');
    }
    buf.writeln('\nThank you! 🙏');

    final phone = inv.buyerMobile?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final waPhone = phone.length == 10 ? '91$phone' : phone;
    final text = buf.toString();
    final uri = waPhone.isNotEmpty
        ? Uri.parse('https://wa.me/$waPhone?text=${Uri.encodeComponent(text)}')
        : Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── PDF actions ──────────────────────────────────────────────
  Future<void> _printInvoice(LanguageProvider lang) async {
  if (_invoice == null) return;
  try {
    final doc = await _InvoicePdfBuilder.build(_invoice!, languageCode: lang.locale.languageCode);
    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: 'Invoice_${_invoice!.invoiceNumber}.pdf',
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print error: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}

Future<void> _downloadPdf(LanguageProvider lang) async {
  if (_invoice == null) return;
  setState(() => _exportingPdf = true);
  try {
    final doc = await _InvoicePdfBuilder.build(_invoice!, languageCode: lang.locale.languageCode);
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'Invoice_${_invoice!.invoiceNumber}.pdf',
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF error: $e'), backgroundColor: AppColors.error),
      );
    }
  } finally {
    if (mounted) setState(() => _exportingPdf = false);
  }
}
  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(lang.t('invoice_screen_title'),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: _red,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _buildLanguageToggle(lang),
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
          ? const Center(child: CircularProgressIndicator(color: _red))
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
  //  INVOICE CARD
  // ─────────────────────────────────────────────────────────────

  Widget _buildInvoiceCard(LanguageProvider lang) {
    final inv = _invoice!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _redBorder, width: 1.5),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Jurisdiction
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: Center(
              child: Text('|| Under Kalwan Jurisdiction ||',
                  style: TextStyle(fontSize: 11, color: _red, letterSpacing: 0.3)),
            ),
          ),
          // Company name
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Center(
              child: Text('Jai Shivrai Vegetable Co.',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: _red,
                      letterSpacing: -0.5)),
            ),
          ),
          // Address
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Center(
              child: Text('Vesarane, Tal. Kalwan, Dist. Nashik',
                  style: TextStyle(
                      fontSize: 11.5, color: _red, fontWeight: FontWeight.w500)),
            ),
          ),
          // TAX INVOICE badge
          const Padding(
            padding: EdgeInsets.only(top: 3, bottom: 6),
            child: Center(
              child: Text('TAX INVOICE',
                  style: TextStyle(
                      fontSize: 11, color: Color(0xFF777777), letterSpacing: 0.5)),
            ),
          ),

          _hBorder(),

          // Proprietors — use Flexible to prevent overflow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Prop. Rakesh Hire M: 9021699991 / 9623956396',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: _red),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Prop. Swajit Hire M: 9565459991 / 9919999999',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: _red),
                  ),
                ),
              ],
            ),
          ),

          _hBorder(),

          // Invoice No / Date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _boldRedLabel('Invoice No.:'),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(inv.invoiceNumber,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 16),
                _boldRedLabel('Date:'),
                const SizedBox(width: 6),
                Text(_fmtDate(inv.saleDate),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),

          _hBorder(),

          // Buyer Name / Mobile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _boldRedLabel('Buyer Name:'),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(inv.buyerName,
                      style: const TextStyle(fontSize: 13)),
                ),
                if (inv.buyerMobile != null && inv.buyerMobile!.isNotEmpty) ...[
                  _boldRedLabel('Mobile:'),
                  const SizedBox(width: 6),
                  Text(inv.buyerMobile!,
                      style: const TextStyle(fontSize: 13)),
                ],
              ],
            ),
          ),

          _hBorder(),

          // Payment Mode / GST
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _boldRedLabel('Payment Mode:'),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(inv.paymentMode.toUpperCase(),
                      style: const TextStyle(fontSize: 13)),
                ),
                if (inv.buyerGst != null && inv.buyerGst!.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  _boldRedLabel('GST:'),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(inv.buyerGst!,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),

          _hBorder(),

          // Product table
          _buildProductTable(inv),

          // Totals
          _totalsRow('Sub Total:', _fmtCurrency(inv.subTotal)),
          if (inv.gstPercent > 0)
            _totalsRow('GST (${inv.gstPercent.toStringAsFixed(0)}%):',
                '+ ${_fmtCurrency(inv.gstAmount)}'),
          _grandTotalRow(inv.grandTotal),

          _hBorder(),

          // Amount in Words
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'Amount in Words:  ${_numberToWords(inv.grandTotal)}',
              style: TextStyle(fontSize: 12, color: _red, fontWeight: FontWeight.w500),
            ),
          ),

          _hBorder(),

          // Reference No.
          if (inv.referenceNumber != null && inv.referenceNumber!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text('Reference No.: ${inv.referenceNumber}',
                  style: TextStyle(
                      fontSize: 12, color: _red, fontWeight: FontWeight.w600)),
            ),
            _hBorder(),
          ],

          // Notes
          if (inv.notes != null && inv.notes!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(inv.notes!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
            ),
            _hBorder(),
          ],

          // Thank You / Total Amount
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Text('Thank You!',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _red)),
                  ),
                ),
                Container(width: 1, color: _redBorder),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total Amount:  ',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _red)),
                      Text(_fmtCurrency(inv.grandTotal),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _red)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _hBorder(),

          // Signatures
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 24, 12, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 150, height: 1, color: _redBorder),
                    const SizedBox(height: 4),
                    Text('Buyer\'s Signature',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _red)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(width: 150, height: 1, color: _redBorder),
                    const SizedBox(height: 4),
                    Text('Jai Shivrai Vegetable Co., Kalwan',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _red)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  PRODUCT TABLE — plain grey header, no red background
  // ─────────────────────────────────────────────────────────────

  Widget _buildProductTable(SalesInvoiceData inv) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header — light grey bg, dark bold text (matches paper sample)
        Container(
          decoration: BoxDecoration(
            color: _tableHeaderBg,
            border: Border(bottom: BorderSide(color: _redBorder, width: 1)),
          ),
          child: Row(
            children: [
              _th('Sr.', flex: 1, align: TextAlign.center),
              _thDivider(),
              _th('Product', flex: 3, align: TextAlign.left),
              _thDivider(),
              _th('Warehouse', flex: 3, align: TextAlign.left),
              _thDivider(),
              _th('Qty', flex: 2, align: TextAlign.center),
              _thDivider(),
              _th('Rate (₹)', flex: 2, align: TextAlign.right),
              _thDivider(),
              _th('Amount (₹)', flex: 2, align: TextAlign.right),
            ],
          ),
        ),
        // Data rows
        ...inv.lines.asMap().entries.map((entry) {
          final i = entry.key;
          final line = entry.value;
          return Container(
            decoration: BoxDecoration(
              color: i.isEven ? Colors.white : _tableBg,
              border: Border(
                  bottom: BorderSide(color: _redBorder.withOpacity(0.22))),
            ),
            child: Row(
              children: [
                _td('${i + 1}', flex: 1, align: TextAlign.center),
                _tdDivider(),
                _td(line.productName, flex: 3, align: TextAlign.left, bold: true),
                _tdDivider(),
                _td(line.warehouse, flex: 3, align: TextAlign.left),
                _tdDivider(),
                _td(
                    '${line.qty.toStringAsFixed(line.qty == line.qty.toInt() ? 0 : 2)} ${line.unit}',
                    flex: 2,
                    align: TextAlign.center),
                _tdDivider(),
                _td('₹ ${NumberFormat('#,##,##0', 'en_IN').format(line.sellingPrice)}',
                    flex: 2, align: TextAlign.right),
                _tdDivider(),
                _td('₹ ${NumberFormat('#,##,##0', 'en_IN').format(line.lineTotal)}',
                    flex: 2,
                    align: TextAlign.right,
                    bold: true,
                    color: _red),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Micro widgets ────────────────────────────────────────────

  Widget _th(String text, {required int flex, TextAlign align = TextAlign.center}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        child: Text(text,
            textAlign: align,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _tableHeaderText)),
      ),
    );
  }

  Widget _thDivider() =>
      Container(width: 1, height: 36, color: const Color(0xFFDDDDDD));

  Widget _tdDivider() =>
      Container(width: 1, height: 38, color: Color(0xFFC8002D).withOpacity(0.18));

  Widget _td(String text,
      {required int flex,
      TextAlign align = TextAlign.center,
      bool bold = false,
      Color? color}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Text(text,
            textAlign: align,
            style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: color ?? const Color(0xFF1A1A1A))),
      ),
    );
  }

  Widget _hBorder() => Container(height: 1, color: _redBorder);

  Widget _boldRedLabel(String text) => Text(text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _red));

  Widget _totalsRow(String label, String value) {
    return Container(
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: _redBorder))),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _red)),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _grandTotalRow(double total) {
    return Container(
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: _redBorder))),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Grand Total:',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: _red)),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: Text(_fmtCurrency(total),
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900, color: _red)),
          ),
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
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFC8002D)),
            const SizedBox(height: 16),
            Text(_error ?? lang.t('network_error'), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadInvoice,
              style:
                  ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC8002D)),
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
          Icon(Icons.receipt_long_outlined,
              size: 64,
              color: const Color(0xFFC8002D).withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(lang.t('no_data')),
        ],
      ),
    );
  }
}

// =============================================================
//  PDF BUILDER  (shared by both SalesInvoicePrinter and screen)
// =============================================================

class _InvoicePdfBuilder {
  static get _englishPdfTranslations => null;
  
  static get _marathiPdfTranslations => null;

  static String numberToWords(double amount) {
    final intAmount = amount.toInt();
    if (intAmount == 0) return 'Zero Rupees Only';

    const ones = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
      'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
      'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen',
    ];
    const tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
      'Sixty', 'Seventy', 'Eighty', 'Ninety',
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

// Update the _InvoicePdfBuilder.build method signature and content:

// Update the _InvoicePdfBuilder.build method in sales_invoice_screen.dart

static Future<pw.Document> build(SalesInvoiceData inv, {required String languageCode}) async {
  final regularFont = await PdfGoogleFonts.notoSansRegular();
  final boldFont = await PdfGoogleFonts.notoSansBold();
  
  // Determine if Marathi
  final isMarathi = languageCode == 'mr';
  
  // ── Translations for PDF (defined inside the method) ──────────────
  final Map<String, String> englishPdfTranslations = {
    'tax_invoice_badge': 'TAX INVOICE',
    'invoice_no_label': 'Invoice No.:',
    'date_label_inv': 'Date:',
    'buyer_section_label': 'Buyer Name:',
    'mobile_prefix': 'Mobile:',
    'gst_prefix': 'GST:',
    'payment_mode_inv': 'Payment Mode:',
    'pdf_col_product': 'Product',
    'pdf_col_warehouse': 'Warehouse',
    'pdf_col_qty': 'Qty',
    'pdf_col_rate': 'Rate (₹)',
    'pdf_col_amount': 'Amount (₹)',
    'pdf_sub_total': 'Sub Total:',
    'pdf_grand_total': 'Grand Total:',
    'pdf_amount_words': 'Amount in Words:',
    'pdf_ref_no': 'Reference No.:',
    'pdf_notes': 'Notes:',
    'pdf_buyers_sig': "Buyer's Signature",
    'pdf_for_company': 'For Jai Shivrai Vegetable Co., Kalwan',
    'pdf_footer': 'Jai Shivrai Vegetable Co., Kalwan',
    'pdf_generated': 'Generated on:',
  };
  
  final Map<String, String> marathiPdfTranslations = {
    'tax_invoice_badge': 'कर बीजक',
    'invoice_no_label': 'बीजक क्र.:',
    'date_label_inv': 'दिनांक:',
    'buyer_section_label': 'खरेदीदाराचे नाव:',
    'mobile_prefix': 'मोबाइल:',
    'gst_prefix': 'जीएसटी:',
    'payment_mode_inv': 'पेमेंट पद्धत:',
    'pdf_col_product': 'उत्पादन',
    'pdf_col_warehouse': 'गोदाम',
    'pdf_col_qty': 'प्रमाण',
    'pdf_col_rate': 'दर (₹)',
    'pdf_col_amount': 'रक्कम (₹)',
    'pdf_sub_total': 'उप-एकूण:',
    'pdf_grand_total': 'एकूण रक्कम:',
    'pdf_amount_words': 'रक्कम अक्षरी:',
    'pdf_ref_no': 'संदर्भ क्रमांक:',
    'pdf_notes': 'सूचना:',
    'pdf_buyers_sig': 'खरेदीदाराची स्वाक्षरी',
    'pdf_for_company': 'जय शिवराय भाजीपाला, कळवण साठी',
    'pdf_footer': 'जय शिवराय भाजीपाला, कळवण',
    'pdf_generated': 'तयार केले:',
  };
  
  // Translation function
  String t(String key) {
    if (isMarathi) {
      return marathiPdfTranslations[key] ?? englishPdfTranslations[key] ?? key;
    }
    return englishPdfTranslations[key] ?? key;
  }
  
  const pdfRed = PdfColor.fromInt(0xFFC8002D);
  const pdfBorder = PdfColor.fromInt(0xFFC8002D);
  const pdfHeaderBg = PdfColor.fromInt(0xFFF7F7F7);
  const pdfGrey = PdfColors.grey700;
  final fmt = NumberFormat('#,##,##0', 'en_IN');
  final fmtDate = DateFormat('dd/MM/yyyy');
  final fmtDT = DateFormat('dd/MM/yyyy, hh:mm a');

  pw.TextStyle ts({
    double size = 9,
    bool bold = false,
    PdfColor color = PdfColors.black,
  }) =>
      pw.TextStyle(
          font: bold ? boldFont : regularFont, fontSize: size, color: color);

  // Plain header cell: grey bg, dark bold text
  pw.Widget hCell(String text, {pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Container(
      color: pdfHeaderBg,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      child: pw.Text(text,
          textAlign: align,
          style: ts(size: 8.5, bold: true, color: PdfColors.black)),
    );
  }

  pw.Widget dCell(String text,
      {pw.TextAlign align = pw.TextAlign.center,
      bool bold = false,
      PdfColor color = PdfColors.black}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      child: pw.Text(text,
          textAlign: align, style: ts(size: 8.5, bold: bold, color: color)),
    );
  }

  pw.Widget infoRow(String label, String value,
      {String? label2, String? value2}) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: pdfBorder, width: 1))),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: pw.Row(children: [
        pw.Text('$label  ', style: ts(size: 9, bold: true, color: pdfRed)),
        pw.Expanded(child: pw.Text(value, style: ts(size: 9))),
        if (label2 != null && value2 != null) ...[
          pw.Text('$label2  ',
              style: ts(size: 9, bold: true, color: pdfRed)),
          pw.Text(value2, style: ts(size: 9)),
        ],
      ]),
    );
  }

  pw.Widget totalsRow(String label, String value,
      {bool bold = false, bool large = false}) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: pdfBorder, width: 1))),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text('$label  ',
              style: ts(size: large ? 10 : 9, bold: bold, color: pdfRed)),
          pw.Text(value,
              style: ts(size: large ? 12 : 9, bold: bold, color: pdfRed)),
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
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: pdfBorder, width: 1.5)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Jurisdiction
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 5),
                  child: pw.Center(
                    child: pw.Text('|| Under Kalwan Jurisdiction ||',
                        style: ts(size: 8.5, color: pdfRed)),
                  ),
                ),
                // Company (always English as per business name)
                pw.Center(
                  child: pw.Text('Jai Shivrai Vegetable Co.',
                      style: ts(size: 22, bold: true, color: pdfRed)),
                ),
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text('Vesarane, Tal. Kalwan, Dist. Nashik',
                      style: ts(size: 9, color: pdfRed)),
                ),
                pw.SizedBox(height: 3),
                pw.Center(
                  child: pw.Text(t('tax_invoice_badge'),
                      style: ts(size: 9, color: pdfGrey)),
                ),
                pw.SizedBox(height: 4),

                // Proprietors (always English)
                pw.Container(
                  decoration: const pw.BoxDecoration(
                      border: pw.Border(
                          top: pw.BorderSide(color: pdfBorder, width: 1),
                          bottom:
                              pw.BorderSide(color: pdfBorder, width: 1))),
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                          'Prop. Rakesh Hire M: 9021699991 / 9623956396',
                          style: ts(size: 7.5, bold: true, color: pdfRed)),
                      pw.Text(
                          'Prop. Swajit Hire M: 9565459991 / 9919999999',
                          style: ts(size: 7.5, bold: true, color: pdfRed)),
                    ],
                  ),
                ),

                // Invoice No / Date
                infoRow(t('invoice_no_label'), inv.invoiceNumber,
                    label2: t('date_label_inv'), value2: fmtDate.format(inv.saleDate)),

                // Buyer / Mobile
                infoRow(t('buyer_section_label'), inv.buyerName,
                    label2: (inv.buyerMobile?.isNotEmpty == true)
                        ? t('mobile_prefix')
                        : null,
                    value2: inv.buyerMobile),

                // Payment / GST
                infoRow(t('payment_mode_inv'), inv.paymentMode.toUpperCase(),
                    label2: (inv.buyerGst?.isNotEmpty == true) ? t('gst_prefix') : null,
                    value2: inv.buyerGst),

                // Product table — plain header with bilingual columns
                pw.Table(
                  border: pw.TableBorder(
                    bottom: const pw.BorderSide(color: pdfBorder, width: 1),
                    horizontalInside:
                        const pw.BorderSide(color: pdfBorder, width: 0.5),
                    verticalInside:
                        const pw.BorderSide(color: pdfBorder, width: 0.8),
                  ),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(28),
                    1: const pw.FlexColumnWidth(2.5),
                    2: const pw.FlexColumnWidth(2.0),
                    3: const pw.FlexColumnWidth(1.5),
                    4: const pw.FlexColumnWidth(1.8),
                    5: const pw.FlexColumnWidth(1.8),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: pdfHeaderBg),
                      children: [
                        hCell('Sr.'),
                        hCell(t('pdf_col_product'), align: pw.TextAlign.left),
                        hCell(t('pdf_col_warehouse'), align: pw.TextAlign.left),
                        hCell(t('pdf_col_qty')),
                        hCell(t('pdf_col_rate'), align: pw.TextAlign.right),
                        hCell(t('pdf_col_amount'), align: pw.TextAlign.right),
                      ],
                    ),
                    ...inv.lines.asMap().entries.map((e) {
                      final i = e.key;
                      final line = e.value;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: i.isEven
                              ? PdfColors.white
                              : const PdfColor.fromInt(0xFFFFF8F9),
                        ),
                        children: [
                          dCell('${i + 1}'),
                          dCell(line.productName, align: pw.TextAlign.left),
                          dCell(line.warehouse, align: pw.TextAlign.left),
                          dCell('${line.qty.toStringAsFixed(0)} ${line.unit}'),
                          dCell('₹ ${fmt.format(line.sellingPrice)}',
                              align: pw.TextAlign.right),
                          dCell('₹ ${fmt.format(line.lineTotal)}',
                              align: pw.TextAlign.right,
                              bold: true,
                              color: pdfRed),
                        ],
                      );
                    }),
                  ],
                ),

                // Totals
                totalsRow(t('pdf_sub_total'), '₹ ${fmt.format(inv.subTotal)}'),
                if (inv.gstPercent > 0)
                  totalsRow(
                      'GST (${inv.gstPercent.toStringAsFixed(0)}%):',
                      '+ ₹ ${fmt.format(inv.gstAmount)}'),
                totalsRow(t('pdf_grand_total'), '₹ ${fmt.format(inv.grandTotal)}',
                    bold: true, large: true),

                // Amount in words
                pw.Container(
                  decoration: const pw.BoxDecoration(
                      border: pw.Border(
                          bottom:
                              pw.BorderSide(color: pdfBorder, width: 1))),
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  child: pw.Text(
                      '${t('pdf_amount_words')} ${numberToWords(inv.grandTotal)}',
                      style: ts(size: 8.5, color: pdfRed)),
                ),

                // Ref No.
                if (inv.referenceNumber?.isNotEmpty == true)
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(
                            bottom: pw.BorderSide(
                                color: pdfBorder, width: 1))),
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    child: pw.Text(
                        '${t('pdf_ref_no')} ${inv.referenceNumber}',
                        style: ts(size: 8.5, color: pdfRed)),
                  ),

                // Notes
                if (inv.notes?.isNotEmpty == true)
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(
                            bottom: pw.BorderSide(
                                color: pdfBorder, width: 1))),
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    child: pw.Text(
                        '${t('pdf_notes')} ${inv.notes}',
                        style: ts(size: 8.5, color: pdfRed)),
                  ),

                // Thank You / Total
                pw.Container(
                  decoration: const pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(color: pdfBorder, width: 1))),
                  child: pw.Row(children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: pw.Text('Thank You!',
                            style: ts(size: 10, bold: true, color: pdfRed)),
                      ),
                    ),
                    pw.Container(width: 1, height: 36, color: pdfBorder),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: pw.Row(children: [
                        pw.Text('Total Amount:  ',
                            style:
                                ts(size: 9, bold: true, color: pdfRed)),
                        pw.Text('₹ ${fmt.format(inv.grandTotal)}',
                            style: ts(
                                size: 13, bold: true, color: pdfRed)),
                      ]),
                    ),
                  ]),
                ),

                // Signatures
                pw.Container(
                  padding:
                      const pw.EdgeInsets.fromLTRB(10, 20, 10, 12),
                  child: pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('......................................',
                              style: ts(size: 9, color: pdfRed)),
                          pw.SizedBox(height: 2),
                          pw.Text(t('pdf_buyers_sig'),
                              style: ts(
                                  size: 8.5, bold: true, color: pdfRed)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('......................................',
                              style: ts(size: 9, color: pdfRed)),
                          pw.SizedBox(height: 2),
                          pw.Text(
                              t('pdf_for_company'),
                              style: ts(
                                  size: 8.5, bold: true, color: pdfRed)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
                '${t('pdf_generated')} ${fmtDT.format(DateTime.now())}',
                style: ts(size: 7, color: PdfColors.grey500)),
          ),
        ],
      ),
    ),
  );

  return doc;
}

}
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/constants/colors.dart';
import '../../../services/dio_client.dart';
import '../../../services/constant_service.dart';
import '../payment/payment_screen.dart';

// ─────────────────────────────────────────────────────────────
//  RECEIPT SCREEN
// ─────────────────────────────────────────────────────────────

class ReceiptScreen extends StatefulWidget {
  final String purchaseId;
  final String? farmerName;
  final String? farmerMobile;

  const ReceiptScreen({
    super.key,
    required this.purchaseId,
    this.farmerName,
    this.farmerMobile,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _receipt;
  bool _loading = true;
  String? _error;

  late AnimationController _checkCtrl;
  late Animation<double> _checkScale;
  late Animation<double> _checkFade;

  // ─────────────────────────────────────────────────────────
  //  PDF DOWNLOAD
  // ─────────────────────────────────────────────────────────
  Future<void> _downloadPdf() async {
    if (_receipt == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 14),
                Text('Generating PDF…',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final pdfDoc = await _generateReceiptPdf();
      final bytes = await pdfDoc.save();

      if (mounted) Navigator.pop(context);

      final receiptNo = (_receipt!['receiptNumber'] as String? ?? 'receipt')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Receipt_$receiptNo.pdf',
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _snack('Failed to generate PDF: $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  //  PDF GENERATION
  // ─────────────────────────────────────────────────────────
Future<pw.Document> _generateReceiptPdf() async {
  // ── Fonts ───────────────────────────────────────────────
  final regularFont = await PdfGoogleFonts.notoSansRegular();
  final boldFont = await PdfGoogleFonts.notoSansBold();

  final r = _receipt!;
  final farmer = r['farmer'] as Map<String, dynamic>? ?? {};
  final business = r['business'] as Map<String, dynamic>? ?? {};
  final lines = r['lines'] as List? ?? [];
  final deductions = r['deductions'] as Map<String, dynamic>? ?? {};
  final payments = r['payments'] as List? ?? [];

  // ── Colors ─────────────────────────────────────────────
  const green = PdfColor.fromInt(0xFF2E7D32);
  const lightGreenBorder = PdfColor.fromInt(0xFFC8E6C9);
  const textGrey = PdfColor.fromInt(0xFF6B4C3B);
  const redAccent = PdfColor.fromInt(0xFFD32F2F);
  const orangeAccent = PdfColor.fromInt(0xFFFF6F00);

  // ── Helpers ────────────────────────────────────────────
  double toD(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

  String fmtRs(dynamic v) =>
      '₹${toD(v).toStringAsFixed(0)}';

  pw.TextStyle ts({
    double size = 9,
    pw.FontWeight weight = pw.FontWeight.normal,
    PdfColor color = PdfColors.black,
  }) {
    return pw.TextStyle(
      font: weight == pw.FontWeight.bold ? boldFont : regularFont,
      fontBold: boldFont,
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  pw.Widget borderedBox(
    pw.Widget child, {
    double padding = 10,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: lightGreenBorder,
          width: 0.8,
        ),
      ),
      padding: pw.EdgeInsets.all(padding),
      child: child,
    );
  }

  pw.Widget summaryRow(
    String label,
    String value, {
    bool bold = false,
    PdfColor valueColor = green,
    double size = 11,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: lightGreenBorder, width: 0.8),
          right: pw.BorderSide(color: lightGreenBorder, width: 0.8),
          bottom: pw.BorderSide(color: lightGreenBorder, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: ts(
              size: size,
              weight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: green,
            ),
          ),
          pw.Text(
            value,
            style: ts(
              size: size,
              weight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget deductionRow(String title, dynamic value) {
    if (toD(value) <= 0) {
      return pw.SizedBox();
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: ts(
              size: 8,
              color: textGrey,
            ),
          ),
          pw.Text(
            fmtRs(value),
            style: ts(
              size: 8,
              weight: pw.FontWeight.bold,
              color: redAccent,
            ),
          ),
        ],
      ),
    );
  }

  // ── Data ───────────────────────────────────────────────
  final grossTotal = toD(r['grossTotal']);
  final totalDed = toD(r['totalDeductions']);
  final finalPayable = toD(r['finalPayable']);
  final amountPaid = toD(r['amountPaid']);
  final amountDue = toD(r['amountDue']);

  final receiptNo =
      r['receiptNumber']?.toString() ?? 'N/A';

  final dateStr = _fmtDateFull(
    r['purchaseDate']?.toString() ??
        r['createdAt']?.toString() ??
        '',
  );

  final farmerName =
      farmer['name']?.toString() ??
          widget.farmerName ??
          '';

  final mobile =
      farmer['mobile']?.toString() ??
          widget.farmerMobile ??
          '';

  final village =
      farmer['village']?.toString() ?? '';

  final state =
      farmer['state']?.toString() ?? '';

  final address =
      farmer['address']?.toString() ?? '';

  final bizName =
      business['name']?.toString() ??
          'Farm ERP';

  final bizAddress =
      business['address']?.toString() ?? '';

  final bizPhone =
      business['phone']?.toString() ?? '';

  final bizEmail =
      business['email']?.toString() ?? '';

  final bizGst =
      business['gst']?.toString() ?? '';

  final notes =
      r['notes']?.toString() ?? '';

  final status =
      r['status']?.toString() ?? 'Saved';

  String paymentMethod = 'Cash';

  if (payments.isNotEmpty) {
    final modes = payments
        .map((p) =>
            (p['mode'] ??
                    p['paymentMode'] ??
                    '')
                .toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .join(', ');

    if (modes.isNotEmpty) {
      paymentMethod = modes;
    }
  }

  final doc = pw.Document();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(35, 25, 35, 20),

      build: (context) {
        return pw.Column(
          crossAxisAlignment:
              pw.CrossAxisAlignment.start,
          children: [

            // HEADER
            pw.Row(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [

                pw.Text(
                  'Logo',
                  style: ts(
                    size: 24,
                    weight: pw.FontWeight.bold,
                    color: green,
                  ),
                ),

                pw.Spacer(),

                pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.end,
                  children: [

                    pw.Text(
                      bizName,
                      style: ts(
                        size: 14,
                        weight: pw.FontWeight.bold,
                        color: green,
                      ),
                    ),

                    pw.SizedBox(height: 2),

                    if (bizAddress.isNotEmpty)
                      pw.Text(
                        bizAddress,
                        style: ts(
                          size: 7.5,
                          color: textGrey,
                        ),
                      ),

                    if (business['city'] != null ||
                        business['state'] != null)
                      pw.Text(
                        '${business['city'] ?? ''}, ${business['state'] ?? ''}',
                        style: ts(
                          size: 7.5,
                          color: textGrey,
                        ),
                      ),

                    if (bizPhone.isNotEmpty)
                      pw.Text(
                        'Tel: $bizPhone',
                        style: ts(
                          size: 7.5,
                          color: textGrey,
                        ),
                      ),

                    if (bizEmail.isNotEmpty)
                      pw.Text(
                        'Email: $bizEmail',
                        style: ts(
                          size: 7.5,
                          color: textGrey,
                        ),
                      ),

                    if (bizGst.isNotEmpty)
                      pw.Text(
                        'GST: $bizGst',
                        style: ts(
                          size: 7.5,
                          color: textGrey,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 18),

            // RECEIPT NO + DATE
            pw.Row(
              children: [

                pw.Expanded(
                  child: borderedBox(
                    pw.Text(
                      'Receipt No: $receiptNo',
                      style: ts(
                        size: 9,
                        weight: pw.FontWeight.bold,
                        color: green,
                      ),
                    ),
                    padding: 7,
                  ),
                ),

                pw.SizedBox(width: 10),

                pw.Expanded(
                  child: borderedBox(
                    pw.Text(
                      dateStr,
                      style: ts(
                        size: 9,
                        weight: pw.FontWeight.bold,
                        color: green,
                      ),
                    ),
                    padding: 7,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 12),

            // FARMER BOX
            borderedBox(
              pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.start,
                children: [

                  pw.Text(
                    farmerName,
                    style: ts(
                      size: 9.5,
                      weight: pw.FontWeight.bold,
                      color: green,
                    ),
                  ),

                  if (mobile.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(
                        'Mobile: $mobile',
                        style: ts(
                          size: 7.8,
                          color: green,
                        ),
                      ),
                    ),

                  if (village.isNotEmpty ||
                      state.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(
                        'Village: $village, $state',
                        style: ts(
                          size: 7.8,
                          color: green,
                        ),
                      ),
                    ),

                  if (address.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(
                        'Address: $address',
                        style: ts(
                          size: 7.8,
                          color: green,
                        ),
                      ),
                    ),
                ],
              ),
              padding: 8,
            ),

            pw.SizedBox(height: 12),

            // TABLE
            pw.Table(
              border: pw.TableBorder.all(
                color: lightGreenBorder,
                width: 0.8,
              ),

              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(2.2),
                4: const pw.FlexColumnWidth(2.5),
              },

              children: [

                // HEADER
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: green,
                  ),
                  children: [

                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'DESCRIPTION',
                        style: ts(
                          size: 7.5,
                          weight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),

                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'QTY',
                        textAlign: pw.TextAlign.right,
                        style: ts(
                          size: 7.5,
                          weight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),

                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'UNIT',
                        textAlign: pw.TextAlign.right,
                        style: ts(
                          size: 7.5,
                          weight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),

                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'RATE',
                        textAlign: pw.TextAlign.right,
                        style: ts(
                          size: 7.5,
                          weight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),

                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'TOTAL',
                        textAlign: pw.TextAlign.right,
                        style: ts(
                          size: 7.5,
                          weight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                // ROWS
                ...lines.map((l) {

                  final qty =
                      toD(l['billedQty']);

                  final unit =
                      l['unit']?.toString() ?? '';

                  final rate =
                      toD(l['rate']);

                  final total =
                      toD(l['lineTotal']);

                  return pw.TableRow(
                    children: [

                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          l['productName']
                                  ?.toString() ??
                              '',
                          style: ts(
                            size: 7.8,
                            color: green,
                          ),
                        ),
                      ),

                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          qty.toStringAsFixed(0),
                          textAlign:
                              pw.TextAlign.right,
                          style: ts(
                            size: 7.8,
                            color: green,
                          ),
                        ),
                      ),

                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          unit,
                          textAlign:
                              pw.TextAlign.right,
                          style: ts(
                            size: 7.8,
                            color: green,
                          ),
                        ),
                      ),

                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          fmtRs(rate),
                          textAlign:
                              pw.TextAlign.right,
                          style: ts(
                            size: 7.8,
                            color: green,
                          ),
                        ),
                      ),

                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          fmtRs(total),
                          textAlign:
                              pw.TextAlign.right,
                          style: ts(
                            size: 7.8,
                            weight: pw.FontWeight.bold,
                            color: orangeAccent,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),

            pw.SizedBox(height: 12),

            // BOTTOM
            pw.Row(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [

                // LEFT SIDE
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [

                      // DEDUCTIONS
                      borderedBox(
                        pw.Column(
                          crossAxisAlignment:
                              pw.CrossAxisAlignment.start,
                          children: [

                            pw.Text(
                              'Deductions',
                              style: ts(
                                size: 8.5,
                                weight: pw.FontWeight.bold,
                                color: green,
                              ),
                            ),

                            pw.SizedBox(height: 6),

                            deductionRow(
                              'Transport',
                              deductions['transport'],
                            ),

                            deductionRow(
                              'Labour',
                              deductions['labour'],
                            ),

                            deductionRow(
                              deductions['commissionType'] == 'percent'
                                  ? 'Commission (${deductions['commission']}%)'
                                  : 'Commission',
                              deductions['commission'],
                            ),

                            deductionRow(
                              'Storage',
                              deductions['storage'],
                            ),

                            deductionRow(
                              'Return',
                              deductions['returnDeduction'],
                            ),

                            deductionRow(
                              'Advance',
                              deductions['advanceAdjusted'],
                            ),

                            deductionRow(
                              'Other',
                              deductions['other'],
                            ),

                            if (totalDed <= 0)
                              pw.Text(
                                'No deductions applied',
                                style: ts(
                                  size: 7.5,
                                  color: textGrey,
                                ),
                              ),
                          ],
                        ),
                        padding: 8,
                      ),

                      pw.SizedBox(height: 8),

                      // PAYMENT
                      borderedBox(
                        pw.Row(
                          children: [

                            pw.Text(
                              'Payment Method: ',
                              style: ts(
                                size: 7.8,
                                weight:
                                    pw.FontWeight.bold,
                                color: textGrey,
                              ),
                            ),

                            pw.Text(
                              paymentMethod,
                              style: ts(
                                size: 7.8,
                                color: textGrey,
                              ),
                            ),
                          ],
                        ),
                        padding: 8,
                      ),

                      pw.SizedBox(height: 8),

                      // TERMS
                      pw.Text(
                        'Terms and Conditions',
                        style: ts(
                          size: 8,
                          weight: pw.FontWeight.bold,
                          color: green,
                        ),
                      ),

                      pw.SizedBox(height: 3),

                      pw.Text(
                        '1. Goods once sold will not be taken back.\n'
                        '2. Payment is due within 30 days.\n'
                        '3. Interest may apply on overdue payments.\n'
                        '4. Computer generated receipt.',
                        style: ts(
                          size: 6.5,
                          color: textGrey,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(width: 10),

                // RIGHT SIDE
                pw.Expanded(
                  flex: 4,
                  child: pw.Column(
                    children: [

                      summaryRow(
                        'Sub Total',
                        fmtRs(grossTotal),
                      ),

                      summaryRow(
                        'Total Deduction',
                        '-${fmtRs(totalDed)}',
                        valueColor: redAccent,
                      ),

                      summaryRow(
                        'Grand Total',
                        fmtRs(finalPayable),
                        bold: true,
                        valueColor: orangeAccent,
                        size: 11,
                      ),

                      summaryRow(
                        'Paid',
                        fmtRs(amountPaid),
                      ),

                      summaryRow(
                        'Balance',
                        fmtRs(amountDue),
                        valueColor: amountDue > 0
                            ? redAccent
                            : green,
                      ),

                      // STATUS
                      pw.Container(
                        width: double.infinity,
                        padding:
                            const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: lightGreenBorder,
                            width: 0.8,
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                          children: [

                            pw.Text(
                              'Status',
                              style: ts(
                                size: 8,
                              ),
                            ),

                            pw.Text(
                              status,
                              style: ts(
                                size: 8,
                                weight:
                                    pw.FontWeight.bold,
                                color: status
                                            .toLowerCase() ==
                                        'paid'
                                    ? green
                                    : orangeAccent,
                              ),
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 8),

                      // SIGNATURES
                      pw.Row(
                        children: [

                          pw.Expanded(
                            child: pw.Container(
                              height: 55,
                              padding:
                                  const pw.EdgeInsets.all(6),
                              decoration:
                                  pw.BoxDecoration(
                                border: pw.Border.all(
                                  color:
                                      lightGreenBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [

                                  pw.Text(
                                    'Receive By',
                                    style: ts(
                                      size: 6.5,
                                      weight:
                                          pw.FontWeight.bold,
                                      color: green,
                                    ),
                                  ),

                                  pw.Text(
                                    'Authorized Signatory',
                                    style: ts(
                                      size: 5.8,
                                      color: textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          pw.SizedBox(width: 6),

                          pw.Expanded(
                            child: pw.Container(
                              height: 55,
                              padding:
                                  const pw.EdgeInsets.all(6),
                              decoration:
                                  pw.BoxDecoration(
                                border: pw.Border.all(
                                  color:
                                      lightGreenBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [

                                  pw.Text(
                                    'Signature',
                                    style: ts(
                                      size: 6.5,
                                      weight:
                                          pw.FontWeight.bold,
                                      color: green,
                                    ),
                                  ),

                                  pw.Text(
                                    'Farmer Signature',
                                    style: ts(
                                      size: 5.8,
                                      color: textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 6),

            // FOOTER
            pw.Container(
              width: double.infinity,
              padding:
                  const pw.EdgeInsets.only(top: 6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(
                    color: lightGreenBorder,
                    width: 0.8,
                  ),
                ),
              ),
              child: pw.Column(
                children: [

                  pw.Text(
                    'Purchase Date: ${_fmtDate(r['purchaseDate']?.toString() ?? '')}',
                    style: ts(
                      size: 6,
                      color: textGrey,
                    ),
                  ),

                  pw.SizedBox(height: 1),

                  pw.Text(
                    'Generated on ${_fmtDateFull(DateTime.now().toIso8601String())}',
                    style: ts(
                      size: 6,
                      color: textGrey,
                    ),
                  ),

                  if (notes.isNotEmpty)
                    pw.Padding(
                      padding:
                          const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(
                        notes,
                        style: ts(
                          size: 6,
                          color: textGrey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  return doc;
} // ─────────────────────────────────────────────────────────
  //  INIT / DISPOSE
  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _checkScale = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut));
    _checkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _checkCtrl, curve: Curves.easeIn));
    _fetchReceipt();
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  FETCH & TRANSFORM
  // ─────────────────────────────────────────────────────────
  Future<void> _fetchReceipt() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await DioClient.instance.dio
          .get('${ApiRoutes.purchaseById(widget.purchaseId)}/receipt?format=json');
      final responseData = res.data as Map<String, dynamic>;
      if (responseData['success'] != true) throw Exception('Failed to load receipt');
      final data = responseData['data'] as Map<String, dynamic>;
      setState(() => _receipt = _transformReceiptData(data));
      _checkCtrl.forward();
    } catch (e) {
      setState(() => _error = _friendly(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _transformReceiptData(Map<String, dynamic> data) {
    final purchase = data['purchase'] as Map<String, dynamic>? ?? {};
    final items    = purchase['items'] as List? ?? [];

    final lines = items.map((item) {
      final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
      final rate     = (item['rate']     as num?)?.toDouble() ?? 0;
      final amount   = (item['amount']   as num?)?.toDouble() ?? 0;
      return {
        'productName'     : item['productName']?.toString() ?? '',
        'billedQty'       : quantity,
        'actualQty'       : quantity,
        'unit'            : item['unit']?.toString() ?? '',
        'rate'            : rate,
        'lineTotal'       : amount,
        'pricingType'     : item['pricingType']?.toString() ?? '',
        'qualityDeduction': (item['qualityDeduction'] as num?)?.toDouble() ?? 0,
      };
    }).toList();

    double grossTotal = (purchase['grossTotal'] as num?)?.toDouble() ?? 0;
    if (grossTotal == 0 && lines.isNotEmpty) {
      grossTotal = lines.fold(0.0, (s, l) => s + (l['lineTotal'] as double));
    }

    final deductions = Map<String, dynamic>.from(purchase['deductions'] as Map? ?? {});

    double advanceAdjusted = (deductions['advanceAdjusted'] as num?)?.toDouble() ?? 0;
    if (advanceAdjusted == 0) {
      for (final p in data['payments'] as List? ?? []) {
        if (p['mode'] == 'advance') {
          advanceAdjusted += (p['amount'] as num?)?.toDouble() ?? 0;
        }
      }
      deductions['advanceAdjusted'] = advanceAdjusted;
    }

    final amountPaid   = (purchase['amountPaid']   as num?)?.toDouble() ?? 0;
    final amountDue    = (purchase['amountDue']    as num?)?.toDouble() ?? 0;
    final finalPayable = (purchase['finalPayable'] as num?)?.toDouble() ?? 0;

    return {
      'receiptNumber'  : data['receiptNumber']?.toString() ?? '',
      'purchaseDate'   : data['purchaseDate']?.toString() ?? data['receiptDate']?.toString() ?? '',
      'createdAt'      : data['receiptDate']?.toString() ?? '',
      'farmer'         : data['farmer']   ?? {},
      'business'       : data['business'] ?? {},
      'lines'          : lines,
      'deductions'     : deductions,
      'grossTotal'     : grossTotal,
      'totalDeductions': (purchase['totalDeductions'] as num?)?.toDouble() ?? 0,
      'finalPayable'   : finalPayable,
      'amountPaid'     : amountPaid,
      'amountDue'      : amountDue,
      'status'         : purchase['status']?.toString() ?? 'Draft',
      'notes'          : purchase['notes'] ?? '',
      'summary'        : data['summary']  ?? {},
      'payments'       : data['payments'] ?? [],
    };
  }

  // ─────────────────────────────────────────────────────────
  //  ACTIONS
  // ─────────────────────────────────────────────────────────
  void _goToPayment() async {
    if (_receipt == null) return;
    final amountDue = (_receipt!['amountDue'] as num?)?.toDouble() ?? 0;
    if (amountDue <= 0) {
      _snack('This purchase is fully paid', success: true);
      return;
    }
    final farmer   = _receipt!['farmer'] as Map<String, dynamic>? ?? {};
    final farmerId = farmer['_id']?.toString() ?? farmer['id']?.toString() ?? '';
    final paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          purchaseId   : widget.purchaseId,
          farmerId     : farmerId,
          farmerName   : farmer['name']?.toString() ?? widget.farmerName ?? '',
          finalPayable : (_receipt!['finalPayable'] as num?)?.toDouble() ?? 0,
          amountPaid   : (_receipt!['amountPaid']   as num?)?.toDouble() ?? 0,
          amountDue    : amountDue,
          receiptNumber: _receipt!['receiptNumber']?.toString() ?? '',
        ),
      ),
    );
    if (paid == true && mounted) await _fetchReceipt();
  }

  Future<void> _shareWhatsApp() async {
    if (_receipt == null) return;
    final text   = _buildWhatsAppText();
    final farmer = _receipt!['farmer'] as Map<String, dynamic>? ?? {};
    final mobile = farmer['mobile']?.toString() ?? widget.farmerMobile ?? '';
    final digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final phone  = digits.length == 10 ? '91$digits' : digits;
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(
          Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'),
          mode: LaunchMode.externalApplication);
    }
  }

  String _buildWhatsAppText() {
    if (_receipt == null) return '';
    final r          = _receipt!;
    final farmer     = r['farmer']     as Map<String, dynamic>? ?? {};
    final business   = r['business']   as Map<String, dynamic>? ?? {};
    final lines      = r['lines']      as List? ?? [];
    final deductions = r['deductions'] as Map<String, dynamic>? ?? {};
    final grossTotal   = (r['grossTotal']   as num?)?.toDouble() ?? 0;
    final finalPayable = (r['finalPayable'] as num?)?.toDouble() ?? 0;
    final amountPaid   = (r['amountPaid']   as num?)?.toDouble() ?? 0;
    final amountDue    = (r['amountDue']    as num?)?.toDouble() ?? 0;

    final buf = StringBuffer();
    buf.writeln('🌾 *${business['name'] ?? 'FARM ERP'}*');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('Receipt No: *${r['receiptNumber'] ?? ''}*');
    buf.writeln('Date: ${_fmtDate(r['purchaseDate']?.toString() ?? '')}');
    buf.writeln('Farmer: *${farmer['name'] ?? widget.farmerName ?? ''}*');
    if ((farmer['mobile'] ?? widget.farmerMobile ?? '').isNotEmpty)
      buf.writeln('Mobile: ${farmer['mobile'] ?? widget.farmerMobile}');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('*PRODUCTS*');
    for (final l in lines) {
      final qty   = (l['billedQty'] as num?)?.toDouble() ?? 0;
      final rate  = (l['rate']      as num?)?.toDouble() ?? 0;
      final total = (l['lineTotal'] as num?)?.toDouble() ?? 0;
      buf.writeln(
          '• ${l['productName']}: ${qty.toStringAsFixed(2)} ${l['unit']} × ₹${rate.toStringAsFixed(2)} = ₹${total.toStringAsFixed(2)}');
    }
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('Gross Total: ₹${grossTotal.toStringAsFixed(2)}');
    if ((deductions['transport']       as num? ?? 0) > 0) buf.writeln('Transport: -₹${(deductions['transport'] as num).toStringAsFixed(2)}');
    if ((deductions['labour']          as num? ?? 0) > 0) buf.writeln('Labour: -₹${(deductions['labour'] as num).toStringAsFixed(2)}');
    if ((deductions['commission']      as num? ?? 0) > 0) buf.writeln('Commission: -₹${(deductions['commission'] as num).toStringAsFixed(2)}');
    if ((deductions['storage']         as num? ?? 0) > 0) buf.writeln('Storage: -₹${(deductions['storage'] as num).toStringAsFixed(2)}');
    if ((deductions['returnDeduction'] as num? ?? 0) > 0) buf.writeln('Return Deduction: -₹${(deductions['returnDeduction'] as num).toStringAsFixed(2)}');
    if ((deductions['advanceAdjusted'] as num? ?? 0) > 0) buf.writeln('Advance Adjusted: -₹${(deductions['advanceAdjusted'] as num).toStringAsFixed(2)}');
    if ((deductions['other']           as num? ?? 0) > 0) buf.writeln('Other: -₹${(deductions['other'] as num).toStringAsFixed(2)}');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('*FINAL PAYABLE: ₹${finalPayable.toStringAsFixed(2)}*');
    if (amountPaid > 0) buf.writeln('Paid: ₹${amountPaid.toStringAsFixed(2)}');
    buf.writeln(amountDue > 0
        ? '*Balance Due: ₹${amountDue.toStringAsFixed(2)}*'
        : '✅ FULLY PAID');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('Thank you for your business!');
    return buf.toString();
  }

  void _printReceipt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PrintSheet(receipt: _receipt),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildReceipt(),
    );
  }

  Widget _buildLoading() => const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Generating receipt…',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppColors.textSecondary)),
        ]),
      );

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.receipt_long_outlined,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text('Purchase saved successfully!',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
                'Receipt could not be loaded: $_error\nYou can view it later from the purchase list.',
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _fetchReceipt,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Retry',
                  style: TextStyle(fontFamily: 'Poppins')),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Done — Go Back',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textSecondary)),
            ),
          ]),
        ),
      );

  Widget _buildReceipt() {
    final r            = _receipt!;
    final farmer       = r['farmer']     as Map<String, dynamic>? ?? {};
    final lines        = r['lines']      as List? ?? [];
    final deductions   = r['deductions'] as Map<String, dynamic>? ?? {};
    final receiptNo    = r['receiptNumber']?.toString() ?? '—';
    final date         = _fmtDateFull(r['purchaseDate']?.toString() ?? r['createdAt']?.toString() ?? '');
    final farmerName   = farmer['name']?.toString()   ?? widget.farmerName   ?? '—';
    final farmerMobile = farmer['mobile']?.toString() ?? widget.farmerMobile ?? '';
    final grossTotal   = (r['grossTotal']   as num?)?.toDouble() ?? 0;
    final finalPayable = (r['finalPayable'] as num?)?.toDouble() ?? 0;
    final amountPaid   = (r['amountPaid']   as num?)?.toDouble() ?? 0;
    final amountDue    = (r['amountDue']    as num?)?.toDouble() ?? 0;
    final isFullyPaid  = amountDue <= 0;

    return Column(children: [
      Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(children: [
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context, true),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                const Text('Purchase Receipt',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins')),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFullyPaid
                        ? Colors.green.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isFullyPaid
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        width: 0.6),
                  ),
                  child: Text(
                    isFullyPaid
                        ? '✓ Fully Paid'
                        : 'Due ₹${_fmtMoney(amountDue)}',
                    style: TextStyle(
                        color: isFullyPaid
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins'),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _checkFade,
                child: ScaleTransition(
                  scale: _checkScale,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 36),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Purchase Saved!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 4),
              Text(receiptNo,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontFamily: 'Poppins')),
            ]),
          ),
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          child: Column(children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('FARMER',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHint,
                                fontFamily: 'Poppins',
                                letterSpacing: 1)),
                        const SizedBox(height: 3),
                        Text(farmerName,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'Poppins')),
                        if (farmerMobile.isNotEmpty)
                          Text(farmerMobile,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'Poppins')),
                      ]),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        const Text('DATE',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHint,
                                fontFamily: 'Poppins',
                                letterSpacing: 1)),
                        const SizedBox(height: 3),
                        Text(date,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontFamily: 'Poppins')),
                      ]),
                    ],
                  ),
                ),
                const Divider(
                    color: AppColors.divider,
                    height: 1,
                    indent: 18,
                    endIndent: 18),
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Text('PRODUCTS',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHint,
                          fontFamily: 'Poppins',
                          letterSpacing: 1)),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Row(children: [
                    Expanded(flex: 3, child: _colHead('Product')),
                    Expanded(
                        flex: 2,
                        child: _colHead('Qty × Rate',
                            align: TextAlign.center)),
                    Expanded(
                        child: _colHead('Total', align: TextAlign.right)),
                  ]),
                ),
                ...lines.map((l) {
                  final name      = l['productName']?.toString() ?? '—';
                  final billedQty = (l['billedQty'] as num?)?.toDouble() ?? 0;
                  final unit      = l['unit']?.toString() ?? '';
                  final rate      = (l['rate'] as num?)?.toDouble() ?? 0;
                  final total     = (l['lineTotal'] as num?)?.toDouble() ?? 0;
                  final pt        = l['pricingType']?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 6),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 3,
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                            fontFamily: 'Poppins')),
                                    if (pt.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                            color: AppColors.primarySurface,
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: Text(pt.toUpperCase(),
                                            style: const TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                                fontFamily: 'Poppins')),
                                      ),
                                  ])),
                          Expanded(
                              flex: 2,
                              child: Text(
                                '${billedQty.toStringAsFixed(2)} $unit\n@ ₹${rate.toStringAsFixed(2)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'Poppins'),
                              )),
                          Expanded(
                              child: Text(
                            '₹${total.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'Poppins'),
                          )),
                        ]),
                  );
                }),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Divider(color: AppColors.divider, height: 24),
                ),
                if (_hasDeductions(deductions)) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, 8),
                    child: Text('DEDUCTIONS',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHint,
                            fontFamily: 'Poppins',
                            letterSpacing: 1)),
                  ),
                  _deductionRow('Transport', deductions['transport']),
                  _deductionRow('Labour', deductions['labour']),
                  if ((deductions['commission'] as num? ?? 0) > 0)
                    _deductionRow(
                        deductions['commissionType'] == 'percent'
                            ? 'Commission (${deductions['commission']}%)'
                            : 'Commission',
                        deductions['commission']),
                  _deductionRow('Storage', deductions['storage']),
                  _deductionRow(
                      'Return Deduction', deductions['returnDeduction']),
                  _deductionRow(
                      'Advance Adjusted', deductions['advanceAdjusted'],
                      isAdvance: true),
                  _deductionRow('Other', deductions['other']),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Divider(color: AppColors.divider, height: 20),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 4),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Gross Total',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontFamily: 'Poppins')),
                        Text('₹${grossTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontFamily: 'Poppins')),
                      ]),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('FINAL PAYABLE',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0.5)),
                          Text('₹${finalPayable.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontFamily: 'Poppins')),
                        ]),
                    if (amountPaid > 0 || amountDue > 0) ...[
                      const SizedBox(height: 8),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 6),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.greenAccent, size: 14),
                              const SizedBox(width: 6),
                              Text('Paid: ₹${amountPaid.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      fontFamily: 'Poppins')),
                            ]),
                            if (amountDue > 0)
                              Text('Due: ₹${amountDue.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orangeAccent,
                                      fontFamily: 'Poppins'))
                            else
                              const Text('✓ Fully Paid',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins')),
                          ]),
                    ],
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                if (amountDue > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _goToPayment,
                      icon: const Icon(Icons.payments_rounded, size: 18),
                      label: Text(
                          'Pay Now  ·  ₹${amountDue.toStringAsFixed(2)} Due',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareWhatsApp,
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text('WhatsApp',
                          style:
                              TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _printReceipt,
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('Print',
                          style:
                              TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _downloadPdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: const Text('PDF',
                          style:
                              TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Done — Back to Dashboard',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    ]);
  }

  // ── Widget helpers ────────────────────────────────────────
  Widget _colHead(String text, {TextAlign align = TextAlign.left}) =>
      Text(text,
          textAlign: align,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textHint,
              fontFamily: 'Poppins',
              letterSpacing: 0.5));

  Widget _deductionRow(String label, dynamic value,
      {bool isAdvance = false}) {
    final v = (value as num?)?.toDouble() ?? 0;
    if (v <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(
              isAdvance
                  ? Icons.currency_rupee_rounded
                  : Icons.remove_circle_outline_rounded,
              size: 13,
              color: isAdvance ? AppColors.info : AppColors.warning),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins')),
        ]),
        Text('-₹${v.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: isAdvance ? AppColors.info : AppColors.warning)),
      ]),
    );
  }

  bool _hasDeductions(Map<String, dynamic> d) {
    for (final k in [
      'transport', 'labour', 'commission', 'storage',
      'returnDeduction', 'advanceAdjusted', 'other'
    ]) {
      if ((d[k] as num? ?? 0) > 0) return true;
    }
    return false;
  }

  String _fmtDate(String raw) {
    if (raw.isEmpty) return '—';
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return raw;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _fmtDateFull(String raw) {
    if (raw.isEmpty) return '—';
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}, '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _fmtMoney(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('connection')) {
      return 'No internet connection.';
    }
    if (s.contains('404')) return 'Receipt not found.';
    return 'Could not load receipt.';
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ─────────────────────────────────────────────────────────────
//  PRINT BOTTOM SHEET
// ─────────────────────────────────────────────────────────────
class _PrintSheet extends StatelessWidget {
  final Map<String, dynamic>? receipt;
  const _PrintSheet({this.receipt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
            child: Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.only(bottom: 20, top: 8),
          decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2)),
        )),
        const Icon(Icons.print_rounded, size: 40, color: AppColors.primary),
        const SizedBox(height: 12),
        const Text('Print Receipt',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        const Text(
          'Make sure your Bluetooth thermal printer is turned on and paired with this device.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
              height: 1.5),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                  'Bluetooth printing — connect your thermal printer and try again.',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                behavior: SnackBarBehavior.floating,
              ));
            },
            icon: const Icon(Icons.bluetooth_rounded, size: 18),
            label: const Text('Connect & Print',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(
                  fontFamily: 'Poppins', color: AppColors.textSecondary)),
        ),
      ]),
    );
  }
}
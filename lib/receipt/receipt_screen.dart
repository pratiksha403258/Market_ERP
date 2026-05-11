import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/constants/colors.dart';
import '../../../services/dio_client.dart';
import '../../../services/constant_service.dart';
import '../payment/payment_screen.dart';

// ─────────────────────────────────────────────────────────────
//  RECEIPT SCREEN  (M-08)
//
//  Spec: "Receipt view after purchase save.
//        Print via Bluetooth thermal printer. WhatsApp share."
//
//  Flow:  NewPurchaseScreen.savePurchase() succeeds
//           → Navigator.pushReplacement to ReceiptScreen(purchaseId)
//           → Receipt loads via GET /purchases/:id/receipt
//           → User can: Pay Now → PaymentScreen
//                        Share WhatsApp
//                        Print (Bluetooth thermal)
//                        Done → back to Dashboard
//
//  API: GET /purchases/:id/receipt
//  Returns: { success: true, data: { receiptNumber, receiptDate, 
//            purchaseDate, farmer, business, purchase: { items, deductions, 
//            grossTotal, totalDeductions, finalPayable, amountPaid, amountDue, 
//            status, notes }, payments, summary } }
// ─────────────────────────────────────────────────────────────

class ReceiptScreen extends StatefulWidget {
  final String purchaseId;

  // These are passed from NewPurchaseScreen immediately after save
  // so we can show something while the API loads
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
  
  Future<void> _downloadPdf() async {
  if (_receipt == null) return;

  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final pdfDoc = await _generateReceiptPdf();
    await Printing.sharePdf(
      bytes: await pdfDoc.save(),
      filename: 'receipt_${_receipt!['receiptNumber']}.pdf',
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } finally {
    if (mounted) Navigator.pop(context); // close loading dialog
  }
}

  @override
  void initState() {
    super.initState();
    // Success checkmark animation
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


Future<pw.Document> _generateReceiptPdf() async {
  final r = _receipt!;
  final farmer = r['farmer'] as Map<String, dynamic>? ?? {};
  final business = r['business'] as Map<String, dynamic>? ?? {};
  final lines = r['lines'] as List? ?? [];
  final deductions = r['deductions'] as Map<String, dynamic>? ?? {};

  final doc = pw.Document();

  // Safe double conversion helper
  double toDouble(dynamic value) => (value as num?)?.toDouble() ?? 0.0;

  // Format currency safely
  String fmt(dynamic v) => '₹${toDouble(v).toStringAsFixed(2)}';

  // ---- CALCULATE ALL VALUES BEFORE BUILDING WIDGETS ----
  final grossTotal = toDouble(r['grossTotal']);
  final finalPayable = toDouble(r['finalPayable']);
  final amountPaid = toDouble(r['amountPaid']);
  final amountDue = toDouble(r['amountDue']);
  final transport = toDouble(deductions['transport']);
  final labour = toDouble(deductions['labour']);
  final commission = toDouble(deductions['commission']);
  final storage = toDouble(deductions['storage']);
  final advanceAdjusted = toDouble(deductions['advanceAdjusted']);

  doc.addPage(
    pw.Page(
      margin: const pw.EdgeInsets.all(20),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Center(
            child: pw.Column(children: [
              pw.Text(
                business['name'] ?? 'FARM ERP',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (business['address'] != null)
                pw.Text(business['address'], style: pw.TextStyle(fontSize: 10)),
              if (business['phone'] != null)
                pw.Text('Tel: ${business['phone']}', style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 10),
              pw.Text('PURCHASE RECEIPT',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Receipt No: ${r['receiptNumber']}',
                  style: pw.TextStyle(fontSize: 12)),
              pw.Text('Date: ${_fmtDateFull(r['purchaseDate'] ?? r['createdAt'])}',
                  style: pw.TextStyle(fontSize: 12)),
            ]),
          ),
          pw.Divider(),
          pw.SizedBox(height: 10),

          // Farmer details
          pw.Row(children: [
            pw.Text('Farmer:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(width: 10),
            pw.Text(farmer['name'] ?? ''),
          ]),
          if (farmer['mobile'] != null)
            pw.Row(children: [
              pw.Text('Mobile:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(width: 10),
              pw.Text(farmer['mobile']),
            ]),
          pw.SizedBox(height: 15),

          // Product table
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Product', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rate', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              ...lines.map((line) {
                final rate = toDouble(line['rate']);
                final lineTotal = toDouble(line['lineTotal']);
                final billedQty = toDouble(line['billedQty']);
                final unit = line['unit'] ?? '';
                return pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(line['productName'] ?? '')),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${billedQty.toStringAsFixed(2)} $unit', textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('₹${rate.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('₹${lineTotal.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 10),

          // Deductions section
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Gross Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(fmt(grossTotal)),
          ]),
          if (transport > 0)
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('  Transport'),
              pw.Text('- ${fmt(transport)}'),
            ]),
          if (labour > 0)
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('  Labour'),
              pw.Text('- ${fmt(labour)}'),
            ]),
          if (commission > 0)
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('  Commission${deductions['commissionType'] == 'percent' ? ' (${deductions['commission']}%)' : ''}'),
              pw.Text('- ${fmt(commission)}'),
            ]),
          if (storage > 0)
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('  Storage'),
              pw.Text('- ${fmt(storage)}'),
            ]),
          if (advanceAdjusted > 0)
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('  Advance Adjusted'),
              pw.Text('- ${fmt(advanceAdjusted)}'),
            ]),
          pw.Divider(),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('FINAL PAYABLE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.Text(fmt(finalPayable), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          ]),
          pw.SizedBox(height: 10),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Amount Paid:'),
            pw.Text(fmt(amountPaid)),
          ]),
          if (amountDue > 0)
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Balance Due:', style: pw.TextStyle(color: PdfColors.red)),
              pw.Text(fmt(amountDue), style: pw.TextStyle(color: PdfColors.red)),
            ])
          else
            pw.Text('✓ FULLY PAID', style: pw.TextStyle(color: PdfColors.green, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Center(child: pw.Text('Thank you for your business!', style: pw.TextStyle(fontSize: 10))),
        ],
      ),
    ),
  );

  return doc;
}
  // ── GET /purchases/:id/receipt ────────────────────────────
  Future<void> _fetchReceipt() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await DioClient.instance.dio
          .get('${ApiRoutes.purchaseById(widget.purchaseId)}/receipt?format=json');

      final responseData = res.data as Map<String, dynamic>;

      if (responseData['success'] != true) {
        throw Exception('Failed to load receipt');
      }

      final data = responseData['data'] as Map<String, dynamic>;
      
      // Transform backend data to match UI expectations
      final transformedReceipt = _transformReceiptData(data);
      
      setState(() => _receipt = transformedReceipt);
      _checkCtrl.forward();
    } catch (e) {
      setState(() => _error = _friendly(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Transforms backend API response to UI-friendly format
 /// Transforms backend API response (from GET /purchases/:id/receipt)
/// into the format expected by the UI.
Map<String, dynamic> _transformReceiptData(Map<String, dynamic> data) {
  final purchase = data['purchase'] as Map<String, dynamic>? ?? {};
  final items = purchase['items'] as List? ?? [];

  // Map each item to a line that the UI understands
  final lines = items.map((item) {
    final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
    final rate = (item['rate'] as num?)?.toDouble() ?? 0;
    final amount = (item['amount'] as num?)?.toDouble() ?? 0;

    return {
      'productName': item['productName']?.toString() ?? '',
      'billedQty': quantity,          // UI uses billedQty = actual quantity
      'actualQty': quantity,
      'unit': item['unit']?.toString() ?? '',
      'rate': rate,
      'lineTotal': amount,             // UI uses lineTotal = amount
      'pricingType': item['pricingType']?.toString() ?? '',
      'qualityDeduction': (item['qualityDeduction'] as num?)?.toDouble() ?? 0,
    };
  }).toList();

  // Gross total from purchase object
  double grossTotal = (purchase['grossTotal'] as num?)?.toDouble() ?? 0;
  if (grossTotal == 0 && lines.isNotEmpty) {
    grossTotal = lines.fold(0.0, (sum, l) => sum + (l['lineTotal'] as double));
  }

  // Deductions – already in purchase['deductions']
  final deductions = Map<String, dynamic>.from(purchase['deductions'] as Map? ?? {});

  // Advance adjusted – if missing, try to extract from payments
  double advanceAdjusted = (deductions['advanceAdjusted'] as num?)?.toDouble() ?? 0;
  if (advanceAdjusted == 0) {
    final payments = data['payments'] as List? ?? [];
    for (final payment in payments) {
      if (payment['mode'] == 'advance') {   // backend uses 'mode', not 'paymentMode'
        advanceAdjusted += (payment['amount'] as num?)?.toDouble() ?? 0;
      }
    }
    deductions['advanceAdjusted'] = advanceAdjusted;
  }

  // Amount paid & due
  final amountPaid = (purchase['amountPaid'] as num?)?.toDouble() ?? 0;
  final amountDue = (purchase['amountDue'] as num?)?.toDouble() ?? 0;
  final finalPayable = (purchase['finalPayable'] as num?)?.toDouble() ?? 0;

  return {
    'receiptNumber': data['receiptNumber']?.toString() ?? '',
    'purchaseDate': data['purchaseDate']?.toString() ?? data['receiptDate']?.toString() ?? '',
    'createdAt': data['receiptDate']?.toString() ?? '',
    'farmer': data['farmer'] ?? {},
    'business': data['business'] ?? {},
    'lines': lines,
    'deductions': deductions,
    'grossTotal': grossTotal,
    'totalDeductions': (purchase['totalDeductions'] as num?)?.toDouble() ?? 0,
    'finalPayable': finalPayable,
    'amountPaid': amountPaid,
    'amountDue': amountDue,
    'status': purchase['status']?.toString() ?? 'draft',
    'notes': purchase['notes'] ?? '',
    'summary': data['summary'] ?? {},
    'payments': data['payments'] ?? [],
  };
}
  // ── Navigate to PaymentScreen ─────────────────────────────
  void _goToPayment() async {
    if (_receipt == null) return;
    final amountDue = (_receipt!['amountDue'] as num?)?.toDouble() ?? 0;
    if (amountDue <= 0) {
      _snack('This purchase is fully paid', success: true);
      return;
    }
    final farmer = _receipt!['farmer'] as Map<String, dynamic>? ?? {};
    final farmerId = farmer['_id']?.toString() ??
        farmer['id']?.toString() ??
        _receipt!['farmerId']?.toString() ??
        '';

    final paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          purchaseId: widget.purchaseId,
          farmerId: farmerId,
          farmerName: farmer['name']?.toString() ?? widget.farmerName ?? '',
          finalPayable: (_receipt!['finalPayable'] as num?)?.toDouble() ?? 0,
          amountPaid: (_receipt!['amountPaid'] as num?)?.toDouble() ?? 0,
          amountDue: amountDue,
          receiptNumber: _receipt!['receiptNumber']?.toString() ?? '',
        ),
      ),
    );
    if (paid == true && mounted) {
      // Refresh receipt to show updated paid/due amounts
      await _fetchReceipt();
    }
  }

  // ── WhatsApp Share ────────────────────────────────────────
  Future<void> _shareWhatsApp() async {
    if (_receipt == null) return;
    final text = _buildWhatsAppText();
    final farmer = _receipt!['farmer'] as Map<String, dynamic>? ?? {};
    final mobile = farmer['mobile']?.toString() ?? widget.farmerMobile ?? '';
    // Remove +91 or leading 0 if present; WhatsApp needs just digits
    final digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final phone = digits.length == 10 ? '91$digits' : digits;

    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: open WhatsApp without pre-filled number
      final fallback = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  String _buildWhatsAppText() {
    if (_receipt == null) return '';
    final r = _receipt!;
    final farmer = r['farmer'] as Map<String, dynamic>? ?? {};
    final business = r['business'] as Map<String, dynamic>? ?? {};
    final lines = r['lines'] as List? ?? [];
    final deductions = r['deductions'] as Map<String, dynamic>? ?? {};
    final receiptNo = r['receiptNumber'] ?? '';
    final date = _fmtDate(r['purchaseDate']?.toString() ?? r['createdAt']?.toString() ?? '');
    final farmerName = farmer['name'] ?? widget.farmerName ?? '';
    final farmerMobile = farmer['mobile'] ?? widget.farmerMobile ?? '';
    final grossTotal = (r['grossTotal'] as num?)?.toDouble() ?? 0;
    final finalPayable = (r['finalPayable'] as num?)?.toDouble() ?? 0;
    final amountPaid = (r['amountPaid'] as num?)?.toDouble() ?? 0;
    final amountDue = (r['amountDue'] as num?)?.toDouble() ?? 0;

    final buf = StringBuffer();
    buf.writeln('🌾 *${business['name'] ?? 'FARM ERP'}*');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('Receipt No: *$receiptNo*');
    buf.writeln('Date: $date');
    buf.writeln('Farmer: *$farmerName*');
    if (farmerMobile.isNotEmpty) buf.writeln('Mobile: $farmerMobile');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('*PRODUCTS*');
    for (final l in lines) {
      final name = l['productName'] ?? '';
      final qty = (l['billedQty'] as num?)?.toDouble() ?? 0;
      final unit = l['unit'] ?? '';
      final rate = (l['rate'] as num?)?.toDouble() ?? 0;
      final total = (l['lineTotal'] as num?)?.toDouble() ?? 0;
      buf.writeln(
          '• $name: ${qty.toStringAsFixed(2)} $unit × ₹${rate.toStringAsFixed(2)} = ₹${total.toStringAsFixed(2)}');
    }
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('Gross Total: ₹${grossTotal.toStringAsFixed(2)}');
    
    if ((deductions['transport'] as num? ?? 0) > 0) {
      buf.writeln('Transport: -₹${(deductions['transport'] as num).toStringAsFixed(2)}');
    }
    if ((deductions['labour'] as num? ?? 0) > 0) {
      buf.writeln('Labour: -₹${(deductions['labour'] as num).toStringAsFixed(2)}');
    }
    if ((deductions['commission'] as num? ?? 0) > 0) {
      final commissionType = deductions['commissionType'] ?? 'fixed';
      if (commissionType == 'percent') {
        buf.writeln('Commission (${deductions['commission']}%): -₹${((grossTotal * (deductions['commission'] as num) / 100)).toStringAsFixed(2)}');
      } else {
        buf.writeln('Commission: -₹${(deductions['commission'] as num).toStringAsFixed(2)}');
      }
    }
    if ((deductions['storage'] as num? ?? 0) > 0) {
      buf.writeln('Storage: -₹${(deductions['storage'] as num).toStringAsFixed(2)}');
    }
    if ((deductions['returnDeduction'] as num? ?? 0) > 0) {
      buf.writeln('Return Deduction: -₹${(deductions['returnDeduction'] as num).toStringAsFixed(2)}');
    }
    if ((deductions['advanceAdjusted'] as num? ?? 0) > 0) {
      buf.writeln('Advance Adjusted: -₹${(deductions['advanceAdjusted'] as num).toStringAsFixed(2)}');
    }
    if ((deductions['other'] as num? ?? 0) > 0) {
      buf.writeln('Other: -₹${(deductions['other'] as num).toStringAsFixed(2)}');
    }
    
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('*FINAL PAYABLE: ₹${finalPayable.toStringAsFixed(2)}*');
    if (amountPaid > 0) {
      buf.writeln('Paid: ₹${amountPaid.toStringAsFixed(2)}');
    }
    if (amountDue > 0) {
      buf.writeln('*Balance Due: ₹${amountDue.toStringAsFixed(2)}*');
    } else {
      buf.writeln('✅ FULLY PAID');
    }
    
    buf.writeln('━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('Thank you for your business!');
    
    return buf.toString();
  }

  // ── Bluetooth Print ───────────────────────────────────────
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

  Widget _buildLoading() {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: AppColors.primary),
        SizedBox(height: 16),
        Text('Generating receipt...',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
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
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Retry',
                style: TextStyle(fontFamily: 'Poppins')),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Done — Go Back',
                style: TextStyle(
                    fontFamily: 'Poppins', color: AppColors.textSecondary)),
          ),
        ]),
      ),
    );
  }

  Widget _buildReceipt() {
    final r = _receipt!;
    final farmer = r['farmer'] as Map<String, dynamic>? ?? {};
    final lines = r['lines'] as List? ?? [];
    final deductions = r['deductions'] as Map<String, dynamic>? ?? {};
    final receiptNo = r['receiptNumber']?.toString() ?? '—';
    final date = _fmtDateFull(
        r['purchaseDate']?.toString() ?? r['createdAt']?.toString() ?? '');
    final farmerName = farmer['name']?.toString() ?? widget.farmerName ?? '—';
    final farmerMobile = farmer['mobile']?.toString() ?? widget.farmerMobile ?? '';
    final grossTotal = (r['grossTotal'] as num?)?.toDouble() ?? 0;
    final finalPayable = (r['finalPayable'] as num?)?.toDouble() ?? 0;
    final amountPaid = (r['amountPaid'] as num?)?.toDouble() ?? 0;
    final amountDue = (r['amountDue'] as num?)?.toDouble() ?? 0;
    final isFullyPaid = amountDue <= 0;

    return Column(
      children: [
        // ── Top gradient header ──────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(children: [
                // Title row
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, true),
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
                  const Text('Purchase Receipt',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins')),
                  const Spacer(),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFullyPaid
                          ? Colors.green.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isFullyPaid
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      isFullyPaid ? '✓ Fully Paid' : 'Due ₹${_fmtMoney(amountDue)}',
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
                // Success checkmark animation
                FadeTransition(
                  opacity: _checkFade,
                  child: ScaleTransition(
                    scale: _checkScale,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        shape: BoxShape.circle,
                      ),
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

        // ── Scrollable receipt body ──────────────────────────
        Expanded(
          child: SingleChildScrollView(
            child: Column(children: [
              // Receipt card
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Farmer Info
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
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
                        color: AppColors.divider, height: 1, indent: 18, endIndent: 18),

                    // Product Lines header
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

                    // Column headers
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                      child: Row(children: [
                        Expanded(
                            flex: 3,
                            child: _colHead('Product')),
                        Expanded(
                            flex: 2,
                            child: _colHead('Qty × Rate',
                                align: TextAlign.center)),
                        Expanded(
                            child: _colHead('Total',
                                align: TextAlign.right)),
                      ]),
                    ),

                    // Product line items
                    ...lines.map((l) {
                      final name = l['productName']?.toString() ?? '—';
                      final billedQty = (l['billedQty'] as num?)?.toDouble() ?? 0;
                      final unit = l['unit']?.toString() ?? '';
                      final rate = (l['rate'] as num?)?.toDouble() ?? 0;
                      final total = (l['lineTotal'] as num?)?.toDouble() ?? 0;
                      final pricingType = l['pricingType']?.toString() ?? '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                              fontFamily: 'Poppins')),
                                      if (pricingType.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(top: 2),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.primarySurface,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            pricingType.toUpperCase(),
                                            style: const TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                                fontFamily: 'Poppins'),
                                          ),
                                        ),
                                    ]),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${billedQty.toStringAsFixed(2)} $unit\n@ ₹${rate.toStringAsFixed(2)}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Poppins'),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '₹${total.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Poppins'),
                                ),
                              ),
                            ]),
                      );
                    }),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Divider(color: AppColors.divider, height: 24),
                    ),

                    // Deductions section
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
                      _deductionRow('Return Deduction', deductions['returnDeduction']),
                      _deductionRow('Advance Adjusted', deductions['advanceAdjusted'],
                          isAdvance: true),
                      _deductionRow('Other', deductions['other']),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18),
                        child: Divider(color: AppColors.divider, height: 20),
                      ),
                    ],

                    // Gross total row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
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

                    // Final Payable
                    Container(
                      margin: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                              Text(
                                '₹${finalPayable.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    fontFamily: 'Poppins'),
                              ),
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
                                  Text(
                                    'Paid: ₹${amountPaid.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        fontFamily: 'Poppins'),
                                  ),
                                ]),
                                if (amountDue > 0)
                                  Text(
                                    'Due: ₹${amountDue.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.orangeAccent,
                                        fontFamily: 'Poppins'),
                                  )
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
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  if (amountDue > 0)
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
                              fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  if (amountDue > 0) const SizedBox(height: 10),
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
                        onPressed: _printReceipt,
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
      onPressed: _downloadPdf,
      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
      label: const Text('PDF',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
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
      ],
    );
  }

  // ── Small helpers ─────────────────────────────────────────

  Widget _colHead(String text, {TextAlign align = TextAlign.left}) => Text(text,
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
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(
                isAdvance
                    ? Icons.currency_rupee_rounded
                    : Icons.remove_circle_outline_rounded,
                size: 13,
                color: isAdvance ? AppColors.info : AppColors.warning,
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins')),
            ]),
            Text(
              '-₹${v.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: isAdvance ? AppColors.info : AppColors.warning),
            ),
          ]),
    );
  }

  bool _hasDeductions(Map<String, dynamic> d) {
    final deductionKeys = [
      'transport', 'labour', 'commission', 'storage',
      'returnDeduction', 'advanceAdjusted', 'other'
    ];
    for (final k in deductionKeys) {
      if ((d[k] as num? ?? 0) > 0) return true;
    }
    return false;
  }

  String _fmtDate(String raw) {
    if (raw.isEmpty) return '—';
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return raw;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _fmtDateFull(String raw) {
    if (raw.isEmpty) return '—';
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, $h:$m';
  }

  String _fmtMoney(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('connection'))
      return 'No internet connection.';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20, top: 8),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Icon(Icons.print_rounded,
              size: 40, color: AppColors.primary),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Bluetooth printing — connect your thermal printer and try again.',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
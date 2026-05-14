// // receipt_screen.dart
// // ─────────────────────────────────────────────────────────────
// //  RECEIPT SCREEN with Marathi/English Language Support
// //  Matches the "Jai Shivrai Vegetable Co." sample format
// // ─────────────────────────────────────────────────────────────

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:printing/printing.dart';
// import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:pdf/widgets.dart' as pw;
// import '../../../core/constants/colors.dart';
// import '../../../providers/language_provider.dart';
// import '../../../services/dio_client.dart';
// import '../../../services/constant_service.dart';
// import '../payment/payment_screen.dart';

// // ─────────────────────────────────────────────────────────────
// //  RECEIPT SCREEN
// // ─────────────────────────────────────────────────────────────

// class ReceiptScreen extends StatefulWidget {
//   final String purchaseId;
//   final String? farmerName;
//   final String? farmerMobile;

//   const ReceiptScreen({
//     super.key,
//     required this.purchaseId,
//     this.farmerName,
//     this.farmerMobile,
//   });

//   @override
//   State<ReceiptScreen> createState() => _ReceiptScreenState();
// }

// class _ReceiptScreenState extends State<ReceiptScreen>
//     with SingleTickerProviderStateMixin {
//   Map<String, dynamic>? _receipt;
//   bool _loading = true;
//   String? _error;

//   late AnimationController _checkCtrl;
//   late Animation<double> _checkScale;
//   late Animation<double> _checkFade;

//   // Colors matching sample
//   static const Color _redColor = Color(0xFFC8002D);
//   static const Color _tableHeaderBg = Color(0xFFF7F7F7);
//   static const Color _tableBg = Color(0xFFFFF5F7);

//   @override
//   void initState() {
//     super.initState();
//     _checkCtrl = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 600));
//     _checkScale = Tween<double>(begin: 0.4, end: 1.0).animate(
//         CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut));
//     _checkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
//         CurvedAnimation(parent: _checkCtrl, curve: Curves.easeIn));
//     _fetchReceipt();
//   }

//   @override
//   void dispose() {
//     _checkCtrl.dispose();
//     super.dispose();
//   }

//   // ─────────────────────────────────────────────────────────
//   //  FETCH & TRANSFORM
//   // ─────────────────────────────────────────────────────────
//   Future<void> _fetchReceipt() async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });
//     try {
//       final res = await DioClient.instance.dio
//           .get('${ApiRoutes.purchaseById(widget.purchaseId)}/receipt?format=json');
//       final responseData = res.data as Map<String, dynamic>;
//       if (responseData['success'] != true) throw Exception('Failed to load receipt');
//       final data = responseData['data'] as Map<String, dynamic>;
//       setState(() => _receipt = _transformReceiptData(data));
//       _checkCtrl.forward();
//     } catch (e) {
//       setState(() => _error = _friendly(e));
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   Map<String, dynamic> _transformReceiptData(Map<String, dynamic> data) {
//     final purchase = data['purchase'] as Map<String, dynamic>? ?? {};
//     final items = purchase['items'] as List? ?? [];

//     final lines = items.map((item) {
//       final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
//       final rate = (item['rate'] as num?)?.toDouble() ?? 0;
//       final amount = (item['amount'] as num?)?.toDouble() ?? 0;
//       return {
//         'productName': item['productName']?.toString() ?? '',
//         'billedQty': quantity,
//         'actualQty': quantity,
//         'unit': item['unit']?.toString() ?? '',
//         'rate': rate,
//         'lineTotal': amount,
//         'pricingType': item['pricingType']?.toString() ?? '',
//         'qualityDeduction': (item['qualityDeduction'] as num?)?.toDouble() ?? 0,
//       };
//     }).toList();

//     double grossTotal = (purchase['grossTotal'] as num?)?.toDouble() ?? 0;
//     if (grossTotal == 0 && lines.isNotEmpty) {
//       grossTotal = lines.fold(0.0, (s, l) => s + (l['lineTotal'] as double));
//     }

//     final deductions = Map<String, dynamic>.from(purchase['deductions'] as Map? ?? {});

//     double advanceAdjusted = (deductions['advanceAdjusted'] as num?)?.toDouble() ?? 0;
//     if (advanceAdjusted == 0) {
//       for (final p in data['payments'] as List? ?? []) {
//         if (p['mode'] == 'advance') {
//           advanceAdjusted += (p['amount'] as num?)?.toDouble() ?? 0;
//         }
//       }
//       deductions['advanceAdjusted'] = advanceAdjusted;
//     }

//     final amountPaid = (purchase['amountPaid'] as num?)?.toDouble() ?? 0;
//     final amountDue = (purchase['amountDue'] as num?)?.toDouble() ?? 0;
//     final finalPayable = (purchase['finalPayable'] as num?)?.toDouble() ?? 0;

//     return {
//       'receiptNumber': data['receiptNumber']?.toString() ?? '',
//       'purchaseDate': data['purchaseDate']?.toString() ?? data['receiptDate']?.toString() ?? '',
//       'createdAt': data['receiptDate']?.toString() ?? '',
//       'farmer': data['farmer'] ?? {},
//       'business': data['business'] ?? {},
//       'lines': lines,
//       'deductions': deductions,
//       'grossTotal': grossTotal,
//       'totalDeductions': (purchase['totalDeductions'] as num?)?.toDouble() ?? 0,
//       'finalPayable': finalPayable,
//       'amountPaid': amountPaid,
//       'amountDue': amountDue,
//       'status': purchase['status']?.toString() ?? 'Draft',
//       'notes': purchase['notes'] ?? '',
//       'summary': data['summary'] ?? {},
//       'payments': data['payments'] ?? [],
//     };
//   }

//   // ─────────────────────────────────────────────────────────
//   //  PDF GENERATION with Language Support
//   // ─────────────────────────────────────────────────────────
//   Future<pw.Document> _generateReceiptPdf(LanguageProvider lang) async {
//     final isMarathi = lang.isMarathi;
    
//     // Translations for PDF
//     final Map<String, String> englishTranslations = {
//       'purchase_receipt': 'PURCHASE RECEIPT',
//       'prop_label': 'Prop.',
//       'date_label': 'Date:',
//       'farmer_label': 'Farmer Name:',
//       'mobile_label': 'Mobile:',
//       'sr_no': 'Sr.',
//       'product_label': 'Product',
//       'quantity_label': 'Quantity',
//       'rate_label': 'Rate',
//       'amount_label': 'Amount',
//       'sub_total': 'Sub Total',
//       'transport': 'Transport:',
//       'labour': 'Labour:',
//       'commission': 'Commission:',
//       'storage': 'Storage:',
//       'return_deduction': 'Return Deduction:',
//       'advance_adjusted': 'Advance Adjusted:',
//       'other': 'Other:',
//       'total_deductions': 'Total Deductions:',
//       'final_payable': 'Final Payable:',
//       'amount_paid': 'Amount Paid:',
//       'balance_due': 'Balance Due:',
//       'amount_in_words': 'Amount in Words:',
//       'thank_you': 'Thank You!',
//       'buyers_signature': "Buyer's Signature",
//       'for_company': 'For Jai Shivrai Vegetable Co.',
//       'footer_company': 'Jai Shivrai Vegetable Co., Kalwan',
//       'status_label': 'Status:',
//       'payment_method': 'Payment Method:',
//       'generated_on': 'Generated on:',
//       'purchase_date_label': 'Purchase Date:',
//       'terms_conditions': 'Terms and Conditions',
//       'terms_text': '1. Goods once sold will not be taken back.\n2. Payment is due within 30 days.\n3. Interest may apply on overdue payments.\n4. Computer generated receipt.',
//       'rupees_only': 'Rupees Only',
//       'qr_code_placeholder': 'Scan for details',
//     };

//     final Map<String, String> marathiTranslations = {
//       'purchase_receipt': 'खरेदी पावती',
//       'prop_label': 'प्रो.',
//       'date_label': 'दिनांक:',
//       'farmer_label': 'शेतकऱ्याचे नाव:',
//       'mobile_label': 'मोबाइल:',
//       'sr_no': 'क्र.',
//       'product_label': 'उत्पादन',
//       'quantity_label': 'प्रमाण',
//       'rate_label': 'दर',
//       'amount_label': 'रक्कम',
//       'sub_total': 'उप-एकूण',
//       'transport': 'वाहतूक:',
//       'labour': 'मजुरी:',
//       'commission': 'कमिशन:',
//       'storage': 'स्टोरेज:',
//       'return_deduction': 'परतावा कपात:',
//       'advance_adjusted': 'अग्रिम समायोजन:',
//       'other': 'इतर:',
//       'total_deductions': 'एकूण कपात:',
//       'final_payable': 'अंतिम देय:',
//       'amount_paid': 'दिलेली रक्कम:',
//       'balance_due': 'बाकी देय:',
//       'amount_in_words': 'रक्कम अक्षरी:',
//       'thank_you': 'धन्यवाद!',
//       'buyers_signature': 'खरेदीदाराची स्वाक्षरी',
//       'for_company': 'जय शिवराय भाजीपाला साठी',
//       'footer_company': 'जय शिवराय भाजीपाला, कळवण',
//       'status_label': 'स्थिती:',
//       'payment_method': 'पेमेंट पद्धत:',
//       'generated_on': 'तयार केले:',
//       'purchase_date_label': 'खरेदी दिनांक:',
//       'terms_conditions': 'अटी व शर्ती',
//       'terms_text': '१. विक्री झालेला माल परत घेतला जाणार नाही.\n२. पेमेंट ३० दिवसांत देय आहे.\n३. थकीत पेमेंटवर व्याज लागू शकते.\n४. संगणकीय पावती.',
//       'rupees_only': 'फक्त रुपये',
//       'qr_code_placeholder': 'तपशीलासाठी स्कॅन करा',
//     };

//     String t(String key) {
//       return (isMarathi ? marathiTranslations[key] : englishTranslations[key]) ?? key;
//     }

//     // Fonts
//     final regularFont = await PdfGoogleFonts.notoSansRegular();
//     final boldFont = await PdfGoogleFonts.notoSansBold();

//     final r = _receipt!;
//     final farmer = r['farmer'] as Map<String, dynamic>? ?? {};
//     final business = r['business'] as Map<String, dynamic>? ?? {};
//     final lines = r['lines'] as List? ?? [];
//     final deductions = r['deductions'] as Map<String, dynamic>? ?? {};
//     final payments = r['payments'] as List? ?? [];

//     // Colors
//     const pdfRed = PdfColor.fromInt(0xFFC8002D);
//     const pdfBorder = PdfColor.fromInt(0xFFC8002D);
//     const pdfHeaderBg = PdfColor.fromInt(0xFFF7F7F7);
//     const pdfTableBg = PdfColor.fromInt(0xFFFFF5F7);
//     const pdfGrey = PdfColors.grey700;

//     double toD(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
//     String fmtRs(dynamic v) => '₹${toD(v).toStringAsFixed(0)}';
//     String fmtRsFull(dynamic v) => '₹${toD(v).toStringAsFixed(2)}';

//     pw.TextStyle ts({
//       double size = 9,
//       pw.FontWeight weight = pw.FontWeight.normal,
//       PdfColor color = PdfColors.black,
//     }) {
//       return pw.TextStyle(
//         font: weight == pw.FontWeight.bold ? boldFont : regularFont,
//         fontBold: boldFont,
//         fontSize: size,
//         fontWeight: weight,
//         color: color,
//       );
//     }

//     String numberToWords(double amount) {
//       final intAmount = amount.toInt();
//       if (intAmount == 0) return isMarathi ? 'शून्य रुपये फक्त' : 'Zero Rupees Only';

//       const ones = [
//         '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
//         'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
//         'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen',
//       ];
//       const tens = [
//         '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
//         'Sixty', 'Seventy', 'Eighty', 'Ninety',
//       ];

//       String conv(int n) {
//         if (n < 20) return ones[n];
//         if (n < 100) return '${tens[n ~/ 10]} ${ones[n % 10]}'.trim();
//         if (n < 1000) return '${ones[n ~/ 100]} Hundred ${conv(n % 100)}'.trim();
//         if (n < 100000) return '${conv(n ~/ 1000)} Thousand ${conv(n % 1000)}'.trim();
//         if (n < 10000000) return '${conv(n ~/ 100000)} Lakh ${conv(n % 100000)}'.trim();
//         return '${conv(n ~/ 10000000)} Crore ${conv(n % 10000000)}'.trim();
//       }

//       final paise = ((amount - intAmount) * 100).round();
//       final wordRupees = conv(intAmount);
//       if (paise > 0) {
//         return isMarathi 
//             ? '$wordRupees रुपये आणि $paise पैसे फक्त'
//             : '$wordRupees Rupees and $paise Paise Only';
//       }
//       return isMarathi ? '$wordRupees रुपये फक्त' : '$wordRupees Rupees Only';
//     }

//     final grossTotal = toD(r['grossTotal']);
//     final totalDed = toD(r['totalDeductions']);
//     final finalPayable = toD(r['finalPayable']);
//     final amountPaid = toD(r['amountPaid']);
//     final amountDue = toD(r['amountDue']);

//     final receiptNo = r['receiptNumber']?.toString() ?? 'N/A';
//     final dateStr = _fmtDateFull(r['purchaseDate']?.toString() ?? r['createdAt']?.toString() ?? '');
//     final farmerName = farmer['name']?.toString() ?? widget.farmerName ?? '';
//     final mobile = farmer['mobile']?.toString() ?? widget.farmerMobile ?? '';
//     final village = farmer['village']?.toString() ?? '';
//     final state = farmer['state']?.toString() ?? '';

//     final bizName = business['name']?.toString() ?? 'Jai Shivrai Vegetable Co.';
//     final bizAddress = business['address']?.toString() ?? 'Vesarane, Tal. Kalwan, Dist. Nashik';
//     final bizPhone = business['phone']?.toString() ?? '9021699991 / 9623956396';
//     final bizGst = business['gst']?.toString() ?? '';

//     String paymentMethod = 'Cash';
//     if (payments.isNotEmpty) {
//       final modes = payments
//           .map((p) => (p['mode'] ?? p['paymentMode'] ?? '').toString())
//           .where((e) => e.isNotEmpty)
//           .toSet()
//           .join(', ');
//       if (modes.isNotEmpty) paymentMethod = modes;
//     }

//     final doc = pw.Document();

//     doc.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.fromLTRB(35, 25, 35, 20),
//         build: (context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               // Main Border Container
//               pw.Container(
//                 decoration: pw.BoxDecoration(
//                   border: pw.Border.all(color: pdfBorder, width: 1.5),
//                 ),
//                 child: pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.stretch,
//                   children: [
//                     // Jurisdiction
//                     pw.Container(
//                       padding: const pw.EdgeInsets.symmetric(vertical: 5),
//                       child: pw.Center(
//                         child: pw.Text('|| Under Kalwan Jurisdiction ||',
//                             style: ts(size: 8.5, color: pdfRed)),
//                       ),
//                     ),
                    
//                     // Company Name
//                     pw.Center(
//                       child: pw.Text(bizName,
//                           style: ts(size: 20, weight: pw.FontWeight.bold, color: pdfRed)),
//                     ),
//                     pw.SizedBox(height: 2),
                    
//                     // Address
//                     pw.Center(
//                       child: pw.Text(bizAddress,
//                           style: ts(size: 9, color: pdfRed)),
//                     ),
//                     pw.SizedBox(height: 3),
                    
//                     // Receipt Title
//                     pw.Center(
//                       child: pw.Text(t('purchase_receipt'),
//                           style: ts(size: 11, color: pdfGrey)),
//                     ),
//                     pw.SizedBox(height: 4),

//                     // Proprietor
//                     pw.Container(
//                       decoration: const pw.BoxDecoration(
//                         border: pw.Border(
//                           top: pw.BorderSide(color: pdfBorder, width: 1),
//                           bottom: pw.BorderSide(color: pdfBorder, width: 1),
//                         ),
//                       ),
//                       padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                       child: pw.Row(
//                         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                         children: [
//                           pw.Text('${t('prop_label')} Rakesh Hire M: 9021699991 / 9623956396',
//                               style: ts(size: 7.5, weight: pw.FontWeight.bold, color: pdfRed)),
//                           if (bizGst.isNotEmpty)
//                             pw.Text('GST: $bizGst',
//                                 style: ts(size: 7.5, weight: pw.FontWeight.bold, color: pdfRed)),
//                         ],
//                       ),
//                     ),

//                     // Receipt No and Date
//                     pw.Container(
//                       decoration: const pw.BoxDecoration(
//                         border: pw.Border(
//                           bottom: pw.BorderSide(color: pdfBorder, width: 1),
//                         ),
//                       ),
//                       padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//                       child: pw.Row(children: [
//                         pw.Text('Receipt No.:  ', style: ts(size: 9, weight: pw.FontWeight.bold, color: pdfRed)),
//                         pw.Expanded(child: pw.Text(receiptNo, style: ts(size: 9))),
//                         pw.Text('${t('date_label')}  ', style: ts(size: 9, weight: pw.FontWeight.bold, color: pdfRed)),
//                         pw.Text(_fmtDateShort(r['purchaseDate']?.toString() ?? ''), style: ts(size: 9)),
//                       ]),
//                     ),

//                     // Farmer Details
//                     pw.Container(
//                       decoration: const pw.BoxDecoration(
//                         border: pw.Border(
//                           bottom: pw.BorderSide(color: pdfBorder, width: 1),
//                         ),
//                       ),
//                       padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//                       child: pw.Row(children: [
//                         pw.Text('${t('farmer_label')}  ', style: ts(size: 9, weight: pw.FontWeight.bold, color: pdfRed)),
//                         pw.Expanded(child: pw.Text(farmerName, style: ts(size: 9))),
//                         if (mobile.isNotEmpty) ...[
//                           pw.Text('${t('mobile_label')}  ', style: ts(size: 9, weight: pw.FontWeight.bold, color: pdfRed)),
//                           pw.Text(mobile, style: ts(size: 9)),
//                         ],
//                       ]),
//                     ),

//                     // Village / Location
//                     if (village.isNotEmpty || state.isNotEmpty)
//                       pw.Container(
//                         decoration: const pw.BoxDecoration(
//                           border: pw.Border(
//                             bottom: pw.BorderSide(color: pdfBorder, width: 1),
//                           ),
//                         ),
//                         padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//                         child: pw.Text('${village.isNotEmpty ? village : ''}${village.isNotEmpty && state.isNotEmpty ? ', ' : ''}$state',
//                             style: ts(size: 9, weight: pw.FontWeight.bold, color: pdfRed)),
//                       ),

//                     // Product Table
//                     pw.Table(
//                       border: pw.TableBorder(
//                         bottom: const pw.BorderSide(color: pdfBorder, width: 1),
//                         horizontalInside: const pw.BorderSide(color: pdfBorder, width: 0.5),
//                         verticalInside: const pw.BorderSide(color: pdfBorder, width: 0.5),
//                       ),
//                       columnWidths: {
//                         0: const pw.FixedColumnWidth(28),
//                         1: const pw.FlexColumnWidth(3.5),
//                         2: const pw.FlexColumnWidth(1.5),
//                         3: const pw.FlexColumnWidth(1.8),
//                         4: const pw.FlexColumnWidth(1.8),
//                       },
//                       children: [
//                         // Table Header
//                         pw.TableRow(
//                           decoration: const pw.BoxDecoration(color: pdfHeaderBg),
//                           children: [
//                             _pdfCell(t('sr_no'), align: pw.TextAlign.center, isHeader: true),
//                             _pdfCell(t('product_label'), align: pw.TextAlign.left, isHeader: true),
//                             _pdfCell(t('quantity_label'), align: pw.TextAlign.center, isHeader: true),
//                             _pdfCell(t('rate_label'), align: pw.TextAlign.right, isHeader: true),
//                             _pdfCell(t('amount_label'), align: pw.TextAlign.right, isHeader: true),
//                           ],
//                         ),
//                         // Data Rows
//                         ...lines.asMap().entries.map((entry) {
//                           final i = entry.key;
//                           final l = entry.value;
//                           final qty = toD(l['billedQty']);
//                           final rate = toD(l['rate']);
//                           final total = toD(l['lineTotal']);
//                           final unit = l['unit']?.toString() ?? '';
//                           return pw.TableRow(
//                             decoration: pw.BoxDecoration(
//                               color: i.isEven ? PdfColors.white : pdfTableBg,
//                             ),
//                             children: [
//                               _pdfCell('${i + 1}', align: pw.TextAlign.center),
//                               _pdfCell(l['productName']?.toString() ?? '',
//                                   align: pw.TextAlign.left, bold: true),
//                               _pdfCell('${qty.toStringAsFixed(qty == qty.toInt() ? 0 : 2)} $unit',
//                                   align: pw.TextAlign.center),
//                               _pdfCell(fmtRs(rate), align: pw.TextAlign.right),
//                               _pdfCell(fmtRs(total), align: pw.TextAlign.right, bold: true, color: pdfRed),
//                             ],
//                           );
//                         }),
//                       ],
//                     ),

//                     // Left side: Deductions, Right side: Totals
//                     pw.Container(
//                       decoration: const pw.BoxDecoration(
//                         border: pw.Border(
//                           bottom: pw.BorderSide(color: pdfBorder, width: 1),
//                         ),
//                       ),
//                       child: pw.Row(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           // Deductions Section
//                           pw.Expanded(
//                             flex: 5,
//                             child: pw.Column(
//                               crossAxisAlignment: pw.CrossAxisAlignment.start,
//                               children: [
//                                 pw.Container(
//                                   padding: const pw.EdgeInsets.all(8),
//                                   child: pw.Text(t('terms_conditions'),
//                                       style: ts(size: 8, weight: pw.FontWeight.bold, color: pdfRed)),
//                                 ),
//                                 pw.Container(
//                                   padding: const pw.EdgeInsets.fromLTRB(8, 0, 8, 8),
//                                   child: pw.Text(t('terms_text'),
//                                       style: ts(size: 6.5, color: pdfGrey)),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           // Vertical divider
//                           pw.Container(width: 1, height: 100, color: pdfBorder),
//                           // Totals Section
//                           pw.Expanded(
//                             flex: 3,
//                             child: pw.Column(
//                               children: [
//                                 _pdfTotalsRow(t('sub_total'), fmtRsFull(grossTotal), pdfRed),
//                                 if (toD(deductions['transport']) > 0)
//                                   _pdfTotalsRow(t('transport'), '-${fmtRsFull(deductions['transport'])}', pdfRed),
//                                 if (toD(deductions['labour']) > 0)
//                                   _pdfTotalsRow(t('labour'), '-${fmtRsFull(deductions['labour'])}', pdfRed),
//                                 if (toD(deductions['commission']) > 0)
//                                   _pdfTotalsRow(
//                                     deductions['commissionType'] == 'percent'
//                                         ? '${t('commission')} (${deductions['commission']}%)'
//                                         : t('commission'),
//                                     '-${fmtRsFull(deductions['commission'])}',
//                                     pdfRed,
//                                   ),
//                                 if (toD(deductions['storage']) > 0)
//                                   _pdfTotalsRow(t('storage'), '-${fmtRsFull(deductions['storage'])}', pdfRed),
//                                 if (toD(deductions['returnDeduction']) > 0)
//                                   _pdfTotalsRow(t('return_deduction'), '-${fmtRsFull(deductions['returnDeduction'])}', pdfRed),
//                                 if (toD(deductions['advanceAdjusted']) > 0)
//                                   _pdfTotalsRow(t('advance_adjusted'), '-${fmtRsFull(deductions['advanceAdjusted'])}', pdfRed),
//                                 if (toD(deductions['other']) > 0)
//                                   _pdfTotalsRow(t('other'), '-${fmtRsFull(deductions['other'])}', pdfRed),
//                                 _pdfDivider(pdfBorder),
//                                 _pdfTotalsRow(t('total_deductions'), '-${fmtRsFull(totalDed)}', pdfRed, bold: true),
//                                 _pdfTotalsRow(t('final_payable'), fmtRsFull(finalPayable), pdfRed, bold: true, large: true),
//                                 _pdfTotalsRow(t('amount_paid'), fmtRsFull(amountPaid), pdfRed),
//                                 _pdfTotalsRow(t('balance_due'), fmtRsFull(amountDue), pdfRed,
//                                     bold: true, color: amountDue > 0 ? PdfColor.fromInt(0xFFD32F2F) : PdfColor.fromInt(0xFF2E7D32)),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     // Amount in Words
//                     pw.Container(
//                       decoration: const pw.BoxDecoration(
//                         border: pw.Border(
//                           bottom: pw.BorderSide(color: pdfBorder, width: 1),
//                         ),
//                       ),
//                       padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//                       child: pw.Text(
//                         '${t('amount_in_words')} ${numberToWords(finalPayable)}',
//                         style: ts(size: 8.5, color: pdfRed),
//                       ),
//                     ),

//                     // Payment Method
//                     pw.Container(
//                       decoration: const pw.BoxDecoration(
//                         border: pw.Border(
//                           bottom: pw.BorderSide(color: pdfBorder, width: 1),
//                         ),
//                       ),
//                       padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//                       child: pw.Row(children: [
//                         pw.Text('${t('payment_method')}  ',
//                             style: ts(size: 9, weight: pw.FontWeight.bold, color: pdfRed)),
//                         pw.Text(paymentMethod, style: ts(size: 9)),
//                       ]),
//                     ),

//                     // Status
//                     pw.Container(
//                       decoration: const pw.BoxDecoration(
//                         border: pw.Border(
//                           bottom: pw.BorderSide(color: pdfBorder, width: 1),
//                         ),
//                       ),
//                       padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//                       child: pw.Row(children: [
//                         pw.Text('${t('status_label')}  ',
//                             style: ts(size: 9, weight: pw.FontWeight.bold, color: pdfRed)),
//                         pw.Text(r['status']?.toString() ?? 'Draft',
//                             style: ts(size: 9, weight: pw.FontWeight.bold,
//                                 color: r['status'] == 'paid' ? PdfColor.fromInt(0xFF2E7D32) : pdfRed)),
//                       ]),
//                     ),

//                     // Thank You + Total Amount
//                     pw.Container(
//                       decoration: const pw.BoxDecoration(
//                         border: pw.Border(
//                           bottom: pw.BorderSide(color: pdfBorder, width: 1),
//                         ),
//                       ),
//                       child: pw.Row(children: [
//                         pw.Expanded(
//                           child: pw.Container(
//                             padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//                             child: pw.Text(t('thank_you'),
//                                 style: ts(size: 10, weight: pw.FontWeight.bold, color: pdfRed)),
//                           ),
//                         ),
//                         pw.Container(width: 1, height: 36, color: pdfBorder),
//                         pw.Container(
//                           padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//                           child: pw.Row(children: [
//                             pw.Text('Total Amount:  ',
//                                 style: ts(size: 9, weight: pw.FontWeight.bold, color: pdfRed)),
//                             pw.Text(fmtRsFull(finalPayable),
//                                 style: ts(size: 13, weight: pw.FontWeight.bold, color: pdfRed)),
//                           ]),
//                         ),
//                       ]),
//                     ),

//                     // Signatures
//                     pw.Container(
//                       padding: const pw.EdgeInsets.fromLTRB(10, 20, 10, 12),
//                       child: pw.Row(
//                         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                         children: [
//                           pw.Column(
//                             crossAxisAlignment: pw.CrossAxisAlignment.start,
//                             children: [
//                               pw.Text('......................................',
//                                   style: ts(size: 9, color: pdfRed)),
//                               pw.SizedBox(height: 2),
//                               pw.Text(t('buyers_signature'),
//                                   style: ts(size: 8.5, weight: pw.FontWeight.bold, color: pdfRed)),
//                             ],
//                           ),
//                           pw.Column(
//                             crossAxisAlignment: pw.CrossAxisAlignment.end,
//                             children: [
//                               pw.Text('......................................',
//                                   style: ts(size: 9, color: pdfRed)),
//                               pw.SizedBox(height: 2),
//                               pw.Text(t('for_company'),
//                                   style: ts(size: 8.5, weight: pw.FontWeight.bold, color: pdfRed)),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Footer
//               pw.SizedBox(height: 8),
//               pw.Center(
//                 child: pw.Text(
//                   '${t('generated_on')} ${DateFormat('dd/MM/yyyy, hh:mm a').format(DateTime.now())}',
//                   style: ts(size: 7, color: PdfColors.grey500),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );

//     return doc;
//   }

//  pw.Widget _pdfCell(String text,
//     {pw.TextAlign align = pw.TextAlign.center,
//     bool bold = false,
//     bool isHeader = false,
//     PdfColor color = PdfColors.black}) {
//   return pw.Container(
//     padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
//     child: pw.Text(
//       text,
//       textAlign: align,
//       softWrap: true,
//       maxLines: 2,
//       style: pw.TextStyle(
//         fontSize: isHeader ? 8.5 : 8.5,
//         fontWeight: isHeader || bold ? pw.FontWeight.bold : pw.FontWeight.normal,
//         color: color,
//       ),
//     ),
//   );
// }
//   pw.Widget _pdfTotalsRow(String label, String value, PdfColor redColor,
//       {bool bold = false, bool large = false, PdfColor? color}) {
//     return pw.Container(
//       padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       child: pw.Row(
//         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//         children: [
//           pw.Text(label,
//               style: pw.TextStyle(
//                 fontSize: large ? 9 : 8,
//                 fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
//                 color: redColor,
//               )),
//           pw.Text(value,
//               style: pw.TextStyle(
//                 fontSize: large ? 11 : 8,
//                 fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
//                 color: color ?? (large ? redColor : PdfColors.black),
//               )),
//         ],
//       ),
//     );
//   }

//   pw.Widget _pdfDivider(PdfColor color) {
//     return pw.Container(height: 1, color: color, margin: const pw.EdgeInsets.symmetric(vertical: 4));
//   }

//   // ─────────────────────────────────────────────────────────
//   //  ACTIONS
//   // ─────────────────────────────────────────────────────────
//   void _goToPayment() async {
//     if (_receipt == null) return;
//     final amountDue = (_receipt!['amountDue'] as num?)?.toDouble() ?? 0;
//     if (amountDue <= 0) {
//       _snack('This purchase is fully paid', success: true);
//       return;
//     }
//     final farmer = _receipt!['farmer'] as Map<String, dynamic>? ?? {};
//     final farmerId = farmer['_id']?.toString() ?? farmer['id']?.toString() ?? '';
//     final paid = await Navigator.push<bool>(
//       context,
//       MaterialPageRoute(
//         builder: (_) => PaymentScreen(
//           purchaseId: widget.purchaseId,
//           farmerId: farmerId,
//           farmerName: farmer['name']?.toString() ?? widget.farmerName ?? '',
//           finalPayable: (_receipt!['finalPayable'] as num?)?.toDouble() ?? 0,
//           amountPaid: (_receipt!['amountPaid'] as num?)?.toDouble() ?? 0,
//           amountDue: amountDue,
//           receiptNumber: _receipt!['receiptNumber']?.toString() ?? '',
//         ),
//       ),
//     );
//     if (paid == true && mounted) await _fetchReceipt();
//   }

//   Future<void> _downloadPdf(LanguageProvider lang) async {
//     if (_receipt == null) return;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const Center(
//         child: Card(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 14),
//                 Text('Generating PDF…', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );

//     try {
//       final pdfDoc = await _generateReceiptPdf(lang);
//       final bytes = await pdfDoc.save();

//       if (mounted) Navigator.pop(context);

//       final receiptNo = (_receipt!['receiptNumber'] as String? ?? 'receipt')
//           .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');

//       await Printing.layoutPdf(
//         onLayout: (_) async => bytes,
//         name: 'Receipt_$receiptNo.pdf',
//       );
//     } catch (e) {
//       if (mounted) {
//         Navigator.pop(context);
//         _snack('Failed to generate PDF: $e');
//       }
//     }
//   }

//   Future<void> _shareWhatsApp(LanguageProvider lang) async {
//     if (_receipt == null) return;
//     final text = _buildWhatsAppText(lang);
//     final farmer = _receipt!['farmer'] as Map<String, dynamic>? ?? {};
//     final mobile = farmer['mobile']?.toString() ?? widget.farmerMobile ?? '';
//     final digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
//     final phone = digits.length == 10 ? '91$digits' : digits;
//     final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(text)}');
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     } else {
//       await launchUrl(
//           Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'),
//           mode: LaunchMode.externalApplication);
//     }
//   }

//   String _buildWhatsAppText(LanguageProvider lang) {
//     if (_receipt == null) return '';
//     final isMarathi = lang.isMarathi;
//     final r = _receipt!;
//     final farmer = r['farmer'] as Map<String, dynamic>? ?? {};
//     final business = r['business'] as Map<String, dynamic>? ?? {};
//     final lines = r['lines'] as List? ?? [];
//     final deductions = r['deductions'] as Map<String, dynamic>? ?? {};
//     final grossTotal = (r['grossTotal'] as num?)?.toDouble() ?? 0;
//     final finalPayable = (r['finalPayable'] as num?)?.toDouble() ?? 0;
//     final amountPaid = (r['amountPaid'] as num?)?.toDouble() ?? 0;
//     final amountDue = (r['amountDue'] as num?)?.toDouble() ?? 0;

//     if (isMarathi) {
//       final buf = StringBuffer();
//       buf.writeln('🌾 *${business['name'] ?? 'शेतकरी बाजार'}*');
//       buf.writeln('━━━━━━━━━━━━━━━━━━━━');
//       buf.writeln('पावती क्र.: *${r['receiptNumber'] ?? ''}*');
//       buf.writeln('दिनांक: ${_fmtDate(r['purchaseDate']?.toString() ?? '')}');
//       buf.writeln('शेतकरी: *${farmer['name'] ?? widget.farmerName ?? ''}*');
//       if ((farmer['mobile'] ?? widget.farmerMobile ?? '').isNotEmpty)
//         buf.writeln('मोबाइल: ${farmer['mobile'] ?? widget.farmerMobile}');
//       buf.writeln('━━━━━━━━━━━━━━━━━━━━');
//       buf.writeln('*उत्पादने*');
//       for (final l in lines) {
//         final qty = (l['billedQty'] as num?)?.toDouble() ?? 0;
//         final rate = (l['rate'] as num?)?.toDouble() ?? 0;
//         final total = (l['lineTotal'] as num?)?.toDouble() ?? 0;
//         buf.writeln('• ${l['productName']}: ${qty.toStringAsFixed(2)} ${l['unit']} × ₹${rate.toStringAsFixed(2)} = ₹${total.toStringAsFixed(2)}');
//       }
//       buf.writeln('━━━━━━━━━━━━━━━━━━━━');
//       buf.writeln('एकूण: ₹${grossTotal.toStringAsFixed(2)}');
//       if ((deductions['transport'] as num? ?? 0) > 0) buf.writeln('वाहतूक: -₹${(deductions['transport'] as num).toStringAsFixed(2)}');
//       if ((deductions['labour'] as num? ?? 0) > 0) buf.writeln('मजुरी: -₹${(deductions['labour'] as num).toStringAsFixed(2)}');
//       if ((deductions['commission'] as num? ?? 0) > 0) buf.writeln('कमिशन: -₹${(deductions['commission'] as num).toStringAsFixed(2)}');
//       buf.writeln('━━━━━━━━━━━━━━━━━━━━');
//       buf.writeln('*अंतिम देय: ₹${finalPayable.toStringAsFixed(2)}*');
//       if (amountPaid > 0) buf.writeln('दिलेली रक्कम: ₹${amountPaid.toStringAsFixed(2)}');
//       buf.writeln(amountDue > 0 ? '*बाकी देय: ₹${amountDue.toStringAsFixed(2)}*' : '✅ पूर्ण भरले');
//       buf.writeln('━━━━━━━━━━━━━━━━━━━━');
//       buf.writeln('व्यवसायाबद्दल धन्यवाद!');
//       return buf.toString();
//     } else {
//       final buf = StringBuffer();
//       buf.writeln('🌾 *${business['name'] ?? 'FARM ERP'}*');
//       buf.writeln('━━━━━━━━━━━━━━━━━━━━');
//       buf.writeln('Receipt No: *${r['receiptNumber'] ?? ''}*');
//       buf.writeln('Date: ${_fmtDate(r['purchaseDate']?.toString() ?? '')}');
//       buf.writeln('Farmer: *${farmer['name'] ?? widget.farmerName ?? ''}*');
//       if ((farmer['mobile'] ?? widget.farmerMobile ?? '').isNotEmpty)
//         buf.writeln('Mobile: ${farmer['mobile'] ?? widget.farmerMobile}');
//       buf.writeln('━━━━━━━━━━━━━━━━━━━━');
//       buf.writeln('*PRODUCTS*');
//       for (final l in lines) {
//         final qty = (l['billedQty'] as num?)?.toDouble() ?? 0;
//         final rate = (l['rate'] as num?)?.toDouble() ?? 0;
//         final total = (l['lineTotal'] as num?)?.toDouble() ?? 0;
//         buf.writeln('• ${l['productName']}: ${qty.toStringAsFixed(2)} ${l['unit']} × ₹${rate.toStringAsFixed(2)} = ₹${total.toStringAsFixed(2)}');
//       }
//       buf.writeln('━━━━━━━━━━━━━━━━━━━━');
//       buf.writeln('Gross Total: ₹${grossTotal.toStringAsFixed(2)}');
//       if ((deductions['transport'] as num? ?? 0) > 0) buf.writeln('Transport: -₹${(deductions['transport'] as num).toStringAsFixed(2)}');
//       if ((deductions['labour'] as num? ?? 0) > 0) buf.writeln('Labour: -₹${(deductions['labour'] as num).toStringAsFixed(2)}');
//       if ((deductions['commission'] as num? ?? 0) > 0) buf.writeln('Commission: -₹${(deductions['commission'] as num).toStringAsFixed(2)}');
//       buf.writeln('━━━━━━━━━━━━━━━━━━━━');
//       buf.writeln('*FINAL PAYABLE: ₹${finalPayable.toStringAsFixed(2)}*');
//       if (amountPaid > 0) buf.writeln('Paid: ₹${amountPaid.toStringAsFixed(2)}');
//       buf.writeln(amountDue > 0 ? '*Balance Due: ₹${amountDue.toStringAsFixed(2)}*' : '✅ FULLY PAID');
//       buf.writeln('━━━━━━━━━━━━━━━━━━━━');
//       buf.writeln('Thank you for your business!');
//       return buf.toString();
//     }
//   }

//   // ─────────────────────────────────────────────────────────
//   //  BUILD
//   // ─────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final lang = context.watch<LanguageProvider>();
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: Text(lang.t('purchase_receipt'),
//             style: const TextStyle(fontWeight: FontWeight.w600)),
//         backgroundColor: _redColor,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           _buildLanguageToggle(lang),
//           IconButton(
//             icon: const Icon(Icons.print_outlined),
//             onPressed: _loading ? null : () => _printReceipt(lang),
//             tooltip: lang.t('print'),
//           ),
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf_outlined),
//             onPressed: _loading ? null : () => _downloadPdf(lang),
//             tooltip: lang.t('download_pdf'),
//           ),
//           IconButton(
//             icon: const Icon(Icons.share_outlined),
//             onPressed: _loading ? null : () => _shareWhatsApp(lang),
//             tooltip: lang.t('share_whatsapp'),
//           ),
//         ],
//       ),
//       body: _loading
//           ? _buildLoading(lang)
//           : _error != null
//               ? _buildError(lang)
//               : _buildReceipt(lang),
//     );
//   }

//   Widget _buildLanguageToggle(LanguageProvider lang) {
//     final isMr = lang.isMarathi;
//     return Container(
//       margin: const EdgeInsets.only(right: 8),
//       height: 32,
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.18),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _langTab(label: 'EN', selected: !isMr, onTap: () => lang.setLanguage('en')),
//           _langTab(label: 'मर', selected: isMr, onTap: () => lang.setLanguage('mr')),
//         ],
//       ),
//     );
//   }

//   Widget _langTab({required String label, required bool selected, required VoidCallback onTap}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//         decoration: BoxDecoration(
//           color: selected ? Colors.white : Colors.transparent,
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Text(label,
//             style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w700,
//                 color: selected ? _redColor : Colors.white)),
//       ),
//     );
//   }

//   void _printReceipt(LanguageProvider lang) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (_) => _PrintSheet(
//         receipt: _receipt,
//         onPrint: () => _downloadPdf(lang),
//       ),
//     );
//   }

//   Widget _buildLoading(LanguageProvider lang) => const Center(
//         child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//           CircularProgressIndicator(color: AppColors.primary),
//           SizedBox(height: 16),
//           Text('Loading receipt…',
//               style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.textSecondary)),
//         ]),
//       );

//   Widget _buildError(LanguageProvider lang) => Center(
//         child: Padding(
//           padding: const EdgeInsets.all(32),
//           child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//             const Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textHint),
//             const SizedBox(height: 16),
//             const Text('Purchase saved successfully!',
//                 style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.success),
//                 textAlign: TextAlign.center),
//             const SizedBox(height: 8),
//             Text('Receipt could not be loaded: $_error',
//                 style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary),
//                 textAlign: TextAlign.center),
//             const SizedBox(height: 28),
//             ElevatedButton(
//               onPressed: _fetchReceipt,
//               style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
//               child: const Text('Retry', style: TextStyle(fontFamily: 'Poppins')),
//             ),
//           ]),
//         ),
//       );

//   Widget _buildReceipt(LanguageProvider lang) {
//     final r = _receipt!;
//     final farmer = r['farmer'] as Map<String, dynamic>? ?? {};
//     final lines = r['lines'] as List? ?? [];
//     final deductions = r['deductions'] as Map<String, dynamic>? ?? {};
//     final receiptNo = r['receiptNumber']?.toString() ?? '—';
//     final date = _fmtDateFull(r['purchaseDate']?.toString() ?? r['createdAt']?.toString() ?? '');
//     final farmerName = farmer['name']?.toString() ?? widget.farmerName ?? '—';
//     final farmerMobile = farmer['mobile']?.toString() ?? widget.farmerMobile ?? '';
//     final grossTotal = (r['grossTotal'] as num?)?.toDouble() ?? 0;
//     final finalPayable = (r['finalPayable'] as num?)?.toDouble() ?? 0;
//     final amountPaid = (r['amountPaid'] as num?)?.toDouble() ?? 0;
//     final amountDue = (r['amountDue'] as num?)?.toDouble() ?? 0;
//     final isFullyPaid = amountDue <= 0;

//     final isMarathi = lang.isMarathi;

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(color: _redColor, width: 1.5),
//           borderRadius: BorderRadius.circular(2),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Jurisdiction
//             Padding(
//               padding: const EdgeInsets.only(top: 10, bottom: 2),
//               child: Center(
//                 child: Text('|| Under Kalwan Jurisdiction ||',
//                     style: TextStyle(fontSize: 11, color: _redColor, letterSpacing: 0.3)),
//               ),
//             ),
//             // Company Name
//             Padding(
//               padding: const EdgeInsets.only(top: 2),
//               child: Center(
//                 child: Text('Jai Shivrai Vegetable Co.',
//                     style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _redColor, letterSpacing: -0.5)),
//               ),
//             ),
//             // Address
//             Padding(
//               padding: const EdgeInsets.only(top: 2),
//               child: Center(
//                 child: Text('Vesarane, Tal. Kalwan, Dist. Nashik',
//                     style: TextStyle(fontSize: 11.5, color: _redColor, fontWeight: FontWeight.w500)),
//               ),
//             ),
//             // Title
//             const Padding(
//               padding: EdgeInsets.only(top: 3, bottom: 6),
//               child: Center(
//                 child: Text('PURCHASE RECEIPT',
//                     style: TextStyle(fontSize: 11, color: Color(0xFF777777), letterSpacing: 0.5)),
//               ),
//             ),
//             _horizontalDivider(),
//             // Proprietor
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Flexible(
//                     child: Text('Prop. Rakesh Hire M: 9021699991 / 9623956396',
//                         style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _redColor)),
//                   ),
//                 ],
//               ),
//             ),
//             _horizontalDivider(),
//             // Receipt No / Date
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               child: Row(
//                 children: [
//                   _redLabel('Receipt No.:'),
//                   const SizedBox(width: 6),
//                   Flexible(child: Text(receiptNo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
//                   const SizedBox(width: 16),
//                   _redLabel(isMarathi ? 'दिनांक:' : 'Date:'),
//                   const SizedBox(width: 6),
//                   Text(_fmtDateShort(r['purchaseDate']?.toString() ?? ''),
//                       style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
//                 ],
//               ),
//             ),
//             _horizontalDivider(),
//             // Farmer Name / Mobile
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               child: Row(
//                 children: [
//                   _redLabel(isMarathi ? 'शेतकऱ्याचे नाव:' : 'Farmer Name:'),
//                   const SizedBox(width: 6),
//                   Expanded(child: Text(farmerName, style: const TextStyle(fontSize: 13))),
//                   if (farmerMobile.isNotEmpty) ...[
//                     _redLabel(isMarathi ? 'मोबाइल:' : 'Mobile:'),
//                     const SizedBox(width: 6),
//                     Text(farmerMobile, style: const TextStyle(fontSize: 13)),
//                   ],
//                 ],
//               ),
//             ),
//             _horizontalDivider(),
//             // Product Table
//             _buildProductTableUI(lines, isMarathi),
//             // Totals and Deductions
//             _buildTotalsSectionUI(grossTotal, deductions, totalDeductions, finalPayable, amountPaid, amountDue, isMarathi),
//             // Amount in Words
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               child: Text(
//                 '${isMarathi ? 'रक्कम अक्षरी:' : 'Amount in Words:'}  ${_numberToWords(finalPayable, isMarathi)}',
//                 style: TextStyle(fontSize: 12, color: _redColor, fontWeight: FontWeight.w500),
//               ),
//             ),
//             _horizontalDivider(),
//             // Thank You / Total
//             IntrinsicHeight(
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Expanded(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                       child: Text(isMarathi ? 'धन्यवाद!' : 'Thank You!',
//                           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _redColor)),
//                     ),
//                   ),
//                   Container(width: 1, color: _redColor),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text('Total Amount:  ',
//                             style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _redColor)),
//                         Text('₹${finalPayable.toStringAsFixed(2)}',
//                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _redColor)),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             _horizontalDivider(),
//             // Signatures
//             Padding(
//               padding: const EdgeInsets.fromLTRB(12, 24, 12, 14),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(width: 150, height: 1, color: _redColor),
//                       const SizedBox(height: 4),
//                       Text(isMarathi ? 'खरेदीदाराची स्वाक्षरी' : "Buyer's Signature",
//                           style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _redColor)),
//                     ],
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Container(width: 150, height: 1, color: _redColor),
//                       const SizedBox(height: 4),
//                       Text('Jai Shivrai Vegetable Co., Kalwan',
//                           style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _redColor)),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   double get totalDeductions {
//     if (_receipt == null) return 0;
//     return (_receipt!['totalDeductions'] as num?)?.toDouble() ?? 0;
//   }

//   Widget _horizontalDivider() => Container(height: 1, color: _redColor);

//   Widget _redLabel(String text) => Text(text,
//       style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _redColor));

//   Widget _buildProductTableUI(List lines, bool isMarathi) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             color: _tableHeaderBg,
//             border: Border(bottom: BorderSide(color: _redColor, width: 1)),
//           ),
//           child: Row(
//             children: [
//               _thUI(isMarathi ? 'क्र.' : 'Sr.', flex: 0.5, align: TextAlign.center),
//               _thDividerUI(),
//               _thUI(isMarathi ? 'उत्पादन' : 'Product', flex: 3, align: TextAlign.left),
//               _thDividerUI(),
//               _thUI(isMarathi ? 'प्रमाण' : 'Qty', flex: 1.5, align: TextAlign.center),
//               _thDividerUI(),
//               _thUI(isMarathi ? 'दर' : 'Rate', flex: 1.5, align: TextAlign.right),
//               _thDividerUI(),
//               _thUI(isMarathi ? 'रक्कम' : 'Amount', flex: 1.5, align: TextAlign.right),
//             ],
//           ),
//         ),
//         ...lines.asMap().entries.map((entry) {
//           final i = entry.key;
//           final l = entry.value;
//           final qty = (l['billedQty'] as num?)?.toDouble() ?? 0;
//           final rate = (l['rate'] as num?)?.toDouble() ?? 0;
//           final total = (l['lineTotal'] as num?)?.toDouble() ?? 0;
//           final unit = l['unit']?.toString() ?? '';
//           return Container(
//             decoration: BoxDecoration(
//               color: i.isEven ? Colors.white : _tableBg,
//               border: Border(bottom: BorderSide(color: _redColor.withOpacity(0.22))),
//             ),
//             child: Row(
//               children: [
//                 _tdUI('${i + 1}', flex: 0.5, align: TextAlign.center),
//                 _tdDividerUI(),
//                 _tdUI(l['productName']?.toString() ?? '', flex: 3, align: TextAlign.left, bold: true),
//                 _tdDividerUI(),
//                 _tdUI('${qty.toStringAsFixed(qty == qty.toInt() ? 0 : 2)} $unit', flex: 1.5, align: TextAlign.center),
//                 _tdDividerUI(),
//                 _tdUI('₹${rate.toStringAsFixed(2)}', flex: 1.5, align: TextAlign.right),
//                 _tdDividerUI(),
//                 _tdUI('₹${total.toStringAsFixed(2)}', flex: 1.5, align: TextAlign.right, bold: true, color: _redColor),
//               ],
//             ),
//           );
//         }),
//       ],
//     );
//   }

//   Widget _buildTotalsSectionUI(double grossTotal, Map deductions, double totalDed, double finalPayable, double amountPaid, double amountDue, bool isMarathi) {
//     return Container(
//       decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _redColor))),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Deductions (left side)
//           Expanded(
//             flex: 5,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: Text(isMarathi ? 'अटी व शर्ती' : 'Terms and Conditions',
//                       style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _redColor)),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
//                   child: Text(
//                     isMarathi
//                         ? '१. विक्री झालेला माल परत घेतला जाणार नाही.\n२. पेमेंट ३० दिवसांत देय आहे.\n३. थकीत पेमेंटवर व्याज लागू शकते.\n४. संगणकीय पावती.'
//                         : '1. Goods once sold will not be taken back.\n2. Payment is due within 30 days.\n3. Interest may apply on overdue payments.\n4. Computer generated receipt.',
//                     style: TextStyle(fontSize: 8, color: Colors.grey.shade700),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Container(width: 1, height: 100, color: _redColor),
//           // Totals (right side)
//           Expanded(
//             flex: 3,
//             child: Column(
//               children: [
//                 _totalsRowUI(isMarathi ? 'उप-एकूण' : 'Sub Total', '₹${grossTotal.toStringAsFixed(2)}', _redColor),
//                 if ((deductions['transport'] as num? ?? 0) > 0)
//                   _totalsRowUI(isMarathi ? 'वाहतूक:' : 'Transport:', '-₹${(deductions['transport'] as num).toStringAsFixed(2)}', _redColor),
//                 if ((deductions['labour'] as num? ?? 0) > 0)
//                   _totalsRowUI(isMarathi ? 'मजुरी:' : 'Labour:', '-₹${(deductions['labour'] as num).toStringAsFixed(2)}', _redColor),
//                 if ((deductions['commission'] as num? ?? 0) > 0)
//                   _totalsRowUI(
//                     deductions['commissionType'] == 'percent'
//                         ? '${isMarathi ? 'कमिशन' : 'Commission'} (${deductions['commission']}%)'
//                         : (isMarathi ? 'कमिशन:' : 'Commission:'),
//                     '-₹${(deductions['commission'] as num).toStringAsFixed(2)}',
//                     _redColor,
//                   ),
//                 if ((deductions['storage'] as num? ?? 0) > 0)
//                   _totalsRowUI(isMarathi ? 'स्टोरेज:' : 'Storage:', '-₹${(deductions['storage'] as num).toStringAsFixed(2)}', _redColor),
//                 if ((deductions['returnDeduction'] as num? ?? 0) > 0)
//                   _totalsRowUI(isMarathi ? 'परतावा कपात:' : 'Return Deduction:', '-₹${(deductions['returnDeduction'] as num).toStringAsFixed(2)}', _redColor),
//                 if ((deductions['advanceAdjusted'] as num? ?? 0) > 0)
//                   _totalsRowUI(isMarathi ? 'अग्रिम समायोजन:' : 'Advance Adjusted:', '-₹${(deductions['advanceAdjusted'] as num).toStringAsFixed(2)}', _redColor),
//                 if ((deductions['other'] as num? ?? 0) > 0)
//                   _totalsRowUI(isMarathi ? 'इतर:' : 'Other:', '-₹${(deductions['other'] as num).toStringAsFixed(2)}', _redColor),
//                 const Divider(height: 8, thickness: 1),
//                 _totalsRowUI(isMarathi ? 'एकूण कपात:' : 'Total Deductions:', '-₹${totalDed.toStringAsFixed(2)}', _redColor, bold: true),
//                 const SizedBox(height: 4),
//                 _totalsRowUI(isMarathi ? 'अंतिम देय:' : 'Final Payable:', '₹${finalPayable.toStringAsFixed(2)}', _redColor, bold: true, large: true),
//                 _totalsRowUI(isMarathi ? 'दिलेली रक्कम:' : 'Amount Paid:', '₹${amountPaid.toStringAsFixed(2)}', _redColor),
//                 _totalsRowUI(isMarathi ? 'बाकी देय:' : 'Balance Due:', '₹${amountDue.toStringAsFixed(2)}', _redColor,
//                     bold: true, color: amountDue > 0 ? Colors.red.shade700 : Colors.green),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _thUI(String text, {required double flex, TextAlign align = TextAlign.center}) {
//     return Expanded(
//       flex: flex.toInt(),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
//         child: Text(text,
//             textAlign: align,
//             style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
//       ),
//     );
//   }

//   Widget _thDividerUI() => Container(width: 1, height: 36, color: const Color(0xFFDDDDDD));

//   Widget _tdDividerUI() => Container(width: 1, height: 38, color: _redColor.withOpacity(0.18));

//  Widget _tdUI(String text, {
//   required double flex,
//   TextAlign align = TextAlign.center,
//   bool bold = false,
//   Color? color,
// }) {
//   return Expanded(
//     flex: flex.toInt(),
//     child: Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
//       child: Text(
//         text,
//         textAlign: align,
//         softWrap: true,
//         overflow: TextOverflow.ellipsis,
//         maxLines: 2,  // adjust as needed
//         style: TextStyle(
//           fontSize: 11,
//           fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
//           color: color ?? const Color(0xFF1A1A1A),
//         ),
//       ),
//     ),
//   );
// }

//   Widget _totalsRowUI(String label, String value, Color redColor,
//       {bool bold = false, bool large = false, Color? color}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label,
//               style: TextStyle(
//                   fontSize: large ? 11 : 10,
//                   fontWeight: bold ? FontWeight.bold : FontWeight.normal,
//                   color: redColor)),
//           Text(value,
//               style: TextStyle(
//                   fontSize: large ? 13 : 10,
//                   fontWeight: bold ? FontWeight.bold : FontWeight.normal,
//                   color: color ?? (large ? redColor : Colors.black87))),
//         ],
//       ),
//     );
//   }

//   String _fmtDateShort(String raw) {
//     if (raw.isEmpty) return '—';
//     final d = DateTime.tryParse(raw)?.toLocal();
//     if (d == null) return raw;
//     return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
//   }

//   String _fmtDateFull(String raw) {
//     if (raw.isEmpty) return '—';
//     final d = DateTime.tryParse(raw)?.toLocal();
//     if (d == null) return raw;
//     const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
//     return '${d.day} ${months[d.month - 1]} ${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
//   }

//   String _fmtDate(String raw) {
//     if (raw.isEmpty) return '—';
//     final d = DateTime.tryParse(raw)?.toLocal();
//     if (d == null) return raw;
//     return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
//   }

//   String _numberToWords(double amount, bool isMarathi) {
//     final intAmount = amount.toInt();
//     if (intAmount == 0) return isMarathi ? 'शून्य रुपये फक्त' : 'Zero Rupees Only';

//     const ones = [
//       '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
//       'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
//       'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen',
//     ];
//     const tens = [
//       '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
//       'Sixty', 'Seventy', 'Eighty', 'Ninety',
//     ];

//     String conv(int n) {
//       if (n < 20) return ones[n];
//       if (n < 100) return '${tens[n ~/ 10]} ${ones[n % 10]}'.trim();
//       if (n < 1000) return '${ones[n ~/ 100]} Hundred ${conv(n % 100)}'.trim();
//       if (n < 100000) return '${conv(n ~/ 1000)} Thousand ${conv(n % 1000)}'.trim();
//       if (n < 10000000) return '${conv(n ~/ 100000)} Lakh ${conv(n % 100000)}'.trim();
//       return '${conv(n ~/ 10000000)} Crore ${conv(n % 10000000)}'.trim();
//     }

//     final paise = ((amount - intAmount) * 100).round();
//     final wordRupees = conv(intAmount);
//     if (paise > 0) {
//       return isMarathi
//           ? '$wordRupees रुपये आणि $paise पैसे फक्त'
//           : '$wordRupees Rupees and $paise Paise Only';
//     }
//     return isMarathi ? '$wordRupees रुपये फक्त' : '$wordRupees Rupees Only';
//   }

//   String _friendly(Object e) {
//     final s = e.toString();
//     if (s.contains('SocketException') || s.contains('connection')) return 'No internet connection.';
//     if (s.contains('404')) return 'Receipt not found.';
//     return 'Could not load receipt.';
//   }

//   void _snack(String msg, {bool success = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(msg, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
//       backgroundColor: success ? AppColors.success : AppColors.error,
//       behavior: SnackBarBehavior.floating,
//       margin: const EdgeInsets.all(16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//     ));
//   }
// }

// // ─────────────────────────────────────────────────────────────
// //  PRINT BOTTOM SHEET
// // ─────────────────────────────────────────────────────────────
// class _PrintSheet extends StatelessWidget {
//   final Map<String, dynamic>? receipt;
//   final VoidCallback onPrint;

//   const _PrintSheet({this.receipt, required this.onPrint});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
//       decoration: const BoxDecoration(
//           color: AppColors.surface,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//       child: Column(mainAxisSize: MainAxisSize.min, children: [
//         Center(
//             child: Container(
//           width: 36,
//           height: 4,
//           margin: const EdgeInsets.only(bottom: 20, top: 8),
//           decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
//         )),
//         const Icon(Icons.print_rounded, size: 40, color: AppColors.primary),
//         const SizedBox(height: 12),
//         const Text('Print Receipt',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Poppins')),
//         const SizedBox(height: 8),
//         const Text(
//           'Make sure your Bluetooth thermal printer is turned on and paired with this device.',
//           textAlign: TextAlign.center,
//           style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Poppins', height: 1.5),
//         ),
//         const SizedBox(height: 24),
//         SizedBox(
//           width: double.infinity,
//           height: 50,
//           child: ElevatedButton.icon(
//             onPressed: () {
//               Navigator.pop(context);
//               onPrint();
//             },
//             icon: const Icon(Icons.print_rounded, size: 18),
//             label: const Text('Print',
//                 style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600)),
//             style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
//           ),
//         ),
//         const SizedBox(height: 10),
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)),
//         ),
//       ]),
//     );
//   }
// }



// receipt_screen.dart
// ─────────────────────────────────────────────────────────────
//  RECEIPT SCREEN with Marathi/English Language Support
//  Matches the "Jai Shivrai Vegetable Co." sample format
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/constants/colors.dart';
import '../../../providers/language_provider.dart';
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

  // Colors matching sample
  static const Color _redColor = Color(0xFFC8002D);
  static const Color _tableHeaderBg = Color(0xFFF7F7F7);
  static const Color _tableBg = Color(0xFFFFF5F7);

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
    final items = purchase['items'] as List? ?? [];

    final lines = items.map((item) {
      final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
      final rate = (item['rate'] as num?)?.toDouble() ?? 0;
      final amount = (item['amount'] as num?)?.toDouble() ?? 0;
      return {
        'productName': item['productName']?.toString() ?? '',
        'billedQty': quantity,
        'actualQty': quantity,
        'unit': item['unit']?.toString() ?? '',
        'rate': rate,
        'lineTotal': amount,
        'pricingType': item['pricingType']?.toString() ?? '',
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
      'status': purchase['status']?.toString() ?? 'Draft',
      'notes': purchase['notes'] ?? '',
      'summary': data['summary'] ?? {},
      'payments': data['payments'] ?? [],
    };
  }

  // ─────────────────────────────────────────────────────────
  //  PDF GENERATION with Language Support - MATCHES UI EXACTLY
  // ─────────────────────────────────────────────────────────
  Future<pw.Document> _generateReceiptPdf(LanguageProvider lang) async {
    final isMarathi = lang.isMarathi;
    
    // Translations for PDF (matching UI)
    final Map<String, String> englishTranslations = {
      'purchase_receipt': 'PURCHASE RECEIPT',
      'prop_label': 'Prop.',
      'date_label': 'Date:',
      'farmer_label': 'Farmer Name:',
      'mobile_label': 'Mobile:',
      'sr_no': 'Sr.',
      'product_label': 'Product',
      'quantity_label': 'Quantity',
      'rate_label': 'Rate',
      'amount_label': 'Amount',
      'sub_total': 'Sub Total',
      'transport': 'Transport:',
      'labour': 'Labour:',
      'commission': 'Commission:',
      'storage': 'Storage:',
      'return_deduction': 'Return Deduction:',
      'advance_adjusted': 'Advance Adjusted:',
      'other': 'Other:',
      'total_deductions': 'Total Deductions:',
      'final_payable': 'Final Payable:',
      'amount_paid': 'Amount Paid:',
      'balance_due': 'Balance Due:',
      'amount_in_words': 'Amount in Words:',
      'thank_you': 'Thank You!',
      'buyers_signature': "Buyer's Signature",
      'for_company': 'For Jai Shivrai Vegetable Co.',
      'footer_company': 'Jai Shivrai Vegetable Co., Kalwan',
      'status_label': 'Status:',
      'payment_method': 'Payment Method:',
      'generated_on': 'Generated on:',
      'purchase_date_label': 'Purchase Date:',
      'terms_conditions': 'Terms and Conditions',
      'terms_text': '1. Goods once sold will not be taken back.\n2. Payment is due within 30 days.\n3. Interest may apply on overdue payments.\n4. Computer generated receipt.',
      'rupees_only': 'Rupees Only',
      'qr_code_placeholder': 'Scan for details',
    };

    final Map<String, String> marathiTranslations = {
      'purchase_receipt': 'खरेदी पावती',
      'prop_label': 'प्रो.',
      'date_label': 'दिनांक:',
      'farmer_label': 'शेतकऱ्याचे नाव:',
      'mobile_label': 'मोबाइल:',
      'sr_no': 'क्र.',
      'product_label': 'उत्पादन',
      'quantity_label': 'प्रमाण',
      'rate_label': 'दर',
      'amount_label': 'रक्कम',
      'sub_total': 'उप-एकूण',
      'transport': 'वाहतूक:',
      'labour': 'मजुरी:',
      'commission': 'कमिशन:',
      'storage': 'स्टोरेज:',
      'return_deduction': 'परतावा कपात:',
      'advance_adjusted': 'अग्रिम समायोजन:',
      'other': 'इतर:',
      'total_deductions': 'एकूण कपात:',
      'final_payable': 'अंतिम देय:',
      'amount_paid': 'दिलेली रक्कम:',
      'balance_due': 'बाकी देय:',
      'amount_in_words': 'रक्कम अक्षरी:',
      'thank_you': 'धन्यवाद!',
      'buyers_signature': 'खरेदीदाराची स्वाक्षरी',
      'for_company': 'जय शिवराय भाजीपाला साठी',
      'footer_company': 'जय शिवराय भाजीपाला, कळवण',
      'status_label': 'स्थिती:',
      'payment_method': 'पेमेंट पद्धत:',
      'generated_on': 'तयार केले:',
      'purchase_date_label': 'खरेदी दिनांक:',
      'terms_conditions': 'अटी व शर्ती',
      'terms_text': '१. विक्री झालेला माल परत घेतला जाणार नाही.\n२. पेमेंट ३० दिवसांत देय आहे.\n३. थकीत पेमेंटवर व्याज लागू शकते.\n४. संगणकीय पावती.',
      'rupees_only': 'फक्त रुपये',
      'qr_code_placeholder': 'तपशीलासाठी स्कॅन करा',
    };

    String t(String key) {
      return (isMarathi ? marathiTranslations[key] : englishTranslations[key]) ?? key;
    }

    // Fonts
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final r = _receipt!;
    final farmer = r['farmer'] as Map<String, dynamic>? ?? {};
    final business = r['business'] as Map<String, dynamic>? ?? {};
    final lines = r['lines'] as List? ?? [];
    final deductions = r['deductions'] as Map<String, dynamic>? ?? {};
    final payments = r['payments'] as List? ?? [];

    // Colors matching UI
    const pdfRed = PdfColor.fromInt(0xFFC8002D);
    const pdfBorder = PdfColor.fromInt(0xFFC8002D);
    const pdfHeaderBg = PdfColor.fromInt(0xFFF7F7F7);
    const pdfTableBg = PdfColor.fromInt(0xFFFFF5F7);
    const pdfGrey = PdfColors.grey700;

    double toD(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
    String fmtRs(dynamic v) => '₹${toD(v).toStringAsFixed(0)}';
    String fmtRsFull(dynamic v) => '₹${toD(v).toStringAsFixed(2)}';

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

    String numberToWords(double amount) {
      final intAmount = amount.toInt();
      if (intAmount == 0) return isMarathi ? 'शून्य रुपये फक्त' : 'Zero Rupees Only';

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
      if (paise > 0) {
        return isMarathi 
            ? '$wordRupees रुपये आणि $paise पैसे फक्त'
            : '$wordRupees Rupees and $paise Paise Only';
      }
      return isMarathi ? '$wordRupees रुपये फक्त' : '$wordRupees Rupees Only';
    }

    final grossTotal = toD(r['grossTotal']);
    final totalDed = toD(r['totalDeductions']);
    final finalPayable = toD(r['finalPayable']);
    final amountPaid = toD(r['amountPaid']);
    final amountDue = toD(r['amountDue']);

    final receiptNo = r['receiptNumber']?.toString() ?? 'N/A';
    final dateStr = _fmtDateFull(r['purchaseDate']?.toString() ?? r['createdAt']?.toString() ?? '');
    final farmerName = farmer['name']?.toString() ?? widget.farmerName ?? '';
    final mobile = farmer['mobile']?.toString() ?? widget.farmerMobile ?? '';
    final village = farmer['village']?.toString() ?? '';
    final state = farmer['state']?.toString() ?? '';

    final bizName = business['name']?.toString() ?? 'Jai Shivrai Vegetable Co.';
    final bizAddress = business['address']?.toString() ?? 'Vesarane, Tal. Kalwan, Dist. Nashik';
    final bizPhone = business['phone']?.toString() ?? '9021699991 / 9623956396';
    final bizGst = business['gst']?.toString() ?? '';

    String paymentMethod = 'Cash';
    if (payments.isNotEmpty) {
      final modes = payments
          .map((p) => (p['mode'] ?? p['paymentMode'] ?? '').toString())
          .where((e) => e.isNotEmpty)
          .toSet()
          .join(', ');
      if (modes.isNotEmpty) paymentMethod = modes;
    }

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(35, 25, 35, 20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Main Border Container - MATCHES UI
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: pdfBorder, width: 1.5),
                ),
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
                    
                    // Company Name
                    pw.Center(
                      child: pw.Text(bizName,
                          style: ts(size: 20, weight: pw.FontWeight.bold, color: pdfRed)),
                    ),
                    pw.SizedBox(height: 2),
                    
                    // Address
                    pw.Center(
                      child: pw.Text(bizAddress,
                          style: ts(size: 9, color: pdfRed)),
                    ),
                    pw.SizedBox(height: 3),
                    
                    // Receipt Title
                    pw.Center(
                      child: pw.Text(t('purchase_receipt'),
                          style: ts(size: 11, color: pdfGrey)),
                    ),
                    pw.SizedBox(height: 4),

                    // Proprietor - MATCHES UI
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(color: pdfBorder, width: 1),
                          bottom: pw.BorderSide(color: pdfBorder, width: 1),
                        ),
                      ),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('${t('prop_label')} Rakesh Hire M: 9021699991 / 9623956396',
                              style: ts(size: 7.5, weight: pw.FontWeight.bold, color: pdfRed)),
                          if (bizGst.isNotEmpty)
                            pw.Text('GST: $bizGst',
                                style: ts(size: 7.5, weight: pw.FontWeight.bold, color: pdfRed)),
                        ],
                      ),
                    ),

                    // Receipt No and Date - MATCHES UI
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: pdfBorder, width: 1),
                        ),
                      ),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      child: pw.Row(children: [
                        pw.Text('Receipt No.:  ', style: ts(size: 9, weight: pw.FontWeight.bold, color: pdfRed)),
                        pw.Expanded(child: pw.Text(receiptNo, style: ts(size: 9))),
                        pw.Text('${t('date_label')}  ', style: ts(size: 9, weight: pw.FontWeight.bold, color: pdfRed)),
                        pw.Text(_fmtDateShort(r['purchaseDate']?.toString() ?? ''), style: ts(size: 9)),
                      ]),
                    ),

                    // Farmer Details - MATCHES UI
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: pdfBorder, width: 1),
                        ),
                      ),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      child: pw.Row(children: [
                        pw.Text('${t('farmer_label')}  ', style: ts(size: 9, weight: pw.FontWeight.bold, color: pdfRed)),
                        pw.Expanded(child: pw.Text(farmerName, style: ts(size: 9))),
                        if (mobile.isNotEmpty) ...[
                          pw.Text('${t('mobile_label')}  ', style: ts(size: 9, weight: pw.FontWeight.bold, color: pdfRed)),
                          pw.Text(mobile, style: ts(size: 9)),
                        ],
                      ]),
                    ),

                    // Product Table - MATCHES UI
                    pw.Table(
                      border: pw.TableBorder(
                        bottom: const pw.BorderSide(color: pdfBorder, width: 1),
                        horizontalInside: const pw.BorderSide(color: pdfBorder, width: 0.5),
                        verticalInside: const pw.BorderSide(color: pdfBorder, width: 0.5),
                      ),
                      columnWidths: {
                        0: const pw.FixedColumnWidth(28),
                        1: const pw.FlexColumnWidth(3.5),
                        2: const pw.FlexColumnWidth(1.5),
                        3: const pw.FlexColumnWidth(1.8),
                        4: const pw.FlexColumnWidth(1.8),
                      },
                      children: [
                        // Table Header
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: pdfHeaderBg),
                          children: [
                            _pdfCell(t('sr_no'), align: pw.TextAlign.center, isHeader: true),
                            _pdfCell(t('product_label'), align: pw.TextAlign.left, isHeader: true),
                            _pdfCell(t('quantity_label'), align: pw.TextAlign.center, isHeader: true),
                            _pdfCell(t('rate_label'), align: pw.TextAlign.right, isHeader: true),
                            _pdfCell(t('amount_label'), align: pw.TextAlign.right, isHeader: true),
                          ],
                        ),
                        // Data Rows
                        ...lines.asMap().entries.map((entry) {
                          final i = entry.key;
                          final l = entry.value;
                          final qty = toD(l['billedQty']);
                          final rate = toD(l['rate']);
                          final total = toD(l['lineTotal']);
                          final unit = l['unit']?.toString() ?? '';
                          return pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: i.isEven ? PdfColors.white : pdfTableBg,
                            ),
                            children: [
                              _pdfCell('${i + 1}', align: pw.TextAlign.center),
                              _pdfCell(l['productName']?.toString() ?? '',
                                  align: pw.TextAlign.left, bold: true),
                              _pdfCell('${qty.toStringAsFixed(qty == qty.toInt() ? 0 : 2)} $unit',
                                  align: pw.TextAlign.center),
                              _pdfCell(fmtRs(rate), align: pw.TextAlign.right),
                              _pdfCell(fmtRs(total), align: pw.TextAlign.right, bold: true, color: pdfRed),
                            ],
                          );
                        }),
                      ],
                    ),

                    // Left side: Terms & Conditions, Right side: Totals - MATCHES UI
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: pdfBorder, width: 1),
                        ),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Terms and Conditions Section (left side)
                          pw.Expanded(
                            flex: 5,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: pw.Text(t('terms_conditions'),
                                      style: ts(size: 8, weight: pw.FontWeight.bold, color: pdfRed)),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.fromLTRB(8, 0, 8, 8),
                                  child: pw.Text(t('terms_text'),
                                      style: ts(size: 6.5, color: pdfGrey)),
                                ),
                              ],
                            ),
                          ),
                          // Vertical divider
                          pw.Container(width: 1, height: 160, color: pdfBorder),
                          // Totals Section (right side) - MATCHES UI
                          pw.Expanded(
                            flex: 3,
                            child: pw.Column(
                              children: [
                                _pdfTotalsRow(t('sub_total'), fmtRsFull(grossTotal), pdfRed),
                                if (toD(deductions['transport']) > 0)
                                  _pdfTotalsRow(t('transport'), '-${fmtRsFull(deductions['transport'])}', pdfRed),
                                if (toD(deductions['labour']) > 0)
                                  _pdfTotalsRow(t('labour'), '-${fmtRsFull(deductions['labour'])}', pdfRed),
                                if (toD(deductions['commission']) > 0)
                                  _pdfTotalsRow(
                                    deductions['commissionType'] == 'percent'
                                        ? '${t('commission')} (${deductions['commission']}%)'
                                        : t('commission'),
                                    '-${fmtRsFull(deductions['commission'])}',
                                    pdfRed,
                                  ),
                                if (toD(deductions['storage']) > 0)
                                  _pdfTotalsRow(t('storage'), '-${fmtRsFull(deductions['storage'])}', pdfRed),
                                if (toD(deductions['returnDeduction']) > 0)
                                  _pdfTotalsRow(t('return_deduction'), '-${fmtRsFull(deductions['returnDeduction'])}', pdfRed),
                                if (toD(deductions['advanceAdjusted']) > 0)
                                  _pdfTotalsRow(t('advance_adjusted'), '-${fmtRsFull(deductions['advanceAdjusted'])}', pdfRed),
                                if (toD(deductions['other']) > 0)
                                  _pdfTotalsRow(t('other'), '-${fmtRsFull(deductions['other'])}', pdfRed),
                                _pdfDivider(pdfBorder),
                                _pdfTotalsRow(t('total_deductions'), '-${fmtRsFull(totalDed)}', pdfRed, bold: true),
                                _pdfTotalsRow(t('final_payable'), fmtRsFull(finalPayable), pdfRed, bold: true, large: true),
                                _pdfTotalsRow(t('amount_paid'), fmtRsFull(amountPaid), pdfRed),
                                _pdfTotalsRow(t('balance_due'), fmtRsFull(amountDue), pdfRed,
                                    bold: true, color: amountDue > 0 ? PdfColor.fromInt(0xFFD32F2F) : PdfColor.fromInt(0xFF2E7D32)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Amount in Words - MATCHES UI
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: pdfBorder, width: 1),
                        ),
                      ),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      child: pw.Text(
                        '${t('amount_in_words')} ${numberToWords(finalPayable)}',
                        style: ts(size: 8.5, color: pdfRed),
                      ),
                    ),

                    // Payment Method - MATCHES UI
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: pdfBorder, width: 1),
                        ),
                      ),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      child: pw.Row(children: [
                        pw.Text('${t('payment_method')}  ',
                            style: ts(size: 9, weight: pw.FontWeight.bold, color: pdfRed)),
                        pw.Text(paymentMethod, style: ts(size: 9)),
                      ]),
                    ),

                    // Status - MATCHES UI
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: pdfBorder, width: 1),
                        ),
                      ),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      child: pw.Row(children: [
                        pw.Text('${t('status_label')}  ',
                            style: ts(size: 9, weight: pw.FontWeight.bold, color: pdfRed)),
                        pw.Text(r['status']?.toString() ?? 'Draft',
                            style: ts(size: 9, weight: pw.FontWeight.bold,
                                color: r['status'] == 'paid' ? PdfColor.fromInt(0xFF2E7D32) : pdfRed)),
                      ]),
                    ),

                    // Thank You + Total Amount - MATCHES UI
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: pdfBorder, width: 1),
                        ),
                      ),
                      child: pw.Row(children: [
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: pw.Text(t('thank_you'),
                                style: ts(size: 10, weight: pw.FontWeight.bold, color: pdfRed)),
                          ),
                        ),
                        pw.Container(width: 1, height: 36, color: pdfBorder),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: pw.Row(children: [
                            pw.Text('Total Amount:  ',
                                style: ts(size: 9, weight: pw.FontWeight.bold, color: pdfRed)),
                            pw.Text(fmtRsFull(finalPayable),
                                style: ts(size: 13, weight: pw.FontWeight.bold, color: pdfRed)),
                          ]),
                        ),
                      ]),
                    ),

                    // Signatures - MATCHES UI
                    pw.Container(
                      padding: const pw.EdgeInsets.fromLTRB(10, 20, 10, 12),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('......................................',
                                  style: ts(size: 9, color: pdfRed)),
                              pw.SizedBox(height: 2),
                              pw.Text(t('buyers_signature'),
                                  style: ts(size: 8.5, weight: pw.FontWeight.bold, color: pdfRed)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('......................................',
                                  style: ts(size: 9, color: pdfRed)),
                              pw.SizedBox(height: 2),
                              pw.Text(t('for_company'),
                                  style: ts(size: 8.5, weight: pw.FontWeight.bold, color: pdfRed)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Footer
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  '${t('generated_on')} ${DateFormat('dd/MM/yyyy, hh:mm a').format(DateTime.now())}',
                  style: ts(size: 7, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc;
  }

  pw.Widget _pdfCell(String text,
      {pw.TextAlign align = pw.TextAlign.center,
      bool bold = false,
      bool isHeader = false,
      PdfColor color = PdfColors.black}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      child: pw.Text(
        text,
        textAlign: align,
        softWrap: true,
        maxLines: 2,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 8.5,
          fontWeight: isHeader || bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }
  
  pw.Widget _pdfTotalsRow(String label, String value, PdfColor redColor,
      {bool bold = false, bool large = false, PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                fontSize: large ? 9 : 8,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: redColor,
              )),
          pw.Text(value,
              style: pw.TextStyle(
                fontSize: large ? 11 : 8,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color ?? (large ? redColor : PdfColors.black),
              )),
        ],
      ),
    );
  }

  pw.Widget _pdfDivider(PdfColor color) {
    return pw.Container(height: 1, color: color, margin: const pw.EdgeInsets.symmetric(vertical: 4));
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
    final farmer = _receipt!['farmer'] as Map<String, dynamic>? ?? {};
    final farmerId = farmer['_id']?.toString() ?? farmer['id']?.toString() ?? '';
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
    if (paid == true && mounted) await _fetchReceipt();
  }

  Future<void> _downloadPdf(LanguageProvider lang) async {
    if (_receipt == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 14),
                Text('Generating PDF…', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final pdfDoc = await _generateReceiptPdf(lang);
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

  Future<void> _shareWhatsApp(LanguageProvider lang) async {
    if (_receipt == null) return;
    final text = _buildWhatsAppText(lang);
    final farmer = _receipt!['farmer'] as Map<String, dynamic>? ?? {};
    final mobile = farmer['mobile']?.toString() ?? widget.farmerMobile ?? '';
    final digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final phone = digits.length == 10 ? '91$digits' : digits;
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(
          Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'),
          mode: LaunchMode.externalApplication);
    }
  }

  String _buildWhatsAppText(LanguageProvider lang) {
    if (_receipt == null) return '';
    final isMarathi = lang.isMarathi;
    final r = _receipt!;
    final farmer = r['farmer'] as Map<String, dynamic>? ?? {};
    final business = r['business'] as Map<String, dynamic>? ?? {};
    final lines = r['lines'] as List? ?? [];
    final deductions = r['deductions'] as Map<String, dynamic>? ?? {};
    final grossTotal = (r['grossTotal'] as num?)?.toDouble() ?? 0;
    final finalPayable = (r['finalPayable'] as num?)?.toDouble() ?? 0;
    final amountPaid = (r['amountPaid'] as num?)?.toDouble() ?? 0;
    final amountDue = (r['amountDue'] as num?)?.toDouble() ?? 0;

    if (isMarathi) {
      final buf = StringBuffer();
      buf.writeln('🌾 *${business['name'] ?? 'शेतकरी बाजार'}*');
      buf.writeln('━━━━━━━━━━━━━━━━━━━━');
      buf.writeln('पावती क्र.: *${r['receiptNumber'] ?? ''}*');
      buf.writeln('दिनांक: ${_fmtDate(r['purchaseDate']?.toString() ?? '')}');
      buf.writeln('शेतकरी: *${farmer['name'] ?? widget.farmerName ?? ''}*');
      if ((farmer['mobile'] ?? widget.farmerMobile ?? '').isNotEmpty)
        buf.writeln('मोबाइल: ${farmer['mobile'] ?? widget.farmerMobile}');
      buf.writeln('━━━━━━━━━━━━━━━━━━━━');
      buf.writeln('*उत्पादने*');
      for (final l in lines) {
        final qty = (l['billedQty'] as num?)?.toDouble() ?? 0;
        final rate = (l['rate'] as num?)?.toDouble() ?? 0;
        final total = (l['lineTotal'] as num?)?.toDouble() ?? 0;
        buf.writeln('• ${l['productName']}: ${qty.toStringAsFixed(2)} ${l['unit']} × ₹${rate.toStringAsFixed(2)} = ₹${total.toStringAsFixed(2)}');
      }
      buf.writeln('━━━━━━━━━━━━━━━━━━━━');
      buf.writeln('एकूण: ₹${grossTotal.toStringAsFixed(2)}');
      if ((deductions['transport'] as num? ?? 0) > 0) buf.writeln('वाहतूक: -₹${(deductions['transport'] as num).toStringAsFixed(2)}');
      if ((deductions['labour'] as num? ?? 0) > 0) buf.writeln('मजुरी: -₹${(deductions['labour'] as num).toStringAsFixed(2)}');
      if ((deductions['commission'] as num? ?? 0) > 0) buf.writeln('कमिशन: -₹${(deductions['commission'] as num).toStringAsFixed(2)}');
      buf.writeln('━━━━━━━━━━━━━━━━━━━━');
      buf.writeln('*अंतिम देय: ₹${finalPayable.toStringAsFixed(2)}*');
      if (amountPaid > 0) buf.writeln('दिलेली रक्कम: ₹${amountPaid.toStringAsFixed(2)}');
      buf.writeln(amountDue > 0 ? '*बाकी देय: ₹${amountDue.toStringAsFixed(2)}*' : '✅ पूर्ण भरले');
      buf.writeln('━━━━━━━━━━━━━━━━━━━━');
      buf.writeln('व्यवसायाबद्दल धन्यवाद!');
      return buf.toString();
    } else {
      final buf = StringBuffer();
      buf.writeln('🌾 *${business['name'] ?? 'FARM ERP'}*');
      buf.writeln('━━━━━━━━━━━━━━━━━━━━');
      buf.writeln('Receipt No: *${r['receiptNumber'] ?? ''}*');
      buf.writeln('Date: ${_fmtDate(r['purchaseDate']?.toString() ?? '')}');
      buf.writeln('Farmer: *${farmer['name'] ?? widget.farmerName ?? ''}*');
      if ((farmer['mobile'] ?? widget.farmerMobile ?? '').isNotEmpty) {
        buf.writeln('Mobile: ${farmer['mobile'] ?? widget.farmerMobile}');
      }
      buf.writeln('━━━━━━━━━━━━━━━━━━━━');
      buf.writeln('*PRODUCTS*');
      for (final l in lines) {
        final qty = (l['billedQty'] as num?)?.toDouble() ?? 0;
        final rate = (l['rate'] as num?)?.toDouble() ?? 0;
        final total = (l['lineTotal'] as num?)?.toDouble() ?? 0;
        buf.writeln('• ${l['productName']}: ${qty.toStringAsFixed(2)} ${l['unit']} × ₹${rate.toStringAsFixed(2)} = ₹${total.toStringAsFixed(2)}');
      }
      buf.writeln('━━━━━━━━━━━━━━━━━━━━');
      buf.writeln('Gross Total: ₹${grossTotal.toStringAsFixed(2)}');
      if ((deductions['transport'] as num? ?? 0) > 0) buf.writeln('Transport: -₹${(deductions['transport'] as num).toStringAsFixed(2)}');
      if ((deductions['labour'] as num? ?? 0) > 0) buf.writeln('Labour: -₹${(deductions['labour'] as num).toStringAsFixed(2)}');
      if ((deductions['commission'] as num? ?? 0) > 0) buf.writeln('Commission: -₹${(deductions['commission'] as num).toStringAsFixed(2)}');
      buf.writeln('━━━━━━━━━━━━━━━━━━━━');
      buf.writeln('*FINAL PAYABLE: ₹${finalPayable.toStringAsFixed(2)}*');
      if (amountPaid > 0) buf.writeln('Paid: ₹${amountPaid.toStringAsFixed(2)}');
      buf.writeln(amountDue > 0 ? '*Balance Due: ₹${amountDue.toStringAsFixed(2)}*' : '✅ FULLY PAID');
      buf.writeln('━━━━━━━━━━━━━━━━━━━━');
      buf.writeln('Thank you for your business!');
      return buf.toString();
    }
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lang.t('purchase_receipt'),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: _redColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _buildLanguageToggle(lang),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: _loading ? null : () => _printReceipt(lang),
            tooltip: lang.t('print'),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _loading ? null : () => _downloadPdf(lang),
            tooltip: lang.t('download_pdf'),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _loading ? null : () => _shareWhatsApp(lang),
            tooltip: lang.t('share_whatsapp'),
          ),
        ],
      ),
      body: _loading
          ? _buildLoading(lang)
          : _error != null
              ? _buildError(lang)
              : _buildReceipt(lang),
    );
  }

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
                color: selected ? _redColor : Colors.white)),
      ),
    );
  }

  void _printReceipt(LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PrintSheet(
        receipt: _receipt,
        onPrint: () => _downloadPdf(lang),
      ),
    );
  }

  Widget _buildLoading(LanguageProvider lang) => const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Loading receipt…',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.textSecondary)),
        ]),
      );

  Widget _buildError(LanguageProvider lang) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text('Purchase saved successfully!',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.success),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Receipt could not be loaded: $_error',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _fetchReceipt,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Retry', style: TextStyle(fontFamily: 'Poppins')),
            ),
          ]),
        ),
      );

  Widget _buildReceipt(LanguageProvider lang) {
    final r = _receipt!;
    final farmer = r['farmer'] as Map<String, dynamic>? ?? {};
    final lines = r['lines'] as List? ?? [];
    final deductions = r['deductions'] as Map<String, dynamic>? ?? {};
    final receiptNo = r['receiptNumber']?.toString() ?? '—';
    final date = _fmtDateFull(r['purchaseDate']?.toString() ?? r['createdAt']?.toString() ?? '');
    final farmerName = farmer['name']?.toString() ?? widget.farmerName ?? '—';
    final farmerMobile = farmer['mobile']?.toString() ?? widget.farmerMobile ?? '';
    final grossTotal = (r['grossTotal'] as num?)?.toDouble() ?? 0;
    final finalPayable = (r['finalPayable'] as num?)?.toDouble() ?? 0;
    final amountPaid = (r['amountPaid'] as num?)?.toDouble() ?? 0;
    final amountDue = (r['amountDue'] as num?)?.toDouble() ?? 0;
    final isFullyPaid = amountDue <= 0;

    final isMarathi = lang.isMarathi;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _redColor, width: 1.5),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Jurisdiction
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 2),
              child: Center(
                child: Text('|| Under Kalwan Jurisdiction ||',
                    style: TextStyle(fontSize: 11, color: _redColor, letterSpacing: 0.3)),
              ),
            ),
            // Company Name
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Center(
                child: Text('Jai Shivrai Vegetable Co.',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _redColor, letterSpacing: -0.5)),
              ),
            ),
            // Address
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Center(
                child: Text('Vesarane, Tal. Kalwan, Dist. Nashik',
                    style: TextStyle(fontSize: 11.5, color: _redColor, fontWeight: FontWeight.w500)),
              ),
            ),
            // Title
            const Padding(
              padding: EdgeInsets.only(top: 3, bottom: 6),
              child: Center(
                child: Text('PURCHASE RECEIPT',
                    style: TextStyle(fontSize: 11, color: Color(0xFF777777), letterSpacing: 0.5)),
              ),
            ),
            _horizontalDivider(),
            // Proprietor
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text('Prop. Rakesh Hire M: 9021699991 / 9623956396',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _redColor)),
                  ),
                ],
              ),
            ),
            _horizontalDivider(),
            // Receipt No / Date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _redLabel('Receipt No.:'),
                  const SizedBox(width: 6),
                  Flexible(child: Text(receiptNo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 16),
                  _redLabel(isMarathi ? 'दिनांक:' : 'Date:'),
                  const SizedBox(width: 6),
                  Text(_fmtDateShort(r['purchaseDate']?.toString() ?? ''),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            _horizontalDivider(),
            // Farmer Name / Mobile
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _redLabel(isMarathi ? 'शेतकऱ्याचे नाव:' : 'Farmer Name:'),
                  const SizedBox(width: 6),
                  Expanded(child: Text(farmerName, style: const TextStyle(fontSize: 13))),
                  if (farmerMobile.isNotEmpty) ...[
                    _redLabel(isMarathi ? 'मोबाइल:' : 'Mobile:'),
                    const SizedBox(width: 6),
                    Text(farmerMobile, style: const TextStyle(fontSize: 13)),
                  ],
                ],
              ),
            ),
            _horizontalDivider(),
            // Product Table with FIXED OVERFLOW
            _buildProductTableUI(lines, isMarathi),
            // Totals and Deductions
            _buildTotalsSectionUI(grossTotal, deductions, totalDeductions, finalPayable, amountPaid, amountDue, isMarathi),
            // Amount in Words
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '${isMarathi ? 'रक्कम अक्षरी:' : 'Amount in Words:'}  ${_numberToWords(finalPayable, isMarathi)}',
                style: TextStyle(fontSize: 12, color: _redColor, fontWeight: FontWeight.w500),
              ),
            ),
            _horizontalDivider(),
            // Thank You / Total
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(isMarathi ? 'धन्यवाद!' : 'Thank You!',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _redColor)),
                    ),
                  ),
                  Container(width: 1, color: _redColor),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total Amount:  ',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _redColor)),
                        Text('₹${finalPayable.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _redColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _horizontalDivider(),
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
                      Container(width: 150, height: 1, color: _redColor),
                      const SizedBox(height: 4),
                      Text(isMarathi ? 'खरेदीदाराची स्वाक्षरी' : "Buyer's Signature",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _redColor)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(width: 150, height: 1, color: _redColor),
                      const SizedBox(height: 4),
                      Text('Jai Shivrai Vegetable Co., Kalwan',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _redColor)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double get totalDeductions {
    if (_receipt == null) return 0;
    return (_receipt!['totalDeductions'] as num?)?.toDouble() ?? 0;
  }

  Widget _horizontalDivider() => Container(height: 1, color: _redColor);

  Widget _redLabel(String text) => Text(text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _redColor));

  // FIXED: Product table with proper overflow handling
  Widget _buildProductTableUI(List lines, bool isMarathi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _tableHeaderBg,
            border: Border(bottom: BorderSide(color: _redColor, width: 1)),
          ),
          child: Row(
            children: [
              _thUI(isMarathi ? 'क्र.' : 'Sr.', flex: 0.5, align: TextAlign.center),
              _thDividerUI(),
              Expanded(flex: 3, child: _thUI(isMarathi ? 'उत्पादन' : 'Product', flex: 3, align: TextAlign.left)),
              _thDividerUI(),
              Expanded(flex: 1, child: _thUI(isMarathi ? 'प्रमाण' : 'Qty', flex: 1.5, align: TextAlign.center)),
              _thDividerUI(),
              Expanded(flex: 1, child: _thUI(isMarathi ? 'दर' : 'Rate', flex: 1.5, align: TextAlign.right)),
              _thDividerUI(),
              Expanded(flex: 1, child: _thUI(isMarathi ? 'रक्कम' : 'Amount', flex: 1.5, align: TextAlign.right)),
            ],
          ),
        ),
        ...lines.asMap().entries.map((entry) {
          final i = entry.key;
          final l = entry.value;
          final qty = (l['billedQty'] as num?)?.toDouble() ?? 0;
          final rate = (l['rate'] as num?)?.toDouble() ?? 0;
          final total = (l['lineTotal'] as num?)?.toDouble() ?? 0;
          final unit = l['unit']?.toString() ?? '';
          return Container(
            decoration: BoxDecoration(
              color: i.isEven ? Colors.white : _tableBg,
              border: Border(bottom: BorderSide(color: _redColor.withOpacity(0.22))),
            ),
            child: Row(
              children: [
                _tdUI('${i + 1}', flex: 0.5, align: TextAlign.center),
                _tdDividerUI(),
                Expanded(
                  flex: 3,
                  child: _tdUI(l['productName']?.toString() ?? '', flex: 3, align: TextAlign.left, bold: true),
                ),
                _tdDividerUI(),
                Expanded(
                  flex: 1,
                  child: _tdUI('${qty.toStringAsFixed(qty == qty.toInt() ? 0 : 2)} $unit', flex: 1.5, align: TextAlign.center),
                ),
                _tdDividerUI(),
                Expanded(
                  flex: 1,
                  child: _tdUI('₹${rate.toStringAsFixed(2)}', flex: 1.5, align: TextAlign.right),
                ),
                _tdDividerUI(),
                Expanded(
                  flex: 1,
                  child: _tdUI('₹${total.toStringAsFixed(2)}', flex: 1.5, align: TextAlign.right, bold: true, color: _redColor),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTotalsSectionUI(double grossTotal, Map deductions, double totalDed, double finalPayable, double amountPaid, double amountDue, bool isMarathi) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _redColor))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Terms (left side)
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(isMarathi ? 'अटी व शर्ती' : 'Terms and Conditions',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _redColor)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Text(
                    isMarathi
                        ? '१. विक्री झालेला माल परत घेतला जाणार नाही.\n२. पेमेंट ३० दिवसांत देय आहे.\n३. थकीत पेमेंटवर व्याज लागू शकते.\n४. संगणकीय पावती.'
                        : '1. Goods once sold will not be taken back.\n2. Payment is due within 30 days.\n3. Interest may apply on overdue payments.\n4. Computer generated receipt.',
                    style: TextStyle(fontSize: 8, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 100, color: _redColor),
          // Totals (right side)
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _totalsRowUI(isMarathi ? 'उप-एकूण' : 'Sub Total', '₹${grossTotal.toStringAsFixed(2)}', _redColor),
                if ((deductions['transport'] as num? ?? 0) > 0)
                  _totalsRowUI(isMarathi ? 'वाहतूक:' : 'Transport:', '-₹${(deductions['transport'] as num).toStringAsFixed(2)}', _redColor),
                if ((deductions['labour'] as num? ?? 0) > 0)
                  _totalsRowUI(isMarathi ? 'मजुरी:' : 'Labour:', '-₹${(deductions['labour'] as num).toStringAsFixed(2)}', _redColor),
                if ((deductions['commission'] as num? ?? 0) > 0)
                  _totalsRowUI(
                    deductions['commissionType'] == 'percent'
                        ? '${isMarathi ? 'कमिशन' : 'Commission'} (${deductions['commission']}%)'
                        : (isMarathi ? 'कमिशन:' : 'Commission:'),
                    '-₹${(deductions['commission'] as num).toStringAsFixed(2)}',
                    _redColor,
                  ),
                if ((deductions['storage'] as num? ?? 0) > 0)
                  _totalsRowUI(isMarathi ? 'स्टोरेज:' : 'Storage:', '-₹${(deductions['storage'] as num).toStringAsFixed(2)}', _redColor),
                if ((deductions['returnDeduction'] as num? ?? 0) > 0)
                  _totalsRowUI(isMarathi ? 'परतावा कपात:' : 'Return Deduction:', '-₹${(deductions['returnDeduction'] as num).toStringAsFixed(2)}', _redColor),
                if ((deductions['advanceAdjusted'] as num? ?? 0) > 0)
                  _totalsRowUI(isMarathi ? 'अग्रिम समायोजन:' : 'Advance Adjusted:', '-₹${(deductions['advanceAdjusted'] as num).toStringAsFixed(2)}', _redColor),
                if ((deductions['other'] as num? ?? 0) > 0)
                  _totalsRowUI(isMarathi ? 'इतर:' : 'Other:', '-₹${(deductions['other'] as num).toStringAsFixed(2)}', _redColor),
                const Divider(height: 8, thickness: 1),
                _totalsRowUI(isMarathi ? 'एकूण कपात:' : 'Total Deductions:', '-₹${totalDed.toStringAsFixed(2)}', _redColor, bold: true),
                const SizedBox(height: 4),
                _totalsRowUI(isMarathi ? 'अंतिम देय:' : 'Final Payable:', '₹${finalPayable.toStringAsFixed(2)}', _redColor, bold: true, large: true),
                _totalsRowUI(isMarathi ? 'दिलेली रक्कम:' : 'Amount Paid:', '₹${amountPaid.toStringAsFixed(2)}', _redColor),
                _totalsRowUI(isMarathi ? 'बाकी देय:' : 'Balance Due:', '₹${amountDue.toStringAsFixed(2)}', _redColor,
                    bold: true, color: amountDue > 0 ? Colors.red.shade700 : Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thUI(String text, {required double flex, TextAlign align = TextAlign.center}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
      child: Text(text,
          textAlign: align,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
    );
  }

  Widget _thDividerUI() => Container(width: 1, height: 36, color: const Color(0xFFDDDDDD));

  Widget _tdDividerUI() => Container(width: 1, height: 38, color: _redColor.withOpacity(0.18));

  Widget _tdUI(String text, {
    required double flex,
    TextAlign align = TextAlign.center,
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Text(
        text,
        textAlign: align,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: color ?? const Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _totalsRowUI(String label, String value, Color redColor,
      {bool bold = false, bool large = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: large ? 11 : 10,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: redColor)),
          Text(value,
              style: TextStyle(
                  fontSize: large ? 13 : 10,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? (large ? redColor : Colors.black87))),
        ],
      ),
    );
  }

  String _fmtDateShort(String raw) {
    if (raw.isEmpty) return '—';
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return raw;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _fmtDateFull(String raw) {
    if (raw.isEmpty) return '—';
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return raw;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _fmtDate(String raw) {
    if (raw.isEmpty) return '—';
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return raw;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _numberToWords(double amount, bool isMarathi) {
    final intAmount = amount.toInt();
    if (intAmount == 0) return isMarathi ? 'शून्य रुपये फक्त' : 'Zero Rupees Only';

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
    if (paise > 0) {
      return isMarathi
          ? '$wordRupees रुपये आणि $paise पैसे फक्त'
          : '$wordRupees Rupees and $paise Paise Only';
    }
    return isMarathi ? '$wordRupees रुपये फक्त' : '$wordRupees Rupees Only';
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('connection')) return 'No internet connection.';
    if (s.contains('404')) return 'Receipt not found.';
    return 'Could not load receipt.';
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
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
  final VoidCallback onPrint;

  const _PrintSheet({this.receipt, required this.onPrint});

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
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
        )),
        const Icon(Icons.print_rounded, size: 40, color: AppColors.primary),
        const SizedBox(height: 12),
        const Text('Print Receipt',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        const Text(
          'Make sure your Bluetooth thermal printer is turned on and paired with this device.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Poppins', height: 1.5),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onPrint();
            },
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Print',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)),
        ),
      ]),
    );
  }
}

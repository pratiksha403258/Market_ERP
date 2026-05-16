
import 'dart:io';
import 'dart:typed_data';

import 'package:agr_market/models/Buyer%20ledger%20model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../core/constants/colors.dart';
import '../providers/language_provider.dart';
import '../services/constant_service.dart';
import '../services/dio_client.dart';

// ─── App-level colours (matches sample exactly) ───────────────────────────────
const _kRed = Color(0xFFB71C1C);
const _kRedLight = Color(0xFFFFEBEE);
const _kRedMid = Color(0xFFEF9A9A);
const _kBorder = Color(0xFFDDDDDD);

class BuyerLedgerDetailScreen extends StatefulWidget {
  final String buyerId;
  final String buyerName;
  final String buyerMobile;

  const BuyerLedgerDetailScreen({
    super.key,
    required this.buyerId,
    required this.buyerName,
    required this.buyerMobile,
  });

  @override
  State<BuyerLedgerDetailScreen> createState() =>
      _BuyerLedgerDetailScreenState();
}

class _BuyerLedgerDetailScreenState extends State<BuyerLedgerDetailScreen> {
  BuyerLedgerData? _data;
  bool _loading = true;
  bool _exporting = false;

  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollCtrl = ScrollController();

  final _fmt = DateFormat('dd/MM/yyyy');
  final _fmtFull = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadLedger();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _totalPages) {
      _loadMore();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Data Loading
  // ═══════════════════════════════════════════════════════════════════════════
Future<void> _loadLedger({bool reset = true}) async {
  if (reset) {
    setState(() {
      _loading = true;
      _currentPage = 1;
    });
  }
  try {
    // LOG 1: Show the API endpoint being called
    final endpoint = ApiRoutes.buyerLedger(widget.buyerId);
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📡 API CALL: GET $endpoint');
    print('📡 Buyer ID: ${widget.buyerId}');
    print('📡 Buyer Name: ${widget.buyerName}');
    print('📡 Page: ${reset ? 1 : _currentPage}, Limit: 50');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final res = await DioClient.instance.dio.get(
      endpoint,
      queryParameters: {
        'page': reset ? 1 : _currentPage,
        'limit': 50,
      },
    );
    
    // LOG 2: Show response status
    print('✅ RESPONSE STATUS: ${res.statusCode}');
    print('✅ RESPONSE SUCCESS: ${res.data['success']}');
    
    final responseData = res.data as Map<String, dynamic>;
    if (responseData['success'] == true) {
      final dataMap = responseData['data'] as Map<String, dynamic>;
      
      // LOG 3: Show summary data
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 SUMMARY DATA:');
      print('   - Total Debit: ${dataMap['summary']?['totalDebit']}');
      print('   - Total Credit: ${dataMap['summary']?['totalCredit']}');
      print('   - Closing Balance: ${dataMap['summary']?['closingBalance']}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // LOG 4: Show business details
      print('🏢 BUSINESS DETAILS:');
      print('   - Name: ${dataMap['businessDetails']?['name']}');
      print('   - Address: ${dataMap['businessDetails']?['address']}');
      print('   - Phone: ${dataMap['businessDetails']?['phone']}');
      print('   - Email: ${dataMap['businessDetails']?['email']}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // LOG 5: Show buyer info
      print('👤 BUYER INFO:');
      print('   - Name: ${dataMap['buyer']?['name']}');
      print('   - Mobile: ${dataMap['buyer']?['mobile']}');
      print('   - Email: ${dataMap['buyer']?['email']}');
      print('   - Address: ${dataMap['buyer']?['address']}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // LOG 6: Show transactions count
      final transactionsList = dataMap['transactions'] as List? ?? [];
      print('📋 TRANSACTIONS COUNT: ${transactionsList.length}');
      if (transactionsList.isNotEmpty) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📝 FIRST 3 TRANSACTIONS (if available):');
        for (int i = 0; i < (transactionsList.length > 3 ? 3 : transactionsList.length); i++) {
          final tx = transactionsList[i];
          print('   ${i+1}. Date: ${tx['entryDate']}');
          print('      Desc: ${tx['description']}');
          print('      Debit: ${tx['debit']}, Credit: ${tx['credit']}, Balance: ${tx['runningBalance']}');
          print('      ---');
        }
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // LOG 7: Show pagination info
      print('📄 PAGINATION:');
      print('   - Page: ${dataMap['pagination']?['page']}');
      print('   - Limit: ${dataMap['pagination']?['limit']}');
      print('   - Total: ${dataMap['pagination']?['total']}');
      print('   - Pages: ${dataMap['pagination']?['pages']}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final newData = BuyerLedgerData.fromJson(dataMap);
      
      // LOG 8: Show parsed data summary
      print('✅ PARSED DATA SUMMARY:');
      print('   - Total Debit: ${newData.summary.totalDebit}');
      print('   - Total Credit: ${newData.summary.totalCredit}');
      print('   - Closing Balance: ${newData.summary.closingBalance}');
      print('   - Transactions Count: ${newData.transactions.length}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      setState(() {
        if (reset) {
          _data = newData;
        } else {
          final existing = _data!.transactions;
          _data = BuyerLedgerData(
            businessDetails: _data!.businessDetails,
            buyer: _data!.buyer,
            summary: newData.summary,
            transactions: [...existing, ...newData.transactions],
            totalPages: newData.totalPages,
            totalTransactions: newData.totalTransactions,
          );
        }
        _totalPages = newData.totalPages;
        _loading = false;
      });
      
      // LOG 9: Final state after setState
      print('🎯 FINAL STATE:');
      print('   - _data exists: ${_data != null}');
      print('   - Total transactions in state: ${_data?.transactions.length ?? 0}');
      print('   - Closing balance in state: ${_data?.summary.closingBalance ?? 0}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
    } else {
      print('❌ API returned success=false');
      print('❌ Response: $responseData');
    }
  } catch (e) {
    print('❌ ERROR loading buyer ledger: $e');
    if (e is DioException) {
      print('❌ DioException type: ${e.type}');
      print('❌ DioException message: ${e.message}');
      print('❌ DioException response: ${e.response?.data}');
      print('❌ DioException status code: ${e.response?.statusCode}');
    }
    setState(() => _loading = false);
    _snack('Failed to load ledger: $e', isError: true);
  }
}
  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _loadLedger(reset: false);
    setState(() => _isLoadingMore = false);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Formatters
  // ═══════════════════════════════════════════════════════════════════════════
  String _fmtAmt(double v) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
          .format(v.abs());

  String _amountInWords(double amount) {
    if (amount == 0) return 'Zero Rupees Only';
    final units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
      'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
      'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen',
    ];
    final tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
      'Sixty', 'Seventy', 'Eighty', 'Ninety',
    ];

    String convert(int n) {
      if (n == 0) return '';
      if (n < 20) return units[n];
      if (n < 100) {
        return '${tens[n ~/ 10]}${n % 10 != 0 ? ' ${units[n % 10]}' : ''}';
      }
      if (n < 1000) {
        return '${units[n ~/ 100]} Hundred${n % 100 != 0 ? ' ${convert(n % 100)}' : ''}';
      }
      return n.toString();
    }

    final intAmt = amount.abs().toInt();
    if (intAmt >= 10000000) {
      return '${convert(intAmt ~/ 10000000)} Crore'
          '${intAmt % 10000000 != 0 ? ' ${convert((intAmt % 10000000) ~/ 100000)} Lakh' : ''}'
          ' Rupees Only';
    }
    if (intAmt >= 100000) {
      return '${convert(intAmt ~/ 100000)} Lakh'
          '${intAmt % 100000 != 0 ? ' ${convert(intAmt % 100000)}' : ''}'
          ' Rupees Only';
    }
    if (intAmt >= 1000) {
      return '${convert(intAmt ~/ 1000)} Thousand'
          '${intAmt % 1000 != 0 ? ' ${convert(intAmt % 1000)}' : ''}'
          ' Rupees Only';
    }
    return '${convert(intAmt)} Rupees Only';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PDF Generation — matches sample exactly
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Uint8List> _buildPdf() async {
    final d = _data!;
    final doc = pw.Document();

    // Exact colours from sample
    final pdfRed = PdfColor.fromHex('#B71C1C');
    final pdfRedLight = PdfColor.fromHex('#FFEBEE');
    final pdfWhite = PdfColors.white;
    final pdfBlack = PdfColors.black;
    final pdfGrey = PdfColor.fromHex('#888888');
    final pdfBorderGrey = PdfColor.fromHex('#DDDDDD');
    final pdfLightGrey = PdfColor.fromHex('#F5F5F5');

    // Load Poppins fonts
    final fontRegular = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();
    final fontMedium = await PdfGoogleFonts.poppinsMedium();
    final fontItalic = await PdfGoogleFonts.poppinsItalic();

    final transactions = d.transactions;
    final int rowsPerPage = 20;
    final int pages =
        transactions.isEmpty ? 1 : (transactions.length / rowsPerPage).ceil();

    for (int pageIndex = 0; pageIndex < pages; pageIndex++) {
      final isFirstPage = pageIndex == 0;
      final isLastPage = pageIndex == pages - 1;

      final pageTransactions = transactions.sublist(
        pageIndex * rowsPerPage,
        ((pageIndex + 1) * rowsPerPage > transactions.length
            ? transactions.length
            : (pageIndex + 1) * rowsPerPage),
      );

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(20, 20, 20, 20),
          build: (ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ── HEADER SECTION (first page only) ──────────────────
                if (isFirstPage) ...[
                  // Outer red border container
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: pdfRed, width: 1.2),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        // Company name section
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          child: pw.Column(
                            children: [
                              pw.Text(
                                '|| Under Kalwan Jurisdiction ||',
                                style: pw.TextStyle(
                                  font: fontMedium,
                                  fontSize: 8.5,
                                  color: pdfRed,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                d.businessDetails.name,
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 22,
                                  color: pdfRed,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                d.businessDetails.address,
                                style: pw.TextStyle(
                                  font: fontMedium,
                                  fontSize: 8,
                                  color: pdfRed,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                              if (d.businessDetails.gstNumber.isNotEmpty ||
                                  d.businessDetails.panNumber.isNotEmpty)
                                pw.Text(
                                  'GST: ${d.businessDetails.gstNumber}${d.businessDetails.panNumber.isNotEmpty ? ' | PAN: ${d.businessDetails.panNumber}' : ''}',
                                  style: pw.TextStyle(
                                    font: fontRegular,
                                    fontSize: 7,
                                    color: pdfGrey,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'BUYER LEDGER',
                                style: pw.TextStyle(
                                  font: fontMedium,
                                  fontSize: 8.5,
                                  color: pdfGrey,
                                  letterSpacing: 1.5,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        // Phone / Email separator row
                        pw.Container(
                          decoration: pw.BoxDecoration(
                            border: pw.Border(
                              top: pw.BorderSide(color: pdfRed, width: 0.8),
                              bottom: pw.BorderSide(color: pdfRed, width: 0.8),
                            ),
                          ),
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Row(
                                children: [
                                  pw.Text(
                                    'M: ',
                                    style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 7.5,
                                        color: pdfRed),
                                  ),
                                  pw.Text(
                                    d.businessDetails.phone,
                                    style: pw.TextStyle(
                                        font: fontRegular,
                                        fontSize: 7.5,
                                        color: pdfBlack),
                                  ),
                                ],
                              ),
                              pw.Row(
                                children: [
                                  pw.Text(
                                    'E: ',
                                    style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 7.5,
                                        color: pdfRed),
                                  ),
                                  pw.Text(
                                    d.businessDetails.email,
                                    style: pw.TextStyle(
                                        font: fontRegular,
                                        fontSize: 7.5,
                                        color: pdfBlack),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Buyer Name + Date row
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          child: pw.Row(
                            children: [
                              pw.Expanded(
                                child: pw.Row(
                                  children: [
                                    pw.Text(
                                      'Buyer Name: ',
                                      style: pw.TextStyle(
                                          font: fontBold,
                                          fontSize: 9,
                                          color: pdfRed),
                                    ),
                                    pw.Text(
                                      d.buyer.name,
                                      style: pw.TextStyle(
                                          font: fontMedium,
                                          fontSize: 9,
                                          color: pdfBlack),
                                    ),
                                  ],
                                ),
                              ),
                              pw.Row(
                                children: [
                                  pw.Text(
                                    'Date: ',
                                    style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 9,
                                        color: pdfRed),
                                  ),
                                  pw.Text(
                                    _fmtFull.format(DateTime.now()),
                                    style: pw.TextStyle(
                                        font: fontMedium,
                                        fontSize: 9,
                                        color: pdfBlack),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Separator
                        pw.Container(
                            height: 0.5,
                            color: pdfBorderGrey),

                        // Mobile + Email row
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          child: pw.Row(
                            children: [
                              pw.Expanded(
                                child: pw.Row(
                                  children: [
                                    pw.Text(
                                      'Mobile: ',
                                      style: pw.TextStyle(
                                          font: fontBold,
                                          fontSize: 9,
                                          color: pdfRed),
                                    ),
                                    pw.Text(
                                      d.buyer.mobile,
                                      style: pw.TextStyle(
                                          font: fontRegular,
                                          fontSize: 9,
                                          color: pdfBlack),
                                    ),
                                  ],
                                ),
                              ),
                              pw.Row(
                                children: [
                                  pw.Text(
                                    'Email: ',
                                    style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 9,
                                        color: pdfRed),
                                  ),
                                  pw.Text(
                                    d.buyer.email.isNotEmpty
                                        ? d.buyer.email
                                        : 'N/A',
                                    style: pw.TextStyle(
                                        font: fontRegular,
                                        fontSize: 9,
                                        color: pdfBlack),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Separator
                        pw.Container(
                            height: 0.5,
                            color: pdfBorderGrey),

                        // Address row
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          child: pw.Row(
                            children: [
                              pw.Text(
                                'Address: ',
                                style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 9,
                                    color: pdfRed),
                              ),
                              pw.Text(
                                _buyerAddress(d.buyer),
                                style: pw.TextStyle(
                                    font: fontRegular,
                                    fontSize: 9,
                                    color: pdfBlack),
                              ),
                            ],
                          ),
                        ),

                        // Separator
                        pw.Container(
                            height: 0.5,
                            color: pdfRed),

                        // Summary boxes — white bg, red border
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Row(
                            children: [
                              _pdfSummaryBox(
                                'Total Payments (Debit)',
                                _fmtAmt(d.summary.totalDebit),
                                pdfRed, pdfWhite,
                                fontBold, fontRegular,
                              ),
                              pw.SizedBox(width: 8),
                              _pdfSummaryBox(
                                'Total Purchases (Credit)',
                                _fmtAmt(d.summary.totalCredit),
                                pdfRed, pdfWhite,
                                fontBold, fontRegular,
                              ),
                              pw.SizedBox(width: 8),
                              _pdfSummaryBox(
                                'Balance',
                                d.summary.closingBalance == 0
                                    ? '${_fmtAmt(d.summary.closingBalance)} (To Pay)'
                                    : '${_fmtAmt(d.summary.closingBalance)}${d.summary.closingBalance < 0 ? ' CR' : ' DR'}',
                                pdfRed, pdfWhite,
                                fontBold, fontRegular,
                              ),
                            ],
                          ),
                        ),

                        // Note
                        pw.Container(
                          color: pdfLightGrey,
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          child: pw.Text(
                            'Note: CR = Buyer owes (To Pay), DR = Buyer paid (Payment Received)',
                            style: pw.TextStyle(
                                font: fontItalic,
                                fontSize: 7,
                                color: pdfGrey),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                ],

                // ── TRANSACTION TABLE ──────────────────────────────────
                pw.Table(
                  border: pw.TableBorder.all(
                      color: pdfBorderGrey, width: 0.5),
                  columnWidths: const {
                    0: pw.FixedColumnWidth(26),   // Sr
                    1: pw.FixedColumnWidth(58),   // Date
                    2: pw.FlexColumnWidth(),       // Particulars
                    3: pw.FixedColumnWidth(62),   // Debit
                    4: pw.FixedColumnWidth(62),   // Credit
                    5: pw.FixedColumnWidth(70),   // Balance
                  },
                  children: [
                    // Header — red bg, white text
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: pdfRed),
                      children: [
                        _th('Sr.', fontBold, pdfWhite),
                        _th('Date', fontBold, pdfWhite),
                        _th('Particulars', fontBold, pdfWhite),
                        _th('Debit (₹)', fontBold, pdfWhite,
                            align: pw.TextAlign.right),
                        _th('Credit (₹)', fontBold, pdfWhite,
                            align: pw.TextAlign.right),
                        _th('Balance (₹)', fontBold, pdfWhite,
                            align: pw.TextAlign.right),
                      ],
                    ),

                    // Data rows — all white bg (no alternate colouring)
                    ...pageTransactions.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final srNo = pageIndex * rowsPerPage + idx + 1;
                      final tx = entry.value;
                      final bal = tx.runningBalance;
                      final balStr = bal == 0
                          ? '₹0 DR'
                          : '${_fmtAmt(bal)} ${bal < 0 ? 'CR' : 'DR'}';

                      return pw.TableRow(
                        decoration:
                            pw.BoxDecoration(color: pdfWhite),
                        children: [
                          _td('$srNo', fontRegular, pdfBlack),
                          _td(_fmt.format(tx.entryDate),
                              fontRegular, pdfBlack),
                          _td(tx.description, fontRegular, pdfBlack),
                          _td(
                            tx.debit > 0 ? _fmtAmt(tx.debit) : '-',
                            fontRegular, pdfBlack,
                            align: pw.TextAlign.right,
                          ),
                          _td(
                            tx.credit > 0 ? _fmtAmt(tx.credit) : '-',
                            fontRegular, pdfBlack,
                            align: pw.TextAlign.right,
                          ),
                          _td(
                            balStr,
                            fontMedium,
                            pdfBlack,
                            align: pw.TextAlign.right,
                          ),
                        ],
                      );
                    }),

                    // Empty state row
                    if (transactions.isEmpty)
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: pdfWhite),
                        children: List.generate(6, (ci) {
                          return _td(
                            ci == 2 ? 'No transactions found' : '',
                            fontRegular, pdfGrey,
                          );
                        }),
                      ),
                  ],
                ),

                // ── FOOTER (last page only) ────────────────────────────
                if (isLastPage) ...[
                  pw.SizedBox(height: 6),

                  // Balance in words
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                          color: pdfBorderGrey, width: 0.5),
                    ),
                    child: pw.Text(
                      'Balance Amount in Words: ${_amountInWords(d.summary.closingBalance.abs())}',
                      style: pw.TextStyle(
                          font: fontMedium,
                          fontSize: 8,
                          color: pdfBlack),
                    ),
                  ),

                  pw.SizedBox(height: 6),

                  // Thank you + Balance row
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                          color: pdfBorderGrey, width: 0.5),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            child: pw.Text(
                              'Thank You!',
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 11,
                                  color: pdfRed),
                            ),
                          ),
                        ),
                        pw.Container(
                          width: 0.5,
                          height: 34,
                          color: pdfRed,
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          child: pw.Row(
                            children: [
                              pw.Text(
                                'Balance: ',
                                style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 9,
                                    color: pdfBlack),
                              ),
                              pw.Text(
                                d.summary.closingBalance == 0
                                    ? '₹0 (To Pay)'
                                    : '${_fmtAmt(d.summary.closingBalance)}${d.summary.closingBalance < 0 ? ' CR' : ' DR'}',
                                style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 9,
                                    color: pdfRed),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 30),

                  // Signature row — dotted lines
                  pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '- ' * 20,
                            style: pw.TextStyle(
                                font: fontRegular,
                                fontSize: 7,
                                color: pdfGrey),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            "Buyer's Signature",
                            style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 9,
                                color: pdfRed),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            '- ' * 20,
                            style: pw.TextStyle(
                                font: fontRegular,
                                fontSize: 7,
                                color: pdfGrey),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            d.businessDetails.name,
                            style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 9,
                                color: pdfRed),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],

                // Page number
                pw.Spacer(),
                pw.Text(
                  'Page ${pageIndex + 1} of $pages',
                  style: pw.TextStyle(
                      font: fontRegular, fontSize: 7, color: pdfGrey),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            );
          },
        ),
      );
    }

    return doc.save();
  }

  // ─── PDF Helper: summary box ──────────────────────────────────────────────
  pw.Widget _pdfSummaryBox(
    String title,
    String value,
    PdfColor borderColor,
    PdfColor bgColor,
    pw.Font bold,
    pw.Font regular,
  ) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: pw.BoxDecoration(
            color: bgColor,
            border: pw.Border.all(color: borderColor, width: 0.8),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                title,
                style:
                    pw.TextStyle(font: regular, fontSize: 7, color: borderColor),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                value,
                style: pw.TextStyle(
                    font: bold, fontSize: 12, color: borderColor),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      );

  // ─── PDF Helper: table header cell ───────────────────────────────────────
  pw.Widget _th(
    String text,
    pw.Font font,
    PdfColor color, {
    pw.TextAlign align = pw.TextAlign.left,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: pw.Text(
          text,
          style: pw.TextStyle(font: font, fontSize: 8, color: color),
          textAlign: align,
        ),
      );

  // ─── PDF Helper: table data cell ─────────────────────────────────────────
  pw.Widget _td(
    String text,
    pw.Font font,
    PdfColor color, {
    pw.TextAlign align = pw.TextAlign.left,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: pw.Text(
          text,
          style: pw.TextStyle(font: font, fontSize: 7.5, color: color),
          textAlign: align,
        ),
      );

  String _buyerAddress(BuyerInfo b) {
    final parts = [b.address, b.city, b.state]
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'N/A' : parts.join(', ');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Download PDF to device storage
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _downloadPdf() async {
    if (_data == null) return;
    setState(() => _exporting = true);
    try {
      final pdfBytes = await _buildPdf();

      if (Platform.isAndroid) {
        // Android 13+: use MediaStore via getExternalStorageDirectory
        // Android <13: request WRITE_EXTERNAL_STORAGE
        final androidInfo = await _getAndroidSdkVersion();
        if (androidInfo < 33) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            _snack('Storage permission denied', isError: true);
            return;
          }
        }

        Directory? dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }

        final fileName =
            'Buyer_Ledger_${widget.buyerName.replaceAll(' ', '_')}_'
            '${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
        final file = File('${dir!.path}/$fileName');
        await file.writeAsBytes(pdfBytes);

        _snack('Saved to Downloads: $fileName');
      } else {
        // iOS — save to app Documents
        final dir = await getApplicationDocumentsDirectory();
        final fileName =
            'Buyer_Ledger_${widget.buyerName.replaceAll(' ', '_')}_'
            '${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(pdfBytes);
        _snack('Saved: $fileName');
      }
    } catch (e) {
      debugPrint('PDF download error: $e');
      _snack('Error saving PDF: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<int> _getAndroidSdkVersion() async {
    try {
      // Simple check — SDK 33 = Android 13
      if (Platform.isAndroid) {
        final result = await Process.run('getprop', ['ro.build.version.sdk']);
        return int.tryParse(result.stdout.toString().trim()) ?? 30;
      }
    } catch (_) {}
    return 30;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Print
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _printLedger() async {
    if (_data == null) return;
    setState(() => _exporting = true);
    try {
      final pdfBytes = await _buildPdf();
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'Buyer Ledger - ${widget.buyerName}',
      );
    } catch (e) {
      debugPrint('Print error: $e');
      _snack('Print error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Show PDF preview (share sheet with save option)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _previewAndSavePdf() async {
    if (_data == null) return;
    setState(() => _exporting = true);
    try {
      final pdfBytes = await _buildPdf();
      // Printing.sharePdf opens the OS share sheet which includes Save to Files / Downloads
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
            'Buyer_Ledger_${widget.buyerName.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Build UI
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.buyerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              widget.buyerMobile,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        actions: [
          if (_exporting)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            )
          else ...[
            // Share/Save button — opens OS share sheet
            IconButton(
              tooltip: 'Share / Save PDF',
              icon: const Icon(Icons.share_rounded,
                  color: Colors.white, size: 22),
              onPressed:
                  (_loading || _data == null) ? null : _previewAndSavePdf,
            ),
            // Direct download to Downloads folder
            IconButton(
              tooltip: 'Download PDF',
              icon: const Icon(Icons.download_rounded,
                  color: Colors.white, size: 22),
              onPressed: (_loading || _data == null) ? null : _downloadPdf,
            ),
            // Print
            IconButton(
              tooltip: 'Print',
              icon: const Icon(Icons.print_rounded,
                  color: Colors.white, size: 22),
              onPressed: (_loading || _data == null) ? null : _printLedger,
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _kRed))
          : _data == null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: _kRed),
            const SizedBox(height: 12),
            const Text(
              'Failed to load ledger',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadLedger,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: _kRed),
            ),
          ],
        ),
      );

  Widget _buildContent() {
    final d = _data!;
    final txs = d.transactions;
    final bal = d.summary.closingBalance;

     print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🎨 RENDERING UI:');
  print('   - Buyer: ${d.buyer.name}');
  print('   - Business: ${d.businessDetails.name}');
  print('   - Total Debit: ${d.summary.totalDebit}');
  print('   - Total Credit: ${d.summary.totalCredit}');
  print('   - Closing Balance: ${d.summary.closingBalance}');
  print('   - Transactions Count: ${txs.length}');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Total item count:
    // 0 = buyer info card
    // 1 = summary cards
    // 2 = note
    // 3 = table header
    // 4..3+txs.length = transaction rows (or 1 empty row)
    // last = footer
    final int txCount = txs.isEmpty ? 1 : txs.length;
    final int totalItems = 4 + txCount + (_isLoadingMore ? 1 : 0) + 1;

    return RefreshIndicator(
      color: _kRed,
      onRefresh: () => _loadLedger(reset: true),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: totalItems,
        itemBuilder: (_, i) {
          if (i == 0) return _buildBuyerInfoCard(d);
          if (i == 1) return _buildSummaryCards(d);
          if (i == 2) return _buildNote();
          if (i == 3) return _buildTableHeader();

          // Transaction rows
          if (i >= 4 && i < 4 + txCount) {
            if (txs.isEmpty) return _buildEmptyTx();
            final idx = i - 4;
            return _buildTxRow(txs[idx], idx + 1, isEven: idx % 2 == 0);
          }

          // Loading more spinner
          if (_isLoadingMore && i == 4 + txCount) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child: CircularProgressIndicator(
                      color: _kRed, strokeWidth: 2)),
            );
          }

          // Footer
          return _buildFooter(bal, d);
        },
      ),
    );
  }

  // ── Buyer Info Card ────────────────────────────────────────────────────────
  Widget _buildBuyerInfoCard(BuyerLedgerData d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kRed.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
              color: _kRed.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Business name header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: const BoxDecoration(
              color: _kRedLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Text(
                  d.businessDetails.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kRed,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                if (d.businessDetails.address.isNotEmpty)
                  Text(
                    d.businessDetails.address,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _kRed,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: _kRed.withOpacity(0.3)),
          // Buyer details grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _infoRow('Buyer', d.buyer.name),
                _infoRow('Mobile', d.buyer.mobile),
                if (d.buyer.email.isNotEmpty)
                  _infoRow('Email', d.buyer.email),
                if (_buyerAddress(d.buyer) != 'N/A')
                  _infoRow('Address', _buyerAddress(d.buyer)),
                if (d.buyer.gstNumber.isNotEmpty)
                  _infoRow('GST', d.buyer.gstNumber),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              child: Text(
                '$label:',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kRed,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      );


  // ── Summary Cards ──────────────────────────────────────────────────────────
  Widget _buildSummaryCards(BuyerLedgerData d) {
    final bal = d.summary.closingBalance;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _summaryCard(
            'Total Payments\n(Debit)',
            _fmtAmt(d.summary.totalDebit),
            _kRed,
          ),
          const SizedBox(width: 8),
          _summaryCard(
            'Total Purchases\n(Credit)',
            _fmtAmt(d.summary.totalCredit),
            _kRed,
          ),
          const SizedBox(width: 8),
          _summaryCard(
            'Balance',
            bal == 0
                ? '${_fmtAmt(bal)} (To Pay)'
                : '${_fmtAmt(bal)}${bal < 0 ? ' CR' : ' DR'}',
            _kRed,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontFamily: 'Poppins',
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Note banner ─────────────────────────────────────────────────────────────
  Widget _buildNote() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: const Text(
        'Note: CR = Buyer owes (To Pay)   •   DR = Buyer paid (Payment Received)',
        style: TextStyle(
          fontSize: 10.5,
          color: Colors.grey,
          fontFamily: 'Poppins',
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── Table Header ────────────────────────────────────────────────────────────
  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: const BoxDecoration(
        color: _kRed,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          _hCell('Sr.', flex: 1),
          _hCell('Date', flex: 3),
          _hCell('Particulars', flex: 6),
          _hCell('Debit', flex: 3, align: TextAlign.right),
          _hCell('Credit', flex: 3, align: TextAlign.right),
          _hCell('Balance', flex: 4, align: TextAlign.right),
        ],
      ),
    );
  }

  Widget _hCell(String text,
      {int flex = 1, TextAlign align = TextAlign.left}) =>
      Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
          child: Text(
            text,
            textAlign: align,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      );

  // ── Transaction Row ──────────────────────────────────────────────────────
  Widget _buildTxRow(BuyerLedgerTransaction tx, int srNo,
      {bool isEven = true}) {
    final bal = tx.runningBalance;
    final balStr =
        bal == 0 ? '₹0 DR' : '${_fmtAmt(bal)} ${bal < 0 ? 'CR' : 'DR'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _kBorder, width: 0.6),
          left: BorderSide(color: _kBorder, width: 0.6),
          right: BorderSide(color: _kBorder, width: 0.6),
        ),
      ),
      child: Row(
        children: [
          _dCell('$srNo', flex: 1),
          _dCell(DateFormat('dd/MM/yy').format(tx.entryDate), flex: 3),
          _dCell(tx.description, flex: 6),
          _dCell(
            tx.debit > 0 ? _fmtAmt(tx.debit) : '-',
            flex: 3,
            align: TextAlign.right,
          ),
          _dCell(
            tx.credit > 0 ? _fmtAmt(tx.credit) : '-',
            flex: 3,
            align: TextAlign.right,
          ),
          _dCell(
            balStr,
            flex: 4,
            align: TextAlign.right,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _dCell(String text,
      {int flex = 1,
      TextAlign align = TextAlign.left,
      bool bold = false}) =>
      Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          child: Text(
            text,
            textAlign: align,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );

  // ── Empty Transactions ────────────────────────────────────────────────────
  Widget _buildEmptyTx() => Container(
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _kBorder),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: const Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 44, color: _kRedMid),
            SizedBox(height: 8),
            Text(
              'No transactions found',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
                fontSize: 13,
              ),
            ),
          ],
        ),
      );

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter(double bal, BuyerLedgerData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Balance in words
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kBorder),
          ),
          child: Text(
            'Balance Amount in Words: ${_amountInWords(bal.abs())}',
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Thank you + Balance
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kBorder),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: const Text(
                      'Thank You!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kRed,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                VerticalDivider(width: 1, color: _kRed),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Text(
                        'Balance: ',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        bal == 0
                            ? '₹0 (To Pay)'
                            : '${_fmtAmt(bal)}${bal < 0 ? ' CR' : ' DR'}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kRed,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Action buttons row
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                Icons.share_rounded,
                'Share / Save',
                _exporting ? null : _previewAndSavePdf,
                outline: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionBtn(
                Icons.download_rounded,
                'Download',
                _exporting ? null : _downloadPdf,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionBtn(
                Icons.print_rounded,
                'Print',
                _exporting ? null : _printLedger,
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Signature row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '- - - - - - - - - - - - - - -',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Buyer's Signature",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kRed,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '- - - - - - - - - - - - - - -',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  d.businessDetails.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kRed,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback? onTap,
      {bool outline = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: outline ? Colors.white : _kRed,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kRed),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: outline ? _kRed : Colors.white, size: 15),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: outline ? _kRed : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
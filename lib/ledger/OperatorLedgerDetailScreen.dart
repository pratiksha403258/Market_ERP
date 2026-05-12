// operator_ledger_detail_screen.dart
import 'package:agr_market/core/constants/colors.dart';
import 'package:agr_market/services/constant_service.dart';
import 'package:agr_market/services/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';
import '../models/ledger_models.dart';

class OperatorLedgerDetailScreen extends StatefulWidget {
  final String operatorId;
  final String operatorName;
  final String operatorEmail;
  final String operatorPhone;

  const OperatorLedgerDetailScreen({
    super.key,
    required this.operatorId,
    required this.operatorName,
    required this.operatorEmail,
    required this.operatorPhone,
  });

  @override
  State<OperatorLedgerDetailScreen> createState() => _OperatorLedgerDetailScreenState();
}

class _OperatorLedgerDetailScreenState extends State<OperatorLedgerDetailScreen> {
  SingleOperatorLedgerData? _ledgerData;
  bool _loading = true;
  bool _exporting = false;
  String? _error;

  int _page = 1;
  int _totalPages = 1;
  bool _loadingMore = false;

  DateTime? _startDate;
  DateTime? _endDate;

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetchLedger(reset: true);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _page < _totalPages) {
      _fetchMore();
    }
  }
Future<void> _fetchLedger({bool reset = false}) async {
  if (reset) {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _ledgerData = null;
    });
  }

  try {
    final params = <String, dynamic>{
      'limit': 50,
      'page': _page,
    };
    if (_startDate != null) {
      params['startDate'] = DateFormat('yyyy-MM-dd').format(_startDate!);
    }
    if (_endDate != null) {
      params['endDate'] = DateFormat('yyyy-MM-dd').format(_endDate!);
    }

    final url = ApiRoutes.operatorLedger(widget.operatorId);
    debugPrint('🔍 Fetching operator ledger from: $url');
    debugPrint('📦 Params: $params');
    debugPrint('👤 Operator ID: ${widget.operatorId}');

    final response = await DioClient.instance.dio.get(
      url,
      queryParameters: params,
    );

    debugPrint('✅ Response status: ${response.statusCode}');
    debugPrint('📄 Response data type: ${response.runtimeType}');
    debugPrint('📄 Response data: ${response.data}');

    final responseData = response.data;
    
    // Check if responseData is null
    if (responseData == null) {
      throw Exception('Response data is null');
    }
    
    // Check if responseData is a Map
    if (responseData is! Map<String, dynamic>) {
      throw Exception('Response data is not a Map: ${responseData.runtimeType}');
    }
    
    debugPrint('📊 Response keys: ${responseData.keys}');
    
    // Check if success field exists
    if (!responseData.containsKey('success')) {
      debugPrint('⚠️ No "success" field in response');
    }
    
    if (responseData['success'] != true) {
      throw Exception('API returned success=false: ${responseData['message'] ?? 'Unknown error'}');
    }
    
    // Check if data field exists
    if (!responseData.containsKey('data')) {
      throw Exception('No "data" field in response');
    }
    
    final dataJson = responseData['data'];
    debugPrint('📊 Data JSON type: ${dataJson.runtimeType}');
    debugPrint('📊 Data JSON keys: ${dataJson is Map ? dataJson.keys : 'Not a map'}');
    
    final data = SingleOperatorLedgerData.fromJson(dataJson);
    
    debugPrint('📊 Transactions count: ${data.transactions.length}');
    debugPrint('📄 Total pages: ${data.pagination.pages}');
    debugPrint('📊 Summary - Total Sales: ${data.summary.totalSales}');
    debugPrint('📊 Summary - Net Profit: ${data.summary.netProfit}');

    setState(() {
      if (reset) {
        _ledgerData = data;
      } else {
        _ledgerData = SingleOperatorLedgerData(
          operator: data.operator,
          period: data.period,
          summary: data.summary,
          transactions: [...?_ledgerData?.transactions, ...data.transactions],
          pagination: data.pagination,
        );
      }
      _totalPages = data.pagination.pages;
      _loading = false;
    });
  } on DioException catch (e) {
    debugPrint('❌ DioException: ${e.type}');
    debugPrint('❌ Dio message: ${e.message}');
    debugPrint('❌ Dio response: ${e.response?.data}');
    debugPrint('❌ Dio status code: ${e.response?.statusCode}');
    setState(() {
      _error = 'Network error: ${e.message}';
      _loading = false;
    });
  } catch (e, stacktrace) {
    debugPrint('❌ OperatorLedger error: $e');
    debugPrint('❌ Stacktrace: $stacktrace');
    setState(() {
      _error = 'Failed to load ledger: $e';
      _loading = false;
    });
  }
}
  Future<void> _fetchMore() async {
    if (_loadingMore || _page >= _totalPages) return;
    setState(() {
      _loadingMore = true;
      _page++;
    });
    await _fetchLedger();
    setState(() => _loadingMore = false);
  }

  Future<void> _pickDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
      _fetchLedger(reset: true);
    }
  }

  Future<void> _exportPdf() async {
    if (_ledgerData == null || _ledgerData!.transactions.isEmpty) {
      _snack('No transactions to export', isError: true);
      return;
    }

    setState(() => _exporting = true);

    try {
      final langProv = Provider.of<LanguageProvider>(context, listen: false);
      final isMarathi = langProv.locale.languageCode == 'mr';

      final pw.Font regularFont;
      final pw.Font boldFont;

      if (isMarathi) {
        regularFont = await PdfGoogleFonts.notoSansDevanagariRegular();
        boldFont = await PdfGoogleFonts.notoSansDevanagariBold();
      } else {
        regularFont = await PdfGoogleFonts.notoSansRegular();
        boldFont = await PdfGoogleFonts.notoSansBold();
      }

      pw.TextStyle s({double sz = 9, bool bold = false, PdfColor color = PdfColors.black}) =>
          pw.TextStyle(font: bold ? boldFont : regularFont, fontSize: sz, color: color);

      final pdf = pw.Document();
      final now = DateTime.now();
      final periodLabel = _startDate != null && _endDate != null
          ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
          : 'All Transactions';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 48),
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Farm ERP Market System', style: s(sz: 10, bold: true)),
                  pw.Text('OPERATOR LEDGER', style: s(sz: 15, bold: true)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 5),
              pw.Text('Operator Name: ${widget.operatorName}', style: s(sz: 9)),
              if (widget.operatorEmail.isNotEmpty)
                pw.Text('Email: ${widget.operatorEmail}', style: s(sz: 8)),
              if (widget.operatorPhone.isNotEmpty)
                pw.Text('Mobile: ${widget.operatorPhone}', style: s(sz: 8)),
              pw.Text('Period: $periodLabel', style: s(sz: 8)),
              pw.SizedBox(height: 8),
            ],
          ),
          footer: (ctx) => pw.Column(children: [
            pw.Divider(),
            pw.SizedBox(height: 3),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Farm ERP Market System', style: s(sz: 7)),
                pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: s(sz: 7)),
              ],
            ),
          ]),
          build: (ctx) => [
            _buildPdfTable(langProv, s),
            pw.SizedBox(height: 10),
            _buildPdfSummary(langProv, s),
            pw.SizedBox(height: 28),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('For Farm ERP Market System', style: s(sz: 8)),
                    pw.SizedBox(height: 28),
                    pw.Text('Authorised Signatory', style: s(sz: 8)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Operator_Ledger_${widget.operatorName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(now)}.pdf',
      );
    } catch (e) {
      _snack('Failed to generate PDF: $e', isError: true);
    } finally {
      setState(() => _exporting = false);
    }
  }

  pw.Widget _buildPdfTable(LanguageProvider langProv, pw.TextStyle Function({double sz, bool bold, PdfColor color}) s) {
    final transactions = _ledgerData?.transactions ?? [];
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _pdfCell('Date', bold: true),
            _pdfCell('Description', bold: true),
            _pdfCell('Reference No', bold: true),
            _pdfCell('Credit (Rs.)', align: pw.TextAlign.right, bold: true),
            _pdfCell('Debit (Rs.)', align: pw.TextAlign.right, bold: true),
            _pdfCell('Balance (Rs.)', align: pw.TextAlign.right, bold: true),
          ],
        ),
        ...transactions.map((tx) {
          final date = DateFormat('dd/MM/yy').format(tx.entryDate);
          final isCredit = tx.credit > 0;
          final amount = isCredit ? tx.credit : tx.debit;
          
          return pw.TableRow(
            children: [
              _pdfCell(date),
              _pdfCell(tx.description),
              _pdfCell(tx.referenceNumber ?? '-'),
              _pdfCell(isCredit ? amount.toStringAsFixed(0) : '-', align: pw.TextAlign.right),
              _pdfCell(!isCredit ? amount.toStringAsFixed(0) : '-', align: pw.TextAlign.right),
              _pdfCell(tx.runningBalance.toStringAsFixed(0), align: pw.TextAlign.right),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _pdfCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  pw.Widget _buildPdfSummary(LanguageProvider langProv, pw.TextStyle Function({double sz, bool bold, PdfColor color}) s) {
    final netProfit = _ledgerData?.summary.netProfit ?? 0;
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
      columnWidths: {0: pw.FlexColumnWidth(5), 1: pw.FixedColumnWidth(80)},
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total Sales', style: s(sz: 8, bold: true))),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_ledgerData?.summary.totalSales.toStringAsFixed(0) ?? '0', textAlign: pw.TextAlign.right, style: s(sz: 8, bold: true))),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total Expenses', style: s(sz: 8, bold: true))),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_ledgerData?.summary.totalExpenses.toStringAsFixed(0) ?? '0', textAlign: pw.TextAlign.right, style: s(sz: 8, bold: true))),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Net Profit', style: s(sz: 8, bold: true))),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(netProfit.toStringAsFixed(0), textAlign: pw.TextAlign.right, style: s(sz: 8, bold: true, color: netProfit >= 0 ? PdfColors.green : PdfColors.red))),
          ],
        ),
      ],
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _fmtShort(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProv, _) {
        final isMarathi = langProv.locale.languageCode == 'mr';
        final netProfit = _ledgerData?.summary.netProfit ?? 0;
        
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              Container(
                decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.operatorName,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.operatorEmail.isNotEmpty)
                                    Text(
                                      widget.operatorEmail,
                                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                                    ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _pickDateRange,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.date_range_rounded, color: Colors.white, size: 15),
                                    const SizedBox(width: 5),
                                    Text(
                                      _startDate != null ? (isMarathi ? 'फिल्टर' : 'Filtered') : (isMarathi ? 'दिनांक' : 'Date'),
                                      style: const TextStyle(fontSize: 11, color: Colors.white),
                                    ),
                                    if (_startDate != null) ...[
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _startDate = null;
                                            _endDate = null;
                                          });
                                          _fetchLedger(reset: true);
                                        },
                                        child: const Icon(Icons.close_rounded, color: Colors.white70, size: 13),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _exporting ? null : _exportPdf,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: _exporting
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                                    : const Row(
                                        children: [
                                          Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 15),
                                          SizedBox(width: 5),
                                          Text('PDF', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (!_loading && _ledgerData != null)
                          Row(
                            children: [
                              _chip('Total Sales', '₹${_fmtShort(_ledgerData!.summary.totalSales)}', AppColors.successSurface, isMarathi),
                              const SizedBox(width: 8),
                              _chip('Total Expenses', '₹${_fmtShort(_ledgerData!.summary.totalExpenses)}', AppColors.warningSurface, isMarathi),
                              const SizedBox(width: 8),
                              _chip(
                                'Net Profit',
                                '${netProfit >= 0 ? '+' : '-'}₹${_fmtShort(netProfit.abs())}',
                                netProfit >= 0 ? AppColors.successSurface : Colors.red.shade100,
                                isMarathi,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _error != null
                        ? _buildError(langProv)
                        : _ledgerData?.transactions.isEmpty ?? true
                            ? _buildEmpty(isMarathi)
                            : RefreshIndicator(
                                onRefresh: () => _fetchLedger(reset: true),
                                color: AppColors.primary,
                                child: ListView.builder(
                                  controller: _scrollCtrl,
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                                  itemCount: (_ledgerData?.transactions.length ?? 0) + (_loadingMore ? 1 : 0),
                                  itemBuilder: (_, i) {
                                    if (i == (_ledgerData?.transactions.length ?? 0)) {
                                      return const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                                      );
                                    }
                                    final tx = _ledgerData!.transactions[i];
                                    return _buildTransactionTile(tx, langProv, isMarathi);
                                  },
                                ),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String label, String value, Color bgColor, bool isMarathi) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );

  Widget _buildTransactionTile(LedgerTransaction tx, LanguageProvider langProv, bool isMarathi) {
    final isCredit = tx.credit > 0;
    final amount = isCredit ? tx.credit : tx.debit;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isCredit ? AppColors.successSurface : AppColors.warningSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? AppColors.success : AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(DateFormat('dd/MM/yyyy').format(tx.entryDate), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    if (tx.referenceNumber != null && tx.referenceNumber!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(tx.referenceNumber!, style: const TextStyle(fontSize: 10, color: AppColors.textHint), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}₹${amount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isCredit ? AppColors.success : AppColors.error),
              ),
              const SizedBox(height: 3),
              Text('Balance: ₹${tx.runningBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError(LanguageProvider langProv) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_error ?? 'Something went wrong', style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _fetchLedger(reset: true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text(langProv.t('retry'), style: const TextStyle(fontFamily: 'Poppins')),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmpty(bool isMarathi) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(isMarathi ? 'कोणतेही खाते नोंदी सापडल्या नाहीत' : 'No ledger entries found', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text(isMarathi ? 'व्यवहार येथे दिसतील' : 'Transactions will appear here', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
          ],
        ),
      );
}
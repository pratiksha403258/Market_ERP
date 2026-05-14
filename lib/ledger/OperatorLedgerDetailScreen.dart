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

      if (responseData == null) {
        throw Exception('Response data is null');
      }

      if (responseData is! Map<String, dynamic>) {
        throw Exception('Response data is not a Map: ${responseData.runtimeType}');
      }

      debugPrint('📊 Response keys: ${responseData.keys}');

      if (!responseData.containsKey('success')) {
        debugPrint('⚠️ No "success" field in response');
      }

      if (responseData['success'] != true) {
        throw Exception('API returned success=false: ${responseData['message'] ?? 'Unknown error'}');
      }

      if (!responseData.containsKey('data')) {
        throw Exception('No "data" field in response');
      }

      final dataJson = responseData['data'];

      if (dataJson == null) {
        throw Exception('Data is null from API');
      }

      if (dataJson is! Map<String, dynamic>) {
        throw Exception('Data is not a valid object: ${dataJson.runtimeType}');
      }

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

  // ── Language popup before PDF export ─────────────────────────
  Future<void> _showLanguageBeforeExport() async {
    final langProv = Provider.of<LanguageProvider>(context, listen: false);
    String? tempSelected = langProv.locale.languageCode;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              const Icon(Icons.language,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                langProv.t('select_language_title'),
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 16),
              ),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  langProv.t('select_language_message'),
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ...LanguageProvider.supportedLanguages.map((lang) {
                  final isSelected = tempSelected == lang.code;
                  return GestureDetector(
                    onTap: () =>
                        setDialog(() => tempSelected = lang.code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primarySurface
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Text(lang.flag,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lang.nativeName,
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary)),
                              Text(lang.name,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary, size: 20),
                      ]),
                    ),
                  );
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(langProv.t('cancel'),
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.textSecondary)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (tempSelected != null) {
                    await langProv.setLanguage(tempSelected!);
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                icon: const Icon(Icons.picture_as_pdf_rounded,
                    size: 16, color: Colors.white),
                label: const Text('Generate PDF',
                    style: TextStyle(
                        color: Colors.white, fontFamily: 'Poppins')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && mounted) {
      await _exportPdf();
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

      pw.TextStyle s({
        num sz = 9,
        bool bold = false,
        PdfColor color = PdfColors.black,
      }) {
        return pw.TextStyle(
          font: bold ? boldFont : regularFont,
          fontSize: sz.toDouble(),
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        );
      }

      final pdf = pw.Document();

      final summary = _ledgerData!.summary;
      final txs = _ledgerData!.transactions;

      final totalSales = (summary.totalSales as num?)?.toDouble() ?? 0.0;
      final totalPurchases = (summary.totalPurchases as num?)?.toDouble() ?? 0.0;
      final totalExpenses = (summary.totalExpenses as num?)?.toDouble() ?? 0.0;
      final netProfit = (summary.netProfit as num?)?.toDouble() ?? 0.0;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(12.0),
          build: (context) => [
            /// HEADER
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.red, width: 1.5),
              ),
              padding: const pw.EdgeInsets.all(10.0),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      '|| Under Kalwan Jurisdiction ||',
                      style: s(sz: 9, bold: true, color: PdfColors.red),
                    ),
                  ),
                  pw.SizedBox(height: 4.0),
                  pw.Center(
                    child: pw.Text(
                      langProv.t('company_name'),
                      style: s(sz: 18, bold: true, color: PdfColors.red),
                    ),
                  ),
                  pw.Center(
                    child: pw.Text(
                      langProv.t('company_address'),
                      style: s(sz: 10),
                    ),
                  ),
                  pw.Center(
                    child: pw.Text('OPERATOR LEDGER', style: s(sz: 10, bold: true)),
                  ),
                  pw.SizedBox(height: 6.0),
                  pw.Divider(color: PdfColors.red),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Prop. Rakesh Hire M: 9021699991', style: s(sz: 8, color: PdfColors.red)),
                      pw.Text('Prop. Swajit Hire M: 9565459991', style: s(sz: 8, color: PdfColors.red)),
                    ],
                  ),
                  pw.Divider(color: PdfColors.red),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${langProv.t('email')}: ${widget.operatorEmail}', style: s(sz: 10)),
                      pw.Text('${langProv.t('date_label')}: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: s(sz: 10)),
                    ],
                  ),
                  pw.Divider(color: PdfColors.red),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${langProv.t('operator_name')}: ${widget.operatorName}', style: s(sz: 10)),
                      pw.Text('${langProv.t('status')}: Active', style: s(sz: 10)),
                    ],
                  ),
                  pw.Divider(color: PdfColors.red),
                  pw.Text('${langProv.t('mobile')}: ${widget.operatorPhone}', style: s(sz: 10)),
                  pw.SizedBox(height: 8.0),

                  /// SUMMARY BOXES
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _box(langProv.t('total_sales'), totalSales, PdfColors.green, s),
                      _box(langProv.t('total_purchases'), totalPurchases, PdfColors.red, s),
                      _box(langProv.t('total_expenses'), totalExpenses, PdfColors.orange, s),
                      _box(langProv.t('net_profit'), netProfit, netProfit >= 0 ? PdfColors.green : PdfColors.red, s),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10.0),

            /// TABLE
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.red),
              columnWidths: {
                0: const pw.FixedColumnWidth(20),
                1: const pw.FixedColumnWidth(60),
                2: const pw.FlexColumnWidth(),
                3: const pw.FixedColumnWidth(70),
                4: const pw.FixedColumnWidth(60),
                5: const pw.FixedColumnWidth(60),
                6: const pw.FixedColumnWidth(70),
              },
              children: [
                /// HEADER
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _cell('Sr', s, true),
                    _cell(langProv.t('ledger_col_date'), s, true),
                    _cell(langProv.t('ledger_col_desc'), s, true),
                    _cell('Ref', s, true),
                    _cell(langProv.t('ledger_col_debit'), s, true),
                    _cell(langProv.t('ledger_col_credit'), s, true),
                    _cell(langProv.t('ledger_col_balance'), s, true),
                  ],
                ),

                /// ROWS
                ...txs.asMap().entries.map((e) {
                  final i = e.key + 1;
                  final tx = e.value;

                  final debit = (tx.debit as num?)?.toDouble() ?? 0.0;
                  final credit = (tx.credit as num?)?.toDouble() ?? 0.0;
                  final balance = (tx.runningBalance as num?)?.toDouble() ?? 0.0;

                  String cleanDescription = tx.description.replaceAll('₹', 'Rs').replaceAll('\u20B9', 'Rs');

                  return pw.TableRow(
                    children: [
                      _cell('$i', s, false),
                      _cell(DateFormat('dd/MM/yyyy').format(tx.entryDate), s, false),
                      _cell(cleanDescription, s, false),
                      _cell(tx.referenceNumber ?? '-', s, false),
                      _cell(debit > 0 ? 'Rs ${debit.toStringAsFixed(0)}' : '-', s, false),
                      _cell(credit > 0 ? 'Rs ${credit.toStringAsFixed(0)}' : '-', s, false),
                      _cell('Rs ${balance.toStringAsFixed(0)}', s, false),
                    ],
                  );
                }).toList(),
              ],
            ),

            pw.SizedBox(height: 12.0),

            /// FOOTER
            pw.Container(
              padding: const pw.EdgeInsets.all(8.0),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.red),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Net Profit in Words: ${_numberToWords(netProfit.toInt())} Rupees Only',
                    style: s(sz: 9),
                  ),
                  pw.SizedBox(height: 6.0),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(langProv.t('thank_you'), style: s(sz: 10, bold: true)),
                      pw.Text(
                        '${langProv.t('net_profit')}: Rs ${netProfit.toStringAsFixed(0)}',
                        style: s(sz: 11, bold: true),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 25.0),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Operator Signature', style: s(sz: 10)),
                      pw.Text(langProv.t('for_company'), style: s(sz: 10, bold: true)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Operator_Ledger.pdf',
      );
    } catch (e) {
      _snack('PDF Error: $e', isError: true);
    } finally {
      setState(() => _exporting = false);
    }
  }

  // Helper method to convert number to words
  String _numberToWords(int number) {
    if (number == 0) return 'Zero';

    final units = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'];
    final teens = ['', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    final tens = ['', 'Ten', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

    String convert(int n) {
      if (n < 10) return units[n];
      if (n < 20) return teens[n - 10];
      if (n < 100) return '${tens[n ~/ 10]} ${units[n % 10]}'.trim();
      if (n < 1000) return '${units[n ~/ 100]} Hundred ${convert(n % 100)}'.trim();
      if (n < 100000) return '${convert(n ~/ 1000)} Thousand ${convert(n % 1000)}'.trim();
      if (n < 10000000) return '${convert(n ~/ 100000)} Lakh ${convert(n % 100000)}'.trim();
      return '${convert(n ~/ 10000000)} Crore ${convert(n % 10000000)}'.trim();
    }

    return convert(number);
  }

  pw.Widget _box(String title, dynamic value, PdfColor color, Function s) {
    final double safeValue = (value as num?)?.toDouble() ?? 0.0;

    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(6.0),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.red),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: s(sz: 8)),
          pw.SizedBox(height: 3.0),
          pw.Text(
            'Rs ${safeValue.toStringAsFixed(0)}',
            style: s(sz: 10, bold: true, color: color),
          ),
        ],
      ),
    );
  }

  pw.Widget _cell(String text, Function s, bool bold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4.0),
      child: pw.Text(text, style: s(sz: 8, bold: bold)),
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
                              onTap: _exporting ? null : _showLanguageBeforeExport,
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
                              _chip(langProv.t('total_sales'), 'Rs ${_fmtShort(_ledgerData!.summary.totalSales)}', AppColors.successSurface, isMarathi),
                              const SizedBox(width: 8),
                              _chip(langProv.t('total_expenses'), 'Rs ${_fmtShort(_ledgerData!.summary.totalExpenses)}', AppColors.warningSurface, isMarathi),
                              const SizedBox(width: 8),
                              _chip(
                                langProv.t('net_profit'),
                                '${netProfit >= 0 ? '+' : '-'}Rs ${_fmtShort(netProfit.abs())}',
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

    String cleanDescription = tx.description.replaceAll('₹', 'Rs').replaceAll('\u20B9', 'Rs');

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
                  cleanDescription,
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
                '${isCredit ? '+' : '-'}Rs ${amount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isCredit ? AppColors.success : AppColors.error),
              ),
              const SizedBox(height: 3),
              Text('${langProv.t('balance')}: Rs ${tx.runningBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
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
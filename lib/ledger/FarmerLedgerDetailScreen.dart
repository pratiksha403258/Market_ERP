import 'package:agr_market/core/constants/colors.dart';
import 'package:agr_market/services/constant_service.dart';
import 'package:agr_market/services/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';

class FarmerLedgerDetailScreen extends StatefulWidget {
  final String farmerId;
  final String farmerName;
  final String farmerMobile;

  const FarmerLedgerDetailScreen({
    super.key,
    required this.farmerId,
    required this.farmerName,
    required this.farmerMobile,
  });

  @override
  State<FarmerLedgerDetailScreen> createState() =>
      _FarmerLedgerDetailScreenState();
}

class _FarmerLedgerDetailScreenState extends State<FarmerLedgerDetailScreen> {
  Map<String, dynamic>? _farmerInfo;
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _transactions = [];
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
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
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
        _transactions = [];
      });
    }

    try {
      final params = <String, dynamic>{'page': _page, 'limit': 50};
      if (_startDate != null) {
        params['startDate'] = DateFormat('yyyy-MM-dd').format(_startDate!);
      }
      if (_endDate != null) {
        params['endDate'] = DateFormat('yyyy-MM-dd').format(_endDate!);
      }

      final res = await DioClient.instance.dio.get(
        ApiRoutes.farmerLedger(widget.farmerId),
        queryParameters: params,
      );

      final responseData = res.data as Map<String, dynamic>;
      if (responseData['success'] != true) {
        throw Exception('API returned success=false');
      }

      final data = responseData['data'] as Map<String, dynamic>;
      final farmerMap = data['farmer'] as Map<String, dynamic>? ?? {};
      final summaryMap = data['summary'] as Map<String, dynamic>? ?? {};
      final txList = data['transactions'] as List? ?? [];
      final transactions =
          txList.map((t) => t as Map<String, dynamic>).toList();
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      final totalPages = (pagination['pages'] as num?)?.toInt() ?? 1;

      setState(() {
        _farmerInfo = farmerMap;
        _summary = summaryMap;
        _transactions =
            reset ? transactions : [..._transactions, ...transactions];
        _totalPages = totalPages;
        _loading = false;
      });
    } catch (e) {
      debugPrint('FarmerLedger error: $e');
      setState(() {
        _error = 'Failed to load ledger. Pull down to retry.';
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

  // ── Language popup ─────────────────────────────────────────
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

  // ── PDF Export ─────────────────────────────────────────────
  Future<void> _exportPdf() async {
    if (_transactions.isEmpty) {
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
          color: color,
        );
      }

      final pdf = pw.Document();

      final farmerName = _farmerInfo?['name']?.toString() ?? widget.farmerName;
      final farmerMobile = _farmerInfo?['mobile']?.toString() ?? widget.farmerMobile;

      final totalDebit = (_summary?['totalDebit'] as num?)?.toDouble() ?? 0.0;
      final totalCredit = (_summary?['totalCredit'] as num?)?.toDouble() ?? 0.0;
      final balance = (_summary?['closingBalance'] as num?)?.toDouble() ?? 0.0;

      final now = DateTime.now();
      final dateStr = DateFormat('dd MMM yyyy').format(now);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (context) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.red, width: 1.5),
              ),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  pw.Center(
                    child: pw.Text(
                      '|| Under Kalwan Jurisdiction ||',
                      style: s(sz: 9, bold: true, color: PdfColors.red),
                    ),
                  ),
                  pw.SizedBox(height: 4),
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
                    child: pw.Text(
                      langProv.t('ledger_title').toUpperCase(),
                      style: s(sz: 10, bold: true),
                    ),
                  ),
                  pw.Divider(color: PdfColors.red),

                  /// PROP
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Prop. Rakesh Hire M: 9021699991',
                        style: s(sz: 8, color: PdfColors.red),
                      ),
                      pw.Text(
                        'Prop. Swajit Hire M: 9565459991',
                        style: s(sz: 8, color: PdfColors.red),
                      ),
                    ],
                  ),
                  pw.Divider(color: PdfColors.red),

                  /// FARMER INFO - USING PROVIDER TRANSLATIONS
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${langProv.t('ledger_farmer_name')} $farmerName', style: s(sz: 10)),
                      pw.Text('${langProv.t('ledger_ledger_date')} $dateStr', style: s(sz: 10)),
                    ],
                  ),
                  pw.Divider(color: PdfColors.red),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${langProv.t('mobile')}: $farmerMobile', style: s(sz: 10)),
                      pw.Text('${langProv.t('village')}: -', style: s(sz: 10)),
                    ],
                  ),
                  pw.Divider(color: PdfColors.red),
                  pw.SizedBox(height: 8),

                  /// SUMMARY - USING PROVIDER TRANSLATIONS
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _summaryBox(langProv.t('total_paid'), totalDebit, PdfColors.green, s),
                      _summaryBox(langProv.t('total_purchased'), totalCredit, PdfColors.red, s),
                      _summaryBox(langProv.t('balance'), balance, PdfColors.green, s),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  /// TABLE - USING PROVIDER TRANSLATIONS
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.red),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(20),
                      1: const pw.FixedColumnWidth(55),
                      2: const pw.FlexColumnWidth(),
                      3: const pw.FixedColumnWidth(55),
                      4: const pw.FixedColumnWidth(55),
                      5: const pw.FixedColumnWidth(65),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          _cell('Sr', s, true),
                          _cell(langProv.t('ledger_col_date'), s, true),
                          _cell(langProv.t('ledger_col_desc'), s, true),
                          _cell(langProv.t('ledger_col_debit'), s, true),
                          _cell(langProv.t('ledger_col_credit'), s, true),
                          _cell(langProv.t('ledger_col_balance'), s, true),
                        ],
                      ),
                      ..._transactions.asMap().entries.map((e) {
                        final i = e.key + 1;
                        final tx = e.value;
                        final debit = (tx['debit'] as num?)?.toDouble() ?? 0.0;
                        final credit = (tx['credit'] as num?)?.toDouble() ?? 0.0;
                        final runningBalance = (tx['runningBalance'] as num?)?.toDouble() ?? 0.0;

                        // Clean description
                        String cleanDescription = (tx['description']?.toString() ?? '-')
                            .replaceAll('₹', 'Rs')
                            .replaceAll('\u20B9', 'Rs');

                        return pw.TableRow(
                          children: [
                            _cell('$i', s, false),
                            _cell(_fmtDate(tx['entryDate'] ?? ''), s, false),
                            _cell(cleanDescription, s, false),
                            _cell(debit > 0 ? 'Rs ${_fmt(debit)}' : '-', s, false),
                            _cell(credit > 0 ? 'Rs ${_fmt(credit)}' : '-', s, false),
                            _cell('Rs ${_fmt(runningBalance)}', s, false),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  /// BALANCE WORDS (BOXED)
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.red),
                    ),
                    child: pw.Text(
                      'Balance Amount in Words: ${_numberToWords(balance.toInt())} Rupees Only',
                      style: s(sz: 9),
                    ),
                  ),
                  pw.SizedBox(height: 6),

                  /// FINAL ROW - USING PROVIDER TRANSLATIONS
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.red),
                    ),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(langProv.t('thank_you'), style: s(sz: 10, bold: true)),
                        pw.Text(
                          '${langProv.t('balance')}: Rs ${_fmt(balance)}',
                          style: s(sz: 11, bold: true),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  /// SIGNATURE - USING PROVIDER TRANSLATIONS
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        children: [
                          pw.Container(width: 120, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 4),
                          pw.Text(langProv.t('buyers_signature'), style: s(sz: 9)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Container(width:160, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            langProv.t('for_company'),
                            style: s(sz: 9, bold: true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      final bytes = await pdf.save();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Farmer_Ledger.pdf',
      );
    } catch (e) {
      _snack('PDF Error: $e', isError: true);
    } finally {
      setState(() => _exporting = false);
    }
  }
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
  pw.Widget _summaryBox(String title, double value, PdfColor color, Function s) {
    return pw.Container(
      width: 140,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.red),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: s(sz: 9)),
          pw.SizedBox(height: 4),
          pw.Text(
            '₹${_fmt(value)}',
            style: s(sz: 11, bold: true, color: color),
          ),
        ],
      ),
    );
  }

  pw.Widget _cell(String text, Function s, bool bold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: s(sz: 8, bold: bold),
      ),
    );
  }


  // ── PDF table ──────────────────────────────────────────────
  pw.Widget _pdfTable({
    required List<Map<String, dynamic>> transactions,
    required LanguageProvider langProv,
    required PdfColor borderGrey,
    required PdfColor lightGrey,
    required PdfColor midGrey,
    required pw.TextStyle Function(
            {double sz, bool bold, PdfColor color})
        s,
  }) {
    final colW = {
      0: const pw.FixedColumnWidth(50),
      1: const pw.FlexColumnWidth(3.5),
      2: const pw.FixedColumnWidth(56),
      3: const pw.FixedColumnWidth(56),
      4: const pw.FixedColumnWidth(56),
      5: const pw.FixedColumnWidth(58),
    };

    pw.Widget hc(String t,
            {pw.TextAlign a = pw.TextAlign.left}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(
              horizontal: 4, vertical: 5),
          child: pw.Text(t,
              textAlign: a, style: s(sz: 8, bold: true)),
        );

    pw.Widget dc(String t,
            {pw.TextAlign a = pw.TextAlign.left,
            bool bold = false,
            PdfColor? color}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(
              horizontal: 4, vertical: 4),
          child: pw.Text(t,
              textAlign: a,
              maxLines: 3,
              style: s(
                  sz: 7.5,
                  bold: bold,
                  color: color ?? PdfColors.black)),
        );

    final headerRow = pw.TableRow(
      decoration: pw.BoxDecoration(color: lightGrey),
      children: [
        hc(langProv.t('ledger_col_date')),
        hc(langProv.t('ledger_col_desc')),
        hc(langProv.t('ledger_col_ref')),
        hc(langProv.t('ledger_col_credit'), a: pw.TextAlign.right),
        hc(langProv.t('ledger_col_debit'), a: pw.TextAlign.right),
        hc(langProv.t('ledger_col_balance'), a: pw.TextAlign.right),
      ],
    );

    double sumC = 0, sumD = 0;

    final rows = transactions.asMap().entries.map((e) {
      final i = e.key;
      final tx = e.value;

      final dateStr = tx['entryDate']?.toString() ?? '';
      final date = DateTime.tryParse(dateStr)?.toLocal();
      final dl =
          date != null ? DateFormat('dd/MM/yy').format(date) : '-';

      final desc = tx['description']?.toString() ?? '-';
      final entryType = tx['entryType']?.toString() ?? '';
      final typeKey = _typeKey(entryType);
      final tl = typeKey != null ? langProv.t(typeKey) : '';
      final fullDesc = tl.isNotEmpty ? '$desc\n$tl' : desc;

      final refNo = tx['referenceNumber']?.toString() ??
          tx['receiptNumber']?.toString() ??
          tx['transactionId']?.toString() ??
          '-';

      final debit = (tx['debit'] as num?)?.toDouble() ?? 0;
      final credit = (tx['credit'] as num?)?.toDouble() ?? 0;
      final balance =
          (tx['runningBalance'] as num?)?.toDouble() ?? 0;

      sumC += credit;
      sumD += debit;

      final bg = i.isEven ? PdfColors.white : lightGrey;

      return pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: [
          dc(dl, color: midGrey),
          dc(fullDesc),
          dc(refNo, color: midGrey),
          dc(credit > 0 ? _fmt(credit) : '0',
              a: pw.TextAlign.right),
          dc(debit > 0 ? _fmt(debit) : '0',
              a: pw.TextAlign.right),
          dc(_fmt(balance.abs()),
              a: pw.TextAlign.right, bold: true),
        ],
      );
    }).toList();

    final lastBal = transactions.isNotEmpty
        ? (transactions.last['runningBalance'] as num?)
                ?.toDouble() ??
            0
        : 0.0;

    final totalRow = pw.TableRow(
      decoration: pw.BoxDecoration(color: lightGrey),
      children: [
        dc(langProv.t('ledger_total'), bold: true),
        dc(''),
        dc(''),
        dc(_fmt(sumC), a: pw.TextAlign.right, bold: true),
        dc(_fmt(sumD), a: pw.TextAlign.right, bold: true),
        dc(_fmt(lastBal.abs()),
            a: pw.TextAlign.right, bold: true),
      ],
    );

    return pw.Table(
      border: pw.TableBorder.all(color: borderGrey, width: 0.5),
      columnWidths: colW,
      children: [headerRow, ...rows, totalRow],
    );
  }

  // ── PDF summary rows ───────────────────────────────────────
  pw.Widget _pdfSummary({
    required double totalCredit,
    required double closingBalance,
    required LanguageProvider langProv,
    required PdfColor borderGrey,
    required PdfColor lightGrey,
    required pw.TextStyle Function(
            {double sz, bool bold, PdfColor color})
        s,
  }) {
    pw.TableRow row(String lbl, String val) => pw.TableRow(
          decoration: pw.BoxDecoration(color: lightGrey),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6, vertical: 5),
              child: pw.Text(lbl, style: s(sz: 8, bold: true)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6, vertical: 5),
              child: pw.Text(val,
                  textAlign: pw.TextAlign.right,
                  style: s(sz: 8, bold: true)),
            ),
          ],
        );

    return pw.Table(
      border: pw.TableBorder.all(color: borderGrey, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(5),
        1: pw.FixedColumnWidth(80),
      },
      children: [
        row(langProv.t('ledger_on_account'), _fmt(totalCredit)),
        row(langProv.t('ledger_final_balance'), _fmt(closingBalance.abs())),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────
  String _fmt(double v) =>
      NumberFormat('#,##,##0', 'en_IN').format(v);

  String? _typeKey(String type) {
    switch (type.toLowerCase()) {
      case 'purchase':
        return 'type_purchase';
      case 'payment':
        return 'type_payment';
      case 'advance':
        return 'type_advance';
      case 'expense_reversal':
        return 'type_reversal';
      default:
        return null;
    }
  }

  pw.Widget _pdfCell(String text, Function s, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: s(
          sz: 8,
          bold: isHeader,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style:
              const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      backgroundColor:
          isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _fmtDate(String raw) {
    if (raw.isEmpty) return '-';
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return raw;
    return DateFormat('dd/MM/yyyy').format(d);
  }

  String _fmtShort(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  // ── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProv, _) {
        final isMarathi = langProv.locale.languageCode == 'mr';
        final closingBalance =
            (_summary?['closingBalance'] as num?)?.toDouble() ?? 0;
        final totalDebit =
            (_summary?['totalDebit'] as num?)?.toDouble() ?? 0;
        final totalCredit =
            (_summary?['totalCredit'] as num?)?.toDouble() ?? 0;

      
      TextStyle _textStyle({
     double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = AppColors.textPrimary,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    
    fontFamily: isMarathi ? 'NotoSansDevanagari' : 'Poppins',
  );
}

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(children: [
            Container(
              decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 14, 16, 20),
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
                          child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(widget.farmerName,
                                style: _textStyle(
                                    size: 17,
                                    weight: FontWeight.w700,
                                    color: Colors.white),
                                overflow: TextOverflow.ellipsis),
                            if (widget.farmerMobile.isNotEmpty)
                              Text(widget.farmerMobile,
                                  style: _textStyle(
                                      size: 12,
                                      color: Colors.white70)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white
                                    .withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.date_range_rounded,
                                color: Colors.white, size: 15),
                            const SizedBox(width: 5),
                            Text(
                              _startDate != null
                                  ? (isMarathi ? 'फिल्टर' : 'Filtered')
                                  : (isMarathi ? 'दिनांक' : 'Date'),
                              style: _textStyle(
                                  size: 11, color: Colors.white),
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
                                child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white70,
                                    size: 13),
                              ),
                            ],
                          ]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _exporting
                            ? null
                            : _showLanguageBeforeExport,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: _exporting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(
                                          color:
                                              AppColors.primary,
                                          strokeWidth: 2))
                              : const Row(children: [
                                  Icon(
                                      Icons
                                          .picture_as_pdf_rounded,
                                      color: AppColors.primary,
                                      size: 15),
                                  SizedBox(width: 5),
                                  Text('PDF',
                                      style: TextStyle(
                                          color:
                                              AppColors.primary,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w700,
                                          fontFamily:
                                              'Poppins')),
                                ]),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    if (!_loading && _summary != null)
                      Row(children: [
                        _chip(
                          langProv.t('total_paid'),
                          '₹${_fmtShort(totalDebit)}',
                          Colors.redAccent.shade100,
                          isMarathi,
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          langProv.t('total_purchased'),
                          '₹${_fmtShort(totalCredit)}',
                          Colors.greenAccent.shade100,
                          isMarathi,
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          closingBalance > 0
                              ? langProv.t('due')
                              : langProv.t('cleared'),
                          '₹${_fmtShort(closingBalance.abs())}',
                          closingBalance > 0
                              ? Colors.orangeAccent.shade100
                              : Colors.greenAccent.shade100,
                          isMarathi,
                        ),
                      ]),
                  ]),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _error != null
                      ? _buildError(langProv)
                      : _transactions.isEmpty
                          ? _buildEmpty(isMarathi)
                          : RefreshIndicator(
                              onRefresh: () =>
                                  _fetchLedger(reset: true),
                              color: AppColors.primary,
                              child: ListView.builder(
                                controller: _scrollCtrl,
                                padding: const EdgeInsets
                                    .fromLTRB(16, 12, 16, 24),
                                itemCount: _transactions.length +
                                    (_loadingMore ? 1 : 0),
                                itemBuilder: (_, i) {
                                  if (i == _transactions.length) {
                                    return const Padding(
                                      padding:
                                          EdgeInsets.all(16),
                                      child: Center(
                                          child:
                                              CircularProgressIndicator(
                                                  color: AppColors
                                                      .primary,
                                                  strokeWidth:
                                                      2)),
                                    );
                                  }
                                  return _buildTile(
                                      _transactions[i],
                                      langProv,
                                      isMarathi);
                                },
                              ),
                            ),
            ),
          ]),
        );
      },
    );
  }

  Widget _chip(String label, String value, Color color, bool isMarathi) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontFamily: isMarathi ? 'NotoSansDevanagari' : 'Poppins',)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: isMarathi ? 'NotoSansDevanagari' : 'Poppins'),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  Widget _buildTile(Map<String, dynamic> tx, LanguageProvider langProv, bool isMarathi) {
    final dateStr = tx['entryDate']?.toString() ?? '';
    final description = tx['description']?.toString() ?? '-';
    final entryType = tx['entryType']?.toString() ?? '';
    final debit = (tx['debit'] as num?)?.toDouble() ?? 0;
    final credit = (tx['credit'] as num?)?.toDouble() ?? 0;
    final runningBalance =
        (tx['runningBalance'] as num?)?.toDouble() ?? 0;
    final refNo = tx['referenceNumber']?.toString() ??
        tx['receiptNumber']?.toString() ??
        '';
    final isCredit = credit > 0;
    final amount = isCredit ? credit : debit;

    final typeKey = _typeKey(entryType);
    final typeLabel = typeKey != null ? langProv.t(typeKey) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isCredit
                ? AppColors.successSurface
                : AppColors.warningSurface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCredit
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color:
                isCredit ? AppColors.success : AppColors.warning,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(description,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: isMarathi ? 'NotoSansDevanagari' : 'Poppins'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Row(children: [
              if (typeLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                        fontSize: 9,
                        color: AppColors.primaryDark,
                       fontFamily: isMarathi ? 'NotoSansDevanagari' : 'Poppins',
                        fontWeight: FontWeight.w600),
                  ),
                ),
              if (typeLabel.isNotEmpty) const SizedBox(width: 8),
              Text(_fmtDate(dateStr),
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                     fontFamily: isMarathi ? 'NotoSansDevanagari' : 'Poppins')),
              if (refNo.isNotEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(refNo,
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                          fontFamily: isMarathi ? 'NotoSansDevanagari' : 'Poppins'),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ]),
          ]),
        ),
        Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
          Text(
            '${isCredit ? '+' : '-'}Rs.${_fmt(amount)}',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isCredit
                    ? AppColors.success
                    : AppColors.error,
                fontFamily: isMarathi ? 'NotoSansDevanagari' : 'Poppins'),
          ),
          const SizedBox(height: 3),
          Text(
            '${langProv.t('balance')}: Rs.${_fmt(runningBalance.abs())}',
            style: TextStyle(
                fontSize: 10,
                color: AppColors.textHint,
                fontFamily: isMarathi ? 'NotoSansDevanagari' : 'Poppins'),
          ),
        ]),
      ]),
    );
  }

  Widget _buildError(LanguageProvider langProv) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_error ?? 'Something went wrong',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins'),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchLedger(reset: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(langProv.t('retry'),
                  style:
                      const TextStyle(fontFamily: 'Poppins')),
            ),
          ]),
        ),
      );

  Widget _buildEmpty(bool isMarathi) => Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          const Icon(Icons.receipt_long_outlined,
              size: 56, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            isMarathi
                ? 'कोणतेही खाते नोंदी सापडल्या नाहीत'
                : 'No ledger entries found',
            style: TextStyle(
                color: AppColors.textSecondary,
               fontFamily: isMarathi ? 'NotoSansDevanagari' : 'Poppins'),
          ),
          const SizedBox(height: 6),
          Text(
            isMarathi
                ? 'खरेदी किंवा पेमेंटनंतर व्यवहार येथे दिसतील'
                : 'Transactions will appear here after purchases or payments',
            style: TextStyle(
                color: AppColors.textHint,
                fontFamily: isMarathi ? 'NotoSansDevanagari' : 'Poppins',
                fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ]),
      );
}
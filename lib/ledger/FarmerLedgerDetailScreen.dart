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
      final langProv =
          Provider.of<LanguageProvider>(context, listen: false);
      final isMarathi = langProv.locale.languageCode == 'mr';

      // ── Load correct fonts ─────────────────────────────────
      final pw.Font regularFont;
      final pw.Font boldFont;

      if (isMarathi) {
        regularFont =
            await PdfGoogleFonts.notoSansDevanagariRegular();
        boldFont = await PdfGoogleFonts.notoSansDevanagariBold();
      } else {
        regularFont = await PdfGoogleFonts.notoSansRegular();
        boldFont = await PdfGoogleFonts.notoSansBold();
      }

      // ── Shorthand text style builder ───────────────────────
      pw.TextStyle s({
        double sz = 9,
        bool bold = false,
        PdfColor color = PdfColors.black,
      }) =>
          pw.TextStyle(
            font: bold ? boldFont : regularFont,
            fontSize: sz,
            color: color,
          );

      final pdf = pw.Document();

      // ── Farmer data ────────────────────────────────────────
      final farmerName =
          _farmerInfo?['name']?.toString() ?? widget.farmerName;
      final farmerMobile =
          _farmerInfo?['mobile']?.toString() ?? widget.farmerMobile;
      final farmerAddress =
          _farmerInfo?['address']?.toString() ?? '';
      final totalCredit =
          (_summary?['totalCredit'] as num?)?.toDouble() ?? 0;
      final closingBalance =
          (_summary?['closingBalance'] as num?)?.toDouble() ?? 0;

      final now = DateTime.now();
      final ledgerDate = DateFormat('dd/MM/yyyy').format(now);

      // ── All labels from LanguageProvider ───────────────────
      String periodLabel = langProv.t('ledger_all_tx');
      if (_startDate != null && _endDate != null) {
        periodLabel =
            '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}';
      }

      // ── Colors ─────────────────────────────────────────────
      const black = PdfColors.black;
      const lightGrey = PdfColor.fromInt(0xFFF2F2F2);
      const borderGrey = PdfColor.fromInt(0xFFBBBBBB);
      const midGrey = PdfColor.fromInt(0xFF555555);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 48),

          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(langProv.t('ledger_company'),
                          style: s(sz: 10, bold: true)),
                      pw.SizedBox(height: 2),
                      pw.Text(langProv.t('ledger_subtitle'),
                          style: s(sz: 8, color: midGrey)),
                    ],
                  ),
                  pw.Text(
                    langProv.t('ledger_company').toUpperCase(),
                    style: s(sz: 15, bold: true),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: black, thickness: 1),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(children: [
                    pw.Text('${langProv.t('ledger_farmer_name')} ',
                        style: s(sz: 9, bold: true)),
                    pw.Text(farmerName, style: s(sz: 9)),
                  ]),
                  pw.Row(children: [
                    pw.Text('${langProv.t('ledger_ledger_date')} ',
                        style: s(sz: 9, bold: true)),
                    pw.Text(ledgerDate, style: s(sz: 9)),
                  ]),
                ],
              ),
              if (farmerMobile.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text('${langProv.t('ledger_mobile')} $farmerMobile',
                    style: s(sz: 8, color: midGrey)),
              ],
              if (farmerAddress.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(farmerAddress,
                    style: s(sz: 8, color: midGrey)),
              ],
              pw.SizedBox(height: 2),
              pw.Text('${langProv.t('ledger_period')} $periodLabel',
                  style: s(sz: 8, color: midGrey)),
              pw.SizedBox(height: 8),
            ],
          ),

          footer: (ctx) => pw.Column(children: [
            pw.Divider(color: borderGrey, thickness: 0.5),
            pw.SizedBox(height: 3),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(langProv.t('ledger_company'),
                    style: s(sz: 7, color: midGrey)),
                pw.Text(
                    '${langProv.t('ledger_page')} ${ctx.pageNumber} ${langProv.t('ledger_of')} ${ctx.pagesCount}',
                    style: s(sz: 7, color: midGrey)),
              ],
            ),
          ]),

          build: (ctx) => [
            pw.Text(langProv.t('ledger_trans_history'),
                style: s(sz: 10, bold: true)),
            pw.SizedBox(height: 5),

            _pdfTable(
              transactions: _transactions,
              langProv: langProv,
              borderGrey: borderGrey,
              lightGrey: lightGrey,
              midGrey: midGrey,
              s: s,
            ),

            pw.SizedBox(height: 10),

            _pdfSummary(
              totalCredit: totalCredit,
              closingBalance: closingBalance,
              langProv: langProv,
              borderGrey: borderGrey,
              lightGrey: lightGrey,
              s: s,
            ),

            pw.SizedBox(height: 28),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                        '${langProv.t('ledger_for_label')} ${langProv.t('ledger_company')}',
                        style: s(sz: 8)),
                    pw.SizedBox(height: 28),
                    pw.Text(langProv.t('ledger_authorised'),
                        style: s(sz: 8)),
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
        name:
            'Ledger_${farmerName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(now)}.pdf',
      );
    } catch (e) {
      debugPrint('PDF error: $e');
      _snack('Failed to generate PDF: $e', isError: true);
    } finally {
      setState(() => _exporting = false);
    }
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
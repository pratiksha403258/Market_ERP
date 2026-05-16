
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
  // ── API data ───────────────────────────────────────────────
  Map<String, dynamic>? _farmerInfo;
  Map<String, dynamic>? _businessDetails; // NEW: from API businessDetails
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

  // ── Computed totals from transactions (API summary can be 0) ──
  double get _computedTotalCredit {
    // From farmer's perspective: when the business DEBITS farmer = farmer is owed money (Credit in ledger)
    // API field: debit > 0 means farmer sold goods (farmer gets credit)
    return _transactions.fold(0.0, (sum, tx) {
      final d = (tx['debit'] as num?)?.toDouble() ?? 0.0;
      return sum + d;
    });
  }

  double get _computedTotalDebit {
    // From farmer's perspective: when business pays farmer = farmer's balance reduces (Debit in ledger)
    // API field: credit > 0 means payment was made to farmer
    return _transactions.fold(0.0, (sum, tx) {
      final c = (tx['credit'] as num?)?.toDouble() ?? 0.0;
      return sum + c;
    });
  }

  double get _computedBalance {
    // Use API closingBalance if non-zero, otherwise compute
    final apiBalance = (_summary?['closingBalance'] as num?)?.toDouble() ?? 0.0;
    if (apiBalance != 0) return apiBalance;
    return _computedTotalCredit - _computedTotalDebit;
  }

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

  // ── Fetch ──────────────────────────────────────────────────
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

      // ── Parse businessDetails (NEW) ────────────────────────
      final businessMap = data['businessDetails'] as Map<String, dynamic>? ?? {};

      // ── Parse farmer ──────────────────────────────────────
      final farmerMap = data['farmer'] as Map<String, dynamic>? ?? {};

      // ── Parse summary ─────────────────────────────────────
      final summaryMap = data['summary'] as Map<String, dynamic>? ?? {};

      // ── Parse transactions ────────────────────────────────
      final txList = data['transactions'] as List? ?? [];
      final transactions = txList.map((t) => t as Map<String, dynamic>).toList();

      // ── Parse pagination ──────────────────────────────────
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      final totalPages = (pagination['pages'] as num?)?.toInt() ?? 1;

      setState(() {
        _businessDetails = businessMap;
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              const Icon(Icons.language, color: AppColors.primary, size: 22),
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
                    onTap: () => setDialog(() => tempSelected = lang.code),
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
                    style:
                        TextStyle(color: Colors.white, fontFamily: 'Poppins')),
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

      // ── Farmer info ────────────────────────────────────────
      final farmerName =
          _farmerInfo?['name']?.toString() ?? widget.farmerName;
      final farmerMobile =
          _farmerInfo?['mobile']?.toString() ?? widget.farmerMobile;
      final farmerAddress = [
        _farmerInfo?['address']?.toString(),
        _farmerInfo?['village']?.toString(),
        _farmerInfo?['city']?.toString(),
        _farmerInfo?['state']?.toString(),
      ].where((s) => s != null && s.isNotEmpty).join(', ');

      // ── Business info from API ────────────────────────────
      final bizName = _businessDetails?['name']?.toString() ??
          langProv.t('company_name');
      final bizAddress = _businessDetails?['address']?.toString() ??
          langProv.t('company_address');
      final bizPhone =
          _businessDetails?['phone']?.toString() ?? '';
      final bizEmail =
          _businessDetails?['email']?.toString() ?? '';
      final bizGst =
          _businessDetails?['gstNumber']?.toString() ?? '';
      final bizPan =
          _businessDetails?['panNumber']?.toString() ?? '';

      // ── Totals: use computed values from transactions ──────
      // IMPORTANT: API summary.totalDebit/totalCredit can be 0 (bug on server).
      // We compute from transactions directly.
      //
      // From the FARMER's perspective (matching the sample PDF):
      //   Credit column  = farmer supplied goods  → API tx.debit > 0
      //   Debit column   = payment made to farmer → API tx.credit > 0
      final totalCreditForPdf = _computedTotalCredit;  // what farmer is owed
      final totalDebitForPdf  = _computedTotalDebit;   // what was paid to farmer
      final balance           = _computedBalance;

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
                  // ── HEADER ─────────────────────────────────
                  pw.Center(
                    child: pw.Text(
                      '|| Under Kalwan Jurisdiction ||',
                      style: s(sz: 9, bold: true, color: PdfColors.red),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Center(
                    child: pw.Text(
                      bizName,
                      style: s(sz: 18, bold: true, color: PdfColors.red),
                    ),
                  ),
                  pw.Center(
                    child: pw.Text(
                      bizAddress,
                      style: s(sz: 10),
                    ),
                  ),
                  // GST & PAN line
                  if (bizGst.isNotEmpty || bizPan.isNotEmpty)
                    pw.Center(
                      child: pw.Text(
                        [
                          if (bizGst.isNotEmpty) 'GST: $bizGst',
                          if (bizPan.isNotEmpty) 'PAN: $bizPan',
                        ].join(' | '),
                        style: s(sz: 8, color: PdfColors.grey600),
                      ),
                    ),
                  pw.SizedBox(height: 4),
                  pw.Center(
                    child: pw.Text(
                      langProv.t('ledger_title').toUpperCase(),
                      style: s(sz: 10, bold: true, color: PdfColors.grey700),
                    ),
                  ),
                  pw.Divider(color: PdfColors.red),

                  // ── CONTACT ROW ────────────────────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      if (bizPhone.isNotEmpty)
                        pw.Text(
                          '\u260E $bizPhone',
                          style: s(sz: 8, color: PdfColors.red),
                        ),
                      if (bizEmail.isNotEmpty)
                        pw.Text(
                          '\u2709 $bizEmail',
                          style: s(sz: 8, color: PdfColors.red),
                        ),
                    ],
                  ),
                  pw.Divider(color: PdfColors.red),

                  // ── FARMER NAME + DATE ─────────────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(children: [
                          pw.TextSpan(
                            text: '${langProv.t('ledger_farmer_name')} ',
                            style: s(sz: 10, bold: true, color: PdfColors.red),
                          ),
                          pw.TextSpan(
                            text: farmerName,
                            style: s(sz: 10, bold: true),
                          ),
                        ]),
                      ),
                      pw.RichText(
                        text: pw.TextSpan(children: [
                          pw.TextSpan(
                            text: '${langProv.t('ledger_ledger_date')} ',
                            style: s(sz: 10, bold: true, color: PdfColors.red),
                          ),
                          pw.TextSpan(
                            text: dateStr,
                            style: s(sz: 10, bold: true),
                          ),
                        ]),
                      ),
                    ],
                  ),
                  pw.Divider(color: PdfColors.red),

                  // ── MOBILE + ADDRESS ──────────────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(children: [
                          pw.TextSpan(
                            text: '${langProv.t('mobile')}: ',
                            style: s(sz: 10, bold: true, color: PdfColors.red),
                          ),
                          pw.TextSpan(
                            text: farmerMobile,
                            style: s(sz: 10),
                          ),
                        ]),
                      ),
                      pw.RichText(
                        text: pw.TextSpan(children: [
                          pw.TextSpan(
                            text: '${langProv.t('address')}: ',
                            style: s(sz: 10, bold: true, color: PdfColors.red),
                          ),
                          pw.TextSpan(
                            text: farmerAddress.isNotEmpty ? farmerAddress : 'N/A',
                            style: s(sz: 10),
                          ),
                        ]),
                      ),
                    ],
                  ),
                  pw.Divider(color: PdfColors.red),
                  pw.SizedBox(height: 8),

                  // ── SUMMARY BOXES ──────────────────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      _summaryBox(
                        langProv.t('total_debit'),
                        totalDebitForPdf,
                        PdfColors.red,
                        s,
                      ),
                      _summaryBox(
                        langProv.t('total_credit'),
                        totalCreditForPdf,
                        PdfColors.red,
                        s,
                      ),
                      _summaryBox(
                        '${langProv.t('balance')} (${balance >= 0 ? langProv.t('to_pay') : langProv.t('overpaid')})',
                        balance.abs(),
                        PdfColors.green,
                        s,
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  // ── TRANSACTION TABLE ──────────────────────
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.red),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(22),   // Sr.
                      1: const pw.FixedColumnWidth(58),   // Date
                      2: const pw.FlexColumnWidth(),      // Particulars
                      3: const pw.FixedColumnWidth(62),   // Debit
                      4: const pw.FixedColumnWidth(62),   // Credit
                      5: const pw.FixedColumnWidth(72),   // Balance
                    },
                    children: [
                      // Header row
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _cell('Sr.', s, true,
                              align: pw.TextAlign.center),
                          _cell(langProv.t('ledger_col_date'), s, true,
                              align: pw.TextAlign.center),
                          _cell(langProv.t('ledger_col_desc'), s, true,
                              align: pw.TextAlign.center),
                          _cell(
                              '${langProv.t('ledger_col_debit')} (Rs)',
                              s,
                              true,
                              align: pw.TextAlign.center),
                          _cell(
                              '${langProv.t('ledger_col_credit')} (Rs)',
                              s,
                              true,
                              align: pw.TextAlign.center),
                          _cell(
                              '${langProv.t('ledger_col_balance')} (Rs)',
                              s,
                              true,
                              align: pw.TextAlign.center),
                        ],
                      ),

                      // Data rows
                      ..._transactions.asMap().entries.map((e) {
                        final i = e.key + 1;
                        final tx = e.value;

                        // API perspective:
                        //   tx['debit'] > 0  → farmer sold goods (farmer is owed money)
                        //                      → show in CREDIT column of ledger
                        //   tx['credit'] > 0 → payment made to farmer
                        //                      → show in DEBIT column of ledger
                        final apiDebit =
                            (tx['debit'] as num?)?.toDouble() ?? 0.0;
                        final apiCredit =
                            (tx['credit'] as num?)?.toDouble() ?? 0.0;

                        // Ledger columns (farmer perspective)
                        final ledgerCredit = apiDebit;  // goods purchased from farmer
                        final ledgerDebit  = apiCredit; // payment sent to farmer

                        final runningBalance =
                            (tx['runningBalance'] as num?)?.toDouble() ?? 0.0;

                        // Clean description (remove rupee symbol for PDF)
                        final cleanDesc =
                            (tx['description']?.toString() ?? '-')
                                .replaceAll('₹', 'Rs')
                                .replaceAll('\u20B9', 'Rs');

                        // Running balance is stored as negative in API when farmer
                        // is in credit (business owes farmer). Display absolute with CR/DR.
                        final balAbs = runningBalance.abs();
                        final balSuffix =
                            runningBalance < 0 ? ' CR' : (runningBalance > 0 ? ' DR' : '');

                        return pw.TableRow(
                          children: [
                            _cell('$i', s, false,
                                align: pw.TextAlign.center),
                            _cell(_fmtDate(tx['entryDate']?.toString() ?? ''),
                                s, false),
                            _cell(cleanDesc, s, false),
                            _cell(
                              ledgerDebit > 0
                                  ? 'Rs ${_fmt(ledgerDebit)}'
                                  : '-',
                              s,
                              false,
                              align: pw.TextAlign.right,
                            ),
                            _cell(
                              ledgerCredit > 0
                                  ? 'Rs ${_fmt(ledgerCredit)}'
                                  : '-',
                              s,
                              false,
                              align: pw.TextAlign.right,
                            ),
                            _cell(
                              'Rs ${_fmt(balAbs)}$balSuffix',
                              s,
                              false,
                              align: pw.TextAlign.right,
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  // ── BALANCE IN WORDS ───────────────────────
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.red),
                    ),
                    child: pw.Text(
                      '${langProv.t('balance_in_words')}: ${_numberToWords(balance.abs().toInt())} Rupees Only',
                      style: s(sz: 9, bold: true),
                    ),
                  ),
                  pw.SizedBox(height: 6),

                  // ── THANK YOU + BALANCE ────────────────────
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.red),
                    ),
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          langProv.t('thank_you'),
                          style: s(sz: 11, bold: true, color: PdfColors.red),
                        ),
                        pw.RichText(
                          text: pw.TextSpan(children: [
                            pw.TextSpan(
                              text: '${langProv.t('balance')}: ',
                              style: s(
                                  sz: 11,
                                  bold: true,
                                  color: PdfColors.red),
                            ),
                            pw.TextSpan(
                              text:
                                  'Rs ${_fmt(balance.abs())} (${balance >= 0 ? langProv.t('to_pay') : langProv.t('overpaid')})',
                              style: s(sz: 11, bold: true),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 24),

                  // ── SIGNATURES ─────────────────────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '--------------------------------',
                            style: s(sz: 9, color: PdfColors.grey600),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            langProv.t('buyers_signature'),
                            style: s(sz: 9, bold: true, color: PdfColors.red),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            '--------------------------------',
                            style: s(sz: 9, color: PdfColors.grey600),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            langProv.t('for_company'),
                            style: s(sz: 9, bold: true, color: PdfColors.red),
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
        name: 'Farmer_Ledger_$farmerName.pdf',
      );
    } catch (e) {
      _snack('PDF Error: $e', isError: true);
      debugPrint('PDF export error: $e');
    } finally {
      setState(() => _exporting = false);
    }
  }

  // ── Number to words ────────────────────────────────────────
  String _numberToWords(int number) {
    if (number == 0) return 'Zero';
    final units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine'
    ];
    final teens = [
      '',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen'
    ];
    final tens = [
      '',
      'Ten',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety'
    ];

    String convert(int n) {
      if (n < 10) return units[n];
      if (n < 20) return teens[n - 10];
      if (n < 100) return '${tens[n ~/ 10]} ${units[n % 10]}'.trim();
      if (n < 1000) return '${units[n ~/ 100]} Hundred ${convert(n % 100)}'.trim();
      if (n < 100000)
        return '${convert(n ~/ 1000)} Thousand ${convert(n % 1000)}'.trim();
      if (n < 10000000)
        return '${convert(n ~/ 100000)} Lakh ${convert(n % 100000)}'.trim();
      return '${convert(n ~/ 10000000)} Crore ${convert(n % 10000000)}'.trim();
    }

    return convert(number);
  }

  // ── PDF helpers ────────────────────────────────────────────
  pw.Widget _summaryBox(
      String title, double value, PdfColor color, Function s) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.red),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(title, style: s(sz: 9, bold: true, color: PdfColors.red)),
          pw.SizedBox(height: 4),
          pw.Text(
            'Rs ${_fmt(value)}',
            style: s(sz: 12, bold: true, color: color),
          ),
        ],
      ),
    );
  }

  pw.Widget _cell(
    String text,
    Function s,
    bool bold, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: s(sz: 8, bold: bold),
        textAlign: align,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────
  String _fmt(double v) => NumberFormat('#,##,##0', 'en_IN').format(v);

  String _fmtShort(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtDate(String raw) {
    if (raw.isEmpty) return '-';
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return raw;
    return DateFormat('dd/MM/yyyy').format(d);
  }

  /// Maps API entryType → translation key.
  /// Handles all known types including the actual API value "debit_transaction".
  String? _typeKey(String type) {
    switch (type.toLowerCase()) {
      case 'purchase':
      case 'debit_transaction': // actual API value for purchase
        return 'type_purchase';
      case 'payment':
      case 'credit_transaction': // actual API value for payment
        return 'type_payment';
      case 'advance':
      case 'advance_given':
        return 'type_advance';
      case 'expense_reversal':
        return 'type_reversal';
      case 'sale':
        return 'type_sale';
      case 'expense':
        return 'type_expense';
      default:
        return null;
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(left: 6, right: 6, bottom: 2),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProv, _) {
        final isMarathi = langProv.locale.languageCode == 'mr';

        // Use computed values (not API summary which can be 0)
        final totalCredit = _computedTotalCredit;
        final totalDebit  = _computedTotalDebit;
        final balance     = _computedBalance;

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
            // ── HEADER ──────────────────────────────────────
            Container(
              decoration:
                  const BoxDecoration(gradient: AppColors.heroGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
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
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                      // Date filter button
                      GestureDetector(
                        onTap: _pickDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.date_range_rounded,
                                color: Colors.white, size: 15),
                            const SizedBox(width: 5),
                            Text(
                              _startDate != null
                                  ? (isMarathi ? 'फिल्टर' : 'Filtered')
                                  : (isMarathi ? 'दिनांक' : 'Date'),
                              style:
                                  _textStyle(size: 11, color: Colors.white),
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
                                child: const Icon(Icons.close_rounded,
                                    color: Colors.white70, size: 13),
                              ),
                            ],
                          ]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // PDF export button
                      GestureDetector(
                        onTap:
                            _exporting ? null : _showLanguageBeforeExport,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _exporting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 2))
                              : const Row(children: [
                                  Icon(Icons.picture_as_pdf_rounded,
                                      color: AppColors.primary, size: 15),
                                  SizedBox(width: 5),
                                  Text('PDF',
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Poppins')),
                                ]),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // Summary chips — use computed totals
                    if (!_loading)
                      Row(children: [
                        _chip(
                          langProv.t('total_debit'),
                          'Rs ${_fmtShort(totalDebit)}',
                          Colors.redAccent.shade100,
                          isMarathi,
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          langProv.t('total_credit'),
                          'Rs ${_fmtShort(totalCredit)}',
                          Colors.greenAccent.shade100,
                          isMarathi,
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          balance > 0
                              ? langProv.t('to_pay')
                              : langProv.t('cleared'),
                          'Rs ${_fmtShort(balance.abs())}',
                          balance > 0
                              ? Colors.orangeAccent.shade100
                              : Colors.greenAccent.shade100,
                          isMarathi,
                        ),
                      ]),
                  ]),
                ),
              ),
            ),

            // ── TRANSACTION LIST ─────────────────────────────
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
                              onRefresh: () => _fetchLedger(reset: true),
                              color: AppColors.primary,
                              child: ListView.builder(
                                controller: _scrollCtrl,
                                padding: const EdgeInsets.fromLTRB(
                                    16, 12, 16, 24),
                                itemCount: _transactions.length +
                                    (_loadingMore ? 1 : 0),
                                itemBuilder: (_, i) {
                                  if (i == _transactions.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                          child: CircularProgressIndicator(
                                              color: AppColors.primary,
                                              strokeWidth: 2)),
                                    );
                                  }
                                  return _buildTile(
                                      _transactions[i], langProv, isMarathi);
                                },
                              ),
                            ),
            ),
          ]),
        );
      },
    );
  }

  // ── CHIP widget ────────────────────────────────────────────
  Widget _chip(
      String label, String value, Color color, bool isMarathi) =>
      Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                        fontFamily: isMarathi
                            ? 'NotoSansDevanagari'
                            : 'Poppins')),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: isMarathi
                            ? 'NotoSansDevanagari'
                            : 'Poppins'),
                    overflow: TextOverflow.ellipsis),
              ]),
        ),
      );

  // ── TRANSACTION TILE ───────────────────────────────────────
  Widget _buildTile(
      Map<String, dynamic> tx, LanguageProvider langProv, bool isMarathi) {
    final dateStr = tx['entryDate']?.toString() ?? '';
    final description = tx['description']?.toString() ?? '-';
    final entryType = tx['entryType']?.toString() ?? '';

    // API debit > 0 = farmer sold goods (credit to farmer = green)
    // API credit > 0 = payment made to farmer (debit from farmer = red)
    final apiDebit  = (tx['debit'] as num?)?.toDouble() ?? 0.0;
    final apiCredit = (tx['credit'] as num?)?.toDouble() ?? 0.0;

    final isFarmerCredit = apiDebit > 0; // farmer is owed money
    final amount = isFarmerCredit ? apiDebit : apiCredit;

    final runningBalance =
        (tx['runningBalance'] as num?)?.toDouble() ?? 0.0;
    final refNo = tx['referenceNumber']?.toString() ??
        tx['receiptNumber']?.toString() ??
        '';

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
        // Icon
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isFarmerCredit
                ? AppColors.successSurface
                : AppColors.warningSurface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isFarmerCredit
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: isFarmerCredit
                ? AppColors.success
                : AppColors.warning,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // Description & meta
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: isMarathi
                            ? 'NotoSansDevanagari'
                            : 'Poppins'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  if (typeLabel.isNotEmpty) ...[
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
                            fontFamily: isMarathi
                                ? 'NotoSansDevanagari'
                                : 'Poppins',
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(_fmtDate(dateStr),
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                          fontFamily: isMarathi
                              ? 'NotoSansDevanagari'
                              : 'Poppins')),
                  if (refNo.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(refNo,
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textHint,
                              fontFamily: isMarathi
                                  ? 'NotoSansDevanagari'
                                  : 'Poppins'),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ]),
              ]),
        ),

        // Amount & balance
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '${isFarmerCredit ? '+' : '-'}Rs.${_fmt(amount)}',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isFarmerCredit
                    ? AppColors.success
                    : AppColors.error,
                fontFamily:
                    isMarathi ? 'NotoSansDevanagari' : 'Poppins'),
          ),
          const SizedBox(height: 3),
          Text(
            '${langProv.t('balance')}: Rs.${_fmt(runningBalance.abs())}${runningBalance < 0 ? ' CR' : ''}',
            style: TextStyle(
                fontSize: 10,
                color: AppColors.textHint,
                fontFamily:
                    isMarathi ? 'NotoSansDevanagari' : 'Poppins'),
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
                    fontFamily: isMarathi
                        ? 'NotoSansDevanagari'
                        : 'Poppins'),
              ),
              const SizedBox(height: 6),
              Text(
                isMarathi
                    ? 'खरेदी किंवा पेमेंटनंतर व्यवहार येथे दिसतील'
                    : 'Transactions will appear here after purchases or payments',
                style: TextStyle(
                    color: AppColors.textHint,
                    fontFamily: isMarathi
                        ? 'NotoSansDevanagari'
                        : 'Poppins',
                    fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ]),
      );
}
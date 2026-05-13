// ─────────────────────────────────────────────────────────────
//  PAYMENT RECEIPT GENERATOR
//  Generates HTML receipt matching "Jai Shivrai Trading Co."
//  receipt design — both English and Marathi.
//
//  Usage:
//    final html = PaymentReceiptGenerator.generate(
//      payment: paymentModel,
//      purchaseSummary: purchaseSummaryData,
//      farmerVillage: 'Sakori',
//      isMarathi: true,
//    );
//    // Then open in WebView or print via url_launcher / printing pkg
// ─────────────────────────────────────────────────────────────

class PaymentReceiptData {
  // Payment fields (from POST /api/payments response or GET /api/payments/{id})
  final String paymentId;
  final double amount;
  final String paymentMode; // cash | upi | bank | cheque
  final String? referenceNumber;
  final String? bankName;
  final String? chequeNumber;
  final String? chequeDate;
  final String? chequeStatus; // pending_clearance | cleared | bounced
  final DateTime paymentDate;
  final String? notes;

  // Purchase summary (from purchase object nested in payment API)
  final String receiptNumber;
  final double finalPayable;
  final double amountDue; // after this payment
  final String purchaseStatus; // paid | partial | pending

  // Farmer details
  final String farmerName;
  final String farmerMobile;
  final String farmerVillage;

  const PaymentReceiptData({
    required this.paymentId,
    required this.amount,
    required this.paymentMode,
    this.referenceNumber,
    this.bankName,
    this.chequeNumber,
    this.chequeDate,
    this.chequeStatus,
    required this.paymentDate,
    this.notes,
    required this.receiptNumber,
    required this.finalPayable,
    required this.amountDue,
    required this.purchaseStatus,
    required this.farmerName,
    required this.farmerMobile,
    required this.farmerVillage,
  });

  /// Build from combined API response:
  /// payment object (from POST /api/payments or GET /api/payments/{id})
  factory PaymentReceiptData.fromApiResponse(Map<String, dynamic> payment) {
    final farmer = payment['farmer'] is Map ? payment['farmer'] as Map : {};
    final purchase =
        payment['purchase'] is Map ? payment['purchase'] as Map : {};
    final summary = payment['purchaseSummary'] is Map
        ? payment['purchaseSummary'] as Map
        : {};

    final payId = payment['_id']?.toString() ?? payment['id']?.toString() ?? '';
    final amountDue = (purchase['amountDue'] as num?)?.toDouble() ??
        (summary['amountDue'] as num?)?.toDouble() ??
        0.0;
    final finalPayable = (purchase['finalPayable'] as num?)?.toDouble() ??
        (summary['finalPayable'] as num?)?.toDouble() ??
        0.0;
    final status = purchase['status']?.toString() ??
        summary['status']?.toString() ??
        (amountDue == 0 ? 'paid' : 'partial');
    final receiptNo = purchase['receiptNumber']?.toString() ??
        summary['receiptNumber']?.toString() ??
        'PAY-${payId.length > 6 ? payId.substring(payId.length - 6) : payId}';

    return PaymentReceiptData(
      paymentId: payId,
      amount: (payment['amount'] as num?)?.toDouble() ?? 0,
      paymentMode: payment['paymentMode']?.toString() ?? 'cash',
      referenceNumber: payment['referenceNumber']?.toString(),
      bankName: payment['bankName']?.toString(),
      chequeNumber: payment['chequeNumber']?.toString(),
      chequeDate: payment['chequeDate']?.toString(),
      chequeStatus: payment['chequeStatus']?.toString(),
      paymentDate: DateTime.tryParse(payment['paymentDate']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
      notes: payment['notes']?.toString(),
      receiptNumber: receiptNo,
      finalPayable: finalPayable,
      amountDue: amountDue,
      purchaseStatus: status,
      farmerName: farmer['name']?.toString() ?? 'N/A',
      farmerMobile: farmer['mobile']?.toString() ?? '',
      farmerVillage: farmer['village']?.toString() ??
          farmer['city']?.toString() ??
          '—',
    );
  }
}

class PaymentReceiptGenerator {
  PaymentReceiptGenerator._();

  // ── Public entry point ────────────────────────────────────────
  static String generate({
    required PaymentReceiptData data,
    bool isMarathi = false,
  }) {
    final t = _T(isMarathi);

    final d = data.paymentDate;
    final formattedDate =
        '${d.day.toString().padStart(2, '0')}/${d.month.toString().padStart(2, '0')}/${d.year}';

    final formattedAmount = _formatINR(data.amount);
    final statusDisplay = _statusDisplay(data.purchaseStatus, data.amountDue,
        data.amount, isMarathi);
    final amountInWords =
        '${_numberToWords(data.amount.truncate())} ${isMarathi ? 'रुपये फक्त' : 'Rupees Only'}';
    final paymentModeText = _paymentModeText(data.paymentMode, isMarathi);
    final paymentExtraInfo =
        _paymentExtraInfo(data, isMarathi);
    final remainingAmount = data.amountDue;

    return '''<!DOCTYPE html>
<html lang="${isMarathi ? 'mr' : 'en'}">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>${isMarathi ? 'पेमेंट पावती' : 'Payment Receipt'} - ${data.receiptNumber}</title>
  <style>
    *{margin:0;padding:0;box-sizing:border-box;}
    body{
      background:#e5e5e5;
      display:flex;
      justify-content:center;
      align-items:flex-start;
      padding:20px 10px;
      font-family:${isMarathi ? "'Noto Sans Devanagari','Mangal'," : ""}'Arial','Segoe UI',sans-serif;
    }
    .receipt{
      width:760px;
      max-width:100%;
      background:#fff;
      border:2px solid #b3153f;
      color:#b3153f;
      box-shadow:0 4px 14px rgba(0,0,0,0.12);
    }

    /* ── HEADER ── */
    .top-header{border-bottom:2px solid #b3153f;padding:10px 16px 8px;}
    .top-line{
      display:flex;justify-content:center;
      font-size:12px;font-weight:bold;
      margin-bottom:4px;letter-spacing:1px;color:#b3153f;
    }
    .title-section{display:flex;align-items:center;justify-content:center;}
    .center-title{flex:1;text-align:center;padding:0 10px;}
    .center-title h1{
      font-size:${isMarathi ? '32px' : '36px'};
      font-weight:700;line-height:1.2;
      margin-bottom:4px;letter-spacing:${isMarathi ? '0px' : '1px'};
      color:#b3153f;
    }
    .sub{font-size:15px;font-weight:bold;color:#b3153f;}
    .receipt-badge{
      display:inline-block;background:#b3153f;color:white;
      padding:4px 14px;border-radius:20px;
      font-size:13px;font-weight:bold;margin-top:6px;
    }
    .contact-row{
      margin-top:8px;border-top:2px solid #b3153f;padding-top:7px;
      display:flex;justify-content:space-between;
      font-size:11px;font-weight:bold;flex-wrap:wrap;gap:4px;
    }

    /* ── DETAILS TABLE ── */
    .details{width:100%;border-collapse:collapse;color:#b3153f;}
    .details td{
      border-bottom:2px solid #b3153f;
      padding:9px 12px;height:46px;font-size:15px;
    }
    .label{font-weight:bold;white-space:nowrap;padding-right:8px;}
    .value{color:#000;font-size:17px;font-weight:500;padding-left:12px;}
    .status-badge{
      display:inline-block;padding:4px 12px;border-radius:20px;
      font-size:13px;font-weight:bold;
      background:${statusDisplay['bg']};color:${statusDisplay['color']};
    }

    /* ── MAIN TABLE ── */
    .main-table{
      width:100%;border-collapse:collapse;
      table-layout:fixed;color:#b3153f;margin:4px 0;
    }
    .main-table th,.main-table td{
      border:2px solid #b3153f;padding:11px 10px;vertical-align:middle;
    }
    .main-table th{
      text-align:center;font-weight:bold;
      font-size:17px;background:#fff5f5;
    }
    .main-table td{color:#000;font-size:15px;}
    .col1{width:8%;text-align:center;}
    .col2{width:42%;}
    .col3{width:15%;text-align:right;}
    .col4{width:20%;text-align:right;}
    .col5{width:15%;text-align:center;}
    .total-row td{font-weight:bold;border-top:2px solid #b3153f;}
    .payment-row td{background:#fff8f0;}

    /* ── FOOTER ── */
    .footer{border-top:2px solid #b3153f;margin-top:4px;}
    .amount-words{
      padding:8px 14px;font-size:13px;
      background:#fff8f0;border-top:1px solid #b3153f;color:#444;
    }
    .pay-summary{
      padding:9px 14px;background:#f9f9f9;
      border-top:1px solid #b3153f;font-size:13px;
    }
    .pay-summary p{margin:4px 0;color:#333;}
    .pay-summary strong{color:#b3153f;}
    .footer-row{
      display:flex;border-bottom:2px solid #b3153f;flex-wrap:wrap;
    }
    .footer-left{
      flex:1;padding:11px 14px;font-size:15px;
      font-weight:bold;color:#b3153f;min-width:180px;
    }
    .footer-right{
      width:270px;border-left:2px solid #b3153f;
      padding:11px 14px;font-size:17px;font-weight:bold;
      display:flex;align-items:center;
      justify-content:space-between;gap:8px;white-space:nowrap;
    }
    .footer-right span{
      color:#000;font-size:21px;font-weight:bold;
      display:inline-block;margin-left:4px;
    }
    .signature-row{
      display:flex;justify-content:space-between;align-items:flex-end;
      padding:20px 14px 14px;min-height:120px;
    }
    .buyer-sign{
      font-size:16px;font-weight:bold;
      border-top:1px dashed #b3153f;padding-top:12px;
      min-width:160px;text-align:center;
    }
    .shop-sign{
      text-align:center;font-size:16px;font-weight:bold;
      position:relative;padding-top:12px;
      border-top:1px dashed #b3153f;min-width:180px;
    }
    .sign-mark{
      font-size:48px;font-family:cursive;
      position:absolute;top:-38px;right:16px;
      color:#000;transform:rotate(-10deg);
    }
    @media print{
      body{background:white;padding:0;margin:0;}
      .receipt{box-shadow:none;margin:0;width:100%;}
    }
  </style>
</head>
<body>
<div class="receipt">

  <!-- HEADER -->
  <div class="top-header">
    <div class="top-line">${isMarathi ? '॥ कळवणच्या न्यायक्षेत्रात ॥' : '॥ Under Kalwan Jurisdiction ॥'}</div>
    <div class="title-section">
      <div class="center-title">
        <h1>${isMarathi ? 'जय शिवराय ट्रेडिंगेटल' : 'Jai Shivrai Trading Co.'}</h1>
        <div class="sub">${isMarathi ? 'वेसराणे, ता. कळवण जि. नाशिक' : 'Vesarane, Tal. Kalwan, Dist. Nashik'}</div>
        <div class="receipt-badge">${isMarathi ? 'पेमेंट पावती' : 'PAYMENT RECEIPT'}</div>
      </div>
    </div>
    <div class="contact-row">
      <div>${isMarathi ? 'प्रो. रोकेश हिरे मो. ९०२१६९९९९१ / ९६२३९५६३९६' : 'Prop. Rakesh Hire M: 9021699991 / 9623956396'}</div>
      <div>${isMarathi ? 'प्रो. स्वजित हिरे मो. ९५६५४५९९९१ / ९९१९९९९९९९' : 'Prop. Swajit Hire M: 9565459991 / 9919999999'}</div>
    </div>
  </div>

  <!-- DETAILS -->
  <table class="details">
    <tr>
      <td style="width:60%">
        <span class="label">${isMarathi ? 'पावती नं.' : 'Receipt No.'}:</span>
        <span class="value">${data.receiptNumber}</span>
      </td>
      <td style="width:40%">
        <span class="label">${isMarathi ? 'दि.' : 'Date'}:</span>
        <span class="value">$formattedDate</span>
      </td>
    </tr>
    <tr>
      <td>
        <span class="label">${isMarathi ? 'श्रीमान' : 'Farmer Name'}:</span>
        <span class="value">${data.farmerName}</span>
      </td>
      <td>
        <span class="label">${isMarathi ? 'मो. नं.' : 'Mobile'}:</span>
        <span class="value">${data.farmerMobile}</span>
      </td>
    </tr>
    <tr>
      <td>
        <span class="label">${isMarathi ? 'गाव' : 'Village'}:</span>
        <span class="value">${data.farmerVillage}</span>
      </td>
      <td style="text-align:right">
        <span class="status-badge">${statusDisplay['text']}</span>
      </td>
    </tr>
  </table>

  <!-- MAIN TABLE -->
  <table class="main-table">
    <colgroup>
      <col class="col1"/><col class="col2"/>
      <col class="col3"/><col class="col4"/><col class="col5"/>
    </colgroup>
    <thead>
      <tr>
        <th>${isMarathi ? 'क्र.' : 'Sr.'}</th>
        <th>${isMarathi ? 'तपशील' : 'Description'}</th>
        <th>${isMarathi ? 'भाव' : 'Rate'}</th>
        <th>${isMarathi ? 'रक्कम' : 'Amount'}</th>
        <th>${isMarathi ? 'स्थिती' : 'Status'}</th>
      </tr>
    </thead>
    <tbody>
      <tr class="total-row">
        <td colspan="3" style="text-align:right;font-weight:bold">
          ${isMarathi ? 'एकूण बिल रक्कम' : 'Total Bill Amount'}:
        </td>
        <td style="text-align:right;font-weight:bold">₹ ${_formatINR(data.finalPayable)}</td>
        <td style="text-align:center">—</td>
      </tr>
      <tr class="payment-row">
        <td colspan="3" style="text-align:right;font-weight:bold;color:#b3153f">
          ${isMarathi ? 'आजचे पेमेंट' : "Today's Payment"}:
        </td>
        <td style="text-align:right;font-weight:bold;color:#b3153f;font-size:19px">
          ₹ $formattedAmount
        </td>
        <td style="text-align:center">
          <span style="display:inline-block;width:20px;height:20px;background:#4CAF50;border-radius:50%;color:white;line-height:20px;font-size:13px;">✓</span>
        </td>
      </tr>
      ${remainingAmount > 0 ? '''
      <tr>
        <td colspan="3" style="text-align:right;font-weight:bold;color:#FF6F00">
          ${isMarathi ? 'उर्वरित रक्कम' : 'Remaining Amount'}:
        </td>
        <td style="text-align:right;font-weight:bold;color:#FF6F00">
          ₹ ${_formatINR(remainingAmount)}
        </td>
        <td style="text-align:center">${isMarathi ? 'बाकी' : 'Due'}</td>
      </tr>
      ''' : ''}
    </tbody>
  </table>

  <!-- FOOTER -->
  <div class="footer">
    <div class="amount-words">
      <strong>${isMarathi ? 'अक्षरी रुपये' : 'Amount in Words'}:</strong> $amountInWords
    </div>

    <!-- Payment summary -->
    <div class="pay-summary">
      <p><strong>${isMarathi ? 'पेमेंट सारांश' : 'Payment Summary'}:</strong></p>
      <p>• ${isMarathi ? 'एकूण बिल' : 'Total Bill'}: ₹ ${_formatINR(data.finalPayable)}</p>
      ${remainingAmount > 0 ? '''
      <p>• ${isMarathi ? 'आजचे पेमेंट' : "Today's Payment"}: ₹ $formattedAmount</p>
      <p>• ${isMarathi ? 'पेमेंट पद्धत' : 'Payment Mode'}: $paymentModeText</p>
      ${paymentExtraInfo.isNotEmpty ? '<p>• $paymentExtraInfo</p>' : ''}
      <p>• ${isMarathi ? 'उर्वरित रक्कम' : 'Remaining Amount'}: ₹ ${_formatINR(remainingAmount)}</p>
      <p>• ${isMarathi ? 'स्थिती' : 'Status'}: ${statusDisplay['text']}</p>
      ''' : '''
      <p>• ${isMarathi ? 'एकूण भरले' : 'Total Paid'}: ₹ ${_formatINR(data.finalPayable)}</p>
      <p>• ${isMarathi ? 'पेमेंट पद्धत' : 'Payment Mode'}: $paymentModeText</p>
      ${paymentExtraInfo.isNotEmpty ? '<p>• $paymentExtraInfo</p>' : ''}
      <p>• ${isMarathi ? 'स्थिती' : 'Status'}: ${isMarathi ? 'पूर्ण भरले ✓' : 'Fully Paid ✓'}</p>
      '''}
    </div>

    <div class="footer-row">
      <div class="footer-left">${isMarathi ? 'धन्यवाद!' : 'Thank You!'}</div>
      <div class="footer-right">
        ${isMarathi ? 'पेमेंट रक्कम' : 'Payment Amount'}:
        <span>₹ $formattedAmount</span>
      </div>
    </div>

    <div class="signature-row">
      <div class="buyer-sign">
        ${isMarathi ? 'खरेदीदाराची सही' : "Buyer's Signature"}
      </div>
      <div class="shop-sign">
        <div class="sign-mark">✓</div>
        ${isMarathi ? 'जय शिवराय ट्रेडिंगेटल कळवण' : 'Jai Shivrai Trading Co., Kalwan'}
      </div>
    </div>
  </div>

</div>
</body>
</html>''';
  }

  // ── Helpers ───────────────────────────────────────────────────

  static String _formatINR(double value) {
    // Indian number format: 1,00,000
    final intPart = value.truncate();
    final str = intPart.toString();
    if (str.length <= 3) return str;
    final last3 = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final groups = <String>[];
    for (var i = rest.length; i > 0; i -= 2) {
      groups.insert(0, rest.substring(i - 2 < 0 ? 0 : i - 2, i));
    }
    return '${groups.join(',')},$last3';
  }

  static Map<String, String> _statusDisplay(
      String status, double amountDue, double amountPaid, bool isMarathi) {
    if (amountDue == 0) {
      return {
        'text': isMarathi ? 'पूर्ण भरले' : 'Fully Paid',
        'color': '#2E7D32',
        'bg': '#E8F5E9',
      };
    } else if (amountPaid > 0 || status == 'partial') {
      return {
        'text': isMarathi ? 'अंशतः भरले' : 'Partially Paid',
        'color': '#FF6F00',
        'bg': '#FFF3E0',
      };
    } else {
      return {
        'text': isMarathi ? 'प्रलंबित' : 'Pending',
        'color': '#D32F2F',
        'bg': '#FFEBEE',
      };
    }
  }

  static String _paymentModeText(String mode, bool isMarathi) {
    switch (mode.toLowerCase()) {
      case 'cash':
        return isMarathi ? 'रोख' : 'Cash';
      case 'upi':
        return isMarathi ? 'यूपीआय' : 'UPI';
      case 'bank':
        return isMarathi ? 'बँक ट्रान्सफर' : 'Bank Transfer';
      case 'cheque':
        return isMarathi ? 'चेक' : 'Cheque';
      default:
        return isMarathi ? 'इतर' : 'Other';
    }
  }

  static String _paymentExtraInfo(
      PaymentReceiptData data, bool isMarathi) {
    switch (data.paymentMode.toLowerCase()) {
      case 'upi':
        return '${isMarathi ? 'संदर्भ क्रमांक' : 'Ref No.'}: ${data.referenceNumber ?? '—'}';
      case 'bank':
        return '${isMarathi ? 'बँक नाव' : 'Bank'}: ${data.bankName ?? '—'} | ${isMarathi ? 'संदर्भ क्रमांक' : 'Ref No.'}: ${data.referenceNumber ?? '—'}';
      case 'cheque':
        final chqStatusMap = {
          'pending_clearance': isMarathi ? 'प्रलंबित' : 'Pending',
          'cleared': isMarathi ? 'क्लियर' : 'Cleared',
          'bounced': isMarathi ? 'बाउन्स' : 'Bounced',
        };
        return '${isMarathi ? 'चेक क्र.' : 'Cheque No.'}: ${data.chequeNumber ?? '—'} | ${isMarathi ? 'बँक' : 'Bank'}: ${data.bankName ?? '—'} | ${isMarathi ? 'स्थिती' : 'Status'}: ${chqStatusMap[data.chequeStatus] ?? (isMarathi ? 'प्रलंबित' : 'Pending')}';
      default:
        return '';
    }
  }

  // ── Number to words (Indian system) ──────────────────────────
  static final _ones = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
    'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
    'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
  ];
  static final _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
    'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  static String _lessThanThousand(int n) {
    if (n == 0) return '';
    if (n < 20) return _ones[n];
    if (n < 100) {
      final t = n ~/ 10;
      final o = n % 10;
      return _tens[t] + (o > 0 ? ' ${_ones[o]}' : '');
    }
    final h = n ~/ 100;
    final rest = n % 100;
    return '${_ones[h]} Hundred${rest > 0 ? ' ${_lessThanThousand(rest)}' : ''}';
  }

  static String _convert(int n) {
    if (n == 0) return 'Zero';
    if (n < 1000) return _lessThanThousand(n);
    if (n < 100000) {
      final th = n ~/ 1000;
      final rest = n % 1000;
      return '${_lessThanThousand(th)} Thousand${rest > 0 ? ' ${_lessThanThousand(rest)}' : ''}';
    }
    if (n < 10000000) {
      final l = n ~/ 100000;
      final rest = n % 100000;
      return '${_lessThanThousand(l)} Lakh${rest > 0 ? ' ${_convert(rest)}' : ''}';
    }
    final c = n ~/ 10000000;
    final rest = n % 10000000;
    return '${_lessThanThousand(c)} Crore${rest > 0 ? ' ${_convert(rest)}' : ''}';
  }

  static String _numberToWords(int n) => n == 0 ? 'Zero' : _convert(n);
}

extension on String {
  padStart(int i, String s) {}
}

/// Internal translation helper
class _T {
  final bool isMarathi;
  const _T(this.isMarathi);
  String call(String en, String mr) => isMarathi ? mr : en;
}
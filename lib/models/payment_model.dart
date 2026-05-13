// import 'package:flutter/material.dart';

// class PaymentModel {
//   final String id;
//   final String purchaseId;
//   final String farmerId;
//   final String vendorId;
//   final double amount;
//   final PaymentMode paymentMode;
//   final String? referenceNumber;
//   final DateTime paymentDate;
//   final String? notes;
//   final ChequeStatus? chequeStatus;
//   final String createdBy;
//   final DateTime createdAt;

//   PaymentModel({
//     required this.id,
//     required this.purchaseId,
//     required this.farmerId,
//     required this.vendorId,
//     required this.amount,
//     required this.paymentMode,
//     this.referenceNumber,
//     required this.paymentDate,
//     this.notes,
//     this.chequeStatus,
//     required this.createdBy,
//     required this.createdAt,
//   });

//   factory PaymentModel.fromJson(Map<String, dynamic> json) {
//     return PaymentModel(
//       id: json['id']?.toString() ?? '',
//       purchaseId: json['purchaseId']?.toString() ?? json['purchase_id']?.toString() ?? '',
//       farmerId: json['farmerId']?.toString() ?? json['farmer_id']?.toString() ?? '',
//       vendorId: json['vendorId']?.toString() ?? json['vendor_id']?.toString() ?? '',
//       amount: (json['amount'] as num?)?.toDouble() ?? 0,
//       paymentMode: PaymentMode.fromString(json['paymentMode']?.toString() ?? json['payment_mode']?.toString() ?? 'cash'),
//       referenceNumber: json['referenceNumber']?.toString() ?? json['reference_number']?.toString(),
//       paymentDate: DateTime.tryParse(json['paymentDate']?.toString() ?? json['payment_date']?.toString() ?? '') ?? DateTime.now(),
//       notes: json['notes'],
//       chequeStatus: json['chequeStatus'] != null ? ChequeStatus.fromString(json['chequeStatus'].toString()) : null,
//       createdBy: json['createdBy']?.toString() ?? json['created_by']?.toString() ?? '',
//       createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'purchaseId': purchaseId,
//       'farmerId': farmerId,
//       'amount': amount,
//       'paymentMode': paymentMode.value,
//       if (referenceNumber != null) 'referenceNumber': referenceNumber,
//       'paymentDate': paymentDate.toIso8601String(),
//       if (notes != null) 'notes': notes,
//       if (chequeStatus != null) 'chequeStatus': chequeStatus?.value,
//     };
//   }

//   PaymentModel copyWith({
//     String? id,
//     String? purchaseId,
//     String? farmerId,
//     String? vendorId,
//     double? amount,
//     PaymentMode? paymentMode,
//     String? referenceNumber,
//     DateTime? paymentDate,
//     String? notes,
//     ChequeStatus? chequeStatus,
//     String? createdBy,
//     DateTime? createdAt,
//   }) {
//     return PaymentModel(
//       id: id ?? this.id,
//       purchaseId: purchaseId ?? this.purchaseId,
//       farmerId: farmerId ?? this.farmerId,
//       vendorId: vendorId ?? this.vendorId,
//       amount: amount ?? this.amount,
//       paymentMode: paymentMode ?? this.paymentMode,
//       referenceNumber: referenceNumber ?? this.referenceNumber,
//       paymentDate: paymentDate ?? this.paymentDate,
//       notes: notes ?? this.notes,
//       chequeStatus: chequeStatus ?? this.chequeStatus,
//       createdBy: createdBy ?? this.createdBy,
//       createdAt: createdAt ?? this.createdAt,
//     );
//   }
// }

// enum PaymentMode {
//   cash('cash'),
//   upi('upi'),
//   bank('bank'),
//   cheque('cheque');

//   final String value;
//   const PaymentMode(this.value);

//   static PaymentMode fromString(String value) {
//     switch (value.toLowerCase()) {
//       case 'cash':
//         return PaymentMode.cash;
//       case 'upi':
//         return PaymentMode.upi;
//       case 'bank':
//         return PaymentMode.bank;
//       case 'cheque':
//         return PaymentMode.cheque;
//       default:
//         return PaymentMode.cash;
//     }
//   }

//   String get displayName {
//     switch (this) {
//       case PaymentMode.cash:
//         return 'Cash';
//       case PaymentMode.upi:
//         return 'UPI';
//       case PaymentMode.bank:
//         return 'Bank Transfer';
//       case PaymentMode.cheque:
//         return 'Cheque';
//     }
//   }

//   IconData get icon {
//     switch (this) {
//       case PaymentMode.cash:
//         return Icons.money_rounded;
//       case PaymentMode.upi:
//         return Icons.qr_code_scanner_rounded;
//       case PaymentMode.bank:
//         return Icons.account_balance_rounded;
//       case PaymentMode.cheque:
//         return Icons.description_rounded;
//     }
//   }
// }

// enum ChequeStatus {
//   pending('pending'),
//   cleared('cleared'),
//   bounced('bounced');

//   final String value;
//   const ChequeStatus(this.value);

//   static ChequeStatus fromString(String value) {
//     switch (value.toLowerCase()) {
//       case 'pending':
//         return ChequeStatus.pending;
//       case 'cleared':
//         return ChequeStatus.cleared;
//       case 'bounced':
//         return ChequeStatus.bounced;
//       default:
//         return ChequeStatus.pending;
//     }
//   }

//   String get displayName {
//     switch (this) {
//       case ChequeStatus.pending:
//         return 'Pending Clearance';
//       case ChequeStatus.cleared:
//         return 'Cleared';
//       case ChequeStatus.bounced:
//         return 'Bounced';
//     }
//   }

//   Color get color {
//     switch (this) {
//       case ChequeStatus.pending:
//         return Colors.orange;
//       case ChequeStatus.cleared:
//         return Colors.green;
//       case ChequeStatus.bounced:
//         return Colors.red;
//     }
//   }
// }

// class PaymentRequest {
//   final String purchaseId;
//   final String farmerId;
//   final double amount;
//   final PaymentMode paymentMode;
//   final String? referenceNumber;
//   final DateTime paymentDate;
//   final String? notes;

//   PaymentRequest({
//     required this.purchaseId,
//     required this.farmerId,
//     required this.amount,
//     required this.paymentMode,
//     this.referenceNumber,
//     required this.paymentDate,
//     this.notes,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'purchaseId': purchaseId,
//       'farmerId': farmerId,
//       'amount': amount,
//       'paymentMode': paymentMode.value,
//       if (referenceNumber != null) 'referenceNumber': referenceNumber,
//       'paymentDate': paymentDate.toIso8601String(),
//       if (notes != null) 'notes': notes,
//     };
//   }
// }

import 'package:flutter/material.dart';
 
class PaymentModel {
  final String id;
  final String purchaseId;
  final String farmerId;
  final String vendorId;
  final double amount;
  final PaymentMode paymentMode;
  final String? referenceNumber;
  final DateTime paymentDate;
  final String? notes;
  final ChequeStatus? chequeStatus;
  final String createdBy;
  final DateTime createdAt;
 
  PaymentModel({
    required this.id,
    required this.purchaseId,
    required this.farmerId,
    required this.vendorId,
    required this.amount,
    required this.paymentMode,
    this.referenceNumber,
    required this.paymentDate,
    this.notes,
    this.chequeStatus,
    required this.createdBy,
    required this.createdAt,
  });
 
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id:              json['_id']?.toString() ?? json['id']?.toString() ?? '',
      purchaseId:      json['purchaseId']?.toString() ?? json['purchase']?.toString() ?? '',
      farmerId:        json['farmerId']?.toString() ?? json['farmer']?.toString() ?? '',
      vendorId:        json['vendorId']?.toString() ?? json['vendor']?.toString() ?? '',
      amount:          (json['amount'] as num?)?.toDouble() ?? 0,
      paymentMode:     PaymentMode.fromString(json['paymentMode']?.toString() ?? 'cash'),
      referenceNumber: json['referenceNumber']?.toString(),
      paymentDate:     DateTime.tryParse(json['paymentDate']?.toString() ?? '') ?? DateTime.now(),
      notes:           json['notes']?.toString(),
      // FIX: parse chequeStatus correctly
      chequeStatus:    json['chequeStatus'] != null && json['chequeStatus'] != 'null'
                         ? ChequeStatus.fromString(json['chequeStatus'].toString())
                         : null,
      createdBy:       json['createdBy']?.toString() ?? '',
      createdAt:       DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
 
  Map<String, dynamic> toJson() => {
    'purchaseId':       purchaseId,
    'farmerId':         farmerId,
    'amount':           amount,
    'paymentMode':      paymentMode.value,
    if (referenceNumber != null) 'referenceNumber': referenceNumber,
    'paymentDate':      paymentDate.toIso8601String(),
    if (notes != null)  'notes': notes,
    // FIX: only include chequeStatus if mode is cheque
    if (paymentMode == PaymentMode.cheque && chequeStatus != null)
      'chequeStatus': chequeStatus!.value,
  };
}
 
// ── Payment Mode Enum ─────────────────────────────────────────────────────────
enum PaymentMode {
  cash('cash'),
  upi('upi'),
  bank('bank'),
  cheque('cheque');
 
  final String value;
  const PaymentMode(this.value);
 
  static PaymentMode fromString(String value) {
    switch (value.toLowerCase()) {
      case 'upi':    return PaymentMode.upi;
      case 'bank':   return PaymentMode.bank;
      case 'cheque': return PaymentMode.cheque;
      default:       return PaymentMode.cash;
    }
  }
 
  String get displayName {
    switch (this) {
      case PaymentMode.cash:   return 'Cash';
      case PaymentMode.upi:    return 'UPI';
      case PaymentMode.bank:   return 'Bank Transfer';
      case PaymentMode.cheque: return 'Cheque';
    }
  }
 
  IconData get icon {
    switch (this) {
      case PaymentMode.cash:   return Icons.money_rounded;
      case PaymentMode.upi:    return Icons.qr_code_scanner_rounded;
      case PaymentMode.bank:   return Icons.account_balance_rounded;
      case PaymentMode.cheque: return Icons.description_rounded;
    }
  }
 
  // Whether this mode requires a reference number
  bool get requiresReference {
    switch (this) {
      case PaymentMode.upi:
      case PaymentMode.bank:
      case PaymentMode.cheque:
        return true;
      default:
        return false;
    }
  }
 
  String get referencePlaceholder {
    switch (this) {
      case PaymentMode.upi:    return 'e.g. UPI Ref: 1234567890';
      case PaymentMode.bank:   return 'e.g. NEFT Ref: NEFT123456';
      case PaymentMode.cheque: return 'e.g. Cheque No: 123456';
      default:                 return '';
    }
  }
 
  String get referenceLabel {
    switch (this) {
      case PaymentMode.upi:    return 'UPI Transaction ID';
      case PaymentMode.bank:   return 'Bank Reference Number';
      case PaymentMode.cheque: return 'Cheque Number';
      default:                 return 'Reference';
    }
  }
}
 
// ── Cheque Status Enum ────────────────────────────────────────────────────────
// FIX: API uses 'pending_clearance', NOT 'pending'
enum ChequeStatus {
  pendingClearance('pending_clearance'),
  cleared('cleared'),
  bounced('bounced');
 
  final String value;
  const ChequeStatus(this.value);
 
  static ChequeStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'cleared':           return ChequeStatus.cleared;
      case 'bounced':           return ChequeStatus.bounced;
      case 'pending_clearance':
      default:                  return ChequeStatus.pendingClearance;
    }
  }
 
  String get displayName {
    switch (this) {
      case ChequeStatus.pendingClearance: return 'Pending Clearance';
      case ChequeStatus.cleared:          return 'Cleared';
      case ChequeStatus.bounced:          return 'Bounced';
    }
  }
 
  Color get color {
    switch (this) {
      case ChequeStatus.pendingClearance: return Colors.orange;
      case ChequeStatus.cleared:          return Colors.green;
      case ChequeStatus.bounced:          return Colors.red;
    }
  }
}
 
// ── Payment Request ───────────────────────────────────────────────────────────
class PaymentRequest {
  final String purchaseId;
  final String farmerId;
  final double amount;
  final PaymentMode paymentMode;
  final String? referenceNumber;
  final DateTime paymentDate;
  final String? notes;
  final ChequeStatus? chequeStatus;
  // New fields for cheque
  final String? chequeNumber;
  final DateTime? chequeDate;
  final String? bankName;

  const PaymentRequest({
    required this.purchaseId,
    required this.farmerId,
    required this.amount,
    required this.paymentMode,
    this.referenceNumber,
    required this.paymentDate,
    this.notes,
    this.chequeStatus,
    this.chequeNumber,
    this.chequeDate,
    this.bankName,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'purchaseId': purchaseId,
      'farmerId': farmerId,
      'amount': amount,
      'paymentMode': paymentMode.value,
      'paymentDate': paymentDate.toIso8601String().split('T').first,
    };
    if (referenceNumber != null && referenceNumber!.isNotEmpty) {
      map['referenceNumber'] = referenceNumber;
    }
    if (notes != null && notes!.isNotEmpty) {
      map['notes'] = notes;
    }
    if (paymentMode == PaymentMode.cheque) {
      if (chequeNumber != null && chequeNumber!.isNotEmpty) {
        map['chequeNumber'] = chequeNumber;
      }
      if (chequeDate != null) {
        map['chequeDate'] = chequeDate!.toIso8601String().split('T').first;
      }
      if (bankName != null && bankName!.isNotEmpty) {
        map['bankName'] = bankName;
      }
      // Send chequeStatus only if the API expects it (optional)
      if (chequeStatus != null) {
        map['chequeStatus'] = chequeStatus!.value;
      }
    }
    return map;
  }
}
// ─────────────────────────────────────────────────────────────
//  EXPENSE MODEL
//  Matches GET /api/expenses response exactly
// ─────────────────────────────────────────────────────────────

class ExpenseModel {
  final String id;
  final String category;
  final double amount;
  final String description;
  final DateTime expenseDate;
  final String paidBy;
  final String paidTo;
  final String referenceNumber;
  final String approvalStatus; // auto_approved | pending | approved | rejected | cancelled
  final Map<String, dynamic>? approvedBy;
  final DateTime? approvedAt;
  final String rejectionReason;
  final String cancelReason;
  final Map<String, dynamic>? createdBy;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.expenseDate,
    required this.paidBy,
    required this.paidTo,
    required this.referenceNumber,
    required this.approvalStatus,
    this.approvedBy,
    this.approvedAt,
    required this.rejectionReason,
    required this.cancelReason,
    this.createdBy,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> j) {
    return ExpenseModel(
      id:               j['_id']?.toString() ?? j['id']?.toString() ?? '',
      category:         j['category']?.toString() ?? '',
      amount:           (j['amount'] as num?)?.toDouble() ?? 0,
      description:      j['description']?.toString() ?? '',
      expenseDate:      DateTime.tryParse(j['expenseDate']?.toString() ?? '') ?? DateTime.now(),
      paidBy:           j['paidBy']?.toString() ?? '',
      paidTo:           j['paidTo']?.toString() ?? '',
      referenceNumber:  j['referenceNumber']?.toString() ?? '',
      approvalStatus:   j['approvalStatus']?.toString() ?? 'pending',
      approvedBy:       j['approvedBy'] is Map ? j['approvedBy'] as Map<String, dynamic> : null,
      approvedAt:       j['approvedAt'] != null ? DateTime.tryParse(j['approvedAt'].toString()) : null,
      rejectionReason:  j['rejectionReason']?.toString() ?? '',
      cancelReason:     j['cancelReason']?.toString() ?? '',
      createdBy:        j['createdBy'] is Map ? j['createdBy'] as Map<String, dynamic> : null,
      notes:            j['notes']?.toString() ?? '',
      createdAt:        DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt:        DateTime.tryParse(j['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  // ── Computed helpers ──────────────────────────────────────────
  String get categoryLabel => ExpenseCategory.labelFor(category);
  String get categoryIcon  => ExpenseCategory.iconFor(category);
  bool get isPending      => approvalStatus == 'pending';
  bool get isApproved     => approvalStatus == 'approved' || approvalStatus == 'auto_approved';
  bool get isRejected     => approvalStatus == 'rejected';
  bool get isCancelled    => approvalStatus == 'cancelled';
  bool get canApprove     => approvalStatus == 'pending';
  bool get canCancel      => approvalStatus != 'cancelled';
  String get approvedByName => approvedBy?['name']?.toString() ?? '';
  String get createdByName  => createdBy?['name']?.toString() ?? '';
}

// ── Expense Categories ────────────────────────────────────────
class ExpenseCategory {
  static const List<Map<String, String>> all = [
    {'value': 'transport_logistics',  'label': 'Transport & Logistics',   },
    {'value': 'labour_wages',         'label': 'Labour & Wages',          },
    {'value': 'market_fees',          'label': 'Market Fees',              },
    {'value': 'storage_cold_chain',   'label': 'Storage & Cold Chain',     },
    {'value': 'shop_office',          'label': 'Shop & Office',           },
    {'value': 'repairs_maintenance',  'label': 'Repairs & Maintenance',   },
    {'value': 'banking_finance',      'label': 'Banking & Finance',       },
    {'value': 'marketing_misc',       'label': 'Marketing & Misc',         },
  ];

  static String labelFor(String value) {
    return all.firstWhere((c) => c['value'] == value,
        orElse: () => {'label': value})['label']!;
  }

  static String iconFor(String value) {
    return all.firstWhere((c) => c['value'] == value,
        orElse: () => {'icon': '💰'})['icon']!;
  }
}

// ── Approval Status Helpers ───────────────────────────────────
class ApprovalStatus {
  static const String autoApproved = 'auto_approved';
  static const String pending      = 'pending';
  static const String approved     = 'approved';
  static const String rejected     = 'rejected';
  static const String cancelled    = 'cancelled';

  static String label(String status) {
    switch (status) {
      case autoApproved: return 'Auto Approved';
      case pending:      return 'Pending';
      case approved:     return 'Approved';
      case rejected:     return 'Rejected';
      case cancelled:    return 'Cancelled';
      default:           return status;
    }
  }
}

// ── Expense Summary by Category ───────────────────────────────
class ExpenseCategorySummary {
  final String category;
  final double total;
  final int count;

  const ExpenseCategorySummary({
    required this.category,
    required this.total,
    required this.count,
  });

  factory ExpenseCategorySummary.fromJson(Map<String, dynamic> j) {
    return ExpenseCategorySummary(
      category: j['_id']?.toString() ?? '',
      total:    (j['total'] as num?)?.toDouble() ?? 0,
      count:    (j['count'] as num?)?.toInt() ?? 0,
    );
  }

  String get label => ExpenseCategory.labelFor(category);
  String get icon  => ExpenseCategory.iconFor(category);
}
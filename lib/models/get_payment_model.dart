class GetPaymentModel {
  final String id;
  final String purchaseId;  // Add this field
  final String farmerId;
  final String farmerName;
  final double amount;
  final String paymentMode;
  final String? chequeNumber;
  final String? transactionId;
  final String? referenceNumber;
  final DateTime paymentDate;
  final String status;
  final String? notes;

  GetPaymentModel({
    required this.id,
    required this.purchaseId,  // Add this
    required this.farmerId,
    required this.farmerName,
    required this.amount,
    required this.paymentMode,
    this.chequeNumber,
    this.transactionId,
    this.referenceNumber,
    required this.paymentDate,
    required this.status,
    this.notes,
  });

  factory GetPaymentModel.fromJson(Map<String, dynamic> json) {
    // Debug print to see what's in the response
    print('Payment JSON: $json');
    print('Purchase ID from JSON: ${json['purchaseId']}');
    print('Purchase field: ${json['purchase']}');

    final farmer = json['farmer'] as Map<String, dynamic>? ?? {};

    // Try multiple possible locations for purchaseId
    String purchaseId = '';
    if (json['purchaseId'] != null) {
      purchaseId = json['purchaseId'].toString();
    } else if (json['purchase_id'] != null) {
      purchaseId = json['purchase_id'].toString();
    } else if (json['purchase'] is Map) {
      purchaseId = (json['purchase'] as Map)['_id']?.toString() ?? '';
    } else if (json['purchase'] is String) {
      purchaseId = json['purchase'].toString();
    }

    print('Extracted Purchase ID: $purchaseId');

    return GetPaymentModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      purchaseId: purchaseId,
      farmerId: farmer['_id']?.toString() ?? json['farmerId']?.toString() ?? '',
      farmerName: farmer['name']?.toString() ?? 'Unknown Farmer',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: json['paymentMode']?.toString() ?? 'cash',
      chequeNumber: json['chequeNumber']?.toString(),
      transactionId: json['transactionId']?.toString(),
      referenceNumber: json['referenceNumber']?.toString(),
      paymentDate: DateTime.tryParse(json['paymentDate']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'completed',
      notes: json['notes']?.toString(),
    );
  }
}

class GetDueSummaryModel {
  final double totalDue;
  final double totalOverdue;
  final double totalPurchases;
  final Map<String, double> byStatus;
  final List<GetFarmerDueModel> farmerWise;
  final List<GetPurchaseDueModel> purchases;

  GetDueSummaryModel({
    required this.totalDue,
    required this.totalOverdue,
    required this.totalPurchases,
    required this.byStatus,
    required this.farmerWise,
    required this.purchases,
  });

  factory GetDueSummaryModel.fromJson(Map<String, dynamic> json) {
    print('=== PARSING DUE SUMMARY MODEL ===');

    final data = json['data'] as Map<String, dynamic>? ?? {};
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final byStatusRaw = summary['byStatus'] as Map<String, dynamic>? ?? {};

    // Get purchases list - this is the key change
    List<GetPurchaseDueModel> purchases = [];

    // The API puts purchases directly in the data object
    final purchasesData = data['purchases'] as List? ?? [];

    if (purchasesData.isNotEmpty) {
      print('Found ${purchasesData.length} purchases');
      purchases = purchasesData.map((p) {
        try {
          return GetPurchaseDueModel.fromJson(p as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing purchase: $e');
          return GetPurchaseDueModel(
            id: '',
            receiptNumber: '',
            farmerId: '',
            farmerName: 'Error',
            finalPayable: 0,
            amountPaid: 0,
            amountDue: 0,
            purchaseDate: DateTime.now(),
            isOverdue: false,
            status: '',
          );
        }
      }).toList();
    } else {
      print('No purchases found in response');
    }

    // Get farmer-wise data (optional)
    List<GetFarmerDueModel> farmerWise = [];
    final farmerWiseData = data['farmerWise'] as List? ?? [];
    if (farmerWiseData.isNotEmpty) {
      farmerWise = farmerWiseData.map((f) {
        try {
          return GetFarmerDueModel.fromJson(f as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing farmer: $e');
          return GetFarmerDueModel(
            id: '',
            name: 'Unknown',
            mobile: '',
            totalDue: 0,
            totalOverdue: 0,
            purchaseCount: 0,
          );
        }
      }).toList();
    }

    final result = GetDueSummaryModel(
      totalDue: (summary['totalDue'] as num?)?.toDouble() ?? 0.0,
      totalOverdue: (summary['totalOverdue'] as num?)?.toDouble() ?? 0.0,
      totalPurchases: (summary['totalPurchases'] as num?)?.toDouble() ?? 0.0,
      byStatus: Map.fromEntries(
          byStatusRaw.entries.map((e) => MapEntry(e.key, (e.value as num?)?.toDouble() ?? 0.0))
      ),
      farmerWise: farmerWise,
      purchases: purchases,
    );

    print('Total purchases parsed: ${result.purchases.length}');
    print('Total Due from summary: ${result.totalDue}');
    print('================================');

    return result;
  }
}

class GetFarmerDueModel {
  final String id;
  final String name;
  final String mobile;
  final double totalDue;
  final double totalOverdue;
  final int purchaseCount;

  GetFarmerDueModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.totalDue,
    required this.totalOverdue,
    required this.purchaseCount,
  });

  factory GetFarmerDueModel.fromJson(Map<String, dynamic> json) {
    return GetFarmerDueModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      mobile: json['mobile']?.toString() ?? '',
      totalDue: (json['totalDue'] as num?)?.toDouble() ?? 0.0,
      totalOverdue: (json['totalOverdue'] as num?)?.toDouble() ?? 0.0,
      purchaseCount: (json['purchaseCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class GetPurchaseDueModel {
  final String id;
  final String receiptNumber;
  final String farmerId;
  final String farmerName;
  final double finalPayable;
  final double amountPaid;
  final double amountDue;
  final DateTime purchaseDate;
  final bool isOverdue;
  final String status;

  GetPurchaseDueModel({
    required this.id,
    required this.receiptNumber,
    required this.farmerId,
    required this.farmerName,
    required this.finalPayable,
    required this.amountPaid,
    required this.amountDue,
    required this.purchaseDate,
    required this.isOverdue,
    required this.status,
  });

  factory GetPurchaseDueModel.fromJson(Map<String, dynamic> json) {
    // The API gives us amountDue directly
    final amountDue = (json['amountDue'] as num?)?.toDouble() ?? 0.0;

    // For due summary, finalPayable is the same as amountDue (no payments made yet)
    // If the API provides finalPayable, use it; otherwise use amountDue
    final finalPayable = (json['finalPayable'] as num?)?.toDouble() ?? amountDue;

    // Amount paid is 0 for due summary items (since they're pending)
    final amountPaid = (json['amountPaid'] as num?)?.toDouble() ?? 0.0;

    // Get farmer info - from the purchase object directly
    String farmerName = json['farmerName']?.toString() ?? 'Unknown';
    String farmerId = json['farmerId']?.toString() ?? '';

    // Get receipt number
    final receiptNumber = json['receiptNumber']?.toString() ?? '';

    // Get purchase date
    DateTime date = DateTime.now();
    final dateStr = json['purchaseDate']?.toString() ?? '';
    if (dateStr.isNotEmpty) {
      date = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
    }

    // Get status
    final status = json['status']?.toString() ?? 'saved';

    // Check if overdue (calculate based on date if not provided)
    bool isOverdue = json['isOverdue'] as bool? ?? false;
    if (!isOverdue && amountDue > 0) {
      // Check if purchase date is more than 30 days old
      isOverdue = date.isBefore(DateTime.now().subtract(const Duration(days: 30)));
    }

    return GetPurchaseDueModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      receiptNumber: receiptNumber,
      farmerId: farmerId,
      farmerName: farmerName,
      finalPayable: finalPayable,
      amountPaid: amountPaid,
      amountDue: amountDue,
      purchaseDate: date,
      isOverdue: isOverdue,
      status: status,
    );
  }
}

class GetPaymentSummaryModel {
  final double totalAmount;
  final int totalPayments;
  final double avgAmount;
  final Map<String, double> byPaymentMode;
  final Map<String, double> byStatus;

  GetPaymentSummaryModel({
    required this.totalAmount,
    required this.totalPayments,
    required this.avgAmount,
    required this.byPaymentMode,
    required this.byStatus,
  });

  factory GetPaymentSummaryModel.fromJson(Map<String, dynamic> json) {
    final byModeRaw = json['byPaymentMode'] as Map<String, dynamic>? ?? {};
    final byStatusRaw = json['byStatus'] as Map<String, dynamic>? ?? {};

    return GetPaymentSummaryModel(
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      totalPayments: (json['totalPayments'] as num?)?.toInt() ?? 0,
      avgAmount: (json['avgAmount'] as num?)?.toDouble() ?? 0.0,
      byPaymentMode: Map.fromEntries(
          byModeRaw.entries.map((e) => MapEntry(e.key, (e.value as num?)?.toDouble() ?? 0.0))
      ),
      byStatus: Map.fromEntries(
          byStatusRaw.entries.map((e) => MapEntry(e.key, (e.value as num?)?.toDouble() ?? 0.0))
      ),
    );
  }
}
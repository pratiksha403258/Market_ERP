// lib/features/ledger/models/buyer_ledger_models.dart

class BuyerInfo {
  final String id;
  final String name;
  final String mobile;
  final String email;
  final String address;
  final String city;
  final String state;
  final String gstNumber;
  final String displayName;
  final String fullAddress;

  BuyerInfo({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.gstNumber,
    required this.displayName,
    required this.fullAddress,
  });

  factory BuyerInfo.fromJson(Map<String, dynamic> j) {
    // Handle both single buyer and nested buyer objects
    final buyerData = j.containsKey('buyer') ? j['buyer'] : j;
    return BuyerInfo(
      id: buyerData['id'] ?? buyerData['_id'] ?? '',
      name: buyerData['name'] ?? '',
      mobile: buyerData['mobile'] ?? '',
      email: buyerData['email'] ?? '',
      address: buyerData['address'] ?? '',
      city: buyerData['city'] ?? '',
      state: buyerData['state'] ?? '',
      gstNumber: buyerData['gstNumber'] ?? '',
      displayName: buyerData['displayName'] ?? buyerData['name'] ?? '',
      fullAddress: buyerData['fullAddress'] ?? '',
    );
  }
}

class BuyerLedgerTransaction {
  final String id;
  final DateTime entryDate;
  final String description;
  final double debit;
  final double credit;
  final double runningBalance;
  final String refModel;
  final String refId;
  final String oppositeParty;
  final double farmerAmount;
  final double buyerAmount;
  final double operatorAmount;

  BuyerLedgerTransaction({
    required this.id,
    required this.entryDate,
    required this.description,
    required this.debit,
    required this.credit,
    required this.runningBalance,
    required this.refModel,
    required this.refId,
    required this.oppositeParty,
    required this.farmerAmount,
    required this.buyerAmount,
    required this.operatorAmount,
  });

  factory BuyerLedgerTransaction.fromJson(Map<String, dynamic> j) {
    return BuyerLedgerTransaction(
      id: j['id'] ?? j['_id'] ?? '',
      entryDate: DateTime.tryParse(j['entryDate'] ?? '') ?? DateTime.now(),
      description: j['description'] ?? '',
      debit: (j['debit'] ?? 0).toDouble(),
      credit: (j['credit'] ?? 0).toDouble(),
      runningBalance: (j['runningBalance'] ?? 0).toDouble(),
      refModel: j['refModel'] ?? '',
      refId: j['refId'] ?? '',
      oppositeParty: j['oppositeParty'] ?? '',
      farmerAmount: (j['farmerAmount'] ?? 0).toDouble(),
      buyerAmount: (j['buyerAmount'] ?? 0).toDouble(),
      operatorAmount: (j['operatorAmount'] ?? 0).toDouble(),
    );
  }
}

class BuyerLedgerSummary {
  final double totalDebit;
  final double totalCredit;
  final double closingBalance;

  BuyerLedgerSummary({
    required this.totalDebit,
    required this.totalCredit,
    required this.closingBalance,
  });

  factory BuyerLedgerSummary.fromJson(Map<String, dynamic> j) {
    return BuyerLedgerSummary(
      totalDebit: (j['totalDebit'] ?? 0).toDouble(),
      totalCredit: (j['totalCredit'] ?? 0).toDouble(),
      closingBalance: (j['closingBalance'] ?? j['currentBalance'] ?? 0).toDouble(),
    );
  }
}

class BusinessDetails {
  final String name;
  final String address;
  final String phone;
  final String email;
  final String gstNumber;
  final String panNumber;
  final String? bankName;
  final String? bankAccountNumber;
  final String? ifscCode;

  BusinessDetails({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.gstNumber,
    required this.panNumber,
    this.bankName,
    this.bankAccountNumber,
    this.ifscCode,
  });

  factory BusinessDetails.fromJson(Map<String, dynamic> j) {
    return BusinessDetails(
      name: j['name'] ?? '',
      address: j['address'] ?? '',
      phone: j['phone'] ?? '',
      email: j['email'] ?? '',
      gstNumber: j['gstNumber'] ?? '',
      panNumber: j['panNumber'] ?? '',
      bankName: j['bankName'],
      bankAccountNumber: j['bankAccountNumber'],
      ifscCode: j['ifscCode'],
    );
  }
}

// lib/features/ledger/models/buyer_ledger_models.dart

class BuyerLedgerData {
  final BusinessDetails businessDetails;
  final BuyerInfo buyer;
  final BuyerLedgerSummary summary;
  final List<BuyerLedgerTransaction> transactions;
  final int totalPages;
  final int totalTransactions;

  BuyerLedgerData({
    required this.businessDetails,
    required this.buyer,
    required this.summary,
    required this.transactions,
    required this.totalPages,
    required this.totalTransactions,
  });

  factory BuyerLedgerData.fromJson(Map<String, dynamic> j) {
    final pagination = j['pagination'] as Map<String, dynamic>? ?? {};
    final summaryData = j['summary'] as Map<String, dynamic>? ?? {};
    final transactionsList = (j['transactions'] as List<dynamic>? ?? [])
        .map((t) => BuyerLedgerTransaction.fromJson(t as Map<String, dynamic>))
        .toList();
    
    // Calculate correct totals from transactions if API returns zeros
    double calculatedTotalDebit = summaryData['totalDebit']?.toDouble() ?? 0;
    double calculatedTotalCredit = summaryData['totalCredit']?.toDouble() ?? 0;
    double calculatedClosingBalance = summaryData['closingBalance']?.toDouble() ?? 0;
    
    // If API returns zeros but we have transactions, calculate from transactions
    if ((calculatedTotalDebit == 0 || calculatedTotalCredit == 0) && transactionsList.isNotEmpty) {
      calculatedTotalDebit = transactionsList.fold(0, (sum, tx) => sum + tx.debit);
      calculatedTotalCredit = transactionsList.fold(0, (sum, tx) => sum + tx.credit);
      // Get the last transaction's running balance
      calculatedClosingBalance = transactionsList.isNotEmpty 
          ? transactionsList.last.runningBalance 
          : 0;
      
      print('🔄 CALCULATED SUMMARY FROM TRANSACTIONS:');
      print('   - Calculated Debit: $calculatedTotalDebit');
      print('   - Calculated Credit: $calculatedTotalCredit');
      print('   - Calculated Balance: $calculatedClosingBalance');
    }
    
    return BuyerLedgerData(
      businessDetails: BusinessDetails.fromJson(
          j['businessDetails'] as Map<String, dynamic>? ?? {}),
      buyer: BuyerInfo.fromJson(j['buyer'] as Map<String, dynamic>? ?? {}),
      summary: BuyerLedgerSummary(
        totalDebit: calculatedTotalDebit,
        totalCredit: calculatedTotalCredit,
        closingBalance: calculatedClosingBalance,
      ),
      transactions: transactionsList,
      totalPages: pagination['pages'] ?? 1,
      totalTransactions: pagination['total'] ?? 0,
    );
  }
}

// ─── All Buyers Ledger List Models ───────────────────────────────────────────

class BuyerLedgerListItem {
  final BuyerInfo buyer;
  final BusinessDetails businessDetails;
  final double totalDebit;
  final double totalCredit;
  final double currentBalance;

  BuyerLedgerListItem({
    required this.buyer,
    required this.businessDetails,
    required this.totalDebit,
    required this.totalCredit,
    required this.currentBalance,
  });

  factory BuyerLedgerListItem.fromJson(Map<String, dynamic> j) {
    final buyerMap = j['buyer'] as Map<String, dynamic>? ?? {};
    final businessMap = j['businessDetails'] as Map<String, dynamic>? ?? {};
    
    return BuyerLedgerListItem(
      buyer: BuyerInfo.fromJson(buyerMap),
      businessDetails: BusinessDetails.fromJson(businessMap),
      totalDebit: (j['totalDebit'] ?? 0).toDouble(),
      totalCredit: (j['totalCredit'] ?? 0).toDouble(),
      currentBalance: (j['currentBalance'] ?? 0).toDouble(),
    );
  }
}

class AllBuyersLedgerData {
  final List<BuyerLedgerListItem> buyers;
  final int totalPages;
  final int totalBuyers;
  final int totalTransactions;
  final double overallDebit;
  final double overallCredit;
  final double totalOutstanding;

  AllBuyersLedgerData({
    required this.buyers,
    required this.totalPages,
    required this.totalBuyers,
    required this.totalTransactions,
    required this.overallDebit,
    required this.overallCredit,
    required this.totalOutstanding,
  });

  factory AllBuyersLedgerData.fromJson(Map<String, dynamic> j) {
    final pagination = j['pagination'] as Map<String, dynamic>? ?? {};
    final summary = j['summary'] as Map<String, dynamic>? ?? {};
    
    // Handle both array formats
    List<BuyerLedgerListItem> buyersList = [];
    final buyersData = j['buyers'];
    
    if (buyersData is List) {
      buyersList = buyersData
          .map((b) => BuyerLedgerListItem.fromJson(b as Map<String, dynamic>))
          .toList();
    }
    
    return AllBuyersLedgerData(
      buyers: buyersList,
      totalPages: pagination['pages'] ?? 1,
      totalBuyers: pagination['total'] ?? 0,
      totalTransactions: summary['totalTransactions'] ?? 0,
      overallDebit: (summary['overallDebit'] ?? 0).toDouble(),
      overallCredit: (summary['overallCredit'] ?? 0).toDouble(),
      totalOutstanding: (summary['totalOutstanding'] ?? 0).toDouble(),
    );
  }
}
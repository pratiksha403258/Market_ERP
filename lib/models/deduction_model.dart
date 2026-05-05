// ─────────────────────────────────────────────────────────────
// DEDUCTION MODEL
// ─────────────────────────────────────────────────────────────

class DeductionData {
  double transport;
  double labour;
  double commission;
  String commissionType; // fixed | percent
  double storage;
  String storageNote;
  double returnDeduction;
  String returnNote;
  double advanceAdjusted;
  double other;
  String otherNote;

  DeductionData({
    this.transport = 0,
    this.labour = 0,
    this.commission = 0,
    this.commissionType = 'fixed',
    this.storage = 0,
    this.storageNote = '',
    this.returnDeduction = 0,
    this.returnNote = '',
    this.advanceAdjusted = 0,
    this.other = 0,
    this.otherNote = '',
  });

  Map<String, dynamic> toJson() => {
    'transport': transport,
    'labour': labour,
    'commission': commission,
    'commissionType': commissionType,
    'storage': storage,
    'storageNote': storageNote,
    'returnDeduction': returnDeduction,
    'returnNote': returnNote,
    'advanceAdjusted': advanceAdjusted,
    'other': other,
    'otherNote': otherNote,
  };

  DeductionData copyWith({
    double? transport,
    double? labour,
    double? commission,
    String? commissionType,
    double? storage,
    String? storageNote,
    double? returnDeduction,
    String? returnNote,
    double? advanceAdjusted,
    double? other,
    String? otherNote,
  }) {
    return DeductionData(
      transport: transport ?? this.transport,
      labour: labour ?? this.labour,
      commission: commission ?? this.commission,
      commissionType: commissionType ?? this.commissionType,
      storage: storage ?? this.storage,
      storageNote: storageNote ?? this.storageNote,
      returnDeduction: returnDeduction ?? this.returnDeduction,
      returnNote: returnNote ?? this.returnNote,
      advanceAdjusted: advanceAdjusted ?? this.advanceAdjusted,
      other: other ?? this.other,
      otherNote: otherNote ?? this.otherNote,
    );
  }
}
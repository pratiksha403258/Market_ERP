class SaleModel {
  final String id;
  final String invoiceNumber;
  final String buyerName;
  final String? buyerGst;
  final DateTime saleDate;
  final String productName;
  final double quantity;
  final String unit;
  final double sellingPricePerUnit;
  final double subtotal;
  final double gstPercentage;
  final double gstAmount;
  final double totalAmount;
  final String paymentStatus; // paid, partial, pending
  final String? notes;

  SaleModel({required this.id, required this.invoiceNumber, required this.buyerName, this.buyerGst,
    required this.saleDate, required this.productName, required this.quantity, required this.unit,
    required this.sellingPricePerUnit, required this.subtotal, required this.gstPercentage,
    required this.gstAmount, required this.totalAmount, required this.paymentStatus, this.notes});

  factory SaleModel.fromJson(Map<String, dynamic> j) => SaleModel(
    id: j['_id'], invoiceNumber: j['invoiceNumber'], buyerName: j['buyerName'], buyerGst: j['buyerGst'],
    saleDate: DateTime.parse(j['saleDate']), productName: j['productName'], quantity: j['quantity'],
    unit: j['unit'], sellingPricePerUnit: j['sellingPricePerUnit'], subtotal: j['subtotal'],
    gstPercentage: j['gstPercentage'], gstAmount: j['gstAmount'], totalAmount: j['totalAmount'],
    paymentStatus: j['paymentStatus'], notes: j['notes'],
  );
}
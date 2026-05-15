// class Product {
//   final String id;
//   final String name;
//   final double? defaultRate;
//   final String? unit;

//   Product({required this.id, required this.name, this.defaultRate, this.unit});

//   factory Product.fromJson(Map<String, dynamic> json) {
//     return Product(
//       id: json['id'].toString(),
//       name: json['name'] ?? '',
//       defaultRate: (json['default_rate'] ?? json['rate'] ?? 0).toDouble(),
//       unit: json['unit'],
//     );
//   }
// }
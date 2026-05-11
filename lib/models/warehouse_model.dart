class WarehouseModel {
  final String id;
  final String name;
  final String code;
  final bool isActive;
  final Map<String, dynamic> location;
  final Map<String, dynamic> manager;
  final Map<String, dynamic> capacity;
  final String notes;

  WarehouseModel({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
    required this.location,
    required this.manager,
    required this.capacity,
    required this.notes,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      isActive: json['isActive'] as bool,
      location: json['location'] as Map<String, dynamic>,
      manager: json['manager'] as Map<String, dynamic>,
      capacity: json['capacity'] as Map<String, dynamic>,
      notes: json['notes'] ?? '',
    );
  }

  get inventory => null;

  get occupiedSpace => null;

  get totalItems => null;
}
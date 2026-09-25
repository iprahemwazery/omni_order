/// حالة التريبية في المطعم.
enum TableStatus {
  available('فارغة'),
  occupied('مشغولة'),
  reserved('محجوزة'),
  cleaning('تنظيف');

  const TableStatus(this.label);

  final String label;

  static TableStatus fromName(String? name) {
    for (final status in values) {
      if (status.name == name) return status;
    }
    return TableStatus.available;
  }
}

/// تريبية داخل صالة المطعم.
class RestaurantTable {
  final int? id;
  final int hallId;
  final int number;
  final int capacity;
  final TableStatus status;
  final int? currentOrderId;
  final DateTime createdAt;

  RestaurantTable({
    this.id,
    required this.hallId,
    required this.number,
    this.capacity = 4,
    this.status = TableStatus.available,
    this.currentOrderId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  RestaurantTable copyWith({
    int? id,
    int? hallId,
    int? number,
    int? capacity,
    TableStatus? status,
    int? currentOrderId,
    DateTime? createdAt,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      hallId: hallId ?? this.hallId,
      number: number ?? this.number,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'hall_id': hallId,
        'number': number,
        'capacity': capacity,
        'status': status.name,
        if (currentOrderId != null) 'current_order_id': currentOrderId,
        'created_at': createdAt.toIso8601String(),
      };

  factory RestaurantTable.fromMap(Map<String, Object?> map) {
    return RestaurantTable(
      id: map['id'] as int?,
      hallId: map['hall_id'] as int,
      number: map['number'] as int,
      capacity: map['capacity'] as int? ?? 4,
      status: TableStatus.fromName(map['status'] as String?),
      currentOrderId: map['current_order_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RestaurantTable && other.id == id && other.number == number;

  @override
  int get hashCode => Object.hash(id, number);
}

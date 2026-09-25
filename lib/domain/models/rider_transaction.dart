/// نوع معاملة المندوب.
enum RiderTransactionType {
  orderCollection('تحصيل أوردر'),
  settlement('تسديد'),
  advance('سلفة');

  const RiderTransactionType(this.label);

  final String label;

  static RiderTransactionType fromName(String? name) {
    for (final type in values) {
      if (type.name == name) return type;
    }
    return RiderTransactionType.orderCollection;
  }
}

/// معاملة مالية للمندوب (تحصيل / تسديد / سلفة).
class RiderTransaction {
  final int? id;
  final int riderId;
  final RiderTransactionType type;
  final double amount;
  final int? orderId;
  final String note;
  final DateTime createdAt;

  RiderTransaction({
    this.id,
    required this.riderId,
    required this.type,
    required this.amount,
    this.orderId,
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  RiderTransaction copyWith({
    int? id,
    int? riderId,
    RiderTransactionType? type,
    double? amount,
    int? orderId,
    String? note,
    DateTime? createdAt,
  }) {
    return RiderTransaction(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      orderId: orderId ?? this.orderId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'rider_id': riderId,
        'type': type.name,
        'amount': amount,
        if (orderId != null) 'order_id': orderId,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };

  factory RiderTransaction.fromMap(Map<String, Object?> map) {
    return RiderTransaction(
      id: map['id'] as int?,
      riderId: map['rider_id'] as int,
      type: RiderTransactionType.fromName(map['type'] as String?),
      amount: (map['amount'] as num).toDouble(),
      orderId: map['order_id'] as int?,
      note: map['note'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

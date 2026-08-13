/// دفعة سداد من عميل على مديونيته — تُسجل وتُغير رصيد العميل.
class CustomerPayment {
  final int? id;
  final int customerId;
  final double amount;
  final DateTime createdAt;

  CustomerPayment({
    this.id,
    required this.customerId,
    required this.amount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  CustomerPayment copyWith({
    int? id,
    int? customerId,
    double? amount,
    DateTime? createdAt,
  }) {
    return CustomerPayment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'customer_id': customerId,
        'amount': amount,
        'created_at': createdAt.toIso8601String(),
      };

  factory CustomerPayment.fromMap(Map<String, Object?> map) {
    return CustomerPayment(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
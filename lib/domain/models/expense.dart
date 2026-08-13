/// مصروف يومي مسجّل (إيجار، كهرباء، مشتريات...).
class Expense {
  final int? id;
  final String name;
  final double amount;
  final DateTime createdAt;

  Expense({
    this.id,
    required this.name,
    required this.amount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Expense copyWith({
    int? id,
    String? name,
    double? amount,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'amount': amount,
        'created_at': createdAt.toIso8601String(),
      };

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id'] as int?,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// عميل مع رصيد مديونية (يرتفع مع البيع "آجل" وينخفض عند السداد).
class Customer {
  final int? id;
  final String name;
  final String phone;
  final double balance;
  final DateTime createdAt;

  Customer({
    this.id,
    required this.name,
    this.phone = '',
    this.balance = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    double? balance,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'balance': balance,
        'created_at': createdAt.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, Object?> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String? ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// عميل في المطعم.
class Customer {
  final int? id;
  final String name;
  final String phone;
  final String address;
  final double balance;
  final int loyaltyPoints;
  final String notes;
  final DateTime createdAt;

  Customer({
    this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.balance = 0,
    this.loyaltyPoints = 0,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    double? balance,
    int? loyaltyPoints,
    String? notes,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'balance': balance,
        'loyalty_points': loyaltyPoints,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, Object?> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      loyaltyPoints: map['loyalty_points'] as int? ?? 0,
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

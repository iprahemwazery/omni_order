/// مورد يورّد البضاعة إلى المتجر.
class Supplier {
  final int? id;
  final String name;
  final String phone;
  final String address;
  final double balance;
  final DateTime createdAt;

  Supplier({
    this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.balance = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Supplier copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    double? balance,
    DateTime? createdAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'phone': phone,
    'address': address,
    'balance': balance,
    'created_at': createdAt.toIso8601String(),
  };

  factory Supplier.fromMap(Map<String, Object?> map) {
    return Supplier(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

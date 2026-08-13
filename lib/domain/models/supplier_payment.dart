/// عملية سداد أو دفعة للمورد — تُخصّص لفاتورة شراء محددة عند الإمكان.
class SupplierPayment {
  final int? id;
  final int supplierId;
  final double amount;
  final int? purchaseId;
  final DateTime createdAt;

  SupplierPayment({
    this.id,
    required this.supplierId,
    required this.amount,
    this.purchaseId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  SupplierPayment copyWith({
    int? id,
    int? supplierId,
    double? amount,
    int? purchaseId,
    DateTime? createdAt,
  }) {
    return SupplierPayment(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      amount: amount ?? this.amount,
      purchaseId: purchaseId ?? this.purchaseId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'supplier_id': supplierId,
        'amount': amount,
        if (purchaseId != null) 'purchase_id': purchaseId,
        'created_at': createdAt.toIso8601String(),
      };

  factory SupplierPayment.fromMap(Map<String, Object?> map) {
    return SupplierPayment(
      id: map['id'] as int?,
      supplierId: map['supplier_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      purchaseId: map['purchase_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

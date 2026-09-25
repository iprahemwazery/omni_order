/// دفعة سداد لمورد.
class SupplierPayment {
  final int? id;
  final int supplierId;
  final int? purchaseId;
  final double amount;
  final DateTime createdAt;

  SupplierPayment({
    this.id,
    required this.supplierId,
    this.purchaseId,
    required this.amount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'supplier_id': supplierId,
        if (purchaseId != null) 'purchase_id': purchaseId,
        'amount': amount,
        'created_at': createdAt.toIso8601String(),
      };

  factory SupplierPayment.fromMap(Map<String, Object?> map) {
    return SupplierPayment(
      id: map['id'] as int?,
      supplierId: map['supplier_id'] as int,
      purchaseId: map['purchase_id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

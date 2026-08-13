/// فاتورة شراء/توريد (مشتريات) — تسجيل البضاعة القادمة للمخزون.
class Purchase {
  final int? id;
  final int? supplierId;
  final String supplierName;
  final double total;
  final double paidAmount;
  final String note;
  final DateTime createdAt;

  Purchase({
    this.id,
    this.supplierId,
    this.supplierName = '',
    required this.total,
    this.paidAmount = 0,
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Purchase copyWith({
    int? id,
    int? supplierId,
    String? supplierName,
    double? total,
    double? paidAmount,
    String? note,
    DateTime? createdAt,
  }) {
    return Purchase(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    if (supplierId != null) 'supplier_id': supplierId,
    'supplier_name': supplierName,
    'total': total,
    'paid_amount': paidAmount,
    if (note.isNotEmpty) 'note': note,
    'created_at': createdAt.toIso8601String(),
  };

  double get remainingBalance =>
      (total - paidAmount).clamp(0.0, double.infinity);

  bool get isFullyPaid => remainingBalance <= 0;

  factory Purchase.fromMap(Map<String, Object?> map) {
    return Purchase(
      id: map['id'] as int?,
      supplierId: map['supplier_id'] as int?,
      supplierName: map['supplier_name'] as String? ?? '',
      total: (map['total'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      note: map['note'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

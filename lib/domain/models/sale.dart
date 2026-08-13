/// كيان عملية بيع (فاتورة) كاملة.
class Sale {
  final int? id;
  final int invoiceNumber;
  final double total;
  final int itemsCount;
  final double discount;
  final String paymentMethod;
  final int? customerId;
  final String cashierName;
  final String note;
  final bool refunded;
  final DateTime createdAt;

  Sale({
    this.id,
    this.invoiceNumber = 0,
    required this.total,
    required this.itemsCount,
    this.discount = 0,
    this.paymentMethod = 'نقدي',
    this.customerId,
    this.cashierName = '',
    this.note = '',
    this.refunded = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'invoice_number': invoiceNumber,
        'total': total,
        'items_count': itemsCount,
        'discount': discount,
        'payment_method': paymentMethod,
        if (customerId != null) 'customer_id': customerId,
        if (cashierName.isNotEmpty) 'cashier_name': cashierName,
        if (note.isNotEmpty) 'note': note,
        'refunded': refunded ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  Sale copyWith({
    int? id,
    int? invoiceNumber,
    double? total,
    int? itemsCount,
    double? discount,
    String? paymentMethod,
    int? customerId,
    String? cashierName,
    String? note,
    bool? refunded,
    DateTime? createdAt,
  }) {
    return Sale(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      total: total ?? this.total,
      itemsCount: itemsCount ?? this.itemsCount,
      discount: discount ?? this.discount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerId: customerId ?? this.customerId,
      cashierName: cashierName ?? this.cashierName,
      note: note ?? this.note,
      refunded: refunded ?? this.refunded,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Sale.fromMap(Map<String, Object?> map) {
    return Sale(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as int? ?? 0,
      total: (map['total'] as num).toDouble(),
      itemsCount: map['items_count'] as int,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'] as String? ?? 'نقدي',
      customerId: map['customer_id'] as int?,
      cashierName: map['cashier_name'] as String? ?? '',
      note: map['note'] as String? ?? '',
      refunded: (map['refunded'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

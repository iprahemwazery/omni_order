import '../../core/constants/payment_methods.dart';

/// كيان عملية بيع (فاتورة) كاملة.
class Sale {
  final int? id;
  final int invoiceNumber;
  final double total;
  final int itemsCount;
  final double discount;
  final double taxRate;
  final double taxAmount;
  final String paymentMethod;
  final int? customerId;
  final String cashierName;
  final String note;
  final bool refunded;
  final DateTime createdAt;

  /// توقيت تسجيل المرتجع (يُستخدم لإسناد المرتجع إلى الوردية التي حدث فيها).
  final DateTime? refundedAt;

  /// المبلغ الذي دفعه العميل فعليًا (لحساب الباقي). صفر = لم يُسجل.
  final double amountTendered;

  /// الجزء المدفوع بالشبكة في حالة الدفع المختلط (نقدي + شبكة).
  final double cardAmount;

  Sale({
    this.id,
    this.invoiceNumber = 0,
    required this.total,
    required this.itemsCount,
    this.discount = 0,
    this.taxRate = 0,
    this.taxAmount = 0,
    this.paymentMethod = PaymentMethod.cash,
    this.customerId,
    this.cashierName = '',
    this.note = '',
    this.refunded = false,
    this.amountTendered = 0,
    this.cardAmount = 0,
    this.refundedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// الباقي للعميل (ما يُرجع نقدًا) عند الدفع بمبلغ أكبر من الصافي.
  double get changeDue =>
      (amountTendered - total).clamp(0, double.infinity);

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'invoice_number': invoiceNumber,
        'total': total,
        'items_count': itemsCount,
        'discount': discount,
        'tax_rate': taxRate,
        'tax_amount': taxAmount,
        'payment_method': paymentMethod,
        if (customerId != null) 'customer_id': customerId,
        if (cashierName.isNotEmpty) 'cashier_name': cashierName,
        if (note.isNotEmpty) 'note': note,
        'refunded': refunded ? 1 : 0,
        'amount_tendered': amountTendered,
        'card_amount': cardAmount,
        if (refundedAt != null) 'refunded_at': refundedAt!.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  Sale copyWith({
    int? id,
    int? invoiceNumber,
    double? total,
    int? itemsCount,
    double? discount,
    double? taxRate,
    double? taxAmount,
    String? paymentMethod,
    int? customerId,
    String? cashierName,
    String? note,
    bool? refunded,
    double? amountTendered,
    double? cardAmount,
    DateTime? refundedAt,
    DateTime? createdAt,
  }) {
    return Sale(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      total: total ?? this.total,
      itemsCount: itemsCount ?? this.itemsCount,
      discount: discount ?? this.discount,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerId: customerId ?? this.customerId,
      cashierName: cashierName ?? this.cashierName,
      note: note ?? this.note,
      refunded: refunded ?? this.refunded,
      amountTendered: amountTendered ?? this.amountTendered,
      cardAmount: cardAmount ?? this.cardAmount,
      refundedAt: refundedAt ?? this.refundedAt,
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
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'] as String? ?? PaymentMethod.cash,
      customerId: map['customer_id'] as int?,
      cashierName: map['cashier_name'] as String? ?? '',
      note: map['note'] as String? ?? '',
      refunded: (map['refunded'] as int? ?? 0) == 1,
      amountTendered: (map['amount_tendered'] as num?)?.toDouble() ?? 0,
      cardAmount: (map['card_amount'] as num?)?.toDouble() ?? 0,
      refundedAt: map['refunded_at'] == null
          ? null
          : DateTime.tryParse(map['refunded_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// وردية عمل كاشير: تبدأ عند أول عملية بيع وتُغلق يدويًا من تقرير الوردية.
class Shift {
  final int? id;
  final String cashierName;
  final DateTime openedAt;
  final DateTime? closedAt;

  Shift({
    this.id,
    required this.cashierName,
    required this.openedAt,
    this.closedAt,
  });

  bool get isOpen => closedAt == null;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'cashier_name': cashierName,
        'opened_at': openedAt.toIso8601String(),
        if (closedAt != null) 'closed_at': closedAt!.toIso8601String(),
      };

  factory Shift.fromMap(Map<String, Object?> map) {
    return Shift(
      id: map['id'] as int?,
      cashierName: map['cashier_name'] as String,
      openedAt: DateTime.parse(map['opened_at'] as String),
      closedAt: map['closed_at'] == null
          ? null
          : DateTime.tryParse(map['closed_at'] as String),
    );
  }

  Shift copyWith({int? id, DateTime? closedAt}) {
    return Shift(
      id: id ?? this.id,
      cashierName: cashierName,
      openedAt: openedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}

/// تقرير الوردية (Z-Report): ملخص مبيعات كاشير خلال وردية محددة.
class ShiftReport {
  final Shift shift;

  /// عدد الفواتير غير المرتجعة في الوردية.
  final int salesCount;

  /// عدد عمليات المرتجع في الوردية.
  final int refundCount;

  final double cashTotal;
  final double cardTotal;
  final double walletTotal;
  final double transferTotal;
  final double mixedTotal;

  /// الجزء المدفوع بالشبكة من فواتير الدفع المختلط.
  final double mixedCardPortion;

  final double deferredTotal;

  /// إجمالي الباقي الذي رُدّ للعملاء (المدفوع نقدًا أزيد من الصافي).
  final double changeGiven;

  /// إجمالي قيمة الفواتير المرتجعة.
  final double refundsTotal;

  ShiftReport({
    required this.shift,
    required this.salesCount,
    required this.refundCount,
    required this.cashTotal,
    required this.cardTotal,
    required this.walletTotal,
    required this.transferTotal,
    required this.mixedTotal,
    required this.mixedCardPortion,
    required this.deferredTotal,
    required this.changeGiven,
    required this.refundsTotal,
  });

  /// النقدي من الدفع المختلط.
  double get mixedCashPortion => mixedTotal - mixedCardPortion;

  /// إجمالي مبيعات الوردية (كل الطرق غير المرتجعة).
  double get totalSales =>
      cashTotal + cardTotal + walletTotal + transferTotal + mixedTotal +
      deferredTotal;

  /// النقد المتوقع في الصندوق (نقدي + الجزء النقدي من المختلط).
  double get cashReceived => cashTotal + mixedCashPortion;

  /// محصلات الشبكة المتوقعة (شبكة + الجزء الشبكي من المختلط).
  double get cardReceived => cardTotal + mixedCardPortion;
}

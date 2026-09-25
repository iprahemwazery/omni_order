import '../../core/constants/payment_methods.dart';

/// حالة الطلب في المطعم.
enum OrderStatus {
  pending('قيد الانتظار'),
  preparing('قيد التحضير'),
  ready('جاهز'),
  served('تم التقديم'),
  outForDelivery('في الطريق'),
  delivered('تم التوصيل'),
  handedOver('تم التسليم'),
  awaitingPayment('بانتظار الدفع'),
  paid('مدفوع'),
  cancelled('ملغي');

  const OrderStatus(this.label);

  final String label;

  static OrderStatus fromName(String? name) {
    for (final status in values) {
      if (status.name == name) return status;
    }
    return OrderStatus.pending;
  }
}

/// نوع الطلب.
enum OrderType {
  hall('صاله'),
  takeaway('تليفريسي'),
  delivery('توصيل');

  const OrderType(this.label);

  final String label;

  static OrderType fromName(String? name) {
    for (final type in values) {
      if (type.name == name) return type;
    }
    return OrderType.hall;
  }
}

/// طلب في المطعم (مرتبط بتريبية أو take-away أو توصيل).
class RestaurantOrder {
  final int? id;
  final int? tableId;
  final int? hallId;
  final int? employeeId;
  final int? riderId;
  final String status;
  final String orderType;
  final double total;
  final double discount;
  final double taxRate;
  final double taxAmount;
  final String paymentMethod;
  final String cashierName;
  final String note;
  final bool isTakeaway;
  final bool refunded;
  final DateTime? refundedAt;
  final double amountTendered;
  final double cardAmount;
  final DateTime? completedAt;
  final DateTime createdAt;
  final String deliveryAddress;
  final String deliveryPhone;
  final String deliveryNotes;
  final String deliveryPersonName;
  final double deliveryFee;

  RestaurantOrder({
    this.id,
    this.tableId,
    this.hallId,
    this.employeeId,
    this.riderId,
    String? status,
    String? orderType,
    required this.total,
    this.discount = 0,
    this.taxRate = 0,
    this.taxAmount = 0,
    this.paymentMethod = PaymentMethod.cash,
    this.cashierName = '',
    this.note = '',
    this.isTakeaway = false,
    this.refunded = false,
    this.amountTendered = 0,
    this.cardAmount = 0,
    this.refundedAt,
    this.completedAt,
    this.deliveryAddress = '',
    this.deliveryPhone = '',
    this.deliveryNotes = '',
    this.deliveryPersonName = '',
    this.deliveryFee = 0,
    DateTime? createdAt,
  })  : status = status ?? 'pending',
        orderType = orderType ?? OrderType.hall.name,
        createdAt = createdAt ?? DateTime.now();

  OrderStatus get orderStatus => OrderStatus.fromName(status);
  OrderType get type => OrderType.fromName(orderType);

  double get changeDue =>
      (amountTendered - total).clamp(0, double.infinity);

  bool get isDelivery => orderType == OrderType.delivery.name;

  RestaurantOrder copyWith({
    int? id,
    int? tableId,
    int? hallId,
    int? employeeId,
    int? riderId,
    String? status,
    String? orderType,
    double? total,
    double? discount,
    double? taxRate,
    double? taxAmount,
    String? paymentMethod,
    String? cashierName,
    String? note,
    bool? isTakeaway,
    bool? refunded,
    double? amountTendered,
    double? cardAmount,
    DateTime? refundedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    String? deliveryAddress,
    String? deliveryPhone,
    String? deliveryNotes,
    String? deliveryPersonName,
    double? deliveryFee,
  }) {
    return RestaurantOrder(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      hallId: hallId ?? this.hallId,
      employeeId: employeeId ?? this.employeeId,
      riderId: riderId ?? this.riderId,
      status: status ?? this.status,
      orderType: orderType ?? this.orderType,
      total: total ?? this.total,
      discount: discount ?? this.discount,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashierName: cashierName ?? this.cashierName,
      note: note ?? this.note,
      isTakeaway: isTakeaway ?? this.isTakeaway,
      refunded: refunded ?? this.refunded,
      amountTendered: amountTendered ?? this.amountTendered,
      cardAmount: cardAmount ?? this.cardAmount,
      refundedAt: refundedAt ?? this.refundedAt,
      completedAt: completedAt ?? this.completedAt,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryPhone: deliveryPhone ?? this.deliveryPhone,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      deliveryPersonName: deliveryPersonName ?? this.deliveryPersonName,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        if (tableId != null) 'table_id': tableId,
        if (hallId != null) 'hall_id': hallId,
        if (employeeId != null) 'employee_id': employeeId,
        if (riderId != null) 'rider_id': riderId,
        'status': status,
        'order_type': orderType,
        'total': total,
        'discount': discount,
        'tax_rate': taxRate,
        'tax_amount': taxAmount,
        'payment_method': paymentMethod,
        if (cashierName.isNotEmpty) 'cashier_name': cashierName,
        if (note.isNotEmpty) 'note': note,
        'is_takeaway': isTakeaway ? 1 : 0,
        'refunded': refunded ? 1 : 0,
        'amount_tendered': amountTendered,
        'card_amount': cardAmount,
        if (refundedAt != null) 'refunded_at': refundedAt!.toIso8601String(),
        if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
        if (deliveryAddress.isNotEmpty)
          'delivery_address': deliveryAddress,
        if (deliveryPhone.isNotEmpty) 'delivery_phone': deliveryPhone,
        if (deliveryNotes.isNotEmpty) 'delivery_notes': deliveryNotes,
        if (deliveryPersonName.isNotEmpty)
          'delivery_person_name': deliveryPersonName,
        if (deliveryFee > 0) 'delivery_fee': deliveryFee,
        'created_at': createdAt.toIso8601String(),
      };

  factory RestaurantOrder.fromMap(Map<String, Object?> map) {
    return RestaurantOrder(
      id: map['id'] as int?,
      tableId: map['table_id'] as int?,
      hallId: map['hall_id'] as int?,
      employeeId: map['employee_id'] as int?,
      riderId: map['rider_id'] as int?,
      status: map['status'] as String? ?? OrderStatus.pending.name,
      orderType: map['order_type'] as String? ?? OrderType.hall.name,
      total: (map['total'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'] as String? ?? PaymentMethod.cash,
      cashierName: map['cashier_name'] as String? ?? '',
      note: map['note'] as String? ?? '',
      isTakeaway: (map['is_takeaway'] as int? ?? 0) == 1,
      refunded: (map['refunded'] as int? ?? 0) == 1,
      amountTendered: (map['amount_tendered'] as num?)?.toDouble() ?? 0,
      cardAmount: (map['card_amount'] as num?)?.toDouble() ?? 0,
      refundedAt: map['refunded_at'] == null
          ? null
          : DateTime.tryParse(map['refunded_at'] as String),
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.parse(map['completed_at'] as String),
      deliveryAddress: map['delivery_address'] as String? ?? '',
      deliveryPhone: map['delivery_phone'] as String? ?? '',
      deliveryNotes: map['delivery_notes'] as String? ?? '',
      deliveryPersonName: map['delivery_person_name'] as String? ?? '',
      deliveryFee: (map['delivery_fee'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

import '../../core/constants/payment_methods.dart';

/// سلة تم تعليقها (Hold Invoice) — تُحفظ محليًا في SQLite لإكمالها لاحقًا.
class HeldCart {
  final int? id;
  final DateTime savedAt;
  final double discount;
  final String paymentMethod;
  final int? customerId;
  final String note;
  final String cashierName;
  final int itemsCount;
  final double total;

  HeldCart({
    this.id,
    required this.savedAt,
    this.discount = 0,
    this.paymentMethod = PaymentMethod.cash,
    this.customerId,
    this.note = '',
    this.cashierName = '',
    required this.itemsCount,
    required this.total,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'saved_at': savedAt.toIso8601String(),
        'discount': discount,
        'payment_method': paymentMethod,
        if (customerId != null) 'customer_id': customerId,
        if (note.isNotEmpty) 'note': note,
        if (cashierName.isNotEmpty) 'cashier_name': cashierName,
        'items_count': itemsCount,
        'total': total,
      };

  factory HeldCart.fromMap(Map<String, Object?> map) {
    return HeldCart(
      id: map['id'] as int?,
      savedAt: DateTime.parse(map['saved_at'] as String),
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'] as String? ?? PaymentMethod.cash,
      customerId: map['customer_id'] as int?,
      note: map['note'] as String? ?? '',
      cashierName: map['cashier_name'] as String? ?? '',
      itemsCount: map['items_count'] as int? ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// بند من سلة معلقة (لقطة من الصنف وقت التعليق).
class HeldCartItem {
  final int? id;
  final int heldCartId;
  final int? productId;
  final String name;
  final double price;
  final double costPrice;
  final double quantity;
  final double subtotal;

  HeldCartItem({
    this.id,
    this.heldCartId = 0,
    this.productId,
    required this.name,
    required this.price,
    this.costPrice = 0,
    required this.quantity,
    required this.subtotal,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'held_cart_id': heldCartId,
        if (productId != null) 'product_id': productId,
        'name': name,
        'price': price,
        'cost_price': costPrice,
        'quantity': quantity,
        'subtotal': subtotal,
      };

  factory HeldCartItem.fromMap(Map<String, Object?> map) {
    return HeldCartItem(
      id: map['id'] as int?,
      heldCartId: map['held_cart_id'] as int? ?? 0,
      productId: map['product_id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }
}

/// بند داخل طلب المطعم.
class OrderItem {
  final int? id;
  final int orderId;
  final int productId;
  final String name;
  final double price;
  final double quantity;
  final double subtotal;
  final String notes;
  final String status;

  const OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.notes = '',
    this.status = 'pending',
  });

  OrderItem copyWith({
    int? id,
    int? orderId,
    int? productId,
    String? name,
    double? price,
    double? quantity,
    double? subtotal,
    String? notes,
    String? status,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'order_id': orderId,
        'product_id': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'subtotal': subtotal,
        'notes': notes,
        'status': status,
      };

  factory OrderItem.fromMap(Map<String, Object?> map) {
    return OrderItem(
      id: map['id'] as int?,
      orderId: map['order_id'] as int,
      productId: map['product_id'] as int,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
      notes: map['notes'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
    );
  }
}

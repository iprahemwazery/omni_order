/// سطر داخل فاتورة شراء (صنف + الكمية + سعر الشراء).
class PurchaseItem {
  final int? id;
  final int purchaseId;
  final int productId;
  final String name;
  final double quantity;
  final double price;
  final double subtotal;

  const PurchaseItem({
    this.id,
    required this.purchaseId,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'purchase_id': purchaseId,
        'product_id': productId,
        'name': name,
        'quantity': quantity,
        'price': price,
        'subtotal': subtotal,
      };

  factory PurchaseItem.fromMap(Map<String, Object?> map) {
    return PurchaseItem(
      id: map['id'] as int?,
      purchaseId: map['purchase_id'] as int,
      productId: map['product_id'] as int,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      price: (map['price'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }
}
/// سطر داخل فاتورة البيع (صنف مباع + كميته + سعره + تكلفة).
class SaleItem {
  final int? id;
  final int saleId;
  final int productId;
  final String name;
  final double price;
  final double costPrice;
  final double quantity;
  final double subtotal;

  const SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.name,
    required this.price,
    this.costPrice = 0,
    required this.quantity,
    required this.subtotal,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'sale_id': saleId,
        'product_id': productId,
        'name': name,
        'price': price,
        'cost_price': costPrice,
        'quantity': quantity,
        'subtotal': subtotal,
      };

  factory SaleItem.fromMap(Map<String, Object?> map) {
    return SaleItem(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int,
      productId: map['product_id'] as int,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }
}

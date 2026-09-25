/// بند في فاتورة شراء.
class PurchaseItem {
  final int? id;
  final int purchaseId;
  final int? productId;
  final String name;

  /// الكمية بوحدة الشراء المختارة (مثل: 8 كراتين).
  final double quantity;

  /// سعر الوحدة الواحدة من وحدة الشراء (سعر الكرتونة مثلًا).
  final double price;
  final double subtotal;

  /// وحدة الشراء المستخدمة في البند (كرتونة، قطعة...). فارغة = وحدة الصنف الأساسية.
  final String unit;

  /// معامل التحويل إلى وحدات المخزون الأساسية (كرتونة = 24 قطعة).
  /// 1 يعني الشراء مباشرة بوحدة المخزون.
  final double conversionFactor;

  PurchaseItem({
    this.id,
    required this.purchaseId,
    this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    double? subtotal,
    this.unit = '',
    this.conversionFactor = 1,
  })  : assert(conversionFactor > 0, 'conversionFactor must be positive'),
        subtotal = subtotal ?? (quantity * price);

  /// الكمية التي ستُضاف فعليًا للمخزون بوحدة الصنف الأساسية.
  double get stockQuantity => quantity * conversionFactor;

  /// تكلفة الوحدة الأساسية الواحدة (سعر القطعة داخل الكرتونة مثلًا).
  double get baseUnitCost => conversionFactor > 0 ? price / conversionFactor : price;

  PurchaseItem copyWith({
    int? id,
    int? purchaseId,
    int? productId,
    String? name,
    double? quantity,
    double? price,
    double? subtotal,
    String? unit,
    double? conversionFactor,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
      unit: unit ?? this.unit,
      conversionFactor: conversionFactor ?? this.conversionFactor,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'purchase_id': purchaseId,
        if (productId != null) 'product_id': productId,
        'name': name,
        'quantity': quantity,
        'price': price,
        'subtotal': subtotal,
        'unit': unit,
        'conversion_factor': conversionFactor,
      };

  factory PurchaseItem.fromMap(Map<String, Object?> map) {
    return PurchaseItem(
      id: map['id'] as int?,
      purchaseId: map['purchase_id'] as int,
      productId: map['product_id'] as int?,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      price: (map['price'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
      unit: map['unit'] as String? ?? '',
      conversionFactor: (map['conversion_factor'] as num?)?.toDouble() ?? 1,
    );
  }
}

/// كيان صنف/منتج داخل المتجر.
class Product {
  final int? id;
  final String name;
  final double price;
  final double stock;
  final String unit;
  final int? categoryId;
  final double costPrice;
  final double lowStockThreshold;
  final String barcode;
  final DateTime createdAt;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.unit = 'قطعة',
    this.categoryId,
    this.costPrice = 0,
    this.lowStockThreshold = 0,
    this.barcode = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Product copyWith({
    int? id,
    String? name,
    double? price,
    double? stock,
    String? unit,
    int? categoryId,
    double? costPrice,
    double? lowStockThreshold,
    String? barcode,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      categoryId: categoryId ?? this.categoryId,
      costPrice: costPrice ?? this.costPrice,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'price': price,
        'stock': stock,
        'unit': unit,
        if (categoryId != null) 'category_id': categoryId,
        'cost_price': costPrice,
        'low_stock_threshold': lowStockThreshold,
        if (barcode.isNotEmpty) 'barcode': barcode,
        'created_at': createdAt.toIso8601String(),
      };

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      stock: (map['stock'] as num).toDouble(),
      unit: map['unit'] as String? ?? 'قطعة',
      categoryId: map['category_id'] as int?,
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0,
      lowStockThreshold: (map['low_stock_threshold'] as num?)?.toDouble() ?? 0,
      barcode: map['barcode'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Product &&
      other.id == id &&
      other.name == name &&
      other.price == price &&
      other.stock == stock &&
      other.unit == unit &&
      other.categoryId == categoryId &&
      other.costPrice == costPrice &&
      other.lowStockThreshold == lowStockThreshold &&
      other.barcode == barcode &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, price, stock, unit, categoryId,
      costPrice, lowStockThreshold, barcode, createdAt);
}

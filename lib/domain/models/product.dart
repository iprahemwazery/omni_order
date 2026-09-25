/// كيان صنف/منتج في قائمة الطعام (أو مادة خام للمخزون).
class Product {
  final int? id;
  final String name;
  final double price;
  final double halfPrice;
  final double stock;
  final String unit;
  final int? categoryId;
  final double costPrice;
  final double lowStockThreshold;
  final String barcode;
  final bool isAvailable;
  final int preparationTime;
  final bool isRawMaterial;
  final String imagePath;

  /// وصف الصنف (مكونات الوجبة مثلًا) يظهر في المنيو تحت الاسم.
  final String description;

  /// وحدة الشراء بالجملة (مثل: كرتونة، علبة). فارغة = الشراء بالوحدة الأساسية فقط.
  final String packageUnit;

  /// عدد الوحدات الأساسية داخل العبوة الواحدة (مثل: كرتونة فيها 24 قطعة).
  final double unitsPerPackage;
  final DateTime createdAt;

  Product({
    this.id,
    required this.name,
    required this.price,
    this.halfPrice = 0,
    required this.stock,
    this.unit = 'قطعة',
    this.categoryId,
    this.costPrice = 0,
    this.lowStockThreshold = 0,
    this.barcode = '',
    this.isAvailable = true,
    this.preparationTime = 0,
    this.isRawMaterial = false,
    this.imagePath = '',
    this.description = '',
    this.packageUnit = '',
    this.unitsPerPackage = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// هل الصنف يدعم الشراء بالعبوة (كرتونة/علبة...)؟
  bool get hasPackage => packageUnit.trim().isNotEmpty && unitsPerPackage > 0;

  Product copyWith({
    int? id,
    String? name,
    double? price,
    double? halfPrice,
    double? stock,
    String? unit,
    int? categoryId,
    double? costPrice,
    double? lowStockThreshold,
    String? barcode,
    bool? isAvailable,
    int? preparationTime,
    bool? isRawMaterial,
    String? imagePath,
    String? description,
    String? packageUnit,
    double? unitsPerPackage,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      halfPrice: halfPrice ?? this.halfPrice,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      categoryId: categoryId ?? this.categoryId,
      costPrice: costPrice ?? this.costPrice,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      barcode: barcode ?? this.barcode,
      isAvailable: isAvailable ?? this.isAvailable,
      preparationTime: preparationTime ?? this.preparationTime,
      isRawMaterial: isRawMaterial ?? this.isRawMaterial,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      packageUnit: packageUnit ?? this.packageUnit,
      unitsPerPackage: unitsPerPackage ?? this.unitsPerPackage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'price': price,
        'half_price': halfPrice,
        'stock': stock,
        'unit': unit,
        if (categoryId != null) 'category_id': categoryId,
        'cost_price': costPrice,
        'low_stock_threshold': lowStockThreshold,
        if (barcode.isNotEmpty) 'barcode': barcode,
        'is_available': isAvailable ? 1 : 0,
        'preparation_time': preparationTime,
        'is_raw_material': isRawMaterial ? 1 : 0,
        'image_path': imagePath,
        'description': description,
        'package_unit': packageUnit,
        'units_per_package': unitsPerPackage,
        'created_at': createdAt.toIso8601String(),
      };

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      halfPrice: (map['half_price'] as num?)?.toDouble() ?? 0,
      stock: (map['stock'] as num).toDouble(),
      unit: map['unit'] as String? ?? 'قطعة',
      categoryId: map['category_id'] as int?,
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0,
      lowStockThreshold: (map['low_stock_threshold'] as num?)?.toDouble() ?? 0,
      barcode: map['barcode'] as String? ?? '',
      isAvailable: (map['is_available'] as int? ?? 1) == 1,
      preparationTime: map['preparation_time'] as int? ?? 0,
      isRawMaterial: (map['is_raw_material'] as int? ?? 0) == 1,
      imagePath: map['image_path'] as String? ?? '',
      description: map['description'] as String? ?? '',
      packageUnit: map['package_unit'] as String? ?? '',
      unitsPerPackage: (map['units_per_package'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  bool get hasHalfPrice => halfPrice > 0;

  @override
  bool operator ==(Object other) =>
      other is Product &&
      other.id == id &&
      other.name == name &&
      other.price == price &&
      other.halfPrice == halfPrice &&
      other.stock == stock &&
      other.unit == unit &&
      other.categoryId == categoryId &&
      other.costPrice == costPrice &&
      other.lowStockThreshold == lowStockThreshold &&
      other.barcode == barcode &&
      other.isAvailable == isAvailable &&
      other.preparationTime == preparationTime &&
      other.isRawMaterial == isRawMaterial &&
      other.imagePath == imagePath &&
      other.description == description &&
      other.packageUnit == packageUnit &&
      other.unitsPerPackage == unitsPerPackage &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
      id,
      name,
      price,
      halfPrice,
      stock,
      unit,
      categoryId,
      costPrice,
      lowStockThreshold,
      barcode,
      isAvailable,
      preparationTime,
      isRawMaterial,
      imagePath,
      description,
      packageUnit,
      unitsPerPackage,
      createdAt);
}

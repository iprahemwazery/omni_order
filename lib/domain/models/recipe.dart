/// وصفة صنف (ربط المنتج بخاماته).
class Recipe {
  final int? id;
  final int productId;
  final String productName;
  final List<RecipeItem> items;
  final DateTime createdAt;

  Recipe({
    this.id,
    required this.productId,
    required this.productName,
    this.items = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Recipe copyWith({
    int? id,
    int? productId,
    String? productName,
    List<RecipeItem>? items,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'product_id': productId,
        'product_name': productName,
        'created_at': createdAt.toIso8601String(),
      };

  factory Recipe.fromMap(Map<String, Object?> map) {
    return Recipe(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// بند في الوصفة (خام مطلوب + الكمية).
class RecipeItem {
  final int? id;
  final int recipeId;
  final int rawMaterialId;
  final String rawMaterialName;
  final double quantity;
  final String unit;

  RecipeItem({
    this.id,
    required this.recipeId,
    required this.rawMaterialId,
    required this.rawMaterialName,
    required this.quantity,
    this.unit = 'كجم',
  });

  RecipeItem copyWith({
    int? id,
    int? recipeId,
    int? rawMaterialId,
    String? rawMaterialName,
    double? quantity,
    String? unit,
  }) {
    return RecipeItem(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      rawMaterialId: rawMaterialId ?? this.rawMaterialId,
      rawMaterialName: rawMaterialName ?? this.rawMaterialName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'recipe_id': recipeId,
        'raw_material_id': rawMaterialId,
        'raw_material_name': rawMaterialName,
        'quantity': quantity,
        'unit': unit,
      };

  factory RecipeItem.fromMap(Map<String, Object?> map) {
    return RecipeItem(
      id: map['id'] as int?,
      recipeId: map['recipe_id'] as int,
      rawMaterialId: map['raw_material_id'] as int,
      rawMaterialName: map['raw_material_name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? 'كجم',
    );
  }
}

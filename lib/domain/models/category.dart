/// تصنيف يجمّع الأصناف لسهولة البحث أثناء البيع.
class Category {
  final int? id;
  final String name;
  final DateTime createdAt;

  Category({
    this.id,
    required this.name,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Category copyWith({int? id, String? name, DateTime? createdAt}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
      };

  factory Category.fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

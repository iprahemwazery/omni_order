/// صالة في المطعم تحتوي على مجموعة ترابيزات.
class Hall {
  final int? id;
  final String name;
  final int capacity;
  final bool isActive;
  final DateTime createdAt;

  Hall({
    this.id,
    required this.name,
    this.capacity = 0,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Hall copyWith({
    int? id,
    String? name,
    int? capacity,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Hall(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'capacity': capacity,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory Hall.fromMap(Map<String, Object?> map) {
    return Hall(
      id: map['id'] as int?,
      name: map['name'] as String,
      capacity: map['capacity'] as int? ?? 0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Hall && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

class OrderStatusHistory {
  final int? id;
  final int orderId;
  final String status;
  final String note;
  final DateTime createdAt;

  OrderStatusHistory({
    this.id,
    required this.orderId,
    required this.status,
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'order_id': orderId,
        'status': status,
        if (note.isNotEmpty) 'note': note,
        'created_at': createdAt.toIso8601String(),
      };

  factory OrderStatusHistory.fromMap(Map<String, Object?> map) {
    return OrderStatusHistory(
      id: map['id'] as int?,
      orderId: map['order_id'] as int,
      status: map['status'] as String,
      note: map['note'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

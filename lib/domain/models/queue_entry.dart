/// حالة العميل في قائمة الانتظار.
enum QueueStatus {
  waiting('ينتظر'),
  seating('يجلس'),
  done('تم'),
  cancelled('ملغي');

  const QueueStatus(this.label);

  final String label;

  static QueueStatus fromName(String? name) {
    for (final status in values) {
      if (status.name == name) return status;
    }
    return QueueStatus.waiting;
  }
}

/// عميل في قائمة الانتظار.
class QueueEntry {
  final int? id;
  final String customerName;
  final String customerPhone;
  final int partySize;
  final QueueStatus status;
  final String note;
  final DateTime createdAt;

  QueueEntry({
    this.id,
    required this.customerName,
    this.customerPhone = '',
    required this.partySize,
    this.status = QueueStatus.waiting,
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  QueueEntry copyWith({
    int? id,
    String? customerName,
    String? customerPhone,
    int? partySize,
    QueueStatus? status,
    String? note,
    DateTime? createdAt,
  }) {
    return QueueEntry(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      partySize: partySize ?? this.partySize,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'party_size': partySize,
        'status': status.name,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };

  factory QueueEntry.fromMap(Map<String, Object?> map) {
    return QueueEntry(
      id: map['id'] as int?,
      customerName: map['customer_name'] as String? ?? '',
      customerPhone: map['customer_phone'] as String? ?? '',
      partySize: map['party_size'] as int? ?? 2,
      status: QueueStatus.fromName(map['status'] as String?),
      note: map['note'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

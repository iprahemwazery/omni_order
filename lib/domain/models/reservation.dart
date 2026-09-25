/// حالة الحجز.
enum ReservationStatus {
  confirmed('مؤكد'),
  seated('جالس'),
  cancelled('ملغي'),
  completed('مكتمل');

  const ReservationStatus(this.label);

  final String label;

  static ReservationStatus fromName(String? name) {
    for (final status in values) {
      if (status.name == name) return status;
    }
    return ReservationStatus.confirmed;
  }
}

/// حجز تريبية في المطعم.
class Reservation {
  final int? id;
  final int tableId;
  final int tableNumber;
  final String customerName;
  final String customerPhone;
  final int partySize;
  final DateTime reservationTime;
  final String note;
  final ReservationStatus status;
  final DateTime createdAt;

  Reservation({
    this.id,
    required this.tableId,
    required this.tableNumber,
    required this.customerName,
    this.customerPhone = '',
    required this.partySize,
    required this.reservationTime,
    this.note = '',
    this.status = ReservationStatus.confirmed,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Reservation copyWith({
    int? id,
    int? tableId,
    int? tableNumber,
    String? customerName,
    String? customerPhone,
    int? partySize,
    DateTime? reservationTime,
    String? note,
    ReservationStatus? status,
    DateTime? createdAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      partySize: partySize ?? this.partySize,
      reservationTime: reservationTime ?? this.reservationTime,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'table_id': tableId,
        'table_number': tableNumber,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'party_size': partySize,
        'reservation_time': reservationTime.toIso8601String(),
        'note': note,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
      };

  factory Reservation.fromMap(Map<String, Object?> map) {
    return Reservation(
      id: map['id'] as int?,
      tableId: map['table_id'] as int,
      tableNumber: map['table_number'] as int,
      customerName: map['customer_name'] as String? ?? '',
      customerPhone: map['customer_phone'] as String? ?? '',
      partySize: map['party_size'] as int? ?? 2,
      reservationTime: DateTime.parse(map['reservation_time'] as String),
      note: map['note'] as String? ?? '',
      status: ReservationStatus.fromName(map['status'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

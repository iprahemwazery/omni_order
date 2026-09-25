/// نوع حركة المرتب: سلفة (advance) أو خصم (deduction).
enum AdvanceType {
  advance('سلفة'),
  deduction('خصم');

  const AdvanceType(this.label);

  final String label;

  static AdvanceType fromName(String? name) {
    for (final type in values) {
      if (type.name == name) return type;
    }
    return AdvanceType.advance;
  }
}

/// حركة سلفة أو خصم على موظف.
class EmployeeAdvance {
  final int? id;
  final int employeeId;
  final double amount;
  final AdvanceType type;
  final String note;
  final DateTime createdAt;

  EmployeeAdvance({
    this.id,
    required this.employeeId,
    required this.amount,
    this.type = AdvanceType.advance,
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  EmployeeAdvance copyWith({
    int? id,
    int? employeeId,
    double? amount,
    AdvanceType? type,
    String? note,
    DateTime? createdAt,
  }) {
    return EmployeeAdvance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'employee_id': employeeId,
        'amount': amount,
        'type': type.name,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };

  factory EmployeeAdvance.fromMap(Map<String, Object?> map) {
    return EmployeeAdvance(
      id: map['id'] as int?,
      employeeId: map['employee_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      type: AdvanceType.fromName(map['type'] as String?),
      note: map['note'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

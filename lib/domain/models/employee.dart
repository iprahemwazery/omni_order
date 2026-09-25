/// دور الموظف في المطعم.
enum EmployeeRole {
  manager('مدير'),
  cashier('كاشير'),
  waiter('جرسون'),
  chef('شيف'),
  host('مضيف'),
  delivery('دليفري');

  const EmployeeRole(this.label);

  final String label;

  static EmployeeRole fromName(String? name) {
    for (final role in values) {
      if (role.name == name) return role;
    }
    return EmployeeRole.waiter;
  }
}

/// موظف في المطعم.
class Employee {
  final int? id;
  final String name;
  final String phone;
  final EmployeeRole role;
  final double salary;
  final bool isActive;
  final DateTime createdAt;

  Employee({
    this.id,
    required this.name,
    this.phone = '',
    this.role = EmployeeRole.waiter,
    this.salary = 0,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Employee copyWith({
    int? id,
    String? name,
    String? phone,
    EmployeeRole? role,
    double? salary,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      salary: salary ?? this.salary,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'role': role.name,
        'salary': salary,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory Employee.fromMap(Map<String, Object?> map) {
    return Employee(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String? ?? '',
      role: EmployeeRole.fromName(map['role'] as String?),
      salary: (map['salary'] as num?)?.toDouble() ?? 0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Employee && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

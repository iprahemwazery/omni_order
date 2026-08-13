/// أدوار المستخدمين في النظام.
enum UserRole {
  superAdmin('أدمن أساسي'),
  admin('أدمن'),
  cashier('كاشير');

  const UserRole(this.label);

  final String label;

  static UserRole fromName(String? name) {
    for (final role in values) {
      if (role.name == name) return role;
    }
    return UserRole.cashier;
  }
}

/// صلاحيات دقيقة داخل النظام.
enum UserPermission {
  makeSales('البيع'),
  viewSales('سجل المبيعات'),
  viewReports('التقارير'),
  manageProducts('الأصناف والتصنيفات'),
  manageCustomers('العملاء والمديونيات'),
  manageExpenses('المصروفات'),
  manageSettings('إعدادات المتجر'),
  manageUsers('إدارة المستخدمين');

  const UserPermission(this.label);

  final String label;
}

extension UserRolePermissions on UserRole {
  /// هل يملك الدور هذه الصلاحية؟
  bool has(UserPermission permission) {
    switch (this) {
      case UserRole.superAdmin:
        return true;
      case UserRole.admin:
        return permission != UserPermission.manageUsers;
      case UserRole.cashier:
        return permission == UserPermission.makeSales ||
            permission == UserPermission.viewSales;
    }
  }
}

/// كيان أدمن/مستخدم داخل التطبيق.
class Admin {
  final int? id;
  final String username;
  final String passwordHash;
  final UserRole role;
  final DateTime createdAt;

  Admin({
    this.id,
    required this.username,
    required this.passwordHash,
    this.role = UserRole.cashier,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isSuperAdmin => role == UserRole.superAdmin;

  bool has(UserPermission permission) => role.has(permission);

  Admin copyWith({
    int? id,
    String? username,
    String? passwordHash,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return Admin(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'username': username,
        'password_hash': passwordHash,
        'role': role.name,
        'created_at': createdAt.toIso8601String(),
      };

  factory Admin.fromMap(Map<String, Object?> map) {
    return Admin(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      role: UserRole.fromName(map['role'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// كوبون خصم يمكن استخدامه في الطلبات.
enum CouponType {
  percent('نسبة مئوية'),
  fixed('مبلغ ثابت');

  const CouponType(this.label);
  final String label;

  static CouponType fromName(String? name) {
    for (final type in values) {
      if (type.name == name) return type;
    }
    return CouponType.percent;
  }
}

class Coupon {
  final int? id;
  final String code;
  final String description;
  final CouponType discountType;
  final double discountValue;
  final double minOrder;
  final int maxUses;
  final int usedCount;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;

  Coupon({
    this.id,
    required this.code,
    this.description = '',
    this.discountType = CouponType.percent,
    required this.discountValue,
    this.minOrder = 0,
    this.maxUses = 0,
    this.usedCount = 0,
    this.isActive = true,
    this.expiresAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isUsable => isActive && !isExpired && (maxUses == 0 || usedCount < maxUses);

  double calculateDiscount(double orderTotal) {
    if (orderTotal < minOrder) return 0;
    switch (discountType) {
      case CouponType.percent:
        return orderTotal * (discountValue / 100);
      case CouponType.fixed:
        return discountValue.clamp(0, orderTotal);
    }
  }

  Coupon copyWith({
    int? id,
    String? code,
    String? description,
    CouponType? discountType,
    double? discountValue,
    double? minOrder,
    int? maxUses,
    int? usedCount,
    bool? isActive,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return Coupon(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minOrder: minOrder ?? this.minOrder,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'code': code.toUpperCase(),
        'description': description,
        'discount_type': discountType.name,
        'discount_value': discountValue,
        'min_order': minOrder,
        'max_uses': maxUses,
        'used_count': usedCount,
        'is_active': isActive ? 1 : 0,
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory Coupon.fromMap(Map<String, Object?> map) {
    return Coupon(
      id: map['id'] as int?,
      code: map['code'] as String,
      description: map['description'] as String? ?? '',
      discountType: CouponType.fromName(map['discount_type'] as String?),
      discountValue: (map['discount_value'] as num).toDouble(),
      minOrder: (map['min_order'] as num?)?.toDouble() ?? 0,
      maxUses: map['max_uses'] as int? ?? 0,
      usedCount: map['used_count'] as int? ?? 0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      expiresAt: map['expires_at'] == null
          ? null
          : DateTime.tryParse(map['expires_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

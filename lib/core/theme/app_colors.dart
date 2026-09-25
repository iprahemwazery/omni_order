import 'package:flutter/material.dart';

/// هوية التطبيق البصرية: أخضر زمردي (#05A660) على أسود عميق مع خط أبيض.
abstract final class AppColors {
  // ===== الهوية الأساسية =====

  /// الأخضر الرئيسي للهوية.
  static const Color primary = Color(0xFF05A660);

  /// أخضر غامق للأزرار المضغوطة والتدرجات.
  static const Color primaryDark = Color(0xFF047A48);

  /// أخضر فاتح للمسات والتمييز.
  static const Color primaryLight = Color(0xFF2BCB82);

  /// لون مساعد نعناعي متناسق مع الأخضر.
  static const Color accent = Color(0xFF6EE7B7);

  // ===== الخلفيات الداكنة =====

  /// خلفية التطبيق: أسود مائل للأخضر قليلًا.
  static const Color background = Color(0xFF0B0F0D);

  /// أسطح الكروت والحقول والحوارات.
  static const Color surface = Color(0xFF151A17);

  /// سطح أفتح درجة (عناصر داخل الكروت).
  static const Color surfaceVariant = Color(0xFF1E2521);

  // ===== النصوص =====

  /// لون الخط الأساسي: أبيض.
  static const Color textPrimary = Colors.white;

  /// نص ثانوي هادئ (وصف، تسميات).
  static const Color textSecondary = Color(0xFF9BA8A1);

  // ===== الحدود وحالات النظام =====
  static const Color border = Color(0xFF26302A);
  static const Color error = Color(0xFFE5484D);
  static const Color success = Color(0xFF30C97A);
  static const Color warning = Color(0xFFF0B24A);
  static const Color info = Color(0xFF4CA6FF);
}

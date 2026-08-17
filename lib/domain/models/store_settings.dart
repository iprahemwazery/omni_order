import '../../core/constants.dart';

/// إعدادات المتجر (اسمه، الهاتف، العملة، المظهر) التي تظهر على الفاتورة.
class StoreSettings {
  final String storeName;
  final String phone;
  final String currency;
  final bool darkMode;
  final double fontScale;

  /// نسبة ضريبة القيمة المضافة % (0 = بدون ضريبة).
  final double taxRate;

  const StoreSettings({
    required this.storeName,
    required this.phone,
    required this.currency,
    this.darkMode = false,
    this.fontScale = 1.0,
    this.taxRate = 0,
  });

  static const StoreSettings empty = StoreSettings(
    storeName: AppConstants.defaultStoreName,
    phone: '',
    currency: AppConstants.defaultCurrency,
  );

  StoreSettings copyWith({
    String? storeName,
    String? phone,
    String? currency,
    bool? darkMode,
    double? fontScale,
    double? taxRate,
  }) {
    return StoreSettings(
      storeName: storeName ?? this.storeName,
      phone: phone ?? this.phone,
      currency: currency ?? this.currency,
      darkMode: darkMode ?? this.darkMode,
      fontScale: fontScale ?? this.fontScale,
      taxRate: taxRate ?? this.taxRate,
    );
  }
}
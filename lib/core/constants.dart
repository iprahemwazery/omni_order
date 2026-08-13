/// ثوابت عامة في التطبيق.
class AppConstants {
  AppConstants._();

  static const String appName = 'أومني أوردر';

  static const String dbName = 'omni_order.db';
  static const int dbVersion = 9;

  static const String defaultStoreName = 'متجري';
  static const String defaultCurrency = 'ج.م';

  static const List<String> productUnits = [
    'قطعة',
    'كيلو',
    'لتر',
    'علبة',
    'عبوة',
    'زجاجة',
    'حزمة',
    'كرتونة',
  ];
}

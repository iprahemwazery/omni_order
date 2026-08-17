/// ثوابت طرق الدفع — مصدر واحد للحقيقة تُستخدم في السلة،
/// الفواتير، التقارير، واستعلامات قاعدة البيانات.
///
/// "مختلط" = نقدي + شبكة (الجزء نقدًا يُدخله الكاشير ويُحسب الباقي بالشبكة).
abstract final class PaymentMethod {
  PaymentMethod._();

  static const String cash = 'نقدي';
  static const String card = 'شبكة';
  static const String wallet = 'محفظة';
  static const String bankTransfer = 'تحويل بنكي';
  static const String mixed = 'مختلط';
  static const String deferred = 'آجل';

  /// كل طرق الدفع المدعومة.
  static const List<String> all = [
    cash,
    card,
    wallet,
    bankTransfer,
    mixed,
    deferred,
  ];

  /// طرق الدفع التي تُسدَّد فورًا (تُستخدم لإظهار حقل "المبلغ المدفوع").
  static const Set<String> paidNow = {cash, card, wallet, bankTransfer};
}

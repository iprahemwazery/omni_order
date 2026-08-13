import 'package:intl/intl.dart';

import '../constants.dart';

/// أدوات تنسيق الأرقام والتواريخ والعملة بشكل موحّد في التطبيق.
abstract final class AppFormatters {
  static final NumberFormat _intFormat = NumberFormat('#,##0');
  static final NumberFormat _decFormat = NumberFormat('#,##0.##');

  /// تنسيق مبلغ مالي مع العملة.
  static String money(num value, [String currency = AppConstants.defaultCurrency]) {
    final isWhole = value == value.roundToDouble();
    final digits = isWhole ? _intFormat.format(value.toInt()) : _decFormat.format(value);
    return '$digits $currency';
  }

  /// تنسيق كمية مع الوحدة.
  static String quantity(num value, String unit) {
    final isWhole = value == value.roundToDouble();
    final digits = isWhole ? _intFormat.format(value.toInt()) : _decFormat.format(value);
    return unit.isEmpty ? digits : '$digits $unit';
  }

  static String date(DateTime value) => DateFormat('yyyy/MM/dd').format(value.toLocal());

  static String time(DateTime value) => DateFormat('hh:mm a').format(value.toLocal());

  static String arabicWeekday(DateTime value) {
    const days = [
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];
    return days[value.weekday % 7];
  }

  static String arabicMonth(DateTime value) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[value.month - 1];
  }

  static String arabicDate(DateTime value) =>
      '${value.day} ${arabicMonth(value)} ${value.year}';

  static String arabicMonthYear(DateTime value) =>
      '${arabicMonth(value)} ${value.year}';

  static String dateTime(DateTime value) => '${date(value)} • ${time(value)}';

  static String invoiceNumber(int id) => 'فاتورة #$id';

  // ---- المبلغ بالحروف (عربي) ----

  static const List<String> _ones = [
    '',
    'واحد',
    'اثنان',
    'ثلاثة',
    'أربعة',
    'خمسة',
    'ستة',
    'سبعة',
    'ثمانية',
    'تسعة',
    'عشرة',
    'أحد عشر',
    'اثنا عشر',
    'ثلاثة عشر',
    'أربعة عشر',
    'خمسة عشر',
    'ستة عشر',
    'سبعة عشر',
    'ثمانية عشر',
    'تسعة عشر',
  ];

  static const List<String> _tens = [
    '',
    'عشرة',
    'عشرون',
    'ثلاثون',
    'أربعون',
    'خمسون',
    'ستون',
    'سبعون',
    'ثمانون',
    'تسعون',
  ];

  /// يحول عددًا صحيحًا (حتى 99,999,999) إلى كلمة عربية.
  static String numberToArabicWords(int n) {
    if (n == 0) return 'صفر';
    final parts = <String>[];

    // الملايين
    if (n >= 1000000) {
      final m = n ~/ 1000000;
      n %= 1000000;
      if (m == 1) {
        parts.add('مليون');
      } else if (m == 2) {
        parts.add('مليونان');
      } else {
        parts.add('${numberToArabicWords(m)} مليون');
      }
    }

    // الألوف
    if (n >= 1000) {
      final t = n ~/ 1000;
      n %= 1000;
      if (t == 1) {
        parts.add('ألف');
      } else if (t == 2) {
        parts.add('ألفان');
      } else if (t >= 3 && t <= 10) {
        parts.add('${numberToArabicWords(t)} آلاف');
      } else {
        parts.add('${numberToArabicWords(t)} ألف');
      }
    }

    // المئات
    if (n >= 100) {
      final h = n ~/ 100;
      n %= 100;
      parts.add(h == 1 ? 'مئة' : '${_ones[h]}مئة');
    }

    // العشرات والآحاد
    if (n >= 20) {
      final one = n % 10;
      final tenWord = _tens[n ~/ 10];
      parts.add(one == 0 ? tenWord : '${_ones[one]} و$tenWord');
    } else if (n >= 1) {
      parts.add(_ones[n]);
    }

    return parts.join(' و');
  }

  /// المبلغ بالحروف مع العملة، مثل: "خمسمئة وعشرون ج.م" أو
  /// "مئة واثنان وعشرون ج.م وخمسة وسبعون قرشًا".
  static String amountInWords(num value, [String currency = AppConstants.defaultCurrency]) {
    if (value <= 0) return 'صفر $currency';
    final intPart = value.floor();
    final fracCents = ((value - intPart) * 100).round();
    final whole = numberToArabicWords(intPart);
    final buffer = StringBuffer('$whole $currency');
    if (fracCents > 0) {
      buffer.write(' و${numberToArabicWords(fracCents)} قرشًا');
    }
    return buffer.toString();
  }
}

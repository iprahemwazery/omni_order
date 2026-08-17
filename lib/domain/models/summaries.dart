/// ملخصات محسوبة داخل قاعدة البيانات (SQL) بدلًا من تحميل كل السجلات
/// إلى الذاكرة — ضروري عند ضغط آلاف العمليات يوميًا.
library;

/// مخرجات "الأعلى مبيعًا": الاسم + الكمية + الإيرادات.
typedef TopProduct = ({String name, double quantity, double revenue});

/// ملخص المبيعات (نقدي/آجل) لليوم والشهر والإجمالي.
class SalesTotals {
  const SalesTotals({
    this.cashToday = 0,
    this.deferredToday = 0,
    this.cashMonth = 0,
    this.deferredMonth = 0,
    this.totalCash = 0,
    this.totalDeferred = 0,
    this.countToday = 0,
    this.countMonth = 0,
    this.countTotal = 0,
  });

  final double cashToday;
  final double deferredToday;
  final double cashMonth;
  final double deferredMonth;
  final double totalCash;
  final double totalDeferred;
  final int countToday;
  final int countMonth;
  final int countTotal;

  double get today => cashToday + deferredToday;
  double get month => cashMonth + deferredMonth;
  double get total => totalCash + totalDeferred;

  SalesTotals copyWith({
    double? cashToday,
    double? deferredToday,
    double? cashMonth,
    double? deferredMonth,
    double? totalCash,
    double? totalDeferred,
    int? countToday,
    int? countMonth,
    int? countTotal,
  }) {
    return SalesTotals(
      cashToday: cashToday ?? this.cashToday,
      deferredToday: deferredToday ?? this.deferredToday,
      cashMonth: cashMonth ?? this.cashMonth,
      deferredMonth: deferredMonth ?? this.deferredMonth,
      totalCash: totalCash ?? this.totalCash,
      totalDeferred: totalDeferred ?? this.totalDeferred,
      countToday: countToday ?? this.countToday,
      countMonth: countMonth ?? this.countMonth,
      countTotal: countTotal ?? this.countTotal,
    );
  }
}

/// ملخص المصروفات لليوم والشهر والإجمالي.
class ExpenseTotals {
  const ExpenseTotals({
    this.today = 0,
    this.month = 0,
    this.total = 0,
    this.count = 0,
  });

  final double today;
  final double month;
  final double total;
  final int count;

  ExpenseTotals copyWith({
    double? today,
    double? month,
    double? total,
    int? count,
  }) {
    return ExpenseTotals(
      today: today ?? this.today,
      month: month ?? this.month,
      total: total ?? this.total,
      count: count ?? this.count,
    );
  }
}

/// تحليل الربح: البيع المحقق (نقدي) مقابل تكلفة البضاعة المباعة.
class ProfitAnalytics {
  const ProfitAnalytics({this.cashRevenue = 0, this.cogs = 0});

  final double cashRevenue;
  final double cogs;

  double get gross => cashRevenue - cogs;
  double get marginPercent => cashRevenue > 0 ? (gross / cashRevenue) * 100 : 0;
}

/// إجمالي مبيعات يوم واحد (نقدي/آجل) — لرسم اتجاه المبيعات.
class DailySaleTotals {
  const DailySaleTotals({
    required this.day,
    this.cash = 0,
    this.deferred = 0,
  });

  final DateTime day;
  final double cash;
  final double deferred;

  double get total => cash + deferred;
}

/// يوم واحد ضمن "الأيام السابقة": إجمالي المبيعات والمصروفات وعددهما.
class DayHistoryEntry {
  const DayHistoryEntry({
    required this.day,
    this.salesTotal = 0,
    this.expensesTotal = 0,
    this.salesCount = 0,
    this.expensesCount = 0,
  });

  final DateTime day;
  final double salesTotal;
  final double expensesTotal;
  final int salesCount;
  final int expensesCount;
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/summaries.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../customers/presentation/customers_cubit.dart';
import '../../expenses/presentation/expenses_cubit.dart';
import '../../products/presentation/products_cubit.dart';
import '../../products/presentation/products_state.dart';
import '../../settings/presentation/settings_cubit.dart';
import '../../suppliers/presentation/supplier_reports_screen.dart';
import 'daily_report_screen.dart';
import 'sales_cubit.dart';
import 'sales_state.dart';
import 'widgets/revenue_chart.dart';

/// شاشة التقارير: ملخصات المبيعات والمصروفات وأفضل الأصناف.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  /// يزيد عند كل تحديث يدوي لإعادة بناء الأقسام المسؤولة عن بيانات حية
  /// (تحليل الربح، الاتجاه، الأيام السابقة) بدل إعادة تنفيذ استعلاماتها
  /// عند كل إعادة بناء عادية للشاشة.
  int _refreshTick = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesCubit, SalesState>(
      builder: (context, sales) => _build(context, sales),
    );
  }

  Widget _build(BuildContext context, SalesState sales) {
    final st = sales.totals;

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _refreshTick++);
            final salesCubit = context.read<SalesCubit>();
            final productsCubit = context.read<ProductsCubit>();
            final customersCubit = context.read<CustomersCubit>();
            final expensesCubit = context.read<ExpensesCubit>();
            await Future.wait([
              salesCubit.init(),
              productsCubit.init(),
              customersCubit.init(),
              expensesCubit.init(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _NetProfitBanner(
                todayRevenue: st.cashToday,
                monthRevenue: st.cashMonth,
                totalRevenue: st.totalCash,
              ),
              const SizedBox(height: 16),
              _StatGrid(
                children: [
                  _StatCard(
                    stat: const _Stat(
                      label: 'مبيعات اليوم',
                      icon: Icons.today,
                      color: AppColors.primary,
                    ).withValue(st.cashToday),
                  ),
                  _StatCard(
                    stat: const _Stat(
                      label: 'مديونية اليوم',
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.error,
                    ).withValue(st.deferredToday),
                  ),
                  const _ExpenseStatCard(
                    label: 'مصروفات اليوم',
                    icon: Icons.request_quote_outlined,
                    color: AppColors.warning,
                    amountOf: _todayExpenses,
                  ),
                  _NetStatCard(
                    label: 'صافي اليوم',
                    icon: Icons.trending_up,
                    color: AppColors.success,
                    salesAmount: st.cashToday,
                    expensesOf: _todayExpenses,
                  ),
                  _StatCard(
                    stat: const _Stat(
                      label: 'مبيعات الشهر',
                      icon: Icons.calendar_month,
                      color: AppColors.success,
                    ).withValue(st.cashMonth),
                  ),
                  const _ExpenseStatCard(
                    label: 'مصروفات الشهر',
                    icon: Icons.request_quote_outlined,
                    color: AppColors.warning,
                    amountOf: _monthExpenses,
                  ),
                  _StatCard(
                    stat: const _Stat(
                      label: 'إجمالي المبيعات',
                      icon: Icons.savings_outlined,
                      color: AppColors.primaryDark,
                    ).withValue(st.totalCash),
                  ),
                  _StatCard(
                    stat: const _Stat(
                      label: 'إجمالي الآجل',
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.error,
                    ).withValue(st.totalDeferred),
                  ),
                  const _ExpenseStatCard(
                    label: 'إجمالي المصروفات',
                    icon: Icons.request_quote_outlined,
                    color: AppColors.warning,
                    amountOf: _allExpenses,
                  ),
                  _NetStatCard(
                    label: 'صافي الإجمالي',
                    icon: Icons.account_balance_outlined,
                    color: AppColors.primary,
                    salesAmount: st.totalCash,
                    expensesOf: _allExpenses,
                  ),
                  _StatCard(
                    stat: _Stat(
                      label: 'عدد الفواتير',
                      value: '${st.countTotal}',
                      icon: Icons.receipt_long_outlined,
                      color: AppColors.accent,
                    ),
                  ),
                  const _CustomerDebtStatCard(),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'تحليل الربح',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _ProfitAnalytics(key: ValueKey('profit_$_refreshTick')),
              const SizedBox(height: 24),
              Text(
                'اتجاه المبيعات',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _RevenueTrend(key: ValueKey('trend_$_refreshTick')),
              const SizedBox(height: 24),
              Text(
                'الأعلى مبيعًا',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const _TopProducts(),
              const SizedBox(height: 24),
              Text(
                'تنبيهات المخزون',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const _StockAlerts(),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.local_shipping_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('تقرير الموردين'),
                  subtitle: const Text(
                    'فلترة حسب المورد والتاريخ وتصدير PDF/Excel',
                  ),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SupplierReportsScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'الأيام السابقة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text(
                'اضغط على أي يوم لفتح تقريره كاملًا',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _DayHistory(key: ValueKey('history_$_refreshTick')),
            ],
          ),
        ),
      ),
    );
  }
}

/// انتقاء مصروفات اليوم من حالة المصروفات (للمستخدمين في الأقسام الداخلية).
double _todayExpenses(ExpenseTotals totals) => totals.today;
double _monthExpenses(ExpenseTotals totals) => totals.month;
double _allExpenses(ExpenseTotals totals) => totals.total;

class _Stat {
  const _Stat({
    required this.label,
    required this.icon,
    required this.color,
    this.value = '',
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  /// ينشئ نسخة بقيمة منسقة (تُستخدم لبناء البطاقة مع قيمة رقمية).
  _Stat withValue(double value) => _Stat(
        label: label,
        value: AppFormatters.money(value),
        icon: icon,
        color: color,
      );
}

/// ملخص صافي الربح (المبيعات ناقص المصروفات) لليوم والشهر والإجمالي.
class _NetProfitBanner extends StatelessWidget {
  const _NetProfitBanner({
    required this.todayRevenue,
    required this.monthRevenue,
    required this.totalRevenue,
  });

  final double todayRevenue;
  final double monthRevenue;
  final double totalRevenue;

  @override
  Widget build(BuildContext context) {
    final et =
        context.select<ExpensesCubit, ExpenseTotals>((c) => c.state.totals);
    final currency = context.select<SettingsCubit, String>(
      (c) => c.state.settings.currency,
    );
    final todayExpenses = et.today;
    final monthExpenses = et.month;
    final totalExpenses = et.total;
    final totalNet = totalRevenue - totalExpenses;
    final profit = totalNet >= 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: profit
              ? const [AppColors.primary, AppColors.primaryDark]
              : const [AppColors.error, Color(0xFF8A2B2B)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pie_chart_outline,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                profit ? 'صافي الربح' : 'صافي الخسارة',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppFormatters.money(totalNet.abs(), currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _NetChip(
                icon: Icons.today,
                label: 'اليوم',
                value: AppFormatters.money(
                  todayRevenue - todayExpenses,
                  currency,
                ),
              ),
              _NetChip(
                icon: Icons.calendar_month,
                label: 'الشهر',
                value: AppFormatters.money(
                  monthRevenue - monthExpenses,
                  currency,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetChip extends StatelessWidget {
  const _NetChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 15),
        const SizedBox(width: 5),
        Text(
          '$value $label',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// بطاقة إحصائية واحدة (تُستخدم داخل [Grid]).
class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(stat.icon, size: 20, color: stat.color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: stat.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة إحصائية تعتمد على إجماليات المصروفات (تتابعها وحدها دون إعادة
/// بناء باقي الشبكة عند تغيّرها).
class _ExpenseStatCard extends StatelessWidget {
  const _ExpenseStatCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.amountOf,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double Function(ExpenseTotals totals) amountOf;

  @override
  Widget build(BuildContext context) {
    final totals =
        context.select<ExpensesCubit, ExpenseTotals>((c) => c.state.totals);
    return _StatCard(
      stat: _Stat(
        label: label,
        value: AppFormatters.money(amountOf(totals)),
        icon: icon,
        color: color,
      ),
    );
  }
}

/// بطاقة صافي (مبيعات ناقص مصروفات) تتابع المصروفات وحدها.
class _NetStatCard extends StatelessWidget {
  const _NetStatCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.salesAmount,
    required this.expensesOf,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double salesAmount;
  final double Function(ExpenseTotals totals) expensesOf;

  @override
  Widget build(BuildContext context) {
    final totals =
        context.select<ExpensesCubit, ExpenseTotals>((c) => c.state.totals);
    return _StatCard(
      stat: _Stat(
        label: label,
        value: AppFormatters.money(salesAmount - expensesOf(totals)),
        icon: icon,
        color: color,
      ),
    );
  }
}

/// بطاقة ديون العملاء (تتابع حالة العملاء وحدها).
class _CustomerDebtStatCard extends StatelessWidget {
  const _CustomerDebtStatCard();

  @override
  Widget build(BuildContext context) {
    final totalDebts = context.select<CustomersCubit, double>(
      (c) => c.state.totalDebts,
    );
    return _StatCard(
      stat: _Stat(
        label: 'ديون العملاء',
        value: AppFormatters.money(totalDebts),
        icon: Icons.account_balance_wallet_outlined,
        color: totalDebts > 0 ? AppColors.error : AppColors.success,
      ),
    );
  }
}

/// تحليل الربح: البيع المحقق مقابل تكلفة البضاعة (سعر التكلفة لكل صنف).
/// تُحسب كل القيم في استعلام واحد داخل قاعدة البيانات.
/// يحفظ الاستعلام مرة واحدة (لا يُعاد تنفيذه مع كل إعادة بناء).
class _ProfitAnalytics extends StatefulWidget {
  const _ProfitAnalytics({super.key});

  @override
  State<_ProfitAnalytics> createState() => _ProfitAnalyticsState();
}

class _ProfitAnalyticsState extends State<_ProfitAnalytics> {
  late final Future<ProfitAnalytics> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<SalesCubit>().profitAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfitAnalytics>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data ?? const ProfitAnalytics();
        final currency = context.read<SettingsCubit>().state.settings.currency;
        final marginPct = data.marginPercent;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ProfitRow(
                  label: 'بيع نقدي محقق',
                  value: AppFormatters.money(data.cashRevenue, currency),
                  color: AppColors.textPrimary,
                ),
                const SizedBox(height: 8),
                _ProfitRow(
                  label: 'تكلفة البضاعة المباعة',
                  value: AppFormatters.money(data.cogs, currency),
                  color: AppColors.warning,
                ),
                const Divider(height: 20),
                _ProfitRow(
                  label: 'هامش الربح',
                  value: AppFormatters.money(data.gross, currency),
                  color: data.gross >= 0 ? AppColors.success : AppColors.error,
                  bold: true,
                ),
                const SizedBox(height: 6),
                Text(
                  'نسبة الهامش: ${marginPct.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfitRow extends StatelessWidget {
  const _ProfitRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              fontSize: bold ? 16 : 14,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// اتجاه المبيعات النقدية على آخر 30 يومًا — إجماليات يومية من قاعدة البيانات.
class _RevenueTrend extends StatefulWidget {
  const _RevenueTrend({super.key});

  @override
  State<_RevenueTrend> createState() => _RevenueTrendState();
}

class _RevenueTrendState extends State<_RevenueTrend> {
  late final Future<List<DailySaleTotals>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<SalesCubit>().dailySalesTotals(30);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currency = context.read<SettingsCubit>().state.settings.currency;
    return FutureBuilder<List<DailySaleTotals>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final totalsByDay = {
          for (final d in snapshot.data ?? const <DailySaleTotals>[])
            DateTime(d.day.year, d.day.month, d.day.day).toIso8601String(): d,
        };
        final days = <DateTime>[
          for (var i = 29; i >= 0; i--) now.subtract(Duration(days: i)),
        ];
        final values = [
          for (final day in days)
            totalsByDay[
                    DateTime(day.year, day.month, day.day).toIso8601String()]
                ?.cash ??
                0,
        ];
        return RevenueTrendChart(values: values, days: days, currency: currency);
      },
    );
  }
}

class _TopProducts extends StatelessWidget {
  const _TopProducts();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<SalesCubit>().topProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final products = snapshot.data ?? const [];
        if (products.isEmpty) {
          return const EmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'لا توجد بيانات بعد',
            subtitle: 'ابدأ بالبيع وستظهر هنا أفضل الأصناف',
          );
        }
        return Card(
          child: Column(
            children: [
              for (var i = 0; i < products.length; i++)
                _TopProductRow(
                  rank: i + 1,
                  name: products[i].name,
                  quantity: products[i].quantity,
                  revenue: products[i].revenue,
                  last: i == products.length - 1,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TopProductRow extends StatelessWidget {
  const _TopProductRow({
    required this.rank,
    required this.name,
    required this.quantity,
    required this.revenue,
    required this.last,
  });

  final int rank;
  final String name;
  final double quantity;
  final double revenue;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F1EF),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'الكمية: ${AppFormatters.quantity(quantity, '')}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppFormatters.money(revenue),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockAlerts extends StatelessWidget {
  const _StockAlerts();

  @override
  Widget build(BuildContext context) {
    final products =
        context.select<ProductsCubit, ProductsState>((c) => c.state);
    final low = products.lowStock;
    final out = products.outOfStock;

    if (low.isEmpty && out.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'المخزون جيد',
        subtitle: 'لا توجد أصناف قاربت على النفاد',
      );
    }

    return Card(
      child: Column(
        children: [
          for (final product in out)
            _AlertRow(
              productName: product.name,
              detail: 'نفد تمامًا',
              isCritical: true,
              last: low.isEmpty,
            ),
          for (var i = 0; i < low.length; i++)
            _AlertRow(
              productName: low[i].name,
              detail:
                  'متبقي: ${AppFormatters.quantity(low[i].stock, low[i].unit)}',
              isCritical: false,
              last: i == low.length - 1,
            ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.productName,
    required this.detail,
    required this.isCritical,
    required this.last,
  });

  final String productName;
  final String detail;
  final bool isCritical;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = isCritical ? AppColors.error : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              productName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          Text(
            detail,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// سجل الأيام السابقة: جدول أيام مجمّعًا حسب الشهر، كل شهر منفصل.
/// البيانات قادمة من استعلامات GROUP BY داخل قاعدة البيانات.
/// يحفظ الاستعلام مرة واحدة بدل تنفيذه مع كل إعادة بناء.
class _DayHistory extends StatefulWidget {
  const _DayHistory({super.key});

  @override
  State<_DayHistory> createState() => _DayHistoryState();
}

class _DayHistoryState extends State<_DayHistory> {
  late final Future<List<DayHistoryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<SalesCubit>().dayHistory();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.read<SettingsCubit>().state.settings.currency;
    return FutureBuilder<List<DayHistoryEntry>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final entries = snapshot.data ?? const <DayHistoryEntry>[];
        if (entries.isEmpty) {
          return const EmptyState(
            icon: Icons.event_note_outlined,
            title: 'لا توجد أيام سابقة',
            subtitle: 'ستظهر هنا تقارير الأيام الماضية فور بدء البيع',
          );
        }

        final sorted = [...entries]..sort((a, b) => b.day.compareTo(a.day));

        final months = <(int, int), List<DayHistoryEntry>>{};
        for (final entry in sorted) {
          months
              .putIfAbsent((entry.day.year, entry.day.month), () => [])
              .add(entry);
        }
        final monthKeys = months.keys.toList()
          ..sort((a, b) {
            final cmp = b.$1.compareTo(a.$1);
            return cmp != 0 ? cmp : b.$2.compareTo(a.$2);
          });

        return Column(
          children: [
            for (final key in monthKeys) ...[
              _MonthCard(
                year: key.$1,
                month: key.$2,
                days: months[key]!,
                currency: currency,
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.year,
    required this.month,
    required this.days,
    required this.currency,
  });

  final int year;
  final int month;
  final List<DayHistoryEntry> days;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final monthRevenue =
        days.fold<double>(0, (sum, d) => sum + d.salesTotal);
    final monthExpenses =
        days.fold<double>(0, (sum, d) => sum + d.expensesTotal);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFE8F1EF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppFormatters.arabicMonthYear(DateTime(year, month)),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    Text(
                      AppFormatters.money(
                        monthRevenue - monthExpenses,
                        currency,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(right: 26),
                  child: Text(
                    'بيع: ${AppFormatters.money(monthRevenue, currency)} • مصروفات: ${AppFormatters.money(monthExpenses, currency)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < days.length; i++) ...[
            _DayRow(
              entry: days[i],
              currency: currency,
              last: i == days.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.entry,
    required this.currency,
    required this.last,
  });

  final DayHistoryEntry entry;
  final String currency;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final day = entry.day;
    final net = entry.salesTotal - entry.expensesTotal;

    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: () async {
          final salesCubit = context.read<SalesCubit>();
          final expensesCubit = context.read<ExpensesCubit>();
          final daySales = await salesCubit.salesOn(day);
          final dayExpenses = await expensesCubit.expensesOn(day);
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DailyReportScreen(
                day: day,
                sales: daySales,
                expenses: dayExpenses,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: last
                ? null
                : const Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 14,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      AppFormatters.arabicMonth(day),
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.primaryDark,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppFormatters.arabicWeekday(day),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${AppFormatters.money(entry.salesTotal, currency)} بيع • ${AppFormatters.money(entry.expensesTotal, currency)} مصروفات',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.money(net, currency),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: net >= 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                  const Text(
                    'صافي',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.chevron_left,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

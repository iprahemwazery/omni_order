import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../customers/presentation/customers_cubit.dart';
import '../../customers/presentation/customers_state.dart';
import '../../expenses/presentation/expenses_cubit.dart';
import '../../expenses/presentation/expenses_state.dart';
import '../../products/presentation/products_cubit.dart';
import '../../products/presentation/products_state.dart';
import '../../settings/presentation/settings_cubit.dart';
import '../../suppliers/presentation/supplier_reports_screen.dart';
import '../../../domain/models/expense.dart';
import '../../../domain/models/sale.dart';
import 'daily_report_screen.dart';
import 'sales_cubit.dart';
import 'sales_state.dart';
import 'widgets/revenue_chart.dart';

/// شاشة التقارير: ملخصات المبيعات والمصروفات وأفضل الأصناف.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesCubit, SalesState>(
      builder: (context, sales) => BlocBuilder<CustomersCubit, CustomersState>(
        builder: (context, customers) =>
            BlocBuilder<ExpensesCubit, ExpensesState>(
              builder: (context, expenses) =>
                  BlocBuilder<ProductsCubit, ProductsState>(
                    builder: (context, products) => _build(
                      context,
                      sales: sales,
                      customers: customers,
                      expenses: expenses,
                      products: products,
                    ),
                  ),
            ),
      ),
    );
  }

  Widget _build(
    BuildContext context, {
    required SalesState sales,
    required CustomersState customers,
    required ExpensesState expenses,
    required ProductsState products,
  }) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
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
                todayRevenue: sales.cashRevenueOn(now),
                todayExpenses: expenses.expensesOn(now),
                monthRevenue: sales.monthCashRevenue,
                monthExpenses: expenses.monthExpenses,
                totalRevenue: sales.totalCashRevenue,
                totalExpenses: expenses.totalExpenses,
                currency: context.read<SettingsCubit>().state.settings.currency,
              ),
              const SizedBox(height: 16),
              _StatGrid(
                items: [
                  _Stat(
                    label: 'مبيعات اليوم',
                    value: AppFormatters.money(sales.cashRevenueOn(now)),
                    icon: Icons.today,
                    color: AppColors.primary,
                  ),
                  _Stat(
                    label: 'مديونية اليوم',
                    value: AppFormatters.money(sales.deferredOn(now)),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.error,
                  ),
                  _Stat(
                    label: 'مصروفات اليوم',
                    value: AppFormatters.money(expenses.expensesOn(now)),
                    icon: Icons.request_quote_outlined,
                    color: AppColors.warning,
                  ),
                  _Stat(
                    label: 'صافي اليوم',
                    value: AppFormatters.money(
                      sales.cashRevenueOn(now) - expenses.expensesOn(now),
                    ),
                    icon: Icons.trending_up,
                    color: AppColors.success,
                  ),
                  _Stat(
                    label: 'مبيعات الشهر',
                    value: AppFormatters.money(sales.monthCashRevenue),
                    icon: Icons.calendar_month,
                    color: AppColors.success,
                  ),
                  _Stat(
                    label: 'مصروفات الشهر',
                    value: AppFormatters.money(expenses.monthExpenses),
                    icon: Icons.request_quote_outlined,
                    color: AppColors.warning,
                  ),
                  _Stat(
                    label: 'إجمالي المبيعات',
                    value: AppFormatters.money(sales.totalCashRevenue),
                    icon: Icons.savings_outlined,
                    color: AppColors.primaryDark,
                  ),
                  _Stat(
                    label: 'إجمالي الآجل',
                    value: AppFormatters.money(sales.totalDeferred),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.error,
                  ),
                  _Stat(
                    label: 'إجمالي المصروفات',
                    value: AppFormatters.money(expenses.totalExpenses),
                    icon: Icons.request_quote_outlined,
                    color: AppColors.warning,
                  ),
                  _Stat(
                    label: 'صافي الإجمالي',
                    value: AppFormatters.money(
                      sales.totalCashRevenue - expenses.totalExpenses,
                    ),
                    icon: Icons.account_balance_outlined,
                    color: AppColors.primary,
                  ),
                  _Stat(
                    label: 'عدد الفواتير',
                    value: '${sales.sales.length}',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.accent,
                  ),
                  _Stat(
                    label: 'ديون العملاء',
                    value: AppFormatters.money(customers.totalDebts),
                    icon: Icons.account_balance_wallet_outlined,
                    color: customers.totalDebts > 0
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'تحليل الربح',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _ProfitAnalytics(sales: sales, products: products),
              const SizedBox(height: 24),
              Text(
                'اتجاه المبيعات',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _RevenueTrend(sales: sales),
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
              _StockAlerts(products: products),
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
              _DayHistory(
                sales: sales.sales,
                expenses: expenses.expenses,
                currency: context.read<SettingsCubit>().state.settings.currency,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat {
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

/// ملخص صافي الربح (المبيعات ناقص المصروفات) لليوم والشهر والإجمالي.
class _NetProfitBanner extends StatelessWidget {
  const _NetProfitBanner({
    required this.todayRevenue,
    required this.todayExpenses,
    required this.monthRevenue,
    required this.monthExpenses,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.currency,
  });

  final double todayRevenue;
  final double todayExpenses;
  final double monthRevenue;
  final double monthExpenses;
  final double totalRevenue;
  final double totalExpenses;
  final String currency;

  @override
  Widget build(BuildContext context) {
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
  const _StatGrid({required this.items});

  final List<_Stat> items;

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
      itemCount: items.length,
      itemBuilder: (context, index) {
        final stat = items[index];
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
      },
    );
  }
}

/// تحليل الربح: البيع المحقق مقابل تكلفة البضاعة (سعر التكلفة لكل صنف).
class _ProfitAnalytics extends StatelessWidget {
  const _ProfitAnalytics({required this.sales, required this.products});

  final SalesState sales;
  final ProductsState products;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({double revenue, double cost, double gross})>(
      future: _compute(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data ?? (revenue: 0.0, cost: 0.0, gross: 0.0);
        final currency = context.read<SettingsCubit>().state.settings.currency;
        final marginPct = data.revenue > 0
            ? (data.gross / data.revenue) * 100
            : 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ProfitRow(
                  label: 'بيع نقدي محقق',
                  value: AppFormatters.money(data.revenue, currency),
                  color: AppColors.textPrimary,
                ),
                const SizedBox(height: 8),
                _ProfitRow(
                  label: 'تكلفة البضاعة المباعة',
                  value: AppFormatters.money(data.cost, currency),
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

  Future<({double revenue, double cost, double gross})> _compute(
    BuildContext context,
  ) async {
    final items = await context.read<SalesCubit>().allSaleItems();
    final costById = <int?, double>{
      for (final product in products.products) product.id: product.costPrice,
    };
    final active = sales.sales.where((s) => !s.refunded).toList();
    final paymentOf = <int?, String>{
      for (final sale in active) sale.id: sale.paymentMethod,
    };
    final refundedIds = sales.sales
        .where((s) => s.refunded)
        .map((s) => s.id)
        .toSet();

    double cashRevenue = 0;
    double cost = 0;
    for (final sale in active) {
      if (sale.paymentMethod == 'آجل') continue;
      cashRevenue += sale.total;
    }
    for (final item in items) {
      if (refundedIds.contains(item.saleId)) continue;
      if (paymentOf[item.saleId] == 'آجل') continue;
      cost += (costById[item.productId] ?? 0) * item.quantity;
    }
    return (revenue: cashRevenue, cost: cost, gross: cashRevenue - cost);
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

/// اتجاه المبيعات النقدية على آخر 30 يومًا.
class _RevenueTrend extends StatelessWidget {
  const _RevenueTrend({required this.sales});

  final SalesState sales;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currency = context.read<SettingsCubit>().state.settings.currency;
    final days = <DateTime>[
      for (var i = 29; i >= 0; i--) now.subtract(Duration(days: i)),
    ];
    final values = List<double>.filled(30, 0);
    for (final sale in sales.sales) {
      if (sale.refunded) continue;
      if (sale.paymentMethod == 'آجل') continue;
      for (var i = 0; i < 30; i++) {
        if (sale.createdAt.year == days[i].year &&
            sale.createdAt.month == days[i].month &&
            sale.createdAt.day == days[i].day) {
          values[i] += sale.total;
          break;
        }
      }
    }
    return RevenueTrendChart(values: values, days: days, currency: currency);
  }
}

class _TopProducts extends StatelessWidget {
  const _TopProducts();

  @override
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
  const _StockAlerts({required this.products});

  final ProductsState products;

  @override
  Widget build(BuildContext context) {
    final low = products.lowStock();
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
class _DayHistory extends StatelessWidget {
  const _DayHistory({
    required this.sales,
    required this.expenses,
    required this.currency,
  });

  final List<Sale> sales;
  final List<Expense> expenses;
  final String currency;

  /// يجمع أيام الفواتير والمصروفات في خريطة: اليوم -> (فواتير، مصروفات).
  /// اليوم الحالي مستبعد لأنه يظهر في ملخص الصفحة الرئيسية.
  Map<DateTime, (List<Sale>, List<Expense>)> _days() {
    final today = DateTime.now();
    final days = <DateTime, (List<Sale>, List<Expense>)>{};
    for (final sale in sales) {
      final day = DateTime(
        sale.createdAt.year,
        sale.createdAt.month,
        sale.createdAt.day,
      );
      if (_sameDay(day, today)) continue;
      final existing = days.putIfAbsent(day, () => (<Sale>[], <Expense>[]));
      existing.$1.add(sale);
    }
    for (final expense in expenses) {
      final day = DateTime(
        expense.createdAt.year,
        expense.createdAt.month,
        expense.createdAt.day,
      );
      if (_sameDay(day, today)) continue;
      final existing = days.putIfAbsent(day, () => (<Sale>[], <Expense>[]));
      existing.$2.add(expense);
    }
    return days;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final days = _days();
    if (days.isEmpty) {
      return const EmptyState(
        icon: Icons.event_note_outlined,
        title: 'لا توجد أيام سابقة',
        subtitle: 'ستظهر هنا تقارير الأيام الماضية فور بدء البيع',
      );
    }

    final sortedDays = days.keys.toList()..sort((a, b) => b.compareTo(a));

    // تجميع الأيام حسب الشهر.
    final months = <(int, int), List<DateTime>>{};
    for (final day in sortedDays) {
      months.putIfAbsent((day.year, day.month), () => []).add(day);
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
            data: days,
            currency: currency,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.year,
    required this.month,
    required this.days,
    required this.data,
    required this.currency,
  });

  final int year;
  final int month;
  final List<DateTime> days;
  final Map<DateTime, (List<Sale>, List<Expense>)> data;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final monthRevenue = days.fold<double>(
      0,
      (sum, day) => sum + data[day]!.$1.fold(0.0, (s, sale) => s + sale.total),
    );
    final monthExpenses = days.fold<double>(
      0,
      (sum, day) => sum + data[day]!.$2.fold(0.0, (s, e) => s + e.amount),
    );

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
              day: days[i],
              daySales: data[days[i]]!.$1,
              dayExpenses: data[days[i]]!.$2,
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
    required this.day,
    required this.daySales,
    required this.dayExpenses,
    required this.currency,
    required this.last,
  });

  final DateTime day;
  final List<Sale> daySales;
  final List<Expense> dayExpenses;
  final String currency;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final deferred = daySales
        .where((s) => s.paymentMethod == 'آجل')
        .fold(0.0, (sum, s) => sum + s.total);
    final cash = daySales.fold(0.0, (sum, s) => sum + s.total) - deferred;
    final expensesTotal = dayExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final net = cash - expensesTotal;

    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DailyReportScreen(
              day: day,
              sales: daySales,
              expenses: dayExpenses,
            ),
          ),
        ),
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
                      '${AppFormatters.money(cash, currency)} بيع • ${AppFormatters.money(expensesTotal, currency)} مصروفات',
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

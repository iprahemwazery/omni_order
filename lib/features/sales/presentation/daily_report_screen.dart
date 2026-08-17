import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/payment_methods.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/expense.dart';
import '../../../domain/models/sale.dart';
import '../../settings/presentation/settings_cubit.dart';
import 'receipt_screen.dart';

/// تقرير يوم كامل منفصل: فواتير اليوم + مصروفات اليوم + ملخصات.
class DailyReportScreen extends StatelessWidget {
  const DailyReportScreen({
    super.key,
    required this.day,
    required this.sales,
    required this.expenses,
  });

  final DateTime day;
  final List<Sale> sales;
  final List<Expense> expenses;

  List<Sale> get _deferredSales =>
      sales.where((s) => s.paymentMethod == PaymentMethod.deferred).toList();

  double get cashRevenue =>
      sales.fold(0.0, (sum, s) => sum + s.total) -
      _deferredSales.fold(0.0, (sum, s) => sum + s.total);

  double get deferred => _deferredSales.fold(0.0, (sum, s) => sum + s.total);

  double get expensesTotal => expenses.fold(0.0, (sum, e) => sum + e.amount);

  double get net => cashRevenue - expensesTotal;

  @override
  Widget build(BuildContext context) {
    final currency = context.read<SettingsCubit>().state.settings.currency;

    return Scaffold(
      appBar: AppBar(title: Text(AppFormatters.arabicDate(day))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DayNetBanner(
              day: day,
              net: net,
              currency: currency,
            ),
            const SizedBox(height: 16),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              children: [
                _DayStat(
                  label: 'مبيعات نقدي',
                  value: AppFormatters.money(cashRevenue, currency),
                  icon: Icons.payments_outlined,
                  color: AppColors.primary,
                ),
                _DayStat(
                  label: 'مديونية (آجل)',
                  value: AppFormatters.money(deferred, currency),
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.error,
                ),
                _DayStat(
                  label: 'مصروفات',
                  value: AppFormatters.money(expensesTotal, currency),
                  icon: Icons.request_quote_outlined,
                  color: AppColors.warning,
                ),
                _DayStat(
                  label: 'فواتير',
                  value: '${sales.length}',
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.accent,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'فواتير اليوم',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (sales.isEmpty)
              const _EmptySection(
                icon: Icons.receipt_long_outlined,
                text: 'لا توجد فواتير في هذا اليوم',
              )
            else
              ...sales.map((sale) => _DaySaleTile(sale: sale)),
            const SizedBox(height: 24),
            Text(
              'مصروفات اليوم',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (expenses.isEmpty)
              const _EmptySection(
                icon: Icons.request_quote_outlined,
                text: 'لا توجد مصروفات في هذا اليوم',
              )
            else
              ...expenses.map((expense) => _DayExpenseTile(expense: expense)),
          ],
        ),
      ),
    );
  }
}

class _DayNetBanner extends StatelessWidget {
  const _DayNetBanner({
    required this.day,
    required this.net,
    required this.currency,
  });

  final DateTime day;
  final double net;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final profit = net >= 0;
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
              const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${AppFormatters.arabicWeekday(day)} • ${AppFormatters.arabicDate(day)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            profit ? 'صافي اليوم' : 'خسارة اليوم',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            AppFormatters.money(net.abs(), currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayStat extends StatelessWidget {
  const _DayStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

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
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
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
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySaleTile extends StatelessWidget {
  const _DaySaleTile({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final currency = context.read<SettingsCubit>().state.settings.currency;
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ReceiptScreen(sale: sale)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
        ),
        title: Text(
          AppFormatters.invoiceNumber(sale.id ?? 0),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          '${AppFormatters.time(sale.createdAt)} • ${sale.itemsCount} أصناف • ${sale.paymentMethod}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Text(
          AppFormatters.money(sale.total, currency),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _DayExpenseTile extends StatelessWidget {
  const _DayExpenseTile({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFBF3E6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.warning,
            size: 20,
          ),
        ),
        title: Text(
          expense.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          AppFormatters.time(expense.createdAt),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Text(
          AppFormatters.money(expense.amount),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

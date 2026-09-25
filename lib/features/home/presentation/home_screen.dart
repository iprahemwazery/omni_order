import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/admin.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../auth/presentation/auth_state.dart';
import '../../categories/presentation/categories_cubit.dart';
import '../../employees/presentation/employees_cubit.dart';
import '../../expenses/presentation/expenses_cubit.dart';
import '../../expenses/presentation/expenses_state.dart';
import '../../halls/presentation/halls_cubit.dart';
import '../../products/presentation/products_cubit.dart';
import '../../products/presentation/products_state.dart';
import '../../sales/presentation/sales_cubit.dart';
import '../../sales/presentation/sales_state.dart';
import '../../settings/presentation/settings_cubit.dart';
import '../../settings/presentation/settings_state.dart';
import '../../../shared/widgets/shell_section.dart';

/// لوحة التحكم (محتوى قسم "الرئيسية" داخل الهيكل الثابت):
/// ملخص اليوم + البطاقات الأساسية. لا تحتوي Scaffold أو قائمة جانبية؛
/// التنقل يحدث عبر [onSectionSelected] فيتغير المحتوى فقط.
class DashboardView extends StatelessWidget {
  const DashboardView({super.key, required this.onSectionSelected});

  final ValueChanged<ShellSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) => BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) => BlocBuilder<SalesCubit, SalesState>(
          builder: (context, sales) =>
              BlocBuilder<ProductsCubit, ProductsState>(
                builder: (context, products) =>
                    BlocBuilder<ExpensesCubit, ExpensesState>(
                      builder: (context, expenses) =>
                          BlocBuilder<EmployeesCubit, EmployeesState>(
                            builder: (context, employees) => _build(
                              context,
                              admin: auth.admin,
                              settings: settings,
                              sales: sales,
                              products: products,
                              expenses: expenses,
                              employees: employees,
                            ),
                          ),
                    ),
              ),
        ),
      ),
    );
  }

  Widget _build(
    BuildContext context, {
    required Admin? admin,
    required SettingsState settings,
    required SalesState sales,
    required ProductsState products,
    required ExpensesState expenses,
    required EmployeesState employees,
  }) {
    final loading =
        settings.loading ||
        sales.loading ||
        products.loading ||
        expenses.loading ||
        employees.loading;

    final error =
        settings.error ??
        sales.error ??
        products.error ??
        expenses.error ??
        employees.error;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        final settingsCubit = context.read<SettingsCubit>();
        final salesCubit = context.read<SalesCubit>();
        final productsCubit = context.read<ProductsCubit>();
        final expensesCubit = context.read<ExpensesCubit>();
        final categoriesCubit = context.read<CategoriesCubit>();
        final employeesCubit = context.read<EmployeesCubit>();
        final hallsCubit = context.read<HallsCubit>();
        await Future.wait([
          settingsCubit.init(),
          salesCubit.init(),
          productsCubit.init(),
          expensesCubit.init(),
          categoriesCubit.init(),
          employeesCubit.init(),
          hallsCubit.init(),
        ]);
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (error != null) ...[
                _ErrorBanner(message: error),
                const SizedBox(height: 14),
              ],
              _TodaySummary(
                revenueToday: sales.totals.cashToday,
                deferredToday: sales.totals.deferredToday,
                salesCount: sales.totals.countToday,
                productsCount: products.products.length,
                expensesToday: expenses.totals.today,
                currency: settings.settings.currency,
                employeesCount: employees.activeCount,
              ),
              if (products.outOfStock.isNotEmpty ||
                  products.lowStock.isNotEmpty) ...[
                const SizedBox(height: 14),
                _StockAlertBanner(
                  outOfStock: products.outOfStock.length,
                  lowStock: products.lowStock.length,
                  onTap: () => onSectionSelected(ShellSection.reports),
                ),
              ],
              const SizedBox(height: 20),
              _ActionsGrid(admin: admin, onSectionSelected: onSectionSelected),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({
    required this.revenueToday,
    required this.deferredToday,
    required this.salesCount,
    required this.productsCount,
    required this.expensesToday,
    required this.currency,
    required this.employeesCount,
  });

  final double revenueToday;
  final double deferredToday;
  final int salesCount;
  final int productsCount;
  final double expensesToday;
  final String currency;
  final int employeesCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إيرادات اليوم',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            AppFormatters.money(revenueToday, currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _SummaryItem(
                icon: Icons.receipt_long,
                label: 'طلبات',
                value: '$salesCount',
              ),
              _SummaryItem(
                icon: Icons.restaurant_menu,
                label: 'منيو',
                value: '$productsCount',
              ),
              _SummaryItem(
                icon: Icons.people_outline,
                label: 'موظفين',
                value: '$employeesCount',
              ),
              if (deferredToday > 0)
                _SummaryItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'آجل',
                  value: AppFormatters.money(deferredToday),
                ),
              if (expensesToday > 0)
                _SummaryItem(
                  icon: Icons.request_quote_outlined,
                  label: 'مصروفات',
                  value: AppFormatters.money(expensesToday),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
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
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StockAlertBanner extends StatelessWidget {
  const _StockAlertBanner({
    required this.outOfStock,
    required this.lowStock,
    required this.onTap,
  });

  final int outOfStock;
  final int lowStock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasOut = outOfStock > 0;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasOut
                  ? AppColors.error.withValues(alpha: 0.45)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: hasOut ? AppColors.error : AppColors.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تنبيهات المخزون',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      hasOut
                          ? '$outOfStock نفد • $lowStock على وشك النفاد'
                          : '$lowStock على وشك النفاد',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionsGrid extends StatelessWidget {
  const _ActionsGrid({required this.admin, required this.onSectionSelected});

  final Admin? admin;
  final ValueChanged<ShellSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final admin = this.admin;

    /// البطاقات الأساسية فقط في الرئيسية،
    /// وباقي الميزات الإضافية في القائمة الجانبية.
    final actions = <_ActionCard>[
      if (admin != null && admin.has(UserPermission.makeSales))
        _ActionCard(
          title: 'طلب جديد',
          subtitle: 'أوردر الصالة',
          icon: Icons.add_shopping_cart_outlined,
          gradient: const [AppColors.primary, AppColors.primaryDark],
          onTap: () => onSectionSelected(ShellSection.sales),
        ),
      if (admin != null && admin.has(UserPermission.makeSales))
        _ActionCard(
          title: 'أوردر الدليفري',
          subtitle: 'سنتر التليفونات والتوصيل',
          icon: Icons.delivery_dining_outlined,
          gradient: const [AppColors.primaryDark, Color(0xFF02331F)],
          onTap: () => onSectionSelected(ShellSection.delivery),
        ),
      if (admin != null && admin.has(UserPermission.manageProducts))
        _ActionCard(
          title: 'المنيو',
          subtitle: 'إدارة الأصناف والتصنيفات',
          icon: Icons.restaurant_menu,
          onTap: () => onSectionSelected(ShellSection.products),
        ),
      if (admin != null && admin.has(UserPermission.viewSales))
        _ActionCard(
          title: 'الوردية',
          subtitle: 'تقرير Z ومرتجعات الكاشير',
          icon: Icons.event_note_outlined,
          onTap: () => onSectionSelected(ShellSection.shift),
        ),
      if (admin != null && admin.has(UserPermission.viewReports))
        _ActionCard(
          title: 'التقارير',
          subtitle: 'التحليلات والتنبيهات',
          icon: Icons.bar_chart,
          onTap: () => onSectionSelected(ShellSection.reports),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: columns == 3 ? 1.7 : 1.45,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) => actions[index],
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.gradient,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    final isGradient = gradient != null;
    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isGradient ? LinearGradient(colors: gradient!) : null,
        color: isGradient ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isGradient ? null : Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: isGradient ? Colors.white : AppColors.primary,
            size: 24,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isGradient ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isGradient ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

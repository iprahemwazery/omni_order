import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/admin.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../categories/presentation/categories_cubit.dart';
import '../../customers/presentation/customers_cubit.dart';
import '../../customers/presentation/customers_state.dart';
import '../../expenses/presentation/expenses_cubit.dart';
import '../../expenses/presentation/expenses_state.dart';
import '../../products/presentation/products_cubit.dart';
import '../../products/presentation/products_state.dart';
import '../../sales/presentation/sales_cubit.dart';
import '../../sales/presentation/sales_state.dart';
import '../../sales/presentation/sales_screen.dart';
import '../../settings/presentation/settings_cubit.dart';
import '../../settings/presentation/settings_state.dart';
import '../../settings/presentation/settings_sheet.dart';
import '../../products/presentation/products_screen.dart';
import '../../purchases/presentation/purchases_screen.dart';
import '../../customers/presentation/customers_screen.dart';
import '../../expenses/presentation/expenses_screen.dart';
import '../../suppliers/presentation/suppliers_screen.dart';
import '../../sales/presentation/sales_history_screen.dart';
import '../../sales/presentation/reports_screen.dart';

/// الشاشة الرئيسية: ملخص اليوم + بوابات التطبيق.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) => BlocBuilder<SalesCubit, SalesState>(
        builder: (context, sales) => BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, products) =>
              BlocBuilder<CustomersCubit, CustomersState>(
                builder: (context, customers) =>
                    BlocBuilder<ExpensesCubit, ExpensesState>(
                      builder: (context, expenses) => _build(
                        context,
                        settings: settings,
                        sales: sales,
                        products: products,
                        customers: customers,
                        expenses: expenses,
                      ),
                    ),
              ),
        ),
      ),
    );
  }

  Widget _build(
    BuildContext context, {
    required SettingsState settings,
    required SalesState sales,
    required ProductsState products,
    required CustomersState customers,
    required ExpensesState expenses,
  }) {
    final loading =
        settings.loading ||
        sales.loading ||
        products.loading ||
        customers.loading ||
        expenses.loading;

    final error =
        settings.error ??
        sales.error ??
        products.error ??
        customers.error ??
        expenses.error;

    return Scaffold(
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  final settingsCubit = context.read<SettingsCubit>();
                  final salesCubit = context.read<SalesCubit>();
                  final productsCubit = context.read<ProductsCubit>();
                  final customersCubit = context.read<CustomersCubit>();
                  final expensesCubit = context.read<ExpensesCubit>();
                  final categoriesCubit = context.read<CategoriesCubit>();
                  await Future.wait([
                    settingsCubit.init(),
                    salesCubit.init(),
                    productsCubit.init(),
                    customersCubit.init(),
                    expensesCubit.init(),
                    categoriesCubit.init(),
                  ]);
                },
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (error != null) ...[
                      _ErrorBanner(message: error),
                      const SizedBox(height: 16),
                    ],
                    _Header(
                      storeName: settings.settings.storeName,
                      onSettings: () => showSettingsSheet(context),
                    ),
                    const SizedBox(height: 20),
                    _TodaySummary(
                      revenueToday: sales.cashRevenueOn(DateTime.now()),
                      deferredToday: sales.deferredOn(DateTime.now()),
                      salesCount: sales.sales.length,
                      productsCount: products.products.length,
                      totalDebts: customers.totalDebts,
                      expensesToday: expenses.expensesOn(DateTime.now()),
                      currency: settings.settings.currency,
                    ),
                    if (products.outOfStock.isNotEmpty ||
                        products.lowStock().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _StockAlertBanner(
                        outOfStock: products.outOfStock.length,
                        lowStock: products.lowStock().length,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _ActionsGrid(salesCount: sales.sales.length),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'نظام أومني أوردر لإدارة المحلات',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.storeName, required this.onSettings});

  final String storeName;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.storefront, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مرحبًا بك 👋',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              Text(
                storeName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onSettings,
          tooltip: 'الإعدادات',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
          ),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({
    required this.revenueToday,
    required this.deferredToday,
    required this.salesCount,
    required this.productsCount,
    required this.totalDebts,
    required this.expensesToday,
    required this.currency,
  });

  final double revenueToday;
  final double deferredToday;
  final int salesCount;
  final int productsCount;
  final double totalDebts;
  final double expensesToday;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مبيعات اليوم',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            AppFormatters.money(revenueToday, currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _SummaryItem(
                icon: Icons.receipt_long,
                label: 'فواتير',
                value: '$salesCount',
              ),
              _SummaryItem(
                icon: Icons.inventory_2,
                label: 'أصناف',
                value: '$productsCount',
              ),
              if (deferredToday > 0)
                _SummaryItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'آجل اليوم',
                  value: AppFormatters.money(deferredToday),
                ),
              if (totalDebts > 0)
                _SummaryItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'ديون',
                  value: AppFormatters.money(totalDebts),
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
  const _StockAlertBanner({required this.outOfStock, required this.lowStock});

  final int outOfStock;
  final int lowStock;

  @override
  Widget build(BuildContext context) {
    final hasOut = outOfStock > 0;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasOut ? const Color(0xFFF0D8D8) : AppColors.border,
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
  const _ActionsGrid({required this.salesCount});

  final int salesCount;

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AuthCubit>().state.admin;
    final actions = <_ActionCard>[
      if (admin != null && admin.has(UserPermission.makeSales))
        _ActionCard(
          title: 'بيع جديد',
          subtitle: 'ابدأ فاتورة بسرعة',
          icon: Icons.point_of_sale,
          gradient: const [AppColors.primary, AppColors.primaryDark],
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SalesScreen())),
        ),
      if (admin != null && admin.has(UserPermission.manageProducts))
        _ActionCard(
          title: 'المخزون',
          subtitle: 'إدارة الأصناف والتصنيفات',
          icon: Icons.inventory_2_outlined,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProductsScreen())),
        ),
      if (admin != null && admin.has(UserPermission.manageProducts))
        _ActionCard(
          title: 'الموردين',
          subtitle: 'إدارة الموردين والمديونيات',
          icon: Icons.local_shipping_outlined,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SuppliersScreen())),
        ),
      if (admin != null && admin.has(UserPermission.manageProducts))
        _ActionCard(
          title: 'المشتريات',
          subtitle: 'فواتير التوريد والموردين',
          icon: Icons.receipt_long_outlined,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PurchasesScreen())),
        ),
      if (admin != null && admin.has(UserPermission.viewSales))
        _ActionCard(
          title: 'المبيعات السابقة',
          subtitle: '$salesCount فاتورة',
          icon: Icons.receipt_long_outlined,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SalesHistoryScreen())),
        ),
      if (admin != null && admin.has(UserPermission.manageCustomers))
        _ActionCard(
          title: 'العملاء',
          subtitle: 'الديون والمديونيات',
          icon: Icons.people_outline,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CustomersScreen())),
        ),
      if (admin != null && admin.has(UserPermission.manageExpenses))
        _ActionCard(
          title: 'المصروفات',
          subtitle: 'تسجيل مصروفات اليوم',
          icon: Icons.request_quote_outlined,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ExpensesScreen())),
        ),
      if (admin != null && admin.has(UserPermission.viewReports))
        _ActionCard(
          title: 'التقارير',
          subtitle: 'التحليلات والتنبيهات',
          icon: Icons.bar_chart,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
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
            childAspectRatio: columns == 3 ? 1.35 : 1.15,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isGradient ? LinearGradient(colors: gradient!) : null,
        color: isGradient ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: isGradient ? null : Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: isGradient ? Colors.white : AppColors.primary,
            size: 30,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
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
                  fontSize: 12,
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
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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

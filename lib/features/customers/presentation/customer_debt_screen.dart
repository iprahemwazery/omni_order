import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/customer.dart';
import '../../../domain/models/customer_payment.dart';
import '../../../domain/models/sale.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../sales/presentation/receipt_screen.dart';
import '../../sales/presentation/sales_cubit.dart';
import '../../sales/presentation/sales_state.dart';
import '../../settings/presentation/settings_cubit.dart';
import 'customers_cubit.dart';
import 'customers_state.dart';

/// شاشة تفاصيل مديونية عميل: فواتيره الآجلة + المتبقي + تسجيل السداد.
class CustomerDebtScreen extends StatelessWidget {
  const CustomerDebtScreen({super.key, required this.customerId});

  final int? customerId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomersCubit, CustomersState>(
      builder: (context, customersState) {
        final customer = customersState.customerById(customerId);
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('العميل')),
            body: const Center(child: Text('العميل غير موجود.')),
          );
        }
        return BlocBuilder<SalesCubit, SalesState>(
          builder: (context, salesState) {
            final sales = salesState.sales
                .where((s) => s.customerId == customer.id)
                .toList();
            return _DebtBody(customer: customer, sales: sales);
          },
        );
      },
    );
  }
}

class _DebtBody extends StatelessWidget {
  const _DebtBody({required this.customer, required this.sales});

  final Customer customer;
  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    final currency = context.read<SettingsCubit>().state.settings.currency;
    final hasDebt = customer.balance > 0;
    final invoicesTotal = sales.fold(0.0, (sum, s) => sum + s.total);

    return Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(
              customer: customer,
              invoicesTotal: invoicesTotal,
              currency: currency,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'الفواتير الآجلة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  '${sales.length} فاتورة',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (sales.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'لا توجد فواتير آجلة',
                subtitle: 'فواتير هذا العميل الآجلة ستظهر هنا',
              )
            else
              ...sales.map((sale) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InvoiceTile(sale: sale, currency: currency),
                  )),
            const SizedBox(height: 8),
            _PaymentsSection(customer: customer),
            if (hasDebt) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => _recordPayment(context),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('تسجيل سداد'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _recordPayment(BuildContext context) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل سداد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'المديونية الحالية: ${AppFormatters.money(customer.balance)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'المبلغ المسدد'),
              onSubmitted: (_) =>
                  Navigator.of(context).pop(double.tryParse(controller.text)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(double.tryParse(controller.text)),
            child: const Text('تسجيل'),
          ),
        ],
      ),
    );

    if (amount == null || !context.mounted) return;
    final error = await context
        .read<CustomersCubit>()
        .recordCustomerPayment(customer, amount);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.customer,
    required this.invoicesTotal,
    required this.currency,
  });

  final Customer customer;
  final double invoicesTotal;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final hasDebt = customer.balance > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: hasDebt
                        ? const Color(0xFFFBE9E9)
                        : const Color(0xFFE8F1EF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 28,
                    color: hasDebt ? AppColors.error : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (customer.phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          customer.phone,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _SummaryItem(
                  label: 'إجمالي الفواتير',
                  value: AppFormatters.money(invoicesTotal, currency),
                  color: AppColors.textPrimary,
                ),
                _SummaryItem(
                  label: 'المسدد',
                  value: AppFormatters.money(
                    invoicesTotal - customer.balance,
                    currency,
                  ),
                  color: AppColors.success,
                ),
                _SummaryItem(
                  label: 'المتبقي',
                  value: AppFormatters.money(customer.balance, currency),
                  color: hasDebt ? AppColors.error : AppColors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// سجل دفعات هذا العميل (الأحدث أولًا).
class _PaymentsSection extends StatelessWidget {
  const _PaymentsSection({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final currency = context.read<SettingsCubit>().state.settings.currency;
    return FutureBuilder<List<CustomerPayment>>(
      future: context.read<CustomersCubit>().paymentsOf(customer),
      builder: (context, snapshot) {
        final payments = snapshot.data ?? const <CustomerPayment>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'سجل السداد (${payments.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (payments.isEmpty)
              const _CardEmpty(
                icon: Icons.payments_outlined,
                text: 'لا توجد دفعات مسجلة',
              )
            else
              ...payments.map(
                (payment) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F5EE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.payments_outlined,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        AppFormatters.money(payment.amount, currency),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                      subtitle: Text(
                        AppFormatters.dateTime(payment.createdAt),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CardEmpty extends StatelessWidget {
  const _CardEmpty({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.sale, required this.currency});

  final Sale sale;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ReceiptScreen(sale: sale)),
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.receipt_long, color: AppColors.primary),
        ),
        title: Text(
          AppFormatters.invoiceNumber(sale.id ?? 0),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          AppFormatters.dateTime(sale.createdAt),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Text(
          AppFormatters.money(sale.total, currency),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

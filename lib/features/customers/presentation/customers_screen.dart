import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/customer.dart';
import '../../../shared/widgets/add_customer_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import 'customer_debt_screen.dart';
import 'customers_cubit.dart';

/// شاشة العملاء: إدارة العملاء والمديونيات وتسجيل السداد.
class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CustomersCubit>().state;
    final totalDebts = state.totalDebts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('العملاء'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Center(
              child: totalDebts > 0
                  ? Text(
                      'ديون: ${AppFormatters.money(totalDebts)}',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : const Text(
                      'لا توجد ديون',
                      style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCustomer(context),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('إضافة عميل'),
      ),
      body: SafeArea(
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : state.customers.isEmpty
                ? const EmptyState(
                    icon: Icons.people_outline,
                    title: 'لا يوجد عملاء',
                    subtitle: 'أضف عملاء لتسجيل البيع الآجل والمتابعة',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: state.customers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final customer = state.customers[index];
                      return _CustomerTile(customer: customer);
                    },
                  ),
      ),
    );
  }

  Future<void> _addCustomer(BuildContext context) async {
    final result = await showAddCustomerDialog(context);
    if (result == null || !context.mounted) return;
    final error = await context
        .read<CustomersCubit>()
        .addCustomer(result.$1, phone: result.$2);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final hasDebt = customer.balance > 0;
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomerDebtScreen(customerId: customer.id),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: hasDebt ? const Color(0xFFFBE9E9) : const Color(0xFFE8F1EF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.person_outline,
            color: hasDebt ? AppColors.error : AppColors.primary,
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.phone.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                customer.phone,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              hasDebt
                  ? 'مديونية: ${AppFormatters.money(customer.balance)}'
                  : 'لا توجد مديونية',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: hasDebt ? AppColors.error : AppColors.success,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'pay') _recordPayment(context);
            if (value == 'delete') _confirmDelete(context);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'pay', child: Text('تسجيل سداد')),
            PopupMenuItem(value: 'delete', child: Text('حذف')),
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

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العميل؟'),
        content: Text('هل أنت متأكد من حذف "${customer.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<CustomersCubit>().deleteCustomer(customer);
    }
  }
}


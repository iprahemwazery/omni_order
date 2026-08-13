import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/expense.dart';
import '../../../shared/widgets/empty_state.dart';
import 'expenses_cubit.dart';

/// شاشة المصروفات اليومية.
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExpensesCubit>().state;
    final todayExpenses = state.expensesOn(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('المصروفات'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Center(
              child: Text(
                'اليوم: ${AppFormatters.money(todayExpenses)}',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addExpense(context),
        icon: const Icon(Icons.add),
        label: const Text('تسجيل مصروف'),
      ),
      body: SafeArea(
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : state.expenses.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_outlined,
                    title: 'لا توجد مصروفات',
                    subtitle: 'سجّل مصاريفك اليومية (إيجار، كهرباء...)',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: state.expenses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final expense = state.expenses[index];
                      return _ExpenseTile(expense: expense);
                    },
                  ),
      ),
    );
  }

  Future<void> _addExpense(BuildContext context) async {
    final result = await _showExpenseDialog(context);
    if (result == null || !context.mounted) return;
    final error = await context
        .read<ExpensesCubit>()
        .addExpense(result.$1, result.$2);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFFBF3E6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.warning),
        ),
        title: Text(
          expense.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          AppFormatters.dateTime(expense.createdAt),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppFormatters.money(expense.amount),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.error,
              ),
            ),
            IconButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('حذف المصروف؟'),
                    content: Text('حذف "${expense.name}"؟'),
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
                  await context.read<ExpensesCubit>().deleteExpense(expense);
                }
              },
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

Future<(String, double)?> _showExpenseDialog(BuildContext context) {
  final name = TextEditingController();
  final amount = TextEditingController();
  return showDialog<(String, double)>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('تسجيل مصروف'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'السبب *',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'المبلغ *',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            (name.text, double.tryParse(amount.text) ?? 0),
          ),
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
}

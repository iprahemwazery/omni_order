import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/employee.dart';
import '../../../domain/models/rider_transaction.dart';
import '../../../domain/repositories/store_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../settings/presentation/settings_cubit.dart';
import 'rider_balance_cubit.dart';

/// شاشة إدارة رصيد مندوبين التوصيل.
class RiderBalanceScreen extends StatelessWidget {
  const RiderBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RiderBalanceCubit?>();
    if (cubit != null) {
      return BlocProvider.value(value: cubit, child: const _RiderBalanceBody());
    }
    return BlocProvider(
      create: (context) =>
          RiderBalanceCubit(context.read<StoreRepository>())..init(),
      child: const _RiderBalanceBody(),
    );
  }
}

class _RiderBalanceBody extends StatelessWidget {
  const _RiderBalanceBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ScreenHeader(title: 'مندوبين التوصيل'),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<RiderBalanceCubit, RiderBalanceState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.error != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () =>
                              context.read<RiderBalanceCubit>().init(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }
                if (state.riders.isEmpty) {
                  return const EmptyState(
                    icon: Icons.delivery_dining_outlined,
                    title: 'لا يوجد مندوبين',
                    subtitle:
                        'أضف مندوبين من شاشة إدارة الموظفين برole "دليفري"',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.riders.length,
                  itemBuilder: (context, index) {
                    final rider = state.riders[index];
                    final balance = state.balances[rider.id!] ?? 0;
                    final txns = state.transactions[rider.id!] ?? [];
                    final outstanding =
                        state.outstandingOrders[rider.id!] ?? [];
                    return _RiderCard(
                      rider: rider,
                      balance: balance,
                      transactions: txns,
                      outstandingOrders: outstanding,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderCard extends StatelessWidget {
  const _RiderCard({
    required this.rider,
    required this.balance,
    required this.transactions,
    required this.outstandingOrders,
  });

  final Employee rider;
  final double balance;
  final List<RiderTransaction> transactions;
  final List outstandingOrders;

  @override
  Widget build(BuildContext context) {
    final currency = context.read<SettingsCubit>().state.settings.currency;
    final isOwed = balance > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRiderDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delivery_dining,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rider.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        if (rider.phone.isNotEmpty)
                          Text(
                            rider.phone,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppFormatters.money(balance, currency),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: isOwed ? AppColors.warning : AppColors.success,
                        ),
                      ),
                      Text(
                        isOwed ? 'عليه' : 'له',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOwed ? AppColors.warning : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (outstandingOrders.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${outstandingOrders.length} أوردر معلق',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRiderDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RiderDetailsSheet(
        rider: rider,
        balance: balance,
        transactions: transactions,
        outstandingOrders: outstandingOrders,
      ),
    );
  }
}

class _RiderDetailsSheet extends StatelessWidget {
  const _RiderDetailsSheet({
    required this.rider,
    required this.balance,
    required this.transactions,
    required this.outstandingOrders,
  });

  final Employee rider;
  final double balance;
  final List<RiderTransaction> transactions;
  final List outstandingOrders;

  @override
  Widget build(BuildContext context) {
    final currency = context.read<SettingsCubit>().state.settings.currency;
    final isOwed = balance > 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.delivery_dining,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rider.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (rider.phone.isNotEmpty)
                            Text(
                              rider.phone,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOwed
                          ? [AppColors.warning, const Color(0xFFE65100)]
                          : [AppColors.success, const Color(0xFF2E7D32)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isOwed ? 'المبلغ المستحق' : 'الرصيد المتاح',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppFormatters.money(balance.abs(), currency),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (outstandingOrders.isNotEmpty) ...[
                  const Text(
                    'الطلبات المعلقة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  ...outstandingOrders.map(
                    (order) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            size: 20,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'أوردر #${order.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  order.deliveryPersonName.isNotEmpty
                                      ? order.deliveryPersonName
                                      : order.deliveryAddress,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            AppFormatters.money(order.total, currency),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showSettlementDialog(context),
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('تسديد'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAdvanceDialog(context),
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                        label: const Text('سلفة'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'سجل المعاملات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'لا توجد معاملات بعد',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...transactions.map(
                    (txn) =>
                        _TransactionTile(transaction: txn, currency: currency),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettlementDialog(BuildContext context) {
    final controller = TextEditingController();
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل تسديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                prefixText: 'ج.م ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                context.read<RiderBalanceCubit>().addSettlement(
                  rider.id!,
                  amount,
                  note: noteController.text,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('تسجيل'),
          ),
        ],
      ),
    );
  }

  void _showAdvanceDialog(BuildContext context) {
    final controller = TextEditingController();
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل سلفة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                prefixText: 'ج.م ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                context.read<RiderBalanceCubit>().addAdvance(
                  rider.id!,
                  amount,
                  note: noteController.text,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('تسجيل'),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.currency});

  final RiderTransaction transaction;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isCollection =
        transaction.type == RiderTransactionType.orderCollection;
    final isSettlement = transaction.type == RiderTransactionType.settlement;
    final icon = isCollection
        ? Icons.arrow_downward
        : isSettlement
        ? Icons.arrow_upward
        : Icons.account_balance_wallet_outlined;
    final color = isCollection
        ? AppColors.success
        : isSettlement
        ? AppColors.error
        : AppColors.info;
    final label = transaction.type.label;
    final amountPrefix = isCollection ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (transaction.note.isNotEmpty)
                  Text(
                    transaction.note,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  AppFormatters.date(transaction.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$amountPrefix${AppFormatters.money(transaction.amount, currency)}',
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

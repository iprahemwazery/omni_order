import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/payment_methods.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/restaurant_table.dart';
import '../../../domain/models/admin.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../orders/presentation/order_form_screen.dart';
import 'tables_cubit.dart';

class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'إدارة الترابيزات',
            actions: [
              IconButton(
                onPressed: () => _showAddTableDialog(context),
                icon: const Icon(Icons.add),
                tooltip: 'إضافة تريبية',
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<TablesCubit, TablesState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  children: [
                    if (state.halls.isNotEmpty)
                      SizedBox(
                        height: 56,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          children: [
                            _HallChip(
                              label: 'الكل',
                              selected: state.selectedHallId == null,
                              onTap: () =>
                                  context.read<TablesCubit>().selectHall(null),
                            ),
                            for (final hall in state.halls)
                              _HallChip(
                                label: hall.name,
                                selected: state.selectedHallId == hall.id,
                                onTap: () => context
                                    .read<TablesCubit>()
                                    .selectHall(hall.id),
                              ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          _StatusBadge(
                            label: 'فارغة',
                            count: state.availableCount,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          _StatusBadge(
                            label: 'مشغولة',
                            count: state.occupiedCount,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 12),
                          _StatusBadge(
                            label: 'محجوزة',
                            count: state.reservedCount,
                            color: AppColors.warning,
                          ),
                          const Spacer(),
                          Text(
                            'الكل: ${state.tables.length}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: state.filteredTables.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.table_restaurant_outlined,
                                    size: 64,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'لا توجد ترابيزات',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1.0,
                                  ),
                              itemCount: state.filteredTables.length,
                              itemBuilder: (context, index) => _TableCard(
                                table: state.filteredTables[index],
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTableDialog(BuildContext context) {
    final state = context.read<TablesCubit>().state;
    if (state.halls.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يجب إنشاء صالة أولاً')));
      return;
    }
    int? selectedHallId = state.selectedHallId ?? state.halls.first.id;
    final numberController = TextEditingController();
    final capacityController = TextEditingController(text: '4');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة تريبية جديدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedHallId,
                decoration: const InputDecoration(labelText: 'الصالة'),
                items: state.halls
                    .map(
                      (h) => DropdownMenuItem(value: h.id, child: Text(h.name)),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedHallId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'رقم التريبية'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'السعة (عدد الأشخاص)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                if (selectedHallId == null) return;
                final number = int.tryParse(numberController.text);
                if (number == null) return;
                final capacity = int.tryParse(capacityController.text) ?? 4;
                await context.read<TablesCubit>().addTable(
                  hallId: selectedHallId!,
                  number: number,
                  capacity: capacity,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.table});
  final RestaurantTable table;

  Color get _statusColor {
    switch (table.status) {
      case TableStatus.available:
        return AppColors.success;
      case TableStatus.occupied:
        return AppColors.error;
      case TableStatus.reserved:
        return AppColors.warning;
      case TableStatus.cleaning:
        return AppColors.textSecondary;
    }
  }

  IconData get _statusIcon {
    switch (table.status) {
      case TableStatus.available:
        return Icons.check_circle_outline;
      case TableStatus.occupied:
        return Icons.hourglass_empty;
      case TableStatus.reserved:
        return Icons.bookmark_outline;
      case TableStatus.cleaning:
        return Icons.cleaning_services_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AuthCubit>().state.admin;
    final canManage = admin?.has(UserPermission.manageTables) ?? false;

    return Material(
      color: _statusColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: canManage
            ? () {
                if (table.status == TableStatus.occupied) {
                  _showOccupiedTableOptions(context);
                } else {
                  _showTableOptions(context);
                }
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_statusIcon, color: _statusColor, size: 28),
              const SizedBox(height: 6),
              Text(
                '${table.number}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _statusColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${table.capacity} أشخاص',
                style: TextStyle(
                  fontSize: 11,
                  color: _statusColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                table.status.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _statusColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOccupiedTableOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'تريبية رقم ${table.number} - مشغولة',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.shopping_cart_outlined,
                color: AppColors.primary,
              ),
              title: const Text('إضافة أوردر جديد'),
              subtitle: const Text('إضافة أوردر إضافي على التريبية'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        OrderFormScreen(preselectedTableId: table.id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: AppColors.info),
              title: const Text('عرض الأوردرات'),
              subtitle: const Text('عرض الطلبات الحالية على التريبية'),
              onTap: () {
                Navigator.pop(ctx);
                _showTableOrders(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment, color: AppColors.success),
              title: const Text('سداد / تسوية'),
              subtitle: const Text('تسوية كل الطلبات وإ frees التريبية'),
              onTap: () {
                Navigator.pop(ctx);
                _showPayTableDialog(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showTableOrders(BuildContext context) async {
    final cubit = context.read<TablesCubit>();
    final orders = await cubit.getTableOrders(table.id!);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('أوردرات التريبية ${table.number}'),
        content: SizedBox(
          width: double.maxFinite,
          child: orders.isEmpty
              ? const Center(child: Text('لا توجد أوردرات نشطة'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _orderStatusColor(
                          order.orderStatus,
                        ).withValues(alpha: 0.1),
                        child: Icon(
                          _orderStatusIcon(order.orderStatus),
                          color: _orderStatusColor(order.orderStatus),
                          size: 20,
                        ),
                      ),
                      title: Text('أوردر #${order.id}'),
                      subtitle: Text(order.orderStatus.label),
                      trailing: Text(
                        AppFormatters.money(order.total),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showPayTableDialog(BuildContext context) {
    String paymentMethod = PaymentMethod.cash;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('تسوية التريبية ${table.number}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختر طريقة السداد:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                decoration: const InputDecoration(labelText: 'طريقة السداد'),
                items: const [
                  DropdownMenuItem(
                    value: PaymentMethod.cash,
                    child: Text('نقدي'),
                  ),
                  DropdownMenuItem(
                    value: PaymentMethod.card,
                    child: Text('شبكة'),
                  ),
                  DropdownMenuItem(
                    value: PaymentMethod.wallet,
                    child: Text('محفظة'),
                  ),
                ],
                onChanged: (v) => setDialogState(() => paymentMethod = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final cubit = context.read<TablesCubit>();
                final total = await cubit.payTable(table.id!, paymentMethod);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم سداد التريبية بنجاح - الإجمالي: ${AppFormatters.money(total)}',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('تسديد'),
            ),
          ],
        ),
      ),
    );
  }

  Color _orderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.preparing:
        return AppColors.info;
      case OrderStatus.ready:
        return AppColors.success;
      case OrderStatus.served:
        return AppColors.textSecondary;
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.outForDelivery:
        return AppColors.warning;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.handedOver:
        return AppColors.info;
      case OrderStatus.awaitingPayment:
        return AppColors.primary;
      case OrderStatus.paid:
        return AppColors.success;
    }
  }

  IconData _orderStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending_actions;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.check_circle_outline;
      case OrderStatus.served:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.handedOver:
        return Icons.handshake;
      case OrderStatus.awaitingPayment:
        return Icons.payment;
      case OrderStatus.paid:
        return Icons.payments;
    }
  }

  void _showTableOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'تريبية رقم ${table.number}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (table.status != TableStatus.available)
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                title: const Text('تحرير التريبية'),
                onTap: () async {
                  await context.read<TablesCubit>().updateStatus(
                    table.id!,
                    TableStatus.available,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            if (table.status != TableStatus.reserved)
              ListTile(
                leading: const Icon(
                  Icons.bookmark_outline,
                  color: AppColors.warning,
                ),
                title: const Text('حجز التريبية'),
                onTap: () async {
                  await context.read<TablesCubit>().updateStatus(
                    table.id!,
                    TableStatus.reserved,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            if (table.status != TableStatus.cleaning)
              ListTile(
                leading: const Icon(
                  Icons.cleaning_services_outlined,
                  color: AppColors.textSecondary,
                ),
                title: const Text('وضع التنظيف'),
                onTap: () async {
                  await context.read<TablesCubit>().updateStatus(
                    table.id!,
                    TableStatus.cleaning,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
              ),
              title: const Text('تعديل'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditDialog(context, table);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text(
                'حذف',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    title: const Text('حذف التريبية'),
                    content: Text(
                      'هل أنت متأكد من حذف التريبية رقم ${table.number}؟',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dctx, false),
                        child: const Text('إلغاء'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  await context.read<TablesCubit>().deleteTable(table.id!);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, RestaurantTable table) {
    final capacityController = TextEditingController(text: '${table.capacity}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل التريبية'),
        content: TextField(
          controller: capacityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'السعة (عدد الأشخاص)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              final capacity =
                  int.tryParse(capacityController.text) ?? table.capacity;
              await context.read<TablesCubit>().updateTable(
                table.copyWith(capacity: capacity),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _HallChip extends StatelessWidget {
  const _HallChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        showCheckmark: false,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.count,
    required this.color,
  });
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

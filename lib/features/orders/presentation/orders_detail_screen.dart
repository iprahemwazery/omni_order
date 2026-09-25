import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/order_item.dart';
import '../../../domain/repositories/store_repository.dart';
import '../../settings/presentation/settings_cubit.dart';
import '../domain/usecases/orders_usecases.dart';

/// شاشة تفاصيل طلب واحد.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RestaurantOrder?>(
      future: _loadOrder(context, orderId),
      builder: (context, orderSnapshot) {
        final order = orderSnapshot.data;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('الطلب')),
            body: const Center(child: Text('الطلب غير موجود')),
          );
        }

        return FutureBuilder<List<OrderItem>>(
          future: _loadOrderItems(context, orderId),
          builder: (context, itemsSnapshot) {
            final items = itemsSnapshot.data ?? [];

            return Scaffold(
              appBar: AppBar(
                title: Text('طلب #${order.id}'),
                actions: [
                  if (order.orderStatus != OrderStatus.served &&
                      order.orderStatus != OrderStatus.cancelled)
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'cancel') {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('إلغاء الطلب'),
                              content: const Text(
                                'هل أنت متأكد من إلغاء هذا الطلب؟',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('لا'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                  ),
                                  child: const Text('إلغاء الطلب'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            if (!context.mounted) return;
                            await _cancelOrder(context, orderId);
                            if (context.mounted) Navigator.pop(context);
                          }
                        } else if (value == 'preparing') {
                          await _updateOrderStatus(
                            context,
                            orderId,
                            OrderStatus.preparing,
                          );
                          if (context.mounted) Navigator.pop(context);
                        } else if (value == 'ready') {
                          await _updateOrderStatus(
                            context,
                            orderId,
                            OrderStatus.ready,
                          );
                          if (context.mounted) Navigator.pop(context);
                        } else if (value == 'served') {
                          await _updateOrderStatus(
                            context,
                            orderId,
                            OrderStatus.served,
                          );
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      itemBuilder: (context) => [
                        if (order.orderStatus == OrderStatus.pending)
                          const PopupMenuItem(
                            value: 'preparing',
                            child: Text('بدء التحضير'),
                          ),
                        if (order.orderStatus == OrderStatus.preparing)
                          const PopupMenuItem(
                            value: 'ready',
                            child: Text('جاهز للتقديم'),
                          ),
                        if (order.orderStatus == OrderStatus.ready)
                          const PopupMenuItem(
                            value: 'served',
                            child: Text('تم التقديم'),
                          ),
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Text(
                            'إلغاء الطلب',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _OrderInfoCard(order: order),
                  const SizedBox(height: 16),
                  const Text(
                    'بنود الطلب',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((item) => _OrderItemTile(item: item)),
                  if (order.note.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.note_outlined,
                            size: 20,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.note,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Future<RestaurantOrder?> _loadOrder(BuildContext context, int orderId) async {
  final getOrderDetails = context.read<GetOrderDetails?>();
  if (getOrderDetails == null) {
    return context.read<StoreRepository>().getOrder(orderId);
  }
  try {
    return (await getOrderDetails(orderId)).order;
  } on StateError {
    return null;
  }
}

Future<List<OrderItem>> _loadOrderItems(
  BuildContext context,
  int orderId,
) async {
  final getOrderDetails = context.read<GetOrderDetails?>();
  if (getOrderDetails == null) {
    return context.read<StoreRepository>().getOrderItems(orderId);
  }
  try {
    return (await getOrderDetails(orderId)).items;
  } on StateError {
    return const [];
  }
}

Future<void> _cancelOrder(BuildContext context, int orderId) {
  final cancelOrder = context.read<CancelOrder?>();
  return cancelOrder == null
      ? context.read<StoreRepository>().cancelOrder(orderId)
      : cancelOrder(orderId);
}

Future<void> _updateOrderStatus(
  BuildContext context,
  int orderId,
  OrderStatus status,
) {
  final updateOrderStatus = context.read<UpdateOrderStatus?>();
  return updateOrderStatus == null
      ? context.read<StoreRepository>().updateOrderStatus(orderId, status)
      : updateOrderStatus(orderId, status);
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({required this.order});
  final RestaurantOrder order;

  Color get _statusColor {
    switch (order.orderStatus) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.preparing:
        return AppColors.primary;
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

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الطلب #${order.id}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.orderStatus.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          _InfoRow(
            icon: Icons.access_time,
            label: 'التاريخ',
            value: AppFormatters.dateTime(order.createdAt),
          ),
          _InfoRow(
            icon: Icons.table_restaurant_outlined,
            label: 'التريبية',
            value: order.isTakeaway ? 'Take-Away' : '${order.tableId ?? "-"}',
          ),
          _InfoRow(
            icon: Icons.payment,
            label: 'طريقة الدفع',
            value: order.paymentMethod,
          ),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'الكاشير',
            value: order.cashierName.isNotEmpty ? order.cashierName : '-',
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الإجمالي',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                AppFormatters.money(order.total, settings.settings.currency),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});
  final OrderItem item;

  Color get _itemStatusColor {
    switch (item.status) {
      case 'pending':
        return AppColors.warning;
      case 'preparing':
        return AppColors.primary;
      case 'ready':
        return AppColors.success;
      case 'served':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _itemStatusColor.withValues(alpha: 0.1),
          child: Text(
            item.quantity.toStringAsFixed(0),
            style: TextStyle(
              color: _itemStatusColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: item.notes.isNotEmpty
            ? Text(
                item.notes,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        trailing: Text(
          AppFormatters.money(item.subtotal),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

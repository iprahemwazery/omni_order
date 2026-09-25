import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/order.dart';
import '../../../shared/widgets/screen_header.dart';
import 'delivery_cubit.dart';

/// شاشة سنتر التليفونات - إدارة طلبات التوصيل.
class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'سنتر التليفونات',
            actions: [
              IconButton(
                onPressed: () => context.read<DeliveryCubit>().init(),
                icon: const Icon(Icons.refresh),
                tooltip: 'تحديث',
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<DeliveryCubit, DeliveryState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.error != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.read<DeliveryCubit>().init(),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }
                if (state.activeOrders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delivery_dining_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد طلبات توصيل نشطة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'يمكنك إنشاء أوردر جديد من شاشة الطلبات',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.activeOrders.length,
                  itemBuilder: (context, index) => _DeliveryOrderCard(
                    order: state.activeOrders[index],
                    onStatusUpdate: (status) async {
                      await context.read<DeliveryCubit>().updateOrderStatus(
                        state.activeOrders[index].id!,
                        status,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryOrderCard extends StatelessWidget {
  const _DeliveryOrderCard({required this.order, required this.onStatusUpdate});
  final RestaurantOrder order;
  final ValueChanged<OrderStatus> onStatusUpdate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(
                      order.orderStatus,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.orderStatus.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _statusColor(order.orderStatus),
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'أوردر #${order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.access_time,
              text: _formatTime(order.createdAt),
            ),
            if (order.deliveryPhone.isNotEmpty)
              _InfoRow(icon: Icons.phone_outlined, text: order.deliveryPhone),
            if (order.deliveryAddress.isNotEmpty)
              _InfoRow(
                icon: Icons.location_on_outlined,
                text: order.deliveryAddress,
              ),
            if (order.deliveryPersonName.isNotEmpty)
              _InfoRow(
                icon: Icons.person_outlined,
                text: 'الدليفري: ${order.deliveryPersonName}',
              ),
            if (order.deliveryNotes.isNotEmpty)
              _InfoRow(icon: Icons.note_outlined, text: order.deliveryNotes),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الإجمالي',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  AppFormatters.money(order.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (order.orderStatus == OrderStatus.pending)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => onStatusUpdate(OrderStatus.preparing),
                      icon: const Icon(Icons.restaurant, size: 18),
                      label: const Text('بدء التحضير'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.warning,
                      ),
                    ),
                  ),
                if (order.orderStatus == OrderStatus.preparing) ...[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => onStatusUpdate(OrderStatus.ready),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('جاهز للتوصيل'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                ],
                if (order.orderStatus == OrderStatus.ready)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          onStatusUpdate(OrderStatus.outForDelivery),
                      icon: const Icon(Icons.delivery_dining, size: 18),
                      label: const Text('خرج للتوصيل'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                      ),
                    ),
                  ),
                if (order.orderStatus == OrderStatus.outForDelivery)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => onStatusUpdate(OrderStatus.delivered),
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('تم التوصيل'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                if (order.orderStatus == OrderStatus.delivered)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'تم التوصيل ✓',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m - ${dt.day}/${dt.month}';
  }

  Color _statusColor(OrderStatus status) {
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
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

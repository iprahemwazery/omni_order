import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/order.dart';
import '../../../domain/repositories/store_repository.dart';
import '../../../shared/widgets/screen_header.dart';
import '../domain/usecases/orders_usecases.dart';
import '../../settings/presentation/settings_cubit.dart';
import 'orders_detail_screen.dart';

/// شاشة سجل الطلبات السابقة.
class OrdersHistoryScreen extends StatelessWidget {
  const OrdersHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ScreenHeader(title: 'الطلبات'),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<RestaurantOrder>>(
              future: _loadOrders(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد طلبات بعد',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) =>
                      _OrderCard(order: orders[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<RestaurantOrder>> _loadOrders(BuildContext context) {
  final getOrders = context.read<GetOrders?>();
  return getOrders == null
      ? context.read<StoreRepository>().getOrders()
      : getOrders();
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id!),
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: _statusColor.withValues(alpha: 0.1),
          child: Text(
            '#${order.id}',
            style: TextStyle(
              color: _statusColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                order.isTakeaway
                    ? 'Take-Away'
                    : 'تريبية ${order.tableId ?? "-"}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                order.orderStatus.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppFormatters.dateTime(order.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppFormatters.money(order.total, settings.settings.currency),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_left,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

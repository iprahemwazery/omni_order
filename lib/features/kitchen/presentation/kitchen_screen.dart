import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/order_item.dart';
import '../../../domain/repositories/store_repository.dart';
import '../domain/usecases/kitchen_usecases.dart';
import 'kitchen_cubit.dart';

/// شاشة عرض المطبخ (Kitchen Display System - KDS).
///
/// تعرض جميع الطلبات النشطة (pending / preparing / ready) على شكل بطاقات
/// مع تحديث تلقائي كل 5 ثوانٍ وإمكانية تحديث حالة كل طلب.
class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  late final KitchenCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<KitchenCubit>();
    _cubit.init();
    _cubit.startAutoRefresh();
  }

  @override
  void dispose() {
    _cubit.stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                const Text(
                  'المطبخ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const Spacer(),
                BlocBuilder<KitchenCubit, KitchenState>(
                  builder: (context, state) {
                    final pending = state.orders
                        .where((o) => o.orderStatus == OrderStatus.pending)
                        .length;
                    final preparing = state.orders
                        .where((o) => o.orderStatus == OrderStatus.preparing)
                        .length;
                    final ready = state.orders
                        .where((o) => o.orderStatus == OrderStatus.ready)
                        .length;
                    return Row(
                      children: [
                        _StatusBadge(
                          label: 'جديد',
                          count: pending,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        _StatusBadge(
                          label: 'تحضير',
                          count: preparing,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 6),
                        _StatusBadge(
                          label: 'جاهز',
                          count: ready,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () => context.read<KitchenCubit>().init(),
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          tooltip: 'تحديث',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<KitchenCubit, KitchenState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
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
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.read<KitchenCubit>().init(),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }
                if (state.orders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.kitchen_outlined,
                          size: 80,
                          color: Color(0xFF4A4A6A),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'المطبخ فاضي',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'فيه أوردر جديد هيظهر هنا تلقائياً',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 3
                        : (constraints.maxWidth >= 600 ? 2 : 1);
                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: state.orders.length,
                      itemBuilder: (context, index) =>
                          _KitchenOrderCard(order: state.orders[index]),
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

Future<List<OrderItem>> _loadItems(BuildContext context, int orderId) {
  final getItems = context.read<GetKitchenOrderItems?>();
  return getItems == null
      ? context.read<StoreRepository>().getOrderItems(orderId)
      : getItems(orderId);
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
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
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KitchenOrderCard extends StatefulWidget {
  const _KitchenOrderCard({required this.order});
  final RestaurantOrder order;

  @override
  State<_KitchenOrderCard> createState() => _KitchenOrderCardState();
}

class _KitchenOrderCardState extends State<_KitchenOrderCard> {
  late Timer _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.order.createdAt);
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(widget.order.createdAt);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.order.orderStatus) {
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
      default:
        return AppColors.textSecondary;
    }
  }

  Color get _cardBorder {
    switch (widget.order.orderStatus) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.preparing:
        return AppColors.info;
      case OrderStatus.ready:
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _elapsedText {
    final mins = _elapsed.inMinutes;
    if (mins < 1) return 'الآن';
    if (mins < 60) return '$mins دقيقة';
    final hrs = mins ~/ 60;
    final rem = mins % 60;
    return '$hrs ساعة${rem > 0 ? ' و $rem دقيقة' : ''}';
  }

  bool get _isUrgent => _elapsed.inMinutes >= 20;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return FutureBuilder<List<OrderItem>>(
      future: _loadItems(context, order.id!),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _cardBorder.withValues(alpha: 0.6),
              width: _isUrgent ? 2.5 : 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.orderStatus.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '#${order.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: _isUrgent
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _elapsedText,
                      style: TextStyle(
                        color: _isUrgent
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontWeight: _isUrgent
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (order.orderType != OrderType.hall.name) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          OrderType.fromName(order.orderType).label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (order.tableId != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.table_restaurant,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'تربيزة ${order.tableId}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.border,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${item.quantity.toStringAsFixed(0)}x',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (item.notes.isNotEmpty)
                                        Text(
                                          item.notes,
                                          style: const TextStyle(
                                            color: AppColors.warning,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (order.note.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.note_outlined,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.note,
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    if (order.orderStatus == OrderStatus.pending)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              context.read<KitchenCubit>().updateOrderStatus(
                                order.id!,
                                OrderStatus.preparing,
                              ),
                          icon: const Icon(Icons.restaurant, size: 18),
                          label: const Text('بدء التحضير'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    if (order.orderStatus == OrderStatus.preparing)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context
                              .read<KitchenCubit>()
                              .updateOrderStatus(order.id!, OrderStatus.ready),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: const Text('جاهز للتقديم'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    if (order.orderStatus == OrderStatus.ready)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context
                              .read<KitchenCubit>()
                              .updateOrderStatus(order.id!, OrderStatus.served),
                          icon: const Icon(Icons.done_all, size: 18),
                          label: const Text('تم التقديم'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

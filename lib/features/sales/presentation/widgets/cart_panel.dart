import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../cart_cubit.dart';
import 'quantity_stepper.dart';

/// لوحة السلة أثناء البيع: قائمة الأصناف + الإجمالي + زر إتمام البيع.
class CartPanel extends StatelessWidget {
  const CartPanel({
    super.key,
    this.onComplete,
    this.onHold,
    this.isSheet = false,
  });

  /// يُستدعى عند الضغط على "إتمام البيع".
  final VoidCallback? onComplete;

  /// يُستدعى عند الضغط على "تعليق السلة" (حفظها محليًا).
  final VoidCallback? onHold;
  final bool isSheet;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartCubit>().state;

    if (cart.isEmpty) {
      return const EmptyState(
        icon: Icons.remove_shopping_cart_outlined,
        title: 'السلة فارغة',
        subtitle: 'اضغط على أي صنف لبدء البيع',
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cart.lines.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final line = cart.lines[index];
              return _CartLineTile(
                index: index,
                quantity: line.quantity,
                name: line.product.name,
                unit: line.product.unit,
                price: line.product.price,
                subtotal: line.subtotal,
                stock: line.product.stock,
              );
            },
          ),
        ),
        _Footer(onComplete: onComplete, onHold: onHold),
      ],
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({
    required this.index,
    required this.quantity,
    required this.name,
    required this.unit,
    required this.price,
    required this.subtotal,
    required this.stock,
  });

  final int index;
  final double quantity;
  final String name;
  final String unit;
  final double price;
  final double subtotal;
  final double stock;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartCubit>();
    final fractional = unit == 'كيلو' || unit == 'لتر';
    final step = fractional ? 0.25 : 1.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppFormatters.money(price)} لكل ${unit.isEmpty ? 'وحدة' : unit}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => cart.removeFromCart(index),
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              QuantityStepper(
                quantity: quantity,
                step: step,
                maxQuantity: stock,
                onChanged: (qty) => cart.updateCartQuantity(index, qty),
              ),
              Text(
                AppFormatters.money(subtotal),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({this.onComplete, this.onHold});

  final VoidCallback? onComplete;
  final VoidCallback? onHold;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartCubit>().state;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.w700)),
              Flexible(
                child: Text(
                  AppFormatters.money(cart.total),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (onHold != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onHold,
                    icon: const Icon(Icons.pause_circle_outline),
                    label: const Text('تعليق'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('إتمام البيع'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

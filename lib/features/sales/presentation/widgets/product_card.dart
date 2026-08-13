import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/product.dart';

/// كارت صنف يُستخدم في شاشة البيع.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onQuickAdd,
  });

  final Product product;
  final VoidCallback? onTap;

  /// إضافة الصنف فورًا بكمية واحدة (زر +).
  final VoidCallback? onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stock <= 0;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: outOfStock ? const Color(0xFFF0D8D8) : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  _QuickAddButton(
                    visible: !outOfStock && onQuickAdd != null,
                    onTap: onQuickAdd,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                AppFormatters.money(product.price),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              _StockBadge(
                quantity: product.stock,
                unit: product.unit,
                outOfStock: outOfStock,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.visible, this.onTap});

  final bool visible;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 16),
            SizedBox(width: 2),
            Text(
              '1',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({
    required this.quantity,
    required this.unit,
    required this.outOfStock,
  });

  final double quantity;
  final String unit;
  final bool outOfStock;

  @override
  Widget build(BuildContext context) {
    final color = outOfStock ? AppColors.error : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        outOfStock ? 'نفد' : 'متوفر: ${AppFormatters.quantity(quantity, unit)}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

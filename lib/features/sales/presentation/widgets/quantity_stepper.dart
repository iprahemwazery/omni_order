import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// محدد كمية بسيط (ناقص / رقم / زائد) يدعم الكسور.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.step,
    required this.onChanged,
    this.maxQuantity,
  });

  final double quantity;
  final double step;
  final ValueChanged<double> onChanged;
  final double? maxQuantity;

  @override
  Widget build(BuildContext context) {
    final canIncrement = maxQuantity == null || quantity + step <= maxQuantity!;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Button(
            icon: Icons.add,
            onTap: canIncrement ? () => onChanged(quantity + step) : null,
          ),
          SizedBox(
            width: 48,
            child: Text(
              _format(quantity),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          _Button(
            icon: Icons.remove,
            onTap: () => onChanged(quantity - step),
          ),
        ],
      ),
    );
  }

  static String _format(double value) {
    final isWhole = value == value.roundToDouble();
    return isWhole ? value.toStringAsFixed(0) : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? AppColors.border : AppColors.primary,
        ),
      ),
    );
  }
}

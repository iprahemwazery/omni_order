import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/product.dart';
import '../cart_cubit.dart';
import 'quantity_stepper.dart';

/// يفتح نافذة اختيار الكمية ويضيف الصنف للسلة.
Future<void> showQuantityDialog(BuildContext context, Product product) {
  return showDialog<void>(
    context: context,
    builder: (_) => _QuantityDialog(product: product),
  );
}

class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({required this.product});

  final Product product;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  late final TextEditingController _controller;
  late double _quantity;
  String? _error;
  double? _available;

  Product get product => widget.product;
  bool get _isFractional => product.unit == 'كيلو' || product.unit == 'لتر';
  double get _step => _isFractional ? 0.25 : 1.0;

  @override
  void initState() {
    super.initState();
    _quantity = _step;
    _controller = TextEditingController(text: _format(_quantity));
    _available = context.read<CartCubit>().state.availableStockOf(product);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuantity(double value) {
    final available = _available ?? product.stock;
    if (value < _step) value = _step;
    if (value > available) {
      value = available <= 0 ? _step : available;
    }
    setState(() {
      _quantity = value;
      _controller.text = _format(value);
      _error = null;
    });
  }

  void _onTextChanged(String text) {
    final parsed = double.tryParse(text);
    if (parsed == null) return;
    final available = _available ?? product.stock;
    final clamped = parsed.clamp(_step, available == 0 ? double.infinity : available);
    setState(() {
      _quantity = clamped.toDouble();
      _error = null;
    });
  }

  void _addToCart() {
    final cart = context.read<CartCubit>();
    final error = cart.addToCart(product, _quantity);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 20),
            _quantityControl(),
            const SizedBox(height: 16),
            _totalRow(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _addToCart,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('إضافة للسلة'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1EF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              Text(
                '${AppFormatters.money(product.price)} • متاح: ${AppFormatters.quantity(product.stock, product.unit)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quantityControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('الكمية', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            QuantityStepper(
              quantity: _quantity,
              step: _step,
              maxQuantity: _available ?? product.stock,
              onChanged: _setQuantity,
            ),
            SizedBox(
              width: 76,
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                decoration: const InputDecoration(
                  isDense: true,
                  filled: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
                onChanged: _onTextChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _totalRow() {
    final total = product.price * _quantity;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'إجمالي السطر',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          AppFormatters.money(total),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  static String _format(double value) {
    final isWhole = value == value.roundToDouble();
    return isWhole ? value.toStringAsFixed(0) : value.toString();
  }
}

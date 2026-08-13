import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/customer.dart';
import '../../../../domain/models/sale.dart';
import '../../../../shared/widgets/add_customer_dialog.dart';
import '../../../auth/presentation/auth_cubit.dart';
import '../../../customers/presentation/customers_cubit.dart';
import '../cart_cubit.dart';
import '../cart_state.dart';

/// يفتح نافذة إتمام البيع (طريقة الدفع + العميل + الخصم)
/// وتُرجِع الفاتورة المنشأة أو null إذا أُلغيت.
Future<Sale?> showCheckoutSheet(BuildContext context) {
  return showModalBottomSheet<Sale>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _CheckoutSheet(),
  );
}

class _CheckoutSheet extends StatefulWidget {
  const _CheckoutSheet();

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

enum _DiscountType { none, percent, amount }

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  _DiscountType _discountType = _DiscountType.none;
  String _paymentMethod = kPaymentMethods.first;
  int? _customerId;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _discountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _discount {
    final subtotal = context.read<CartCubit>().state.subtotal;
    final value = double.tryParse(_discountController.text);
    if (value == null || value <= 0) return 0;
    switch (_discountType) {
      case _DiscountType.percent:
        return (subtotal * value / 100).clamp(0, subtotal);
      case _DiscountType.amount:
        return value.clamp(0, subtotal);
      case _DiscountType.none:
        return 0;
    }
  }

  Future<void> _confirm() async {
    final cart = context.read<CartCubit>();

    if (_paymentMethod == 'آجل' && _customerId == null) {
      setState(() => _error = 'البيع الآجل يتطلب اختيار عميل.');
      return;
    }

    setState(() => _saving = true);
    try {
      cart.setCartDiscount(_discount);
      cart.setPaymentMethod(_paymentMethod);
      cart.selectCustomer(_customerById());
      cart.setSaleNote(_noteController.text);
      final cashierName =
          context.read<AuthCubit>().state.admin?.username ?? '';
      final sale = await cart.completeSale(cashierName: cashierName);
      if (!mounted) return;
      Navigator.of(context).pop(sale);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'حدث خطأ أثناء حفظ الفاتورة: $e';
        });
      }
    }
  }

  Customer? _customerById() {
    if (_customerId == null) return null;
    return context.read<CustomersCubit>().state.customerById(_customerId);
  }

  /// يفتح نافذة إضافة عميل ثم يختاره تلقائيًا ليصبح جاهزًا للبيع الآجل.
  Future<void> _addCustomer() async {
    final result = await showAddCustomerDialog(context);
    if (result == null || !mounted) return;
    final cubit = context.read<CustomersCubit>();
    final name = result.$1.trim();
    final phone = result.$2.trim();
    final error = await cubit.addCustomer(name, phone: phone);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final added = cubit.state.customers
        .where((c) => c.name == name && c.phone == phone)
        .reduce((a, b) => (a.id ?? 0) > (b.id ?? 0) ? a : b);
    setState(() {
      _error = null;
      _customerId = added.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartCubit>().state;
    final customers = context.watch<CustomersCubit>().state;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text(
                'إتمام البيع',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 20),
            _label('طريقة الدفع'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final method in kPaymentMethods)
                  ChoiceChip(
                    label: Text(method),
                    selected: _paymentMethod == method,
                    onSelected: (_) => setState(() => _paymentMethod = method),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _paymentMethod == method
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _label('العميل'),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              key: ValueKey('customer_$_customerId'),
              initialValue: _customerId,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'بدون عميل',
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('بدون عميل'),
                ),
                for (final customer in customers.customers)
                  DropdownMenuItem<int?>(
                    value: customer.id,
                    child: Text(customer.name),
                  ),
              ],
              onChanged: (value) => setState(() => _customerId = value),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _addCustomer,
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: const Text('إضافة عميل جديد'),
              ),
            ),
            const SizedBox(height: 10),
            _label('خصم'),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('بدون'),
                  selected: _discountType == _DiscountType.none,
                  onSelected: (_) => setState(() {
                    _discountType = _DiscountType.none;
                    _discountController.clear();
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('نسبة %'),
                  selected: _discountType == _DiscountType.percent,
                  onSelected: (_) => setState(() => _discountType = _DiscountType.percent),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('مبلغ'),
                  selected: _discountType == _DiscountType.amount,
                  onSelected: (_) => setState(() => _discountType = _DiscountType.amount),
                ),
              ],
            ),
            if (_discountType != _DiscountType.none) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.local_offer_outlined),
                  hintText: _discountType == _DiscountType.percent
                      ? 'مثال: 10'
                      : 'مثال: 50',
                  suffixText: _discountType == _DiscountType.percent ? '%' : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 16),
            _label('ملاحظة على الفاتورة (اختياري)'),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.notes_outlined),
                hintText: 'مثال: تم الدفع نقدًا جزئيًا',
              ),
            ),
            const SizedBox(height: 16),
            _totals(cart),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _confirm,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_saving ? 'جارٍ الحفظ...' : 'تأكيد البيع'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    );
  }

  Widget _totals(CartState cart) {
    final discount = _discount;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _totalRow('إجمالي الأصناف', cart.subtotal),
          if (discount > 0) _totalRow('الخصم', -discount, highlight: AppColors.error),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الصافي', style: TextStyle(fontWeight: FontWeight.w700)),
              Text(
                AppFormatters.money(cart.subtotal - discount),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, {Color? highlight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            AppFormatters.money(amount),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: highlight ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

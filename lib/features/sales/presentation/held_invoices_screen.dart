import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/held_cart.dart';
import '../../../domain/repositories/store_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../customers/presentation/customers_cubit.dart';
import '../../settings/presentation/settings_cubit.dart';
import 'cart_cubit.dart';

/// قائمة الفواتير المعلقة (Hold Invoice): استرجاع لإكمال البيع أو حذف.
class HeldInvoicesScreen extends StatefulWidget {
  const HeldInvoicesScreen({super.key});

  @override
  State<HeldInvoicesScreen> createState() => _HeldInvoicesScreenState();
}

class _HeldInvoicesScreenState extends State<HeldInvoicesScreen> {
  bool _loading = true;
  List<HeldCart> _carts = [];
  String? _error;

  StoreRepository get _repository => context.read<StoreRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final carts = await _repository.getHeldCarts();
      if (!mounted) return;
      setState(() {
        _carts = carts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = safeErrorMessage('تعذر تحميل الفواتير المعلقة', e);
      });
    }
  }

  String _customerName(int? customerId) {
    final customer = customerId == null
        ? null
        : context.read<CustomersCubit>().state.customerById(customerId);
    if (customer != null) return customer.name;
    return customerId == null ? '' : 'عميل محذوف';
  }

  Future<void> _restore(HeldCart cart) async {
    final cartCubit = context.read<CartCubit>();
    final currentCart = cartCubit.state;

    if (!currentCart.isEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('استرجاع فاتورة معلقة'),
          content: const Text('السلة الحالية بها أصناف. هل تريد استبدالها '
              'بالفاتورة المعلقة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('استبدال'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final message = await cartCubit.restoreHeldCart(cart);
    if (!mounted) return;
    if (message == null || !cartCubit.state.isEmpty) {
      // نجحت الاستعادة كاملةً أو جزئيًا (مع تنبيه): نرجع لشاشة البيع.
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            message ?? 'تم استرجاع الفاتورة إلى السلة.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      // فشلت الاستعادة (السلة فارغة ولم يُسترد شيء): نبقى في القائمة.
      messenger.showSnackBar(SnackBar(content: Text(message)));
      await _load();
    }
  }

  Future<void> _delete(HeldCart cart) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف فاتورة معلقة'),
        content: Text(
          'هل تريد حذف الفاتورة المعلقة بقيمة '
          '${AppFormatters.money(cart.total)}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _repository.deleteHeldCart(cart.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف الفاتورة المعلقة.')),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفواتير المعلقة'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  )
                : _carts.isEmpty
                    ? const EmptyState(
                        icon: Icons.pause_circle_outline,
                        title: 'لا توجد فواتير معلقة',
                        subtitle: 'أي سلة تعلّقها أثناء البيع ستظهر هنا '
                            'لاستكمالها لاحقًا',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _carts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _HeldCartTile(
                              cart: _carts[index],
                              customerName: _customerName(
                                _carts[index].customerId,
                              ),
                              onRestore: () => _restore(_carts[index]),
                              onDelete: () => _delete(_carts[index]),
                            ),
                      ),
      ),
    );
  }
}

class _HeldCartTile extends StatelessWidget {
  const _HeldCartTile({
    required this.cart,
    required this.customerName,
    required this.onRestore,
    required this.onDelete,
  });

  final HeldCart cart;
  final String customerName;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E9F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pause_circle_outline,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppFormatters.date(cart.savedAt)} • '
                      '${AppFormatters.time(cart.savedAt)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        '${cart.itemsCount} أصناف',
                        'طريقة الدفع: ${cart.paymentMethod}',
                        if (customerName.isNotEmpty) 'العميل: $customerName',
                      ].join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                AppFormatters.money(
                  cart.total,
                  context.read<SettingsCubit>().state.settings.currency,
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: const Text('استرجاع'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('حذف'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

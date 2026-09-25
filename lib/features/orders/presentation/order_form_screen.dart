import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/employee.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/product.dart';
import '../../../domain/models/restaurant_table.dart';
import '../../../domain/repositories/store_repository.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../products/presentation/products_cubit.dart';
import '../../products/presentation/products_state.dart';
import '../../categories/presentation/categories_cubit.dart';
import '../../settings/presentation/settings_cubit.dart';
import '../../employees/domain/usecases/employees_usecases.dart';
import '../../tables/domain/usecases/tables_usecases.dart';
import '../domain/usecases/orders_usecases.dart';
import 'orders_cubit.dart';

/// شاشة إنشاء طلب جديد في المطعم.
class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key, this.preselectedTableId});

  final int? preselectedTableId;

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final TextEditingController _search = TextEditingController();
  int? _selectedCategoryId;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedTableId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<OrdersCubit>().selectTable(widget.preselectedTableId);
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, products) => BlocBuilder<OrdersCubit, OrderState>(
        builder: (context, order) => Scaffold(
          appBar: AppBar(
            title: const Text('طلب جديد'),
            actions: [
              if (!order.isEmpty)
                IconButton(
                  onPressed: _completing ? null : _clearOrder,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: 'مسح الطلب',
                ),
            ],
          ),
          body: SafeArea(
            child: products.loading
                ? const Center(child: CircularProgressIndicator())
                : products.products.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد أصناف في المنيو',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 760;
                      final menuGrid = _MenuGrid(
                        search: _search,
                        selectedCategoryId: _selectedCategoryId,
                        onCategoryChanged: (id) =>
                            setState(() => _selectedCategoryId = id),
                      );

                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(child: menuGrid),
                            Container(
                              width: 380,
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: _OrderPanel(
                                completing: _completing,
                                onComplete: _completeOrder,
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          Expanded(child: menuGrid),
                          _MobileOrderBar(
                            onOpenOrder: () => _showOrderSheet(context),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  void _clearOrder() {
    context.read<OrdersCubit>().clearOrder();
  }

  Future<void> _showOrderSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _OrderPanel(
          isSheet: true,
          completing: _completing,
          onComplete: () {
            Navigator.of(context).pop();
            _completeOrder();
          },
        ),
      ),
    );
  }

  Future<void> _completeOrder() async {
    if (_completing) return;
    setState(() => _completing = true);
    try {
      final settings = context.read<SettingsCubit>().state;
      final cashierName = context.read<AuthCubit>().state.admin?.username ?? '';
      final order = await context.read<OrdersCubit>().completeOrder(
        cashierName: cashierName,
        taxRate: settings.settings.taxRate,
      );
      if (!mounted) return;
      if (order != null) {
        if (order.orderType == 'takeaway') {
          _showPaymentDialog(context, order);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إنشاء الطلب #${order.id} بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  void _showPaymentDialog(BuildContext context, RestaurantOrder order) {
    final settings = context.read<SettingsCubit>().state;
    String paymentMethod = 'نقدي';
    double amountTendered = 0;
    double cardAmount = 0;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('الدفع'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الإجمالي'),
                    Text(
                      AppFormatters.money(
                        order.total,
                        settings.settings.currency,
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'طريقة الدفع',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'نقدي', child: Text('نقدي')),
                    DropdownMenuItem(value: 'شبكة', child: Text('شبكة')),
                    DropdownMenuItem(value: 'محفظة', child: Text('محفظة')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => paymentMethod = v ?? 'نقدي'),
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ المدفوع',
                    prefixIcon: Icon(Icons.payments_outlined),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    final parsed = double.tryParse(v) ?? 0;
                    setDialogState(() => amountTendered = parsed);
                  },
                ),
                const SizedBox(height: 8),
                if (paymentMethod == 'شبكة') ...[
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'مبلغ الكارت',
                      prefixIcon: Icon(Icons.credit_card_outlined),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v) ?? 0;
                      setDialogState(() => cardAmount = parsed);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                if (amountTendered > 0 || cardAmount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المتبقي'),
                      Text(
                        AppFormatters.money(
                          (order.total - amountTendered - cardAmount).clamp(
                            0,
                            double.infinity,
                          ),
                          settings.settings.currency,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final repo = context.read<StoreRepository>();
                try {
                  final updateOrderStatus = context.read<UpdateOrderStatus?>();
                  if (updateOrderStatus == null) {
                    await repo.updateOrderStatus(order.id!, OrderStatus.paid);
                  } else {
                    await updateOrderStatus(order.id!, OrderStatus.paid);
                  }
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم الدفع للطلب #${order.id} بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('ادفع'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuGrid extends StatefulWidget {
  const _MenuGrid({
    required this.search,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
  });

  final TextEditingController search;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategoryChanged;

  @override
  State<_MenuGrid> createState() => _MenuGridState();
}

class _MenuGridState extends State<_MenuGrid> {
  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsCubit>().state.products;
    final categories = context.watch<CategoriesCubit>().state.categories;
    final query = widget.search.text.trim().toLowerCase();

    final filtered = products.where((p) {
      if (!p.isAvailable) return false;
      final matchesSearch =
          query.isEmpty || p.name.toLowerCase().contains(query);
      final matchesCategory =
          widget.selectedCategoryId == null ||
          p.categoryId == widget.selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: widget.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ابحث في المنيو...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: widget.search.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        widget.search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    )
                  : null,
            ),
          ),
        ),
        if (categories.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _CategoryChip(
                  label: 'الكل',
                  selected: widget.selectedCategoryId == null,
                  onTap: () => widget.onCategoryChanged(null),
                ),
                for (final cat in categories)
                  _CategoryChip(
                    label: cat.name,
                    selected: widget.selectedCategoryId == cat.id,
                    onTap: () => widget.onCategoryChanged(cat.id),
                  ),
              ],
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد نتائج',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisExtent: 160,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return _MenuItemCard(
                      product: product,
                      onTap: () => _quickAdd(product),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _quickAdd(Product product) {
    final error = context.read<OrdersCubit>().addToOrder(product, 1);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isKilo = product.unit == 'كيلو' || product.unit == 'نص كيلو';
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                product.preparationTime > 0
                    ? Icons.timer_outlined
                    : Icons.restaurant_outlined,
                color: AppColors.primary,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (isKilo && product.price > 0) ...[
                Text(
                  'كيلو: ${AppFormatters.money(product.price)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                if (product.halfPrice > 0)
                  Text(
                    'نص: ${AppFormatters.money(product.halfPrice)}',
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
              ] else
                Text(
                  AppFormatters.money(product.price),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              if (product.preparationTime > 0)
                Text(
                  '${product.preparationTime} دقيقة',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderPanel extends StatelessWidget {
  const _OrderPanel({
    this.isSheet = false,
    required this.completing,
    required this.onComplete,
  });

  final bool isSheet;
  final bool completing;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrdersCubit>().state;
    final settings = context.watch<SettingsCubit>().state;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'الطلب',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (!order.isEmpty)
                Text(
                  '${order.totalQuantity.toStringAsFixed(0)} صنف',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
        Expanded(
          child: order.isEmpty
              ? const Center(
                  child: Text(
                    'أضف أصناف من المنيو',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: order.lines.length,
                  itemBuilder: (context, index) {
                    final line = order.lines[index];
                    return _OrderLineTile(
                      line: line,
                      onIncrement: () => context
                          .read<OrdersCubit>()
                          .updateQuantity(index, line.quantity + 1),
                      onDecrement: () {
                        if (line.quantity <= 1) {
                          context.read<OrdersCubit>().removeFromOrder(index);
                        } else {
                          context.read<OrdersCubit>().updateQuantity(
                            index,
                            line.quantity - 1,
                          );
                        }
                      },
                      onRemove: () =>
                          context.read<OrdersCubit>().removeFromOrder(index),
                    );
                  },
                ),
        ),
        if (!order.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                // اختيار نوع الطلب
                _OrderTypeSelector(selectedType: order.orderType),
                const SizedBox(height: 10),

                // حسب نوع الطلب
                if (order.orderType == 'hall') ...[
                  _TableSelector(selectedTableId: order.selectedTableId),
                  const SizedBox(height: 8),
                ],
                if (order.orderType == 'delivery') ...[
                  _DeliveryFields(),
                  const SizedBox(height: 8),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الإجمالي'),
                    Text(
                      AppFormatters.money(
                        order.total + order.deliveryFee,
                        settings.settings.currency,
                      ),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: completing ? null : onComplete,
                    child: Text(completing ? 'جارٍ الإتمام...' : 'إتمام الطلب'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _OrderTypeSelector extends StatelessWidget {
  const _OrderTypeSelector({required this.selectedType});
  final String selectedType;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TypeChip(
          label: 'صاله',
          icon: Icons.table_restaurant_outlined,
          selected: selectedType == 'hall',
          onTap: () => context.read<OrdersCubit>().setOrderType('hall'),
        ),
        const SizedBox(width: 8),
        _TypeChip(
          label: 'تليفريسي',
          icon: Icons.takeout_dining_outlined,
          selected: selectedType == 'takeaway',
          onTap: () => context.read<OrdersCubit>().setOrderType('takeaway'),
        ),
        const SizedBox(width: 8),
        _TypeChip(
          label: 'توصيل',
          icon: Icons.delivery_dining_outlined,
          selected: selectedType == 'delivery',
          onTap: () => context.read<OrdersCubit>().setOrderType('delivery'),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryFields extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrderState>(
      builder: (context, order) {
        return Column(
          children: [
            TextField(
              controller: TextEditingController(text: order.deliveryPhone),
              onChanged: (v) => context.read<OrdersCubit>().setDeliveryPhone(v),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم التليفون',
                prefixIcon: Icon(Icons.phone_outlined),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: order.deliveryAddress),
              onChanged: (v) =>
                  context.read<OrdersCubit>().setDeliveryAddress(v),
              decoration: const InputDecoration(
                labelText: 'العنوان',
                prefixIcon: Icon(Icons.location_on_outlined),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Employee>>(
              future: _loadEmployees(context),
              builder: (context, snapshot) {
                final employees = snapshot.data ?? [];
                final riders = employees
                    .where((e) => e.role == EmployeeRole.delivery && e.isActive)
                    .toList();
                return DropdownButtonFormField<int>(
                  initialValue: order.selectedRiderId,
                  decoration: const InputDecoration(
                    labelText: 'عامل التوصيل',
                    prefixIcon: Icon(Icons.person_outlined),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('اختر عامل توصيل...'),
                    ),
                    for (final rider in riders)
                      DropdownMenuItem(
                        value: rider.id,
                        child: Text(rider.name),
                      ),
                  ],
                  onChanged: (v) => context.read<OrdersCubit>().selectRider(v),
                );
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: order.deliveryNotes),
              onChanged: (v) => context.read<OrdersCubit>().setDeliveryNotes(v),
              decoration: const InputDecoration(
                labelText: 'ملاحظات التوصيل',
                prefixIcon: Icon(Icons.note_outlined),
                isDense: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TableSelector extends StatelessWidget {
  const _TableSelector({this.selectedTableId});
  final int? selectedTableId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RestaurantTable>>(
      future: _loadTables(context),
      builder: (context, snapshot) {
        final tables = snapshot.data ?? [];
        final available = tables
            .where((t) => t.status == TableStatus.available)
            .toList();
        // لو التريبية المحددة مشغولة، نضيفها عشان نقدر نضيف أوردر عليها
        final selected = selectedTableId != null
            ? tables.where((t) => t.id == selectedTableId).toList()
            : <RestaurantTable>[];
        final allOptions = [
          ...available,
          ...selected.where((t) => !available.contains(t)),
        ];

        return DropdownButtonFormField<int>(
          initialValue: selectedTableId,
          decoration: const InputDecoration(
            labelText: 'التريبية',
            prefixIcon: Icon(Icons.table_restaurant_outlined),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('اختر تريبية...'),
            ),
            for (final t in allOptions)
              DropdownMenuItem(
                value: t.id,
                child: Text(
                  'تريبية ${t.number} (${t.capacity} أشخاص)${t.status == TableStatus.occupied ? ' - مشغولة' : ''}',
                ),
              ),
          ],
          onChanged: (v) => context.read<OrdersCubit>().selectTable(v),
        );
      },
    );
  }
}

class _OrderLineTile extends StatelessWidget {
  const _OrderLineTile({
    required this.line,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final OrderLine line;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.product.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${line.quantity.toStringAsFixed(0)} x ${AppFormatters.money(line.product.price)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onDecrement,
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  style: IconButton.styleFrom(foregroundColor: AppColors.error),
                ),
                Text(
                  line.quantity.toStringAsFixed(0),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  onPressed: onIncrement,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              AppFormatters.money(line.subtotal),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16),
              style: IconButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileOrderBar extends StatelessWidget {
  const _MobileOrderBar({required this.onOpenOrder});
  final VoidCallback onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrdersCubit>().state;
    if (order.isEmpty) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'الإجمالي',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    AppFormatters.money(order.total + order.deliveryFee),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onOpenOrder,
              icon: Badge(
                label: Text(order.totalQuantity.toStringAsFixed(0)),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              label: const Text('عرض الطلب'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<List<Employee>> _loadEmployees(BuildContext context) {
  final getEmployees = context.read<GetEmployees?>();
  return getEmployees == null
      ? context.read<StoreRepository>().getEmployees()
      : getEmployees();
}

Future<List<RestaurantTable>> _loadTables(BuildContext context) {
  final getTables = context.read<GetTables?>();
  return getTables == null
      ? context.read<StoreRepository>().getTables()
      : getTables();
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        showCheckmark: false,
      ),
    );
  }
}

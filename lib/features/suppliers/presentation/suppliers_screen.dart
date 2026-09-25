import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/product.dart';
import '../../../domain/models/purchase.dart';
import '../../../domain/models/purchase_item.dart';
import '../../../domain/models/supplier.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../products/presentation/products_cubit.dart';
import '../../products/presentation/products_state.dart';
import 'suppliers_cubit.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'الموردين والمشتريات',
            actions: [
              IconButton(
                onPressed: () => context.read<SuppliersCubit>().init(),
                icon: const Icon(Icons.refresh),
                tooltip: 'تحديث',
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<SuppliersCubit, SuppliersState>(
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
                          onPressed: () =>
                              context.read<SuppliersCubit>().init(),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }
                if (state.suppliers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.business_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لا يوجد موردين',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'اضغط على + لإضافة مورد جديد',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.suppliers.length,
                  itemBuilder: (context, index) => _SupplierCard(
                    supplier: state.suppliers[index],
                    purchaseCount: state.purchases
                        .where((p) => p.supplierId == state.suppliers[index].id)
                        .length,
                    pendingAmount: state.purchases
                        .where(
                          (p) =>
                              p.supplierId == state.suppliers[index].id &&
                              !p.isFullyPaid,
                        )
                        .fold<double>(0, (s, p) => s + p.remaining),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'addPurchase',
            onPressed: () => _showCreatePurchaseDialog(context),
            tooltip: 'فاتورة شراء جديدة',
            child: const Icon(Icons.add_shopping_cart),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'addSupplier',
            onPressed: () => _showAddSupplierDialog(context),
            tooltip: 'إضافة مورد',
            child: const Icon(Icons.person_add_outlined),
          ),
        ],
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة مورد جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المورد'),
                  autofocus: true,
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'العنوان'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final result = await context.read<SuppliersCubit>().addSupplier(
                  Supplier(
                    name: name,
                    phone: phoneController.text.trim(),
                    address: addressController.text.trim(),
                  ),
                );
                if (result != null) {
                  setDialogState(() => errorText = result);
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePurchaseDialog(BuildContext context) {
    final supplierCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final items = <_PurchaseLine>[];
    Supplier? selectedSupplier;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final total = items.fold<double>(0, (s, l) => s + l.subtotal);
          return AlertDialog(
            title: const Text('فاتورة شراء جديدة'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Autocomplete<Supplier>(
                      optionsBuilder: (textEditingValue) {
                        final suppliers = context
                            .read<SuppliersCubit>()
                            .state
                            .suppliers;
                        if (textEditingValue.text.isEmpty) return suppliers;
                        return suppliers.where(
                          (s) => s.name.contains(textEditingValue.text),
                        );
                      },
                      displayStringForOption: (s) => s.name,
                      onSelected: (supplier) {
                        selectedSupplier = supplier;
                        supplierCtrl.text = supplier.name;
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onSubmitted) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'المورد',
                              ),
                            );
                          },
                    ),
                    const SizedBox(height: 12),
                    ...items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final line = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  line.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${line.quantity.toStringAsFixed(0)} ${line.unit}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  AppFormatters.money(line.price),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  AppFormatters.money(line.subtotal),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                onPressed: () =>
                                    setDialogState(() => items.removeAt(i)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showAddPurchaseItemDialog(
                        ctx,
                        setDialogState,
                        items,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة صنف'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(labelText: 'ملاحظة'),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الإجمالي',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          AppFormatters.money(total),
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
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: items.isEmpty
                    ? null
                    : () async {
                        final purchase = Purchase(
                          supplierId: selectedSupplier?.id,
                          supplierName: supplierCtrl.text.trim(),
                          total: total,
                          paidAmount: 0,
                          note: noteCtrl.text.trim(),
                        );
                        final purchaseItems = items
                            .map(
                              (l) => PurchaseItem(
                                purchaseId: 0,
                                productId: l.productId,
                                name: l.name,
                                quantity: l.quantity,
                                price: l.price,
                                unit: l.unit,
                                conversionFactor: l.conversionFactor,
                              ),
                            )
                            .toList();
                        await context.read<SuppliersCubit>().createPurchase(
                          purchase: purchase,
                          items: purchaseItems,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                child: const Text('حفظ الفاتورة'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddPurchaseItemDialog(
    BuildContext context,
    StateSetter setDialogState,
    List<_PurchaseLine> items,
  ) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    int? selectedProductId;
    Product? selectedProduct;

    /// وحدة الشراء الحالية للبند (وحدة الصنف الأساسية أو العبوة).
    String purchaseUnit = '';
    double conversionFactor = 1;

    void applyUnit(Product product) {
      if (purchaseUnit == product.packageUnit && product.hasPackage) {
        conversionFactor = product.unitsPerPackage;
      } else {
        purchaseUnit = product.unit;
        conversionFactor = 1;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setItemState) {
          final hasPackage = selectedProduct?.hasPackage ?? false;
          final qty = double.tryParse(qtyCtrl.text) ?? 0;
          final price = double.tryParse(priceCtrl.text) ?? 0;
          final stockPreview = qty * conversionFactor;
          return AlertDialog(
            title: const Text('إضافة صنف'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BlocBuilder<ProductsCubit, ProductsState>(
                    builder: (context, state) {
                      return DropdownButtonFormField<int?>(
                        decoration: const InputDecoration(
                          labelText: 'صنف من المنيو (اختياري)',
                        ),
                        initialValue: selectedProductId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('-- بدون --'),
                          ),
                          ...state.products.map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setItemState(() {
                            selectedProductId = v;
                            if (v != null) {
                              selectedProduct = state.products.firstWhere(
                                (p) => p.id == v,
                              );
                              nameCtrl.text = selectedProduct!.name;
                              purchaseUnit = '';
                              applyUnit(selectedProduct!);
                              // اقتراح سعر الشراء حسب الوحدة المختارة.
                              priceCtrl.text =
                                  selectedProduct!.hasPackage &&
                                      purchaseUnit ==
                                          selectedProduct!.packageUnit
                                  ? (selectedProduct!.costPrice *
                                            selectedProduct!.unitsPerPackage)
                                        .toStringAsFixed(2)
                                  : selectedProduct!.costPrice.toString();
                            } else {
                              selectedProduct = null;
                              purchaseUnit = '';
                              conversionFactor = 1;
                            }
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'اسم الصنف'),
                  ),
                  const SizedBox(height: 12),
                  if (hasPackage) ...[
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: selectedProduct!.packageUnit,
                          label: Text('بـ${selectedProduct!.packageUnit}'),
                          icon: const Icon(Icons.inventory_2_outlined),
                        ),
                        ButtonSegment(
                          value: selectedProduct!.unit,
                          label: Text('بـ${selectedProduct!.unit}'),
                          icon: const Icon(Icons.radio_button_unchecked),
                        ),
                      ],
                      selected: {purchaseUnit},
                      onSelectionChanged: (selection) {
                        setItemState(() {
                          purchaseUnit = selection.first;
                          applyUnit(selectedProduct!);
                          priceCtrl.text =
                              purchaseUnit == selectedProduct!.packageUnit
                              ? (selectedProduct!.costPrice *
                                        selectedProduct!.unitsPerPackage)
                                    .toStringAsFixed(2)
                              : selectedProduct!.costPrice.toString();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setItemState(() {}),
                          decoration: InputDecoration(
                            labelText: 'الكمية ($purchaseUnit)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setItemState(() {}),
                          decoration: InputDecoration(
                            labelText: 'سعر ال$purchaseUnit',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (conversionFactor > 1 && qty > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'سيُضاف للمخزون: ${_formatQty(stockPreview)} ${selectedProduct?.unit ?? ''} '
                        '(${_formatQty(qty)} $purchaseUnit × ${_formatQty(conversionFactor)})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty || qty <= 0) return;
                  setDialogState(() {
                    items.add(
                      _PurchaseLine(
                        productId: selectedProductId,
                        name: name,
                        quantity: qty,
                        price: price,
                        unit: purchaseUnit,
                        conversionFactor: conversionFactor,
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatQty(num value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toString();
}

class _PurchaseLine {
  final int? productId;
  final String name;
  final double quantity;
  final double price;

  /// وحدة الشراء (كرتونة/قطعة...) ومعامل التحويل لوحدة المخزون.
  final String unit;
  final double conversionFactor;
  double get subtotal => quantity * price;

  _PurchaseLine({
    this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.unit = '',
    this.conversionFactor = 1,
  });
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.supplier,
    required this.purchaseCount,
    required this.pendingAmount,
  });
  final Supplier supplier;
  final int purchaseCount;
  final double pendingAmount;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(
            Icons.business_outlined,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        title: Text(
          supplier.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (supplier.phone.isNotEmpty)
              Text(
                '📱 ${supplier.phone}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            Text(
              '$purchaseCount فاتورة شراء',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: pendingAmount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'مديون: ${AppFormatters.money(pendingAmount)}',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'مسدّد',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
      ),
    );
  }
}

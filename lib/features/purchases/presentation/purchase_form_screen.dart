import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/product.dart';
import '../../../domain/models/supplier.dart';
import '../../products/presentation/products_cubit.dart';
import '../../products/presentation/products_state.dart';
import '../../suppliers/presentation/suppliers_cubit.dart';
import '../../suppliers/presentation/suppliers_state.dart';
import 'purchases_cubit.dart';

/// نموذج إضافة فاتورة شراء: اختيار أصناف + كميات + أسعار شراء.
class PurchaseFormScreen extends StatefulWidget {
  const PurchaseFormScreen({super.key, this.supplierName});

  final String? supplierName;

  /// [supplierName] يُمرر من الخارج إذا كان المفتوح من شاشة الموردين.
  static Route<void> route({required String supplierName}) {
    return MaterialPageRoute(
      builder: (_) => PurchaseFormScreen(supplierName: supplierName),
    );
  }

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final TextEditingController _supplier = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final TextEditingController _quantity = TextEditingController(text: '1');
  final TextEditingController _purchasePrice = TextEditingController();
  final TextEditingController _paidAmount = TextEditingController(text: '0');
  final TextEditingController _newProductName = TextEditingController();
  final TextEditingController _newProductSalePrice = TextEditingController();
  Product? _selectedProduct;
  int? _selectedSupplierId;
  String _newProductUnit = AppConstants.productUnits.first;
  final List<PurchaseLine> _lines = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.supplierName != null && widget.supplierName!.trim().isNotEmpty) {
      _supplier.text = widget.supplierName!;
      final suppliers = context.read<SuppliersCubit>().state.suppliers;
      final match = suppliers.firstWhere(
        (s) => s.name.trim().toLowerCase() == widget.supplierName!.trim().toLowerCase(),
        orElse: () => Supplier(name: ''),
      );
      _selectedSupplierId = match.id;
    }
  }

  @override
  void dispose() {
    _supplier.dispose();
    _note.dispose();
    _quantity.dispose();
    _purchasePrice.dispose();
    _paidAmount.dispose();
    _newProductName.dispose();
    _newProductSalePrice.dispose();
    super.dispose();
  }

  double get _total => _lines.fold(0.0, (sum, l) => sum + l.quantity * l.price);
  double get _paidAmountValue => double.tryParse(_paidAmount.text) ?? 0;
  double get _remainingDebt =>
      (_total - _paidAmountValue).clamp(0.0, double.infinity);

  void _resetLineInputs() {
    _selectedProduct = null;
    _newProductName.clear();
    _newProductSalePrice.clear();
    _newProductUnit = AppConstants.productUnits.first;
    _quantity.text = '1';
    _purchasePrice.clear();
  }

  String? _addLineError() {
    final quantity = double.tryParse(_quantity.text);
    if (quantity == null || quantity <= 0) return 'أدخل كمية صحيحة.';

    final purchasePrice = double.tryParse(_purchasePrice.text);
    if (purchasePrice == null || purchasePrice < 0)
      return 'أدخل سعر شراء صحيحًا.';

    if (_selectedProduct == null) {
      final name = _newProductName.text.trim();
      if (name.isEmpty) return 'اختر صنفًا أو أدخل اسم صنف جديد.';
      final salePrice = double.tryParse(_newProductSalePrice.text);
      if (salePrice == null || salePrice <= 0) return 'أدخل سعر البيع الصحيح.';
    }

    return null;
  }

  void _addLine() {
    final error = _addLineError();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (_selectedProduct != null) {
      setState(() {
        _lines.add((
          product: _selectedProduct!,
          quantity: double.parse(_quantity.text),
          price: double.parse(_purchasePrice.text),
        ));
        _resetLineInputs();
      });
      return;
    }

    _addNewProductLine();
  }

  Future<void> _addNewProductLine() async {
    final name = _newProductName.text.trim();
    if (name.isEmpty) return;

    final salePrice = double.tryParse(_newProductSalePrice.text) ?? 0;
    final purchasePrice = double.tryParse(_purchasePrice.text) ?? 0;
    final quantity = double.tryParse(_quantity.text) ?? 1;

    final existing = context.read<ProductsCubit>().state.products.firstWhere(
      (p) =>
          p.name.trim().toLowerCase() == name.toLowerCase() &&
          p.unit == _newProductUnit,
      orElse: () =>
          Product(name: '', price: 0, stock: 0, unit: _newProductUnit),
    );

    final productToUse = existing.name.isEmpty ? null : existing;

    final error = productToUse == null
        ? await context.read<ProductsCubit>().addProduct(
            name: name,
            price: salePrice,
            stock: 0,
            unit: _newProductUnit,
          )
        : null;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final created =
        productToUse ??
        context.read<ProductsCubit>().state.products.firstWhere(
          (p) =>
              p.name.trim().toLowerCase() == name.toLowerCase() &&
              p.unit == _newProductUnit,
        );

    setState(() {
      _lines.add((product: created, quantity: quantity, price: purchasePrice));
      _resetLineInputs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فاتورة شراء')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('purchase_supplier'),
                controller: _supplier,
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_selectedSupplierId != null) {
                    setState(() => _selectedSupplierId = null);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'اسم المورد (اختياري)',
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'مثال: شركة الأهرام للتوريد',
                ),
              ),
              const SizedBox(height: 10),
              BlocBuilder<SuppliersCubit, SuppliersState>(
                builder: (context, suppliers) {
                  if (suppliers.suppliers.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return DropdownButtonFormField<int?>(
                    key: const Key('purchase_supplier_select'),
                    initialValue: _selectedSupplierId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'أو اختر من الموردين الموجودين',
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('مورد جديد / كتابة اسم يدوي'),
                      ),
                      for (final supplier in suppliers.suppliers)
                        DropdownMenuItem<int?>(
                          value: supplier.id,
                          child: Text(
                            supplier.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSupplierId = value;
                        if (value != null) {
                          final supplier = suppliers.suppliers.firstWhere(
                            (s) => s.id == value,
                          );
                          _supplier.text = supplier.name;
                        }
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'إضافة صنف للفاتورة',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              BlocBuilder<ProductsCubit, ProductsState>(
                builder: (context, products) {
                  final available = products.products
                      .where((p) => !_lines.any((l) => l.product.id == p.id))
                      .toList();
                  return DropdownButtonFormField<Product?>(
                    key: ValueKey(_selectedProduct),
                    initialValue: _selectedProduct,
                    decoration: const InputDecoration(
                      labelText: 'اختر صنفًا موجودًا',
                      prefixIcon: Icon(Icons.sell_outlined),
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<Product?>(
                        value: null,
                        child: Text('صنف جديد'),
                      ),
                      for (final product in available)
                        DropdownMenuItem<Product?>(
                          value: product,
                          child: Text(
                            '${product.name} (${AppFormatters.quantity(product.stock, product.unit)})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedProduct = value),
                  );
                },
              ),
              const SizedBox(height: 12),
              if (_selectedProduct == null) ...[
                TextField(
                  key: const Key('purchase_new_product_name'),
                  controller: _newProductName,
                  decoration: const InputDecoration(
                    labelText: 'اسم الصنف الجديد',
                    prefixIcon: Icon(Icons.add),
                    hintText: 'مثال: ماء معبأ',
                  ),
                  onSubmitted: (_) => _addLine(),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('purchase_new_product_sale_price'),
                  controller: _newProductSalePrice,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'سعر البيع',
                    prefixIcon: Icon(Icons.attach_money),
                    hintText: '0.00',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'وحدة القياس',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final unit in AppConstants.productUnits)
                      ChoiceChip(
                        label: Text(unit),
                        selected: _newProductUnit == unit,
                        onSelected: (_) =>
                            setState(() => _newProductUnit = unit),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _newProductUnit == unit
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('purchase_quantity'),
                      controller: _quantity,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'الكمية',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      key: const Key('purchase_price'),
                      controller: _purchasePrice,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'سعر الشراء',
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _addLine,
                icon: const Icon(Icons.add),
                label: const Text('إضافة للفاتورة'),
              ),
              const SizedBox(height: 20),
              if (_lines.isNotEmpty) ...[
                Text(
                  'أصناف الفاتورة (${_lines.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < _lines.length; i++) ...[
                  _PurchaseLineTile(
                    line: _lines[i],
                    onRemove: () => setState(() => _lines.removeAt(i)),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الإجمالي',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      AppFormatters.money(_total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _paidAmount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'المبلغ المدفوع الآن',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'المتبقي للمورد',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      AppFormatters.money(_remainingDebt),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: _remainingDebt > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              FilledButton.icon(
                onPressed: _saving ? null : _save,
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
                label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ فاتورة الشراء'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف صنفًا واحدًا على الأقل.')),
      );
      return;
    }
    setState(() => _saving = true);
    final paidAmount = double.tryParse(_paidAmount.text) ?? 0;
    final error = await context.read<PurchasesCubit>().createPurchase(
      supplierName: _supplier.text.trim(),
      supplierId: _selectedSupplierId,
      note: _note.text.trim(),
      lines: List.of(_lines),
      paidAmount: paidAmount,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تسجيل فاتورة الشراء وزيادة المخزون')),
    );
    Navigator.of(context).pop();
  }
}

class _PurchaseLineTile extends StatelessWidget {
  const _PurchaseLineTile({required this.line, required this.onRemove});

  final PurchaseLine line;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppFormatters.quantity(line.quantity, line.product.unit)} × ${AppFormatters.money(line.price)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppFormatters.money(line.quantity * line.price),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

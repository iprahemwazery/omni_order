import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/product.dart';
import '../../categories/presentation/categories_cubit.dart';
import '../../categories/presentation/categories_state.dart';
import 'products_cubit.dart';

/// نموذج إضافة صنف جديد أو تعديل صنف موجود.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _costPrice;
  late final TextEditingController _lowStockThreshold;
  late final TextEditingController _barcode;
  late String _unit;
  int? _categoryId;
  bool _saving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _price = TextEditingController(
      text: product == null ? '' : _formatNumber(product.price),
    );
    _stock = TextEditingController(
      text: product == null ? '0' : _formatNumber(product.stock),
    );
    _costPrice = TextEditingController(
      text: product == null || product.costPrice <= 0
          ? ''
          : _formatNumber(product.costPrice),
    );
    _lowStockThreshold = TextEditingController(
      text: product == null || product.lowStockThreshold <= 0
          ? ''
          : _formatNumber(product.lowStockThreshold),
    );
    _barcode = TextEditingController(text: product?.barcode ?? '');
    _unit = product?.unit ?? AppConstants.productUnits.first;
    _categoryId = product?.categoryId;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _costPrice.dispose();
    _lowStockThreshold.dispose();
    _barcode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final productsCubit = context.read<ProductsCubit>();
    final price = double.tryParse(_price.text) ?? 0;
    final stock = double.tryParse(_stock.text) ?? 0;
    final costPrice = double.tryParse(_costPrice.text) ?? 0;
    final lowStockThreshold = double.tryParse(_lowStockThreshold.text) ?? 0;
    final barcode = _barcode.text.trim();

    setState(() => _saving = true);
    final String? error;
    if (_isEditing) {
      error = await productsCubit.updateProduct(
        widget.product!,
        name: _name.text,
        price: price,
        stock: stock,
        unit: _unit,
        categoryId: _categoryId,
        costPrice: costPrice,
        lowStockThreshold: lowStockThreshold,
        barcode: barcode,
      );
    } else {
      error = await productsCubit.addProduct(
        name: _name.text,
        price: price,
        stock: stock,
        unit: _unit,
        categoryId: _categoryId,
        costPrice: costPrice,
        lowStockThreshold: lowStockThreshold,
        barcode: barcode,
      );
    }
    if (!mounted) return;

    if (error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل صنف' : 'إضافة صنف'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'اسم الصنف *',
                    prefixIcon: Icon(Icons.sell_outlined),
                    hintText: 'مثال: أرز، زيت، عصير...',
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'اكتب اسم الصنف' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'سعر البيع *',
                    prefixIcon: Icon(Icons.payments_outlined),
                    hintText: '0.00',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) return 'السعر مطلوب وأكبر من صفر';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stock,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'الكمية المتاحة',
                    prefixIcon: Icon(Icons.numbers),
                    hintText: '0',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed < 0) return 'كمية غير صحيحة';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _costPrice,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'سعر التكلفة (اختياري)',
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                    hintText: 'يحسب الربح الحقيقي',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    if (double.tryParse(value) == null || double.parse(value) < 0) {
                      return 'سعر تكلفة غير صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lowStockThreshold,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'حد التنبيه بالمخزون (اختياري)',
                    prefixIcon: Icon(Icons.notifications_outlined),
                    hintText: 'مثال: 10',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    if (double.tryParse(value) == null || double.parse(value) < 0) {
                      return 'حد غير صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _barcode,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'الباركود (اختياري)',
                    prefixIcon: Icon(Icons.qr_code_scanner),
                    hintText: 'مثال: 6221031550621',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'وحدة القياس',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final unit in AppConstants.productUnits)
                      ChoiceChip(
                        label: Text(unit),
                        selected: _unit == unit,
                        onSelected: (_) => setState(() => _unit = unit),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _unit == unit ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                BlocBuilder<CategoriesCubit, CategoriesState>(
                  builder: (context, categories) {
                    return DropdownButtonFormField<int?>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'التصنيف (اختياري)',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('بدون تصنيف'),
                        ),
                        for (final category in categories.categories)
                          DropdownMenuItem<int?>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                      ],
                      onChanged: (value) => setState(() => _categoryId = value),
                    );
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEditing ? 'حفظ التعديلات' : 'حفظ الصنف'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatNumber(num value) {
    final isWhole = value == value.roundToDouble();
    return isWhole ? value.toStringAsFixed(0) : value.toString();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/product.dart';
import '../../../shared/widgets/barcode_scanner_dialog.dart';
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
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _halfPrice;
  late final TextEditingController _stock;
  late final TextEditingController _costPrice;
  late final TextEditingController _lowStockThreshold;
  late final TextEditingController _barcode;
  late final TextEditingController _preparationTime;
  late final TextEditingController _unitsPerPackage;
  late String _unit;
  String _packageUnit = '';
  int? _categoryId;
  bool _isAvailable = true;
  bool _isRawMaterial = false;
  String _imagePath = '';
  bool _saving = false;

  bool get _isEditing => widget.product != null;

  void _onUnitsPerPackageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _description = TextEditingController(text: product?.description ?? '');
    _price = TextEditingController(
      text: product == null ? '' : _formatNumber(product.price),
    );
    _halfPrice = TextEditingController(
      text: product == null || product.halfPrice <= 0
          ? ''
          : _formatNumber(product.halfPrice),
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
    _preparationTime = TextEditingController(
      text: product != null && product.preparationTime > 0
          ? '${product.preparationTime}'
          : '',
    );
    _unit = product?.unit ?? AppConstants.productUnits.first;
    _packageUnit = product?.packageUnit ?? '';
    _unitsPerPackage = TextEditingController(
      text: product != null && product.unitsPerPackage > 0
          ? _formatNumber(product.unitsPerPackage)
          : '',
    );
    _unitsPerPackage.addListener(_onUnitsPerPackageChanged);
    _categoryId = product?.categoryId;
    _isAvailable = product?.isAvailable ?? true;
    _isRawMaterial = product?.isRawMaterial ?? false;
    _imagePath = product?.imagePath ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _halfPrice.dispose();
    _stock.dispose();
    _costPrice.dispose();
    _lowStockThreshold.dispose();
    _barcode.dispose();
    _preparationTime.dispose();
    _unitsPerPackage.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final code = await showBarcodeScanner(context);
    if (code == null || !mounted) return;
    _barcode.text = code;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final productsCubit = context.read<ProductsCubit>();
    final price = double.tryParse(_price.text) ?? 0;
    final halfPrice = double.tryParse(_halfPrice.text) ?? 0;
    final stock = double.tryParse(_stock.text) ?? 0;
    final costPrice = double.tryParse(_costPrice.text) ?? 0;
    final lowStockThreshold = double.tryParse(_lowStockThreshold.text) ?? 0;
    final barcode = _barcode.text.trim();
    final preparationTime = int.tryParse(_preparationTime.text) ?? 0;
    final unitsPerPackage = double.tryParse(_unitsPerPackage.text) ?? 0;
    final packageUnit = _packageUnit.trim().isEmpty || unitsPerPackage <= 0 ? '' : _packageUnit;

    setState(() => _saving = true);
    final String? error;
    if (_isEditing) {
      error = await productsCubit.updateProduct(
        widget.product!,
        name: _name.text,
        price: price,
        halfPrice: halfPrice,
        stock: stock,
        unit: _unit,
        categoryId: _categoryId,
        costPrice: costPrice,
        lowStockThreshold: lowStockThreshold,
        barcode: barcode,
        isAvailable: _isAvailable,
        preparationTime: preparationTime,
        isRawMaterial: _isRawMaterial,
        imagePath: _imagePath,
        description: _description.text.trim(),
        packageUnit: packageUnit,
        unitsPerPackage: unitsPerPackage,
      );
    } else {
      error = await productsCubit.addProduct(
        name: _name.text,
        price: price,
        halfPrice: halfPrice,
        stock: stock,
        unit: _unit,
        categoryId: _categoryId,
        costPrice: costPrice,
        lowStockThreshold: lowStockThreshold,
        barcode: barcode,
        isAvailable: _isAvailable,
        preparationTime: preparationTime,
        isRawMaterial: _isRawMaterial,
        imagePath: _imagePath,
        description: _description.text.trim(),
        packageUnit: packageUnit,
        unitsPerPackage: unitsPerPackage,
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
                  controller: _description,
                  maxLines: 3,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'وصف الصنف (اختياري)',
                    prefixIcon: Icon(Icons.notes),
                    hintText: 'مكونات الوجبة أو أي تفاصيل تظهر في المنيو',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                _label('صورة الصنف (اختياري)'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: _imagePath.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              _imagePath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stack) => const Center(
                                child: Icon(Icons.broken_image, size: 40, color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.textSecondary),
                              SizedBox(height: 8),
                              Text(
                                'اضغط لاختيار صورة',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                  ),
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
                  controller: _halfPrice,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'سعر النص كيلو (اختياري)',
                    prefixIcon: Icon(Icons.price_change_outlined),
                    hintText: 'يظهر في المنيو بجانب سعر الكيلو',
                  ),
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
                  decoration: InputDecoration(
                    labelText: 'الباركود (اختياري)',
                    prefixIcon: const Icon(Icons.qr_code_scanner),
                    hintText: 'مثال: 6221031550621',
                    suffixIcon: IconButton(
                      tooltip: 'مسح بالكاميرا',
                      icon: const Icon(Icons.photo_camera_outlined),
                      onPressed: _scanBarcode,
                    ),
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
                 Text(
                   'وحدة الشراء بالجملة (اختياري)',
                   style: Theme.of(context).textTheme.titleSmall,
                 ),
                 const SizedBox(height: 4),
                 Text(
                   'لتمكين الشراء بالكرتونة/العلبة وإضافتها للمخزون تلقائيًا',
                   style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                 ),
                 const SizedBox(height: 10),
                 Row(
                   children: [
                     Expanded(
                       child: DropdownButtonFormField<String>(
                         initialValue: _packageUnit.isEmpty ? null : _packageUnit,
                         decoration: const InputDecoration(
                           labelText: 'وحدة الشراء',
                           hintText: 'مثال: كرتونة',
                           prefixIcon: Icon(Icons.inventory_2_outlined),
                         ),
                         items: [
                           const DropdownMenuItem(value: null, child: Text('-- بدون --')),
                           for (final unit in AppConstants.productUnits)
                             if (unit != _unit)
                               DropdownMenuItem(value: unit, child: Text(unit)),
                         ],
                         onChanged: (v) => setState(() => _packageUnit = v ?? ''),
                       ),
                     ),
                     const Padding(
                       padding: EdgeInsets.symmetric(horizontal: 8),
                       child: Text('=', style: TextStyle(fontWeight: FontWeight.w700)),
                     ),
                     Expanded(
                       child: TextFormField(
                         controller: _unitsPerPackage,
                         keyboardType:
                             const TextInputType.numberWithOptions(decimal: true),
                         enabled: _packageUnit.isNotEmpty,
                         decoration: InputDecoration(
                           labelText: 'عدد ال$_unit',
                           hintText: 'مثال: 24',
                         ),
                         validator: (value) {
                           if (_packageUnit.isEmpty) return null;
                           final parsed = double.tryParse(value ?? '');
                           if (parsed == null || parsed <= 0) {
                             return 'اكتب عدد ال$_unit في الواحدة';
                           }
                           return null;
                         },
                       ),
                     ),
                   ],
                 ),
                 if (_packageUnit.isNotEmpty &&
                     (double.tryParse(_unitsPerPackage.text) ?? 0) > 0)
                   Padding(
                     padding: const EdgeInsets.only(top: 8),
                     child: Text(
                       '1 $_packageUnit = ${_formatNumber(double.parse(_unitsPerPackage.text))} $_unit — عند شراء 8 $_packageUnit يُضاف ${_formatNumber(8 * double.parse(_unitsPerPackage.text))} $_unit للمخزون',
                       style: const TextStyle(
                           fontSize: 12, fontWeight: FontWeight.w600),
                     ),
                   ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _preparationTime,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'وقت التحضير بالدقائق (اختياري)',
                    prefixIcon: Icon(Icons.timer_outlined),
                    hintText: '0 = بدون وقت محدد',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    if (int.tryParse(value) == null || int.parse(value) < 0) {
                      return 'وقت غير صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('متاح في المنيو'),
                  subtitle: const Text('إذا كان مطفأ لن يظهر في شاشة الطلب', style: TextStyle(fontSize: 12)),
                  value: _isAvailable,
                  onChanged: (v) => setState(() => _isAvailable = v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('مادة خام (مخزون)'),
                  subtitle: const Text('يُستخدم للمشتريات وليس للبيع المباشر', style: TextStyle(fontSize: 12)),
                  value: _isRawMaterial,
                  onChanged: (v) => setState(() => _isRawMaterial = v),
                  contentPadding: EdgeInsets.zero,
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

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    );
  }
}

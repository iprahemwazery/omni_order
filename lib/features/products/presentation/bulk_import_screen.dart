import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/product.dart';
import '../../categories/presentation/categories_cubit.dart';
import '../../products/presentation/products_cubit.dart';

/// شاشة إضافة أصناف المنيو دفعة واحدة (استيراد جماعي).
class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  final List<_ProductEntry> _entries = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // نبدأ بـ 5 صفوف فاضية
    for (var i = 0; i < 5; i++) {
      _entries.add(_ProductEntry());
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoriesCubit>().state.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('استيراد منيو'),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() => _entries.add(_ProductEntry()));
            },
            icon: const Icon(Icons.add),
            label: const Text('إضافة صنف'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.primary.withValues(alpha: 0.05),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'أضف أصناف المنيو بسرعة. املأ البيانات واضغط "استيراد" في الأسفل.',
                    style: TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                ),
                Text(
                  '${_entries.length} أصناف',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _entries.length,
              itemBuilder: (context, index) => _ProductEntryCard(
                entry: _entries[index],
                index: index,
                categories: categories,
                onRemove: () {
                  setState(() => _entries.removeAt(index));
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: FilledButton.icon(
            onPressed: _saving ? null : _saveAll,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'جارٍ الاستيراد...' : 'استيراد ${_entries.length} صنف'),
          ),
        ),
      ),
    );
  }

  Future<void> _saveAll() async {
    final validEntries = _entries.where((e) => e.nameController.text.trim().isNotEmpty).toList();
    if (validEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف صنف واحد على الأقل')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final products = validEntries.map((e) => Product(
            name: e.nameController.text.trim(),
            price: double.tryParse(e.priceController.text) ?? 0,
            halfPrice: double.tryParse(e.halfPriceController.text) ?? 0,
            stock: 9999,
            unit: e.unit,
            categoryId: e.categoryId,
            isAvailable: true,
          )).toList();

      await context.read<ProductsCubit>().importProducts(products);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم استيراد ${products.length} صنف بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ProductEntry {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final halfPriceController = TextEditingController();
  String unit = 'قطعة';
  int? categoryId;
}

class _ProductEntryCard extends StatelessWidget {
  const _ProductEntryCard({
    required this.entry,
    required this.index,
    required this.categories,
    required this.onRemove,
  });

  final _ProductEntry entry;
  final int index;
  final List<Category> categories;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  radius: 16,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: entry.nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الصنف',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 20),
                  style: IconButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: entry.priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'السعر',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: entry.halfPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'سعر النص (اختياري)',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: entry.unit,
                    decoration: const InputDecoration(
                      labelText: 'الوحدة',
                      isDense: true,
                    ),
                    items: AppConstants.productUnits
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => entry.unit = v!,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: entry.categoryId,
                    decoration: const InputDecoration(
                      labelText: 'التصنيف',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<int>(value: null, child: Text('بدون تصنيف')),
                      for (final cat in categories)
                        DropdownMenuItem(value: cat.id, child: Text(cat.name)),
                    ],
                    onChanged: (v) => entry.categoryId = v,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

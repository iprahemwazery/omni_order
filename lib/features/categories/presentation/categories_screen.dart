import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/category.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../products/presentation/products_cubit.dart';
import '../../products/presentation/products_state.dart';
import 'categories_cubit.dart';

/// شاشة إدارة تصنيفات الأصناف.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoriesCubit>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('التصنيفات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCategory(context),
        icon: const Icon(Icons.add),
        label: const Text('إضافة تصنيف'),
      ),
      body: SafeArea(
        child: categories.categories.isEmpty
            ? const EmptyState(
                icon: Icons.category_outlined,
                title: 'لا توجد تصنيفات',
                subtitle: 'أضف تصنيفات لتنظيم الأصناف والوصول إليها بسرعة أثناء البيع',
              )
            : BlocBuilder<ProductsCubit, ProductsState>(
                builder: (context, products) {
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: categories.categories.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final category = categories.categories[index];
                      final count = products.products
                          .where((p) => p.categoryId == category.id)
                          .length;
                      return _CategoryTile(
                        category: category,
                        productsCount: count,
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Future<void> _addCategory(BuildContext context) async {
    final name = await _showCategoryDialog(context);
    if (name == null || !context.mounted) return;
    final error = await context.read<CategoriesCubit>().addCategory(name);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.productsCount});

  final Category category;
  final int productsCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1EF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.category, color: AppColors.primary),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$productsCount صنف',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') _confirmDelete(context);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التصنيف؟'),
        content: Text('سيتم حذف "${category.name}" ونقل أصنافه إلى "بدون تصنيف".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final categoriesCubit = context.read<CategoriesCubit>();
      final productsCubit = context.read<ProductsCubit>();
      await categoriesCubit.deleteCategory(category);
      await productsCubit.refresh();
    }
  }
}

Future<String?> _showCategoryDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('إضافة تصنيف'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'مثال: مشروبات، ألبان...',
        ),
        onSubmitted: (_) => Navigator.of(context).pop(controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('إضافة'),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/product.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../categories/presentation/categories_screen.dart';
import 'product_form_screen.dart';
import 'products_cubit.dart';

/// شاشة المخزون: عرض وإدارة الأصناف.
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProductsCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المخزون'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            ),
            tooltip: 'التصنيفات',
            icon: const Icon(Icons.category_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Center(
              child: Text(
                '${state.products.length} صنف',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('إضافة صنف'),
      ),
      body: SafeArea(
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : state.products.isEmpty
                ? const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'المخزون فارغ',
                    subtitle: 'اضغط زر "إضافة صنف" لإضافة أول منتج',
                  )
                : _ProductsList(
                    products: state.products,
                    onEdit: (product) => _openForm(context, product: product),
                  ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Product? product}) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
  }
}

class _ProductsList extends StatelessWidget {
  const _ProductsList({required this.products, required this.onEdit});

  final List<Product> products;
  final ValueChanged<Product> onEdit;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductTile(product: product, onEdit: () => onEdit(product));
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onEdit});

  final Product product;
  final VoidCallback onEdit;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الصنف؟'),
        content: Text('هل أنت متأكد من حذف "${product.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<ProductsCubit>().deleteProduct(product);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف "${product.name}"')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stock <= 0;
    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.money(product.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      outOfStock
                          ? 'نفد من المخزون'
                          : 'المخزون: ${AppFormatters.quantity(product.stock, product.unit)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: outOfStock ? AppColors.error : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') _confirmDelete(context);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('تعديل')),
                  PopupMenuItem(value: 'delete', child: Text('حذف')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

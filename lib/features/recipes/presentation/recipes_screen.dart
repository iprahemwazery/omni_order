import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/product.dart';
import '../../../domain/models/recipe.dart';
import '../../../domain/repositories/store_repository.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../products/presentation/products_cubit.dart';
import 'recipes_cubit.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RecipesCubit?>();
    if (cubit != null) {
      return BlocProvider.value(value: cubit, child: const _RecipesView());
    }
    return BlocProvider(
      create: (_) =>
          RecipesCubit(repository: context.read<StoreRepository>())..load(),
      child: const _RecipesView(),
    );
  }
}

class _RecipesView extends StatelessWidget {
  const _RecipesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'الوصفات',
            actions: [
              IconButton(
                onPressed: () => _showAddRecipeDialog(context),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<RecipesCubit, RecipesState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.recipes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد وصفات بعد',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => _showAddRecipeDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة وصفة'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = state.recipes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.12,
                          ),
                          child: const Icon(
                            Icons.menu_book,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(recipe.productName),
                        subtitle: Text('(${recipe.items.length} خام)'),
                        trailing: IconButton(
                          onPressed: () {
                            context.read<RecipesCubit>().deleteRecipe(
                              recipe.id!,
                            );
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _showAddRecipeDialog(BuildContext context) async {
    final products = context.read<ProductsCubit>().state.products;
    final rawMaterials = products.where((p) => p.isRawMaterial).toList();

    if (rawMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف مواد خام أولاً (من الأصناف)')),
      );
      return;
    }

    Product? selectedProduct;
    final items = <_RecipeItemDraft>[];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('وصفة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Product>(
                  decoration: const InputDecoration(labelText: 'الصنف *'),
                  items: products
                      .where((p) => !p.isRawMaterial)
                      .map(
                        (p) => DropdownMenuItem(value: p, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedProduct = val),
                ),
                const SizedBox(height: 16),
                const Text(
                  'الخامات المطلوبة',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.rawMaterialName,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${item.quantity} ${item.unit}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 18),
                        onPressed: () =>
                            setDialogState(() => items.removeAt(idx)),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 8),
                // Add raw material
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Product>(
                        decoration: const InputDecoration(
                          labelText: 'خام',
                          isDense: true,
                        ),
                        items: rawMaterials
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              items.add(
                                _RecipeItemDraft(
                                  rawMaterialId: val.id!,
                                  rawMaterialName: val.name,
                                  quantity: 1,
                                  unit: val.unit,
                                ),
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: selectedProduct == null || items.isEmpty
                  ? null
                  : () {
                      context.read<RecipesCubit>().addRecipe(
                        Recipe(
                          productId: selectedProduct!.id!,
                          productName: selectedProduct!.name,
                          items: items
                              .map(
                                (d) => RecipeItem(
                                  recipeId: 0,
                                  rawMaterialId: d.rawMaterialId,
                                  rawMaterialName: d.rawMaterialName,
                                  quantity: d.quantity,
                                  unit: d.unit,
                                ),
                              )
                              .toList(),
                        ),
                      );
                      Navigator.of(ctx).pop();
                    },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeItemDraft {
  final int rawMaterialId;
  final String rawMaterialName;
  final double quantity;
  final String unit;

  const _RecipeItemDraft({
    required this.rawMaterialId,
    required this.rawMaterialName,
    required this.quantity,
    required this.unit,
  });
}

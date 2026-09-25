import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/order_item.dart';
import '../../../domain/models/product.dart';
import '../../../domain/models/restaurant_table.dart';
import '../../../domain/repositories/store_repository.dart';
import '../../../shared/widgets/screen_header.dart';
import '../domain/usecases/waiter_usecases.dart';
import '../../categories/presentation/categories_cubit.dart';
import '../../categories/presentation/categories_state.dart';
import '../../products/presentation/products_cubit.dart';
import '../../products/presentation/products_state.dart';
import '../../settings/presentation/settings_cubit.dart';

/// شاشة طلب من الترابيزة — للجرساني لأخذ الطلب من عند الترابيزة.
class WaiterOrderScreen extends StatefulWidget {
  const WaiterOrderScreen({super.key});

  @override
  State<WaiterOrderScreen> createState() => _WaiterOrderScreenState();
}

class _WaiterOrderScreenState extends State<WaiterOrderScreen> {
  RestaurantTable? _selectedTable;
  final List<_WaiterOrderLine> _lines = [];
  final TextEditingController _noteController = TextEditingController();
  String _selectedCategory = '';

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double get _total => _lines.fold(0, (sum, l) => sum + l.subtotal);

  void _addItem(Product product) {
    final idx = _lines.indexWhere((l) => l.product.id == product.id);
    setState(() {
      if (idx >= 0) {
        _lines[idx] = _lines[idx].copyWith(quantity: _lines[idx].quantity + 1);
      } else {
        _lines.add(_WaiterOrderLine(product: product, quantity: 1));
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      if (_lines[index].quantity > 1) {
        _lines[index] = _lines[index].copyWith(
          quantity: _lines[index].quantity - 1,
        );
      } else {
        _lines.removeAt(index);
      }
    });
  }

  void _submitOrder() async {
    if (_selectedTable == null || _lines.isEmpty) return;

    final settings = context.read<SettingsCubit>().state.settings;
    final taxRate = settings.taxRate;

    final total = _total;
    final taxAmount = taxRate > 0 ? total * taxRate / (100 + taxRate) : 0.0;

    final repo = context.read<StoreRepository>();
    try {
      final order = RestaurantOrder(
        tableId: _selectedTable!.id!,
        total: total,
        discount: 0,
        taxRate: taxRate,
        taxAmount: taxAmount,
        status: 'pending',
        note: _noteController.text.trim(),
      );
      final items = _lines
          .map(
            (l) => OrderItem(
              orderId: 0,
              productId: l.product.id ?? 0,
              name: l.product.name,
              price: l.product.price,
              quantity: l.quantity,
              subtotal: l.subtotal,
            ),
          )
          .toList();
      final submitOrder = context.read<SubmitWaiterOrder?>();
      if (submitOrder == null) {
        await repo.createOrder(order: order, items: items);
      } else {
        await submitOrder(order: order, items: items);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إرسال الطلب للتربيزة ${_selectedTable!.number}'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'طلب من الترابيزة',
            actions: [
              if (_lines.isNotEmpty)
                FilledButton.icon(
                  onPressed: _submitOrder,
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('إرسال الطلب'),
                ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                // Left: Table Selection + Products
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Table Selection
                      _buildTableSelector(),
                      const Divider(height: 1),
                      // Category Tabs
                      _buildCategoryTabs(),
                      // Products Grid
                      Expanded(child: _buildProductsGrid()),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                // Right: Order Summary
                SizedBox(width: 320, child: _buildOrderSummary()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختر التربيزة',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: FutureBuilder<List<RestaurantTable>>(
              future: _loadTables(context),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final tables = snapshot.data!;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: tables.length,
                  itemBuilder: (context, idx) {
                    final table = tables[idx];
                    final isSelected = _selectedTable?.id == table.id;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text('تريبية ${table.number}'),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedTable = table),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
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

  Widget _buildCategoryTabs() {
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, categories) {
        return Container(
          height: 48,
          color: AppColors.surface,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: const Text('الكل'),
                  selected: _selectedCategory.isEmpty,
                  onSelected: (_) => setState(() => _selectedCategory = ''),
                ),
              ),
              ...categories.categories.map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(cat.name),
                    selected: _selectedCategory == cat.name,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat.name),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductsGrid() {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, products) {
        var filtered = products.products.where((p) => p.isAvailable).toList();
        if (_selectedCategory.isNotEmpty) {
          final cats = context.read<CategoriesCubit>().state.categories;
          final cat = cats
              .where((c) => c.name == _selectedCategory)
              .firstOrNull;
          if (cat != null) {
            filtered = filtered.where((p) => p.categoryId == cat.id).toList();
          }
        }

        if (filtered.isEmpty) {
          return const Center(child: Text('لا توجد أصناف متاحة'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final product = filtered[index];
            return _ProductCard(
              product: product,
              onTap: () => _addItem(product),
            );
          },
        );
      },
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  _selectedTable != null
                      ? 'التربيزة ${_selectedTable!.number}'
                      : 'اختر تربيزة',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_lines.length} أصناف',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: _lines.isEmpty
                ? const Center(
                    child: Text(
                      'اضغط على صنف لإضافته',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _lines.length,
                    itemBuilder: (context, index) {
                      final line = _lines[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(line.product.name),
                          subtitle: Text(
                            '${AppFormatters.money(line.product.price)} × ${line.quantity.toInt()}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppFormatters.money(line.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 20,
                                ),
                                onPressed: () => _removeItem(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Note
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'ملاحظات الطلب...',
                prefixIcon: Icon(Icons.notes_outlined),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ),
          // Total & Submit
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الإجمالي',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      AppFormatters.money(_total),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: (_selectedTable != null && _lines.isNotEmpty)
                        ? _submitOrder
                        : null,
                    icon: const Icon(Icons.send),
                    label: const Text('إرسال الطلب'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<RestaurantTable>> _loadTables(BuildContext context) {
  final getTables = context.read<GetWaiterTables?>();
  return getTables == null
      ? context.read<StoreRepository>().getTables()
      : getTables();
}

class _WaiterOrderLine {
  final Product product;
  final double quantity;
  const _WaiterOrderLine({required this.product, required this.quantity});
  double get subtotal => product.price * quantity;

  _WaiterOrderLine copyWith({double? quantity}) {
    return _WaiterOrderLine(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                product.imagePath.isNotEmpty
                    ? Icons.image
                    : Icons.fastfood_outlined,
                size: 32,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                AppFormatters.money(product.price),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

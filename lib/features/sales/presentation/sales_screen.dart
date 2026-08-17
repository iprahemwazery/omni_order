import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/product.dart';
import '../../../shared/widgets/barcode_scanner_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../categories/presentation/categories_cubit.dart';
import '../../products/presentation/products_cubit.dart';
import '../../products/presentation/products_state.dart';
import 'cart_cubit.dart';
import 'held_invoices_screen.dart';
import 'receipt_screen.dart';
import 'shift_screen.dart';
import 'widgets/cart_panel.dart';
import 'widgets/checkout_sheet.dart';
import 'widgets/product_card.dart';
import 'widgets/quantity_dialog.dart';

/// شاشة البيع: كل الأصناف أمامك، تضغط وتختار الكمية وتكمل البيع.
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  bool _completing = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, products) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('المبيعات'),
            actions: [
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HeldInvoicesScreen(),
                  ),
                ),
                tooltip: 'الفواتير المعلقة',
                icon: const Icon(Icons.pause_circle_outline),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ShiftScreen()),
                ),
                tooltip: 'تقرير الوردية',
                icon: const Icon(Icons.event_note_outlined),
              ),
              IconButton(
                onPressed: () => _openCartSheet(context),
                tooltip: 'السلة',
                icon: const Icon(Icons.shopping_cart_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: products.loading
                ? const Center(child: CircularProgressIndicator())
                : products.products.isEmpty
                    ? const EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'لا توجد أصناف بعد',
                        subtitle: 'ابدأ بإضافة الأصناف من شاشة المخزون',
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 760;
                          final grid = const _SalesGrid();

                          if (isWide) {
                            return Row(
                              children: [
                                Expanded(child: grid),
                                Container(
                                  width: 380,
                                  margin: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(18),
                                    border:
                                        Border.all(color: AppColors.border),
                                  ),
                                  child: CartPanel(
                                    onComplete:
                                        _completing ? null : _completeSale,
                                    onHold: _completing ? null : _holdCart,
                                  ),
                                ),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              Expanded(child: grid),
                              _MobileCartBar(
                                onOpenCart: () => _openCartSheet(context),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        );
      },
    );
  }

  Future<void> _openCartSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: CartPanel(
          isSheet: true,
          onComplete: _completing
              ? null
              : () {
                  Navigator.of(context).pop();
                  _completeSale();
                },
          onHold: _completing
              ? null
              : () {
                  Navigator.of(context).pop();
                  _holdCart();
                },
        ),
      ),
    );
  }

  /// يعلّق السلة الحالية محليًا ثم يُفرّغها لاستقبال عميل جديد.
  Future<void> _holdCart() async {
    final cubit = context.read<CartCubit>();
    if (cubit.state.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final cashierName =
        context.read<AuthCubit>().state.admin?.username ?? '';
    try {
      final id = await cubit.holdCart(cashierName: cashierName);
      if (id == null) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم تعليق الفاتورة. يمكنك استرجاعها من الفواتير المعلقة.'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(safeErrorMessage('تعذر تعليق الفاتورة', e))),
      );
    }
  }

  Future<void> _completeSale() async {
    if (_completing) return;
    setState(() => _completing = true);
    try {
      final sale = await showCheckoutSheet(context);
      if (!mounted) return;
      if (sale != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ReceiptScreen(sale: sale)),
        );
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }
}

/// شبكة الأصناف + البحث + التصنيفات. معزولة عن تغيّرات السلة حتى لا تُعاد
/// بناء كل الأصناف عند كل تعديل كمية.
class _SalesGrid extends StatefulWidget {
  const _SalesGrid();

  @override
  State<_SalesGrid> createState() => _SalesGridState();
}

class _SalesGridState extends State<_SalesGrid> {
  final TextEditingController _search = TextEditingController();
  int? _selectedCategoryId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsCubit>().state.products;
    final categories = context.watch<CategoriesCubit>().state.categories;
    final query = _search.text.trim().toLowerCase();

    final filtered = products.where((p) {
      final matchesSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          (p.barcode.isNotEmpty && p.barcode.toLowerCase().contains(query));
      final matchesCategory =
          _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _searchExact(),
            decoration: InputDecoration(
              hintText: 'ابحث عن صنف أو امسح الباركود...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'مسح بالكاميرا',
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.qr_code_scanner),
                  ),
                  if (_search.text.isNotEmpty)
                    IconButton(
                      onPressed: () => _search.clear(),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (categories.isNotEmpty)
          _CategoryBar(
            categories: categories,
            selectedId: _selectedCategoryId,
            onSelected: (id) => setState(() => _selectedCategoryId = id),
          ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off,
                  title: 'لا توجد نتائج',
                  subtitle: 'جرّب كلمة بحث أخرى أو تصنيف مختلف',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 190,
                    mainAxisExtent: 182,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return ProductCard(
                      product: product,
                      onTap: () => _onProductTap(product),
                      onQuickAdd: product.stock > 0
                          ? () => _quickAdd(product)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _quickAdd(Product product) {
    final error = context.read<CartCubit>().addToCart(product, 1);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  /// يمسح باركودًا بالكاميرا: لو طابق صنفًا يُضاف فورًا للسلة بكمية 1،
  /// وإلا يعرض الباركود في البحث ليبحث عنه.
  Future<void> _scanBarcode() async {
    final code = await showBarcodeScanner(context);
    if (code == null || !mounted) return;

    final normalized = code.trim().toLowerCase();
    Product? match;
    for (final product in context.read<ProductsCubit>().state.products) {
      if (product.barcode.isNotEmpty &&
          product.barcode.toLowerCase() == normalized) {
        match = product;
        break;
      }
    }

    if (match == null) {
      _search.text = code.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد صنف بهذا الباركود')),
      );
      return;
    }

    if (match.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عذرًا، هذا الصنف نفد من المخزون')),
      );
      return;
    }
    _quickAdd(match);
  }

  /// عند الضغط Enter: لو النص يطابق باركود أو اسم صنف تمامًا يُضاف فورًا
  /// بكمية 1 (مفيد مع قارئ الباركود وسرعة البيع).
  void _searchExact() {
    final query = _search.text.trim();
    if (query.isEmpty) return;
    final normalized = query.toLowerCase();
    Product? match;
    for (final product in context.read<ProductsCubit>().state.products) {
      if (product.barcode.isNotEmpty &&
          product.barcode.toLowerCase() == normalized) {
        match = product;
        break;
      }
    }
    if (match == null) {
      for (final product in context.read<ProductsCubit>().state.products) {
        if (product.name.toLowerCase() == normalized) {
          match = product;
          break;
        }
      }
    }
    if (match == null) return;
    _search.clear();
    if (match.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عذرًا، هذا الصنف نفد من المخزون')),
      );
      return;
    }
    _quickAdd(match);
  }

  void _onProductTap(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عذرًا، هذا الصنف نفد من المخزون')),
      );
      return;
    }
    showQuantityDialog(context, product);
  }
}

/// شريط الإجمالي السفلي في وضع الموبايل. يتابع السلة بنفسه.
class _MobileCartBar extends StatelessWidget {
  const _MobileCartBar({required this.onOpenCart});

  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartCubit>().state;
    if (cart.isEmpty) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('الإجمالي', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text(
                    AppFormatters.money(cart.total),
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
              onPressed: onOpenCart,
              icon: Badge(
                label: Text(cart.totalQuantity.toStringAsFixed(0)),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              label: const Text('عرض السلة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _chip(null, 'الكل'),
          for (final category in categories) _chip(category.id, category.name),
        ],
      ),
    );
  }

  Widget _chip(int? id, String label) {
    final selected = selectedId == id;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(id),
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

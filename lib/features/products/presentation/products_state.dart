import 'package:equatable/equatable.dart';

import '../../../../domain/models/product.dart';

/// حالة شاشة المخزون (قائمة الأصناف + حالة التحميل/الخطأ).
class ProductsState extends Equatable {
  const ProductsState({
    this.products = const [],
    this.loading = false,
    this.error,
  });

  final List<Product> products;
  final bool loading;
  final String? error;

  /// أصناف على وشك النفاد (الكمية أقل من حد كل صنف أو حد عام 5 إن لم يُحدَّد).
  List<Product> lowStock() => products
      .where((p) {
        final threshold = p.lowStockThreshold > 0 ? p.lowStockThreshold : 5;
        return p.stock > 0 && p.stock <= threshold;
      })
      .toList();

  List<Product> get outOfStock => products.where((p) => p.stock <= 0).toList();

  Product? productById(int? id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  ProductsState copyWith({
    List<Product>? products,
    bool? loading,
    String? error,
  }) {
    return ProductsState(
      products: products ?? this.products,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [products, loading, error];
}

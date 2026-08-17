import 'package:equatable/equatable.dart';

import '../../../../domain/models/product.dart';

/// حالة شاشة المخزون (قائمة الأصناف + حالة التحميل/الخطأ).
class ProductsState extends Equatable {
  ProductsState({
    this.products = const [],
    this.loading = false,
    this.error,
  })  : _lowStock = _computeLowStock(products),
        _outOfStock = _computeOutOfStock(products);

  final List<Product> products;
  final bool loading;
  final String? error;
  final List<Product> _lowStock;
  final List<Product> _outOfStock;

  /// أصناف على وشك النفاد (الكمية أقل من حد كل صنف أو حد عام 5 إن لم يُحدَّد).
  /// تُحسب مرة واحدة عند إنشاء الحالة (البيانات ثابتة بعد الإنشاء).
  List<Product> get lowStock => _lowStock;

  List<Product> get outOfStock => _outOfStock;

  static List<Product> _computeLowStock(List<Product> products) => products
      .where((p) {
        final threshold = p.lowStockThreshold > 0 ? p.lowStockThreshold : 5;
        return p.stock > 0 && p.stock <= threshold;
      })
      .toList();

  static List<Product> _computeOutOfStock(List<Product> products) =>
      products.where((p) => p.stock <= 0).toList();

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

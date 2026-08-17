import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../../../domain/models/product.dart';
import '../../../../domain/repositories/store_repository.dart';
import 'products_state.dart';

/// يدير قائمة الأصناف داخل شاشة المخزون.
class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(this._repository) : super(ProductsState(loading: true));

  final StoreRepository _repository;

  /// التحميل الأولي عند فتح التطبيق (يعرض مؤشر التحميل).
  Future<void> init() async {
    emit(ProductsState(loading: true));
    await refresh();
  }

  /// إعادة تحميل الأصناف من المصدر (بدون مؤشر تحميل).
  Future<void> refresh() async {
    try {
      final products = await _repository.getProducts();
      emit(ProductsState(products: products));
    } catch (e) {
      emit(state.copyWith(error: safeErrorMessage('تعذر تحميل الأصناف', e)));
    }
  }

  /// يضيف صنفًا جديدًا، ويعيد رسالة خطأ إن وُجدت (null يعني نجاح).
  Future<String?> addProduct({
    required String name,
    required double price,
    required double stock,
    required String unit,
    int? categoryId,
    double costPrice = 0,
    double lowStockThreshold = 0,
    String barcode = '',
  }) async {
    final error = _validateProduct(name: name, price: price, stock: stock);
    if (error != null) return error;

    final product = Product(
      name: name.trim(),
      price: price,
      stock: stock,
      unit: unit,
      categoryId: categoryId,
      costPrice: costPrice,
      lowStockThreshold: lowStockThreshold,
      barcode: barcode.trim(),
    );
    final id = await _repository.addProduct(product);
    emit(state.copyWith(products: [product.copyWith(id: id), ...state.products]));
    return null;
  }

  Future<String?> updateProduct(
    Product original, {
    required String name,
    required double price,
    required double stock,
    required String unit,
    int? categoryId,
    double costPrice = 0,
    double lowStockThreshold = 0,
    String barcode = '',
  }) async {
    final error = _validateProduct(name: name, price: price, stock: stock);
    if (error != null) return error;

    final updated = original.copyWith(
      name: name.trim(),
      price: price,
      stock: stock,
      unit: unit,
      categoryId: categoryId,
      costPrice: costPrice,
      lowStockThreshold: lowStockThreshold,
      barcode: barcode.trim(),
    );
    await _repository.updateProduct(updated);
    emit(state.copyWith(
      products: [
        for (final p in state.products) p.id == updated.id ? updated : p,
      ],
    ));
    return null;
  }

  Future<void> deleteProduct(Product product) async {
    if (product.id == null) return;
    await _repository.deleteProduct(product.id!);
    emit(state.copyWith(
      products: state.products.where((p) => p.id != product.id).toList(),
    ));
  }

  static String? _validateProduct({
    required String name,
    required double price,
    required double stock,
  }) {
    if (name.trim().isEmpty) return 'من فضلك اكتب اسم الصنف.';
    if (price <= 0) return 'سعر الصنف مطلوب ويجب أن يكون أكبر من صفر.';
    if (stock < 0) return 'الكمية لا يمكن أن تكون سالبة.';
    return null;
  }
}

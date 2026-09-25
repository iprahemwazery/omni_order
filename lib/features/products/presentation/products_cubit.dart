import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../../../domain/models/product.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../domain/usecases/products_usecases.dart';
import 'products_state.dart';

/// يدير قائمة الأصناف داخل شاشة المخزون.
class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(
    this._repository, {
    GetProductsUseCase? getProducts,
    CreateProductUseCase? createProduct,
    UpdateProductUseCase? updateProduct,
    DeleteProductUseCase? deleteProduct,
    ImportProductsUseCase? importProducts,
  }) : _getProducts = getProducts,
       _createProduct = createProduct,
       _updateProduct = updateProduct,
       _deleteProduct = deleteProduct,
       _importProducts = importProducts,
       super(ProductsState(loading: true));

  final StoreRepository _repository;
  final GetProductsUseCase? _getProducts;
  final CreateProductUseCase? _createProduct;
  final UpdateProductUseCase? _updateProduct;
  final DeleteProductUseCase? _deleteProduct;
  final ImportProductsUseCase? _importProducts;

  /// التحميل الأولي عند فتح التطبيق (يعرض مؤشر التحميل).
  Future<void> init() async {
    emit(ProductsState(loading: true));
    await refresh();
  }

  /// إعادة تحميل الأصناف من المصدر (بدون مؤشر تحميل).
  Future<void> refresh() async {
    try {
      final products =
          await (_getProducts?.call() ?? _repository.getProducts());
      emit(ProductsState(products: products));
    } catch (e) {
      emit(state.copyWith(error: safeErrorMessage('تعذر تحميل الأصناف', e)));
    }
  }

  /// يضيف صنفًا جديدًا، ويعيد رسالة خطأ إن وُجدت (null يعني نجاح).
  Future<String?> addProduct({
    required String name,
    required double price,
    double halfPrice = 0,
    required double stock,
    required String unit,
    int? categoryId,
    double costPrice = 0,
    double lowStockThreshold = 0,
    String barcode = '',
    bool isAvailable = true,
    int preparationTime = 0,
    bool isRawMaterial = false,
    String imagePath = '',
    String description = '',
    String packageUnit = '',
    double unitsPerPackage = 0,
  }) async {
    final error = _validateProduct(name: name, price: price, stock: stock);
    if (error != null) return error;

    final product = Product(
      name: name.trim(),
      price: price,
      halfPrice: halfPrice,
      stock: stock,
      unit: unit,
      categoryId: categoryId,
      costPrice: costPrice,
      lowStockThreshold: lowStockThreshold,
      barcode: barcode.trim(),
      isAvailable: isAvailable,
      preparationTime: preparationTime,
      isRawMaterial: isRawMaterial,
      imagePath: imagePath,
      description: description.trim(),
      packageUnit: packageUnit,
      unitsPerPackage: unitsPerPackage,
    );
    final Product created;
    if (_createProduct != null) {
      created = await _createProduct(product);
    } else {
      final id = await _repository.addProduct(product);
      created = product.copyWith(id: id);
    }
    emit(state.copyWith(products: [created, ...state.products]));
    return null;
  }

  Future<String?> updateProduct(
    Product original, {
    required String name,
    required double price,
    double halfPrice = 0,
    required double stock,
    required String unit,
    int? categoryId,
    double costPrice = 0,
    double lowStockThreshold = 0,
    String barcode = '',
    bool isAvailable = true,
    int preparationTime = 0,
    bool isRawMaterial = false,
    String imagePath = '',
    String? description,
    String? packageUnit,
    double? unitsPerPackage,
  }) async {
    final error = _validateProduct(name: name, price: price, stock: stock);
    if (error != null) return error;

    final updated = original.copyWith(
      name: name.trim(),
      price: price,
      halfPrice: halfPrice,
      stock: stock,
      unit: unit,
      categoryId: categoryId,
      costPrice: costPrice,
      lowStockThreshold: lowStockThreshold,
      barcode: barcode.trim(),
      isAvailable: isAvailable,
      preparationTime: preparationTime,
      isRawMaterial: isRawMaterial,
      imagePath: imagePath,
      description: description,
      packageUnit: packageUnit,
      unitsPerPackage: unitsPerPackage,
    );
    if (_updateProduct != null) {
      await _updateProduct(updated);
    } else {
      await _repository.updateProduct(updated);
    }
    emit(
      state.copyWith(
        products: [
          for (final p in state.products) p.id == updated.id ? updated : p,
        ],
      ),
    );
    return null;
  }

  Future<void> deleteProduct(Product product) async {
    if (product.id == null) return;
    if (_deleteProduct != null) {
      await _deleteProduct(product.id!);
    } else {
      await _repository.deleteProduct(product.id!);
    }
    emit(
      state.copyWith(
        products: state.products.where((p) => p.id != product.id).toList(),
      ),
    );
  }

  Future<void> importProducts(List<Product> products) async {
    if (_importProducts != null) {
      await _importProducts(products);
    } else {
      await _repository.addProductsBulk(products);
    }
    await refresh();
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

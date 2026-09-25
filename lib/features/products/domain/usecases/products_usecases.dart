import '../../../../domain/models/product.dart';
import '../repositories/products_repository.dart';

class GetProductsUseCase {
  const GetProductsUseCase(this._repository);

  final ProductsRepository _repository;

  Future<List<Product>> call() => _repository.getProducts();
}

class CreateProductUseCase {
  const CreateProductUseCase(this._repository);

  final ProductsRepository _repository;

  Future<Product> call(Product product) async {
    _validateProduct(product);
    final id = await _repository.addProduct(product);
    return product.copyWith(id: id);
  }
}

class UpdateProductUseCase {
  const UpdateProductUseCase(this._repository);

  final ProductsRepository _repository;

  Future<void> call(Product product) async {
    _validateProduct(product);
    if (product.id == null || product.id! <= 0) {
      throw ArgumentError.value(
        product.id,
        'id',
        'A saved product is required',
      );
    }
    await _repository.updateProduct(product);
  }
}

class DeleteProductUseCase {
  const DeleteProductUseCase(this._repository);

  final ProductsRepository _repository;

  Future<void> call(int id) {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive');
    return _repository.deleteProduct(id);
  }
}

class ImportProductsUseCase {
  const ImportProductsUseCase(this._repository);

  final ProductsRepository _repository;

  Future<List<int>> call(List<Product> products) async {
    for (final product in products) {
      _validateProduct(product);
    }
    return _repository.addProductsBulk(List<Product>.from(products));
  }
}

class AdjustStockUseCase {
  const AdjustStockUseCase(this._repository);

  final ProductsRepository _repository;

  Future<void> call({required int productId, required double delta}) {
    if (productId <= 0) {
      throw ArgumentError.value(productId, 'productId', 'Must be positive');
    }
    if (!delta.isFinite) {
      throw ArgumentError.value(delta, 'delta', 'Must be finite');
    }
    return _repository.updateStock(productId, delta);
  }
}

void _validateProduct(Product product) {
  if (product.name.trim().isEmpty) {
    throw ArgumentError.value(product.name, 'name', 'Cannot be empty');
  }
  if (!product.price.isFinite || product.price <= 0) {
    throw ArgumentError.value(product.price, 'price', 'Must be positive');
  }
  if (!product.stock.isFinite || product.stock < 0) {
    throw ArgumentError.value(product.stock, 'stock', 'Cannot be negative');
  }
}

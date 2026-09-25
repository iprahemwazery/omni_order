import '../../../../domain/models/product.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/products_repository.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  ProductsRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<Product>> getProducts() => _storeRepository.getProducts();

  @override
  Future<int> addProduct(Product product) =>
      _storeRepository.addProduct(product);

  @override
  Future<void> updateProduct(Product product) =>
      _storeRepository.updateProduct(product);

  @override
  Future<void> deleteProduct(int id) => _storeRepository.deleteProduct(id);

  @override
  Future<List<int>> addProductsBulk(List<Product> products) =>
      _storeRepository.addProductsBulk(products);

  @override
  Future<void> updateStock(int productId, double delta) =>
      _storeRepository.updateStock(productId, delta);
}

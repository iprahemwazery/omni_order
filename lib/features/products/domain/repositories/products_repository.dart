import '../../../../domain/models/product.dart';

abstract interface class ProductsRepository {
  Future<List<Product>> getProducts();
  Future<int> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(int id);
  Future<List<int>> addProductsBulk(List<Product> products);
  Future<void> updateStock(int productId, double delta);
}

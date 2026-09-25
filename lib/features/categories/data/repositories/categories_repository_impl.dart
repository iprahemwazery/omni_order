import '../../../../domain/models/category.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/categories_repository.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  CategoriesRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<Category>> getCategories() => _storeRepository.getCategories();

  @override
  Future<int> addCategory(Category category) =>
      _storeRepository.addCategory(category);

  @override
  Future<void> updateCategory(Category category) =>
      _storeRepository.updateCategory(category);

  @override
  Future<void> deleteCategory(int id) => _storeRepository.deleteCategory(id);
}

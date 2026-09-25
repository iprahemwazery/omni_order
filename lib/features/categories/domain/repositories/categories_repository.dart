import '../../../../domain/models/category.dart';

abstract interface class CategoriesRepository {
  Future<List<Category>> getCategories();
  Future<int> addCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(int id);
}

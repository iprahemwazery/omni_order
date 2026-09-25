import '../../../../domain/models/category.dart';
import '../repositories/categories_repository.dart';

class GetCategoriesUseCase {
  const GetCategoriesUseCase(this._repository);

  final CategoriesRepository _repository;

  Future<List<Category>> call() => _repository.getCategories();
}

class CreateCategoryUseCase {
  const CreateCategoryUseCase(this._repository);

  final CategoriesRepository _repository;

  Future<Category> call(String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Cannot be empty');
    }

    final category = Category(name: normalizedName);
    final id = await _repository.addCategory(category);
    return category.copyWith(id: id);
  }
}

class UpdateCategoryUseCase {
  const UpdateCategoryUseCase(this._repository);

  final CategoriesRepository _repository;

  Future<void> call(Category category) async {
    if (category.id == null || category.id! <= 0) {
      throw ArgumentError.value(
        category.id,
        'id',
        'A saved category is required',
      );
    }
    if (category.name.trim().isEmpty) {
      throw ArgumentError.value(category.name, 'name', 'Cannot be empty');
    }
    await _repository.updateCategory(
      category.copyWith(name: category.name.trim()),
    );
  }
}

class DeleteCategoryUseCase {
  const DeleteCategoryUseCase(this._repository);

  final CategoriesRepository _repository;

  Future<void> call(int id) {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive');
    return _repository.deleteCategory(id);
  }
}

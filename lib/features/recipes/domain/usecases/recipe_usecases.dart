import '../../../../domain/models/recipe.dart';
import '../repositories/recipe_repository.dart';

class GetRecipesUseCase {
  const GetRecipesUseCase(this._repository);

  final RecipeRepository _repository;

  Future<List<Recipe>> call() => _repository.getRecipes();
}

class RecipeDetails {
  const RecipeDetails({required this.recipe, required this.items});

  final Recipe recipe;
  final List<RecipeItem> items;
}

class GetRecipeDetailsUseCase {
  const GetRecipeDetailsUseCase(this._repository);

  final RecipeRepository _repository;

  Future<RecipeDetails> call(int recipeId) async {
    if (recipeId <= 0) throw ArgumentError('معرف الوصفة مطلوب.');
    final recipes = await _repository.getRecipes();
    Recipe? recipe;
    for (final item in recipes) {
      if (item.id == recipeId) {
        recipe = item;
        break;
      }
    }
    if (recipe == null) throw StateError('الوصفة غير موجودة.');
    final items = await _repository.getRecipeItems(recipeId);
    return RecipeDetails(
      recipe: recipe.copyWith(items: items),
      items: items,
    );
  }
}

class GetRecipeItemsUseCase {
  const GetRecipeItemsUseCase(this._repository);

  final RecipeRepository _repository;

  Future<List<RecipeItem>> call(int recipeId) {
    if (recipeId <= 0) return Future.value(const <RecipeItem>[]);
    return _repository.getRecipeItems(recipeId);
  }
}

class CreateRecipeUseCase {
  const CreateRecipeUseCase(this._repository);

  final RecipeRepository _repository;

  Future<int> call(Recipe recipe) {
    final normalized = _normalizeRecipe(recipe);
    _validateRecipe(normalized);
    return _repository.createRecipe(normalized);
  }
}

class UpdateRecipeUseCase {
  const UpdateRecipeUseCase(this._repository);

  final RecipeRepository _repository;

  Future<void> call(Recipe recipe) {
    if (recipe.id == null || recipe.id! <= 0) {
      throw ArgumentError('معرف الوصفة مطلوب.');
    }
    final normalized = _normalizeRecipe(recipe);
    _validateRecipe(normalized);
    return _repository.updateRecipe(normalized);
  }
}

class DeleteRecipeUseCase {
  const DeleteRecipeUseCase(this._repository);

  final RecipeRepository _repository;

  Future<void> call(int id) {
    if (id <= 0) throw ArgumentError('معرف الوصفة مطلوب.');
    return _repository.deleteRecipe(id);
  }
}

class AddRecipeItemUseCase {
  const AddRecipeItemUseCase(this._repository);

  final RecipeRepository _repository;

  Future<void> call(RecipeItem item) {
    if (item.recipeId <= 0) throw ArgumentError('معرف الوصفة مطلوب.');
    final normalized = _normalizeItem(item);
    _validateItem(normalized);
    return _repository.addRecipeItem(normalized);
  }
}

class DeleteRecipeItemUseCase {
  const DeleteRecipeItemUseCase(this._repository);

  final RecipeRepository _repository;

  Future<void> call(int id) {
    if (id <= 0) throw ArgumentError('معرف بند الوصفة مطلوب.');
    return _repository.deleteRecipeItem(id);
  }
}

Recipe _normalizeRecipe(Recipe recipe) => recipe.copyWith(
  productName: recipe.productName.trim(),
  items: [for (final item in recipe.items) _normalizeItem(item)],
);

RecipeItem _normalizeItem(RecipeItem item) => item.copyWith(
  rawMaterialName: item.rawMaterialName.trim(),
  unit: item.unit.trim().isEmpty ? 'كجم' : item.unit.trim(),
);

void _validateRecipe(Recipe recipe) {
  if (recipe.productId <= 0) {
    throw ArgumentError('معرف الصنف مطلوب.');
  }
  if (recipe.productName.isEmpty) {
    throw ArgumentError('اسم الصنف مطلوب.');
  }
  if (recipe.items.isEmpty) {
    throw ArgumentError('يجب إضافة خامة واحدة على الأقل.');
  }
  final materialIds = <int>{};
  for (final item in recipe.items) {
    _validateItem(item);
    if (!materialIds.add(item.rawMaterialId)) {
      throw StateError('لا يمكن تكرار الخامة داخل الوصفة.');
    }
  }
}

void _validateItem(RecipeItem item) {
  if (item.rawMaterialId <= 0) {
    throw ArgumentError('معرف الخامة مطلوب.');
  }
  if (item.rawMaterialName.isEmpty) {
    throw ArgumentError('اسم الخامة مطلوب.');
  }
  if (item.quantity <= 0) {
    throw ArgumentError('كمية الخامة يجب أن تكون أكبر من صفر.');
  }
}

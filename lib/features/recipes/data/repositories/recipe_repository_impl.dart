import '../../../../domain/models/recipe.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/recipe_repository.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  const RecipeRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<Recipe>> getRecipes() => _storeRepository.getRecipes();

  @override
  Future<int> createRecipe(Recipe recipe) =>
      _storeRepository.createRecipe(recipe);

  @override
  Future<void> updateRecipe(Recipe recipe) =>
      _storeRepository.updateRecipe(recipe);

  @override
  Future<void> deleteRecipe(int id) => _storeRepository.deleteRecipe(id);

  @override
  Future<List<RecipeItem>> getRecipeItems(int recipeId) =>
      _storeRepository.getRecipeItems(recipeId);

  @override
  Future<void> addRecipeItem(RecipeItem item) =>
      _storeRepository.addRecipeItem(item);

  @override
  Future<void> deleteRecipeItem(int id) =>
      _storeRepository.deleteRecipeItem(id);
}

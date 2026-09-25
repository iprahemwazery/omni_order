import '../../../../domain/models/recipe.dart';

abstract interface class RecipeRepository {
  Future<List<Recipe>> getRecipes();

  Future<int> createRecipe(Recipe recipe);

  Future<void> updateRecipe(Recipe recipe);

  Future<void> deleteRecipe(int id);

  Future<List<RecipeItem>> getRecipeItems(int recipeId);

  Future<void> addRecipeItem(RecipeItem item);

  Future<void> deleteRecipeItem(int id);
}

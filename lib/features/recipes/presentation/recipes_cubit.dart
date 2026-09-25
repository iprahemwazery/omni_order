import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/recipe.dart';
import '../../../domain/repositories/store_repository.dart';
import '../domain/usecases/recipe_usecases.dart';

/// يدير حالة الوصفات.
class RecipesCubit extends Cubit<RecipesState> {
  RecipesCubit({
    required StoreRepository repository,
    GetRecipesUseCase? getRecipes,
    CreateRecipeUseCase? createRecipe,
    UpdateRecipeUseCase? updateRecipe,
    DeleteRecipeUseCase? deleteRecipe,
  }) : _repository = repository,
       _getRecipes = getRecipes,
       _createRecipe = createRecipe,
       _updateRecipe = updateRecipe,
       _deleteRecipe = deleteRecipe,
       super(const RecipesState());

  final StoreRepository _repository;
  final GetRecipesUseCase? _getRecipes;
  final CreateRecipeUseCase? _createRecipe;
  final UpdateRecipeUseCase? _updateRecipe;
  final DeleteRecipeUseCase? _deleteRecipe;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final recipes = await (_getRecipes?.call() ?? _repository.getRecipes());
      emit(state.copyWith(recipes: recipes, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addRecipe(Recipe recipe) async {
    try {
      if (_createRecipe != null) {
        await _createRecipe(recipe);
      } else {
        await _repository.createRecipe(recipe);
      }
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteRecipe(int id) async {
    try {
      if (_deleteRecipe != null) {
        await _deleteRecipe(id);
      } else {
        await _repository.deleteRecipe(id);
      }
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> updateRecipe(Recipe recipe) async {
    try {
      if (_updateRecipe != null) {
        await _updateRecipe(recipe);
      } else {
        await _repository.updateRecipe(recipe);
      }
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}

class RecipesState {
  const RecipesState({
    this.recipes = const [],
    this.loading = false,
    this.error,
  });

  final List<Recipe> recipes;
  final bool loading;
  final String? error;

  RecipesState copyWith({List<Recipe>? recipes, bool? loading, String? error}) {
    return RecipesState(
      recipes: recipes ?? this.recipes,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

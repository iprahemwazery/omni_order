import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/repositories/store_repository.dart';
import 'categories_state.dart';

/// يدير قائمة تصنيفات الأصناف.
class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit(this._repository)
      : super(const CategoriesState(loading: true));

  final StoreRepository _repository;

  Future<void> init() async {
    emit(const CategoriesState(loading: true));
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final categories = await _repository.getCategories();
      emit(CategoriesState(categories: categories));
    } catch (e) {
      emit(state.copyWith(error: safeErrorMessage('تعذر تحميل التصنيفات', e)));
    }
  }

  Future<String?> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'اكتب اسم التصنيف.';
    final exists = state.categories.any((c) => c.name == trimmed);
    if (exists) return 'هذا التصنيف موجود بالفعل.';
    final id = await _repository.addCategory(Category(name: trimmed));
    emit(state.copyWith(
      categories: [...state.categories, Category(id: id, name: trimmed)],
    ));
    return null;
  }

  Future<void> deleteCategory(Category category) async {
    if (category.id == null) return;
    await _repository.deleteCategory(category.id!);
    emit(state.copyWith(
      categories: state.categories.where((c) => c.id != category.id).toList(),
    ));
  }
}

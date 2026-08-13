import 'package:equatable/equatable.dart';

import '../../../../domain/models/category.dart';

/// حالة شاشة التصنيفات.
class CategoriesState extends Equatable {
  const CategoriesState({
    this.categories = const [],
    this.loading = false,
    this.error,
  });

  final List<Category> categories;
  final bool loading;
  final String? error;

  Category? categoryById(int? id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  CategoriesState copyWith({
    List<Category>? categories,
    bool? loading,
    String? error,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [categories, loading, error];
}

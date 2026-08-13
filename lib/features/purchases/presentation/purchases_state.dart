import 'package:equatable/equatable.dart';

import '../../../../domain/models/purchase.dart';

/// حالة شاشة المشتريات.
class PurchasesState extends Equatable {
  const PurchasesState({
    this.purchases = const [],
    this.loading = false,
    this.error,
  });

  final List<Purchase> purchases;
  final bool loading;
  final String? error;

  PurchasesState copyWith({
    List<Purchase>? purchases,
    bool? loading,
    String? error,
  }) {
    return PurchasesState(
      purchases: purchases ?? this.purchases,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [purchases, loading, error];
}
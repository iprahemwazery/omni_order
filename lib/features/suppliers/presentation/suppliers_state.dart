import 'package:equatable/equatable.dart';

import '../../../../domain/models/supplier.dart';

/// حالة شاشة الموردين.
class SuppliersState extends Equatable {
  const SuppliersState({
    this.suppliers = const [],
    this.loading = false,
    this.error,
  });

  final List<Supplier> suppliers;
  final bool loading;
  final String? error;

  double get totalDebts => suppliers.fold(0.0, (sum, s) => sum + s.balance);

  Supplier? supplierById(int? id) {
    if (id == null) return null;
    for (final supplier in suppliers) {
      if (supplier.id == id) return supplier;
    }
    return null;
  }

  SuppliersState copyWith({
    List<Supplier>? suppliers,
    bool? loading,
    String? error,
  }) {
    return SuppliersState(
      suppliers: suppliers ?? this.suppliers,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [suppliers, loading, error];
}

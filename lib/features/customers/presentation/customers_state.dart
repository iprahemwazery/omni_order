import 'package:equatable/equatable.dart';

import '../../../../domain/models/customer.dart';

/// حالة شاشة العملاء.
class CustomersState extends Equatable {
  const CustomersState({
    this.customers = const [],
    this.loading = false,
    this.error,
  });

  final List<Customer> customers;
  final bool loading;
  final String? error;

  double get totalDebts =>
      customers.fold(0.0, (sum, c) => sum + c.balance);

  Customer? customerById(int? id) {
    if (id == null) return null;
    for (final customer in customers) {
      if (customer.id == id) return customer;
    }
    return null;
  }

  CustomersState copyWith({
    List<Customer>? customers,
    bool? loading,
    String? error,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [customers, loading, error];
}

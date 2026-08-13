import 'package:equatable/equatable.dart';

import '../../../../domain/models/expense.dart';

/// حالة شاشة المصروفات.
class ExpensesState extends Equatable {
  const ExpensesState({
    this.expenses = const [],
    this.loading = false,
    this.error,
  });

  final List<Expense> expenses;
  final bool loading;
  final String? error;

  double expensesOn(DateTime day) => expenses
      .where((e) =>
          e.createdAt.year == day.year &&
          e.createdAt.month == day.month &&
          e.createdAt.day == day.day)
      .fold(0.0, (sum, e) => sum + e.amount);

  double get totalExpenses => expenses.fold(0.0, (sum, e) => sum + e.amount);

  double get monthExpenses {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return expenses
        .where((e) => !e.createdAt.isBefore(monthStart))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  ExpensesState copyWith({
    List<Expense>? expenses,
    bool? loading,
    String? error,
  }) {
    return ExpensesState(
      expenses: expenses ?? this.expenses,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [expenses, loading, error];
}

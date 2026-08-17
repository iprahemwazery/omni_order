import 'package:equatable/equatable.dart';

import '../../../../domain/models/expense.dart';
import '../../../../domain/models/summaries.dart';

/// حالة شاشة المصروفات.
///
/// [expenses] قائمة محدودة لأحدث المصروفات، بينما الأرقام الإجمالية في
/// [totals] محسوبة داخل قاعدة البيانات بـ SQL.
class ExpensesState extends Equatable {
  const ExpensesState({
    this.expenses = const [],
    this.totals = const ExpenseTotals(),
    this.loading = false,
    this.error,
  });

  final List<Expense> expenses;
  final ExpenseTotals totals;
  final bool loading;
  final String? error;

  double get totalExpenses => totals.total;
  double get monthExpenses => totals.month;

  /// مصروفات يوم محدد (تُستخدم لليوم الحالي فقط).
  double expensesOn(DateTime day) => expenses
      .where((e) =>
          e.createdAt.year == day.year &&
          e.createdAt.month == day.month &&
          e.createdAt.day == day.day)
      .fold(0.0, (sum, e) => sum + e.amount);

  ExpensesState copyWith({
    List<Expense>? expenses,
    ExpenseTotals? totals,
    bool? loading,
    String? error,
  }) {
    return ExpensesState(
      expenses: expenses ?? this.expenses,
      totals: totals ?? this.totals,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [expenses, totals, loading, error];
}

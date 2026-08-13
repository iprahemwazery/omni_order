import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/models/expense.dart';
import '../../../../domain/repositories/store_repository.dart';
import 'expenses_state.dart';

/// يدير قائمة المصروفات اليومية.
class ExpensesCubit extends Cubit<ExpensesState> {
  ExpensesCubit(this._repository) : super(const ExpensesState(loading: true));

  final StoreRepository _repository;

  Future<void> init() async {
    emit(const ExpensesState(loading: true));
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final expenses = await _repository.getExpenses();
      emit(ExpensesState(expenses: expenses));
    } catch (e) {
      emit(state.copyWith(error: 'تعذر تحميل المصروفات: $e'));
    }
  }

  Future<String?> addExpense(String name, double amount) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'اكتب سبب المصروف.';
    if (amount <= 0) return 'أدخل مبلغًا أكبر من صفر.';
    final expense = Expense(name: trimmed, amount: amount);
    final id = await _repository.addExpense(expense);
    emit(state.copyWith(
      expenses: [expense.copyWith(id: id), ...state.expenses],
    ));
    return null;
  }

  Future<void> deleteExpense(Expense expense) async {
    if (expense.id == null) return;
    await _repository.deleteExpense(expense.id!);
    emit(state.copyWith(
      expenses: state.expenses.where((e) => e.id != expense.id).toList(),
    ));
  }
}

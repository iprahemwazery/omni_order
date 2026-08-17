import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../../../domain/models/expense.dart';
import '../../../../domain/models/summaries.dart';
import '../../../../domain/repositories/store_repository.dart';
import 'expenses_state.dart';

/// يدير قائمة المصروفات اليومية.
class ExpensesCubit extends Cubit<ExpensesState> {
  ExpensesCubit(this._repository) : super(const ExpensesState(loading: true));

  final StoreRepository _repository;

  /// عدد المصروفات المحمّلة في الذاكرة لشاشة المصروفات.
  static const int historyLimit = 500;

  Future<void> init() async {
    emit(const ExpensesState(loading: true));
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final results = await Future.wait<Object>([
        _repository.getExpenses(limit: historyLimit),
        _repository.getExpenseTotals(),
      ]);
      final expenses = results[0] as List<Expense>;
      final totals = results[1] as ExpenseTotals;
      emit(ExpensesState(expenses: expenses, totals: totals));
    } catch (e) {
      emit(state.copyWith(error: safeErrorMessage('تعذر تحميل المصروفات', e)));
    }
  }

  /// ملخص المصروفات محسوبًا داخل قاعدة البيانات (تُستخدم في التقارير).
  Future<ExpenseTotals> expenseTotals() => _repository.getExpenseTotals();

  /// مصروفات يوم واحد (تقرير اليوم المنفصل).
  Future<List<Expense>> expensesOn(DateTime day) =>
      _repository.getExpensesOn(day);

  Future<String?> addExpense(String name, double amount) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'اكتب سبب المصروف.';
    if (amount <= 0) return 'أدخل مبلغًا أكبر من صفر.';
    final expense = Expense(name: trimmed, amount: amount);
    final id = await _repository.addExpense(expense);
    emit(state.copyWith(
      expenses: [expense.copyWith(id: id), ...state.expenses],
      totals: state.totals.copyWith(
        today: state.totals.today + amount,
        month: state.totals.month + amount,
        total: state.totals.total + amount,
        count: state.totals.count + 1,
      ),
    ));
    return null;
  }

  Future<void> deleteExpense(Expense expense) async {
    if (expense.id == null) return;
    await _repository.deleteExpense(expense.id!);
    emit(state.copyWith(
      expenses: state.expenses.where((e) => e.id != expense.id).toList(),
      totals: state.totals.copyWith(
        today: (state.totals.today - expense.amount).clamp(0, double.infinity),
        month: (state.totals.month - expense.amount).clamp(0, double.infinity),
        total: (state.totals.total - expense.amount).clamp(0, double.infinity),
        count: (state.totals.count - 1).clamp(0, double.infinity).toInt(),
      ),
    ));
  }
}

import '../../../../domain/models/expense.dart';
import '../../../../domain/models/summaries.dart';

abstract interface class ExpensesRepository {
  Future<List<Expense>> getExpenses({int? limit});
  Future<int> addExpense(Expense expense);
  Future<void> deleteExpense(int id);
  Future<ExpenseTotals> getExpenseTotals();
  Future<List<Expense>> getExpensesOn(DateTime day);
}

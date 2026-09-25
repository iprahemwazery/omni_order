import '../../../../domain/models/expense.dart';
import '../../../../domain/models/summaries.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/expenses_repository.dart';

class ExpensesRepositoryImpl implements ExpensesRepository {
  ExpensesRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<Expense>> getExpenses({int? limit}) =>
      _storeRepository.getExpenses(limit: limit);

  @override
  Future<int> addExpense(Expense expense) =>
      _storeRepository.addExpense(expense);

  @override
  Future<void> deleteExpense(int id) => _storeRepository.deleteExpense(id);

  @override
  Future<ExpenseTotals> getExpenseTotals() =>
      _storeRepository.getExpenseTotals();

  @override
  Future<List<Expense>> getExpensesOn(DateTime day) =>
      _storeRepository.getExpensesOn(day);
}

import '../../../../domain/models/expense.dart';
import '../../../../domain/models/summaries.dart';
import '../repositories/expenses_repository.dart';

class GetExpensesUseCase {
  const GetExpensesUseCase(this._repository);

  final ExpensesRepository _repository;

  Future<List<Expense>> call({int? limit}) {
    if (limit != null && limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Must be positive');
    }
    return _repository.getExpenses(limit: limit);
  }
}

class CreateExpenseUseCase {
  const CreateExpenseUseCase(this._repository);

  final ExpensesRepository _repository;

  Future<Expense> call(Expense expense) async {
    if (expense.name.trim().isEmpty) {
      throw ArgumentError.value(expense.name, 'name', 'Cannot be empty');
    }
    if (!expense.amount.isFinite || expense.amount <= 0) {
      throw ArgumentError.value(expense.amount, 'amount', 'Must be positive');
    }

    final id = await _repository.addExpense(
      expense.copyWith(name: expense.name.trim()),
    );
    return expense.copyWith(id: id, name: expense.name.trim());
  }
}

class DeleteExpenseUseCase {
  const DeleteExpenseUseCase(this._repository);

  final ExpensesRepository _repository;

  Future<void> call(int id) {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive');
    return _repository.deleteExpense(id);
  }
}

class GetExpenseTotalsUseCase {
  const GetExpenseTotalsUseCase(this._repository);

  final ExpensesRepository _repository;

  Future<ExpenseTotals> call() => _repository.getExpenseTotals();
}

class GetExpensesOnDateUseCase {
  const GetExpensesOnDateUseCase(this._repository);

  final ExpensesRepository _repository;

  Future<List<Expense>> call(DateTime day) => _repository.getExpensesOn(day);
}

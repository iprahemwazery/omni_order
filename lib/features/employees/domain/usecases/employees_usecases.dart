import '../../../../domain/models/employee.dart';
import '../../../../domain/models/employee_advance.dart';
import '../../../../domain/models/summaries.dart';
import '../repositories/employees_repository.dart';

class GetEmployees {
  const GetEmployees(this._repository);

  final EmployeesRepository _repository;

  Future<List<Employee>> call({
    bool activeOnly = false,
    EmployeeRole? role,
  }) async {
    final employees = activeOnly
        ? await _repository.getActiveEmployees()
        : await _repository.getEmployees();
    if (role == null) return employees;
    return employees
        .where((employee) => employee.role == role)
        .toList(growable: false);
  }
}

class GetDeliveryPersons {
  const GetDeliveryPersons(this._repository);

  final EmployeesRepository _repository;

  Future<List<Employee>> call() => _repository.getDeliveryPersons();
}

class GetEmployee {
  const GetEmployee(this._repository);

  final EmployeesRepository _repository;

  Future<Employee?> call(int employeeId) {
    _requirePositiveId(employeeId);
    return _repository.getEmployee(employeeId);
  }
}

class AddEmployee {
  const AddEmployee(this._repository);

  final EmployeesRepository _repository;

  Future<int> call(Employee employee) {
    _validateEmployee(employee);
    return _repository.addEmployee(
      employee.copyWith(name: employee.name.trim()),
    );
  }
}

class UpdateEmployee {
  const UpdateEmployee(this._repository);

  final EmployeesRepository _repository;

  Future<void> call(Employee employee) {
    _validateEmployee(employee, requireId: true);
    return _repository.updateEmployee(
      employee.copyWith(name: employee.name.trim()),
    );
  }
}

class DeleteEmployee {
  const DeleteEmployee(this._repository);

  final EmployeesRepository _repository;

  Future<void> call(int employeeId) {
    _requirePositiveId(employeeId);
    return _repository.deleteEmployee(employeeId);
  }
}

class ToggleEmployeeActive {
  const ToggleEmployeeActive(this._repository);

  final EmployeesRepository _repository;

  Future<void> call(Employee employee) {
    if (employee.id == null) {
      throw ArgumentError.value(employee.id, 'id', 'is required');
    }
    return _repository.updateEmployee(
      employee.copyWith(isActive: !employee.isActive),
    );
  }
}

class AddEmployeeAdvance {
  const AddEmployeeAdvance(this._repository);

  final EmployeesRepository _repository;

  Future<int> call(EmployeeAdvance advance) {
    _requirePositiveId(advance.employeeId);
    if (!advance.amount.isFinite || advance.amount <= 0) {
      throw ArgumentError.value(
        advance.amount,
        'amount',
        'must be greater than zero',
      );
    }
    return _repository.addEmployeeAdvance(
      advance.copyWith(note: advance.note.trim()),
    );
  }
}

class GetEmployeeAdvances {
  const GetEmployeeAdvances(this._repository);

  final EmployeesRepository _repository;

  Future<List<EmployeeAdvance>> call(int employeeId, {DateTime? date}) {
    _requirePositiveId(employeeId);
    return _repository.getEmployeeAdvances(
      employeeId,
      date: date == null ? null : DateTime(date.year, date.month, date.day),
    );
  }
}

class GetEmployeeDailyReport {
  const GetEmployeeDailyReport(this._repository);

  final EmployeesRepository _repository;

  Future<DailyEmployeeReport> call(int employeeId, DateTime date) {
    _requirePositiveId(employeeId);
    return _repository.getEmployeeDailyReport(
      employeeId,
      DateTime(date.year, date.month, date.day),
    );
  }
}

void _validateEmployee(Employee employee, {bool requireId = false}) {
  if (requireId) _requirePositiveId(employee.id ?? 0);
  if (employee.name.trim().isEmpty) {
    throw ArgumentError.value(employee.name, 'name', 'must not be empty');
  }
  if (!employee.salary.isFinite || employee.salary < 0) {
    throw ArgumentError.value(employee.salary, 'salary', 'is invalid');
  }
}

void _requirePositiveId(int id) {
  if (id <= 0) {
    throw ArgumentError.value(id, 'id', 'must be greater than zero');
  }
}

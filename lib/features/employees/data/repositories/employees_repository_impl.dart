import '../../../../domain/models/employee.dart';
import '../../../../domain/models/employee_advance.dart';
import '../../../../domain/models/summaries.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/employees_repository.dart';

class EmployeesRepositoryImpl implements EmployeesRepository {
  const EmployeesRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<Employee>> getEmployees() => _storeRepository.getEmployees();

  @override
  Future<List<Employee>> getActiveEmployees() =>
      _storeRepository.getActiveEmployees();

  @override
  Future<List<Employee>> getDeliveryPersons() =>
      _storeRepository.getDeliveryPersons();

  @override
  Future<int> addEmployee(Employee employee) =>
      _storeRepository.addEmployee(employee);

  @override
  Future<void> updateEmployee(Employee employee) =>
      _storeRepository.updateEmployee(employee);

  @override
  Future<void> deleteEmployee(int id) => _storeRepository.deleteEmployee(id);

  @override
  Future<Employee?> getEmployee(int id) => _storeRepository.getEmployee(id);

  @override
  Future<int> addEmployeeAdvance(EmployeeAdvance advance) =>
      _storeRepository.addEmployeeAdvance(advance);

  @override
  Future<List<EmployeeAdvance>> getEmployeeAdvances(
    int employeeId, {
    DateTime? date,
  }) {
    return _storeRepository.getEmployeeAdvances(employeeId, date: date);
  }

  @override
  Future<DailyEmployeeReport> getEmployeeDailyReport(
    int employeeId,
    DateTime date,
  ) {
    return _storeRepository.getEmployeeDailyReport(employeeId, date);
  }
}

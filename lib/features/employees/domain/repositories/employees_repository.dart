import '../../../../domain/models/employee.dart';
import '../../../../domain/models/employee_advance.dart';
import '../../../../domain/models/summaries.dart';

abstract interface class EmployeesRepository {
  Future<List<Employee>> getEmployees();

  Future<List<Employee>> getActiveEmployees();

  Future<List<Employee>> getDeliveryPersons();

  Future<int> addEmployee(Employee employee);

  Future<void> updateEmployee(Employee employee);

  Future<void> deleteEmployee(int id);

  Future<Employee?> getEmployee(int id);

  Future<int> addEmployeeAdvance(EmployeeAdvance advance);

  Future<List<EmployeeAdvance>> getEmployeeAdvances(
    int employeeId, {
    DateTime? date,
  });

  Future<DailyEmployeeReport> getEmployeeDailyReport(
    int employeeId,
    DateTime date,
  );
}

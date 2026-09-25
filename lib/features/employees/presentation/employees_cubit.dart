import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/employee.dart';
import '../../../domain/models/employee_advance.dart';
import '../../../domain/models/summaries.dart';
import '../../../domain/repositories/store_repository.dart';
import '../domain/usecases/employees_usecases.dart';

class EmployeesState {
  final List<Employee> employees;
  final bool loading;
  final String? error;

  const EmployeesState({
    this.employees = const [],
    this.loading = false,
    this.error,
  });

  int get activeCount => employees.where((e) => e.isActive).length;

  EmployeesState copyWith({
    List<Employee>? employees,
    bool? loading,
    String? error,
  }) {
    return EmployeesState(
      employees: employees ?? this.employees,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class EmployeesCubit extends Cubit<EmployeesState> {
  EmployeesCubit(
    this._repository, {
    GetEmployees? getEmployees,
    AddEmployee? addEmployee,
    UpdateEmployee? updateEmployee,
    DeleteEmployee? deleteEmployee,
    ToggleEmployeeActive? toggleEmployeeActive,
    AddEmployeeAdvance? addEmployeeAdvance,
    GetEmployeeAdvances? getEmployeeAdvances,
    GetEmployeeDailyReport? getEmployeeDailyReport,
  }) : _getEmployees = getEmployees,
       _addEmployee = addEmployee,
       _updateEmployee = updateEmployee,
       _deleteEmployee = deleteEmployee,
       _toggleEmployeeActive = toggleEmployeeActive,
       _addEmployeeAdvance = addEmployeeAdvance,
       _getEmployeeAdvances = getEmployeeAdvances,
       _getEmployeeDailyReport = getEmployeeDailyReport,
       super(const EmployeesState());

  final StoreRepository _repository;
  final GetEmployees? _getEmployees;
  final AddEmployee? _addEmployee;
  final UpdateEmployee? _updateEmployee;
  final DeleteEmployee? _deleteEmployee;
  final ToggleEmployeeActive? _toggleEmployeeActive;
  final AddEmployeeAdvance? _addEmployeeAdvance;
  final GetEmployeeAdvances? _getEmployeeAdvances;
  final GetEmployeeDailyReport? _getEmployeeDailyReport;

  Future<void> init() async {
    emit(state.copyWith(loading: true));
    try {
      final employees =
          await (_getEmployees?.call() ?? _repository.getEmployees());
      emit(EmployeesState(employees: employees));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'تعذر تحميل الموظفين: $e'));
    }
  }

  Future<String?> addEmployee(Employee employee) async {
    final trimmed = employee.name.trim();
    if (trimmed.isEmpty) return 'اكتب اسم الموظف.';
    final exists = state.employees.any((e) => e.name.trim() == trimmed);
    if (exists) {
      return 'الاسم "$trimmed" موجود بالفعل. أضف اسم الأب أو الجد للتمييز.';
    }
    if (_addEmployee != null) {
      await _addEmployee(employee);
    } else {
      await _repository.addEmployee(employee);
    }
    await init();
    return null;
  }

  Future<String?> updateEmployee(Employee employee) async {
    final trimmed = employee.name.trim();
    if (trimmed.isEmpty) return 'اكتب اسم الموظف.';
    final exists = state.employees.any(
      (e) => e.id != employee.id && e.name.trim() == trimmed,
    );
    if (exists) {
      return 'الاسم "$trimmed" موجود بالفعل. أضف اسم الأب أو الجد للتمييز.';
    }
    if (_updateEmployee != null) {
      await _updateEmployee(employee);
    } else {
      await _repository.updateEmployee(employee);
    }
    await init();
    return null;
  }

  Future<void> deleteEmployee(int id) async {
    if (_deleteEmployee != null) {
      await _deleteEmployee(id);
    } else {
      await _repository.deleteEmployee(id);
    }
    await init();
  }

  Future<void> toggleActive(Employee employee) async {
    if (_toggleEmployeeActive != null) {
      await _toggleEmployeeActive(employee);
    } else {
      await _repository.updateEmployee(
        employee.copyWith(isActive: !employee.isActive),
      );
    }
    await init();
  }

  Future<int> addAdvance(EmployeeAdvance advance) async {
    final id = _addEmployeeAdvance != null
        ? await _addEmployeeAdvance(advance)
        : await _repository.addEmployeeAdvance(advance);
    await init();
    return id;
  }

  Future<List<EmployeeAdvance>> getAdvances(
    int employeeId, {
    DateTime? date,
  }) async {
    return await (_getEmployeeAdvances?.call(employeeId, date: date) ??
        _repository.getEmployeeAdvances(employeeId, date: date));
  }

  Future<DailyEmployeeReport> getDailyReport(
    int employeeId,
    DateTime date,
  ) async {
    return await (_getEmployeeDailyReport?.call(employeeId, date) ??
        _repository.getEmployeeDailyReport(employeeId, date));
  }
}

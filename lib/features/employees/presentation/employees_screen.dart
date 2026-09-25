import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/employee.dart';
import '../../../domain/models/employee_advance.dart';
import '../../../domain/models/admin.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../auth/presentation/auth_cubit.dart';
import 'employees_cubit.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'إدارة الموظفين',
            actions: [
              IconButton(
                onPressed: () => _showAddEmployeeDialog(context),
                icon: const Icon(Icons.person_add_outlined),
                tooltip: 'إضافة موظف',
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<EmployeesCubit, EmployeesState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.employees.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا يوجد موظفين بعد',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'اضغط على + لإضافة موظف جديد',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.employees.length,
                  itemBuilder: (context, index) =>
                      _EmployeeCard(employee: state.employees[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEmployeeDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final salaryController = TextEditingController();
    EmployeeRole selectedRole = EmployeeRole.waiter;
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة موظف جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الموظف'),
                  autofocus: true,
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EmployeeRole>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'الدور'),
                  items: EmployeeRole.values
                      .map(
                        (r) => DropdownMenuItem(value: r, child: Text(r.label)),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: salaryController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الراتب الشهري'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final salary = double.tryParse(salaryController.text) ?? 0;
                final result = await context.read<EmployeesCubit>().addEmployee(
                  Employee(
                    name: name,
                    phone: phoneController.text.trim(),
                    role: selectedRole,
                    salary: salary,
                  ),
                );
                if (result != null) {
                  setDialogState(() => errorText = result);
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee});
  final Employee employee;

  Color get _roleColor {
    switch (employee.role) {
      case EmployeeRole.manager:
        return AppColors.primaryDark;
      case EmployeeRole.cashier:
        return AppColors.primary;
      case EmployeeRole.waiter:
        return AppColors.success;
      case EmployeeRole.chef:
        return AppColors.warning;
      case EmployeeRole.host:
        return AppColors.accent;
      case EmployeeRole.delivery:
        return AppColors.primary;
    }
  }

  IconData get _roleIcon {
    switch (employee.role) {
      case EmployeeRole.manager:
        return Icons.admin_panel_settings_outlined;
      case EmployeeRole.cashier:
        return Icons.point_of_sale;
      case EmployeeRole.waiter:
        return Icons.room_service_outlined;
      case EmployeeRole.chef:
        return Icons.restaurant_outlined;
      case EmployeeRole.host:
        return Icons.waving_hand_outlined;
      case EmployeeRole.delivery:
        return Icons.delivery_dining_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AuthCubit>().state.admin;
    final canManage = admin?.has(UserPermission.manageEmployees) ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _roleColor.withValues(alpha: 0.1),
          child: Icon(_roleIcon, color: _roleColor, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                employee.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (!employee.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'معطّل',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              employee.role.label,
              style: TextStyle(
                color: _roleColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            if (employee.phone.isNotEmpty)
              Text(
                '📱 ${employee.phone}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            if (employee.salary > 0)
              Text(
                'الراتب: ${employee.salary.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: canManage
            ? PopupMenuButton<String>(
                onSelected: (value) async {
                  final cubit = context.read<EmployeesCubit>();
                  if (value == 'toggle') {
                    await cubit.toggleActive(employee);
                  } else if (value == 'edit') {
                    _showEditDialog(context, employee);
                  } else if (value == 'details') {
                    _showEmployeeDetails(context, employee);
                  } else if (value == 'advance') {
                    _showAddAdvanceDialog(context, employee);
                  } else if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dctx) => AlertDialog(
                        title: const Text('حذف الموظف'),
                        content: Text(
                          'هل أنت متأكد من حذف "${employee.name}"؟',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dctx, false),
                            child: const Text('إلغاء'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dctx, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            child: const Text('حذف'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await cubit.deleteEmployee(employee.id!);
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Text('التفاصيل والتقرير'),
                  ),
                  const PopupMenuItem(
                    value: 'advance',
                    child: Text('إضافة سلفة'),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(employee.isActive ? 'تعطيل' : 'تفعيل'),
                  ),
                  const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'حذف',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  void _showEmployeeDetails(BuildContext context, Employee employee) async {
    final cubit = context.read<EmployeesCubit>();
    final report = await cubit.getDailyReport(employee.id!, DateTime.now());
    final advances = await cubit.getAdvances(employee.id!);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تفاصيل ${employee.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'الدور', value: employee.role.label),
                _DetailRow(
                  label: 'الهاتف',
                  value: employee.phone.isNotEmpty
                      ? employee.phone
                      : 'غير محدد',
                ),
                _DetailRow(
                  label: 'الراتب الشهري',
                  value: '${employee.salary.toStringAsFixed(0)} ج.م',
                ),
                const Divider(height: 24),
                const Text(
                  'تقرير اليوم',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'عدد الأوردرات',
                  value: '${report.ordersCount}',
                ),
                _DetailRow(
                  label: 'إجمالي المبيعات',
                  value: AppFormatters.money(report.totalSales),
                ),
                _DetailRow(
                  label: 'السلف المسحوبة',
                  value: AppFormatters.money(report.advancesTaken),
                  valueColor: AppColors.error,
                ),
                _DetailRow(
                  label: 'الخصومات',
                  value: AppFormatters.money(report.deductions),
                  valueColor: AppColors.warning,
                ),
                _DetailRow(
                  label: 'المتبقي من المرتب',
                  value: AppFormatters.money(report.remainingSalary),
                  valueColor: AppColors.success,
                ),
                if (advances.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text(
                    'آخر السلف',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...advances
                      .take(5)
                      .map(
                        (a) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: a.type == AdvanceType.advance
                                ? AppColors.error.withValues(alpha: 0.1)
                                : AppColors.warning.withValues(alpha: 0.1),
                            child: Icon(
                              a.type == AdvanceType.advance
                                  ? Icons.money_off
                                  : Icons.discount,
                              size: 18,
                              color: a.type == AdvanceType.advance
                                  ? AppColors.error
                                  : AppColors.warning,
                            ),
                          ),
                          title: Text(
                            '${a.type.label}: ${AppFormatters.money(a.amount)}',
                          ),
                          subtitle: Text(
                            '${a.createdAt.day}/${a.createdAt.month}/${a.createdAt.year}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showAddAdvanceDialog(BuildContext context, Employee employee) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    AdvanceType type = AdvanceType.advance;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('إضافة سلفة - ${employee.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<AdvanceType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'النوع'),
                items: AdvanceType.values
                    .map(
                      (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => type = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المبلغ'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;
                await context.read<EmployeesCubit>().addAdvance(
                  EmployeeAdvance(
                    employeeId: employee.id!,
                    amount: amount,
                    type: type,
                    note: noteController.text.trim(),
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Employee employee) {
    final nameController = TextEditingController(text: employee.name);
    final phoneController = TextEditingController(text: employee.phone);
    final salaryController = TextEditingController(
      text: employee.salary > 0 ? '${employee.salary}' : '',
    );
    EmployeeRole selectedRole = employee.role;
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('تعديل الموظف'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الموظف'),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EmployeeRole>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'الدور'),
                  items: EmployeeRole.values
                      .map(
                        (r) => DropdownMenuItem(value: r, child: Text(r.label)),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: salaryController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الراتب الشهري'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final salary = double.tryParse(salaryController.text) ?? 0;
                final result = await context
                    .read<EmployeesCubit>()
                    .updateEmployee(
                      employee.copyWith(
                        name: name,
                        phone: phoneController.text.trim(),
                        role: selectedRole,
                        salary: salary,
                      ),
                    );
                if (result != null) {
                  setDialogState(() => errorText = result);
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, color: valueColor),
          ),
        ],
      ),
    );
  }
}

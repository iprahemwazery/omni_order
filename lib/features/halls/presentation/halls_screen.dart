import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/hall.dart';
import '../../../domain/models/summaries.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../../domain/models/admin.dart';
import 'halls_cubit.dart';

class HallsScreen extends StatelessWidget {
  const HallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'إدارة الصالات',
            actions: [
              IconButton(
                onPressed: () => _showAddHallDialog(context),
                icon: const Icon(Icons.add),
                tooltip: 'إضافة صالة',
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<HallsCubit, HallsState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.halls.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.room_service_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد صالات بعد',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'اضغط + لإضافة صالة جديدة',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.halls.length,
                  itemBuilder: (context, index) =>
                      _HallCard(hall: state.halls[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddHallDialog(BuildContext context) {
    final nameController = TextEditingController();
    final capacityController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة صالة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم الصالة'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'السعة (عدد الترابيزات)',
                hintText: '0 = غير محدد',
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
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final capacity = int.tryParse(capacityController.text) ?? 0;
              await context.read<HallsCubit>().addHall(
                name,
                capacity: capacity,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

class _HallCard extends StatelessWidget {
  const _HallCard({required this.hall});
  final Hall hall;

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AuthCubit>().state.admin;
    final canManage = admin?.has(UserPermission.manageHalls) ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hall.isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.textSecondary.withValues(alpha: 0.1),
          child: Icon(
            Icons.room_service_outlined,
            color: hall.isActive ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        title: Text(
          hall.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          hall.capacity > 0
              ? 'السعة: ${hall.capacity} تريبية'
              : 'بدون سعة محددة',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: canManage
            ? PopupMenuButton<String>(
                onSelected: (value) async {
                  final cubit = context.read<HallsCubit>();
                  if (value == 'toggle') {
                    await cubit.toggleActive(hall);
                  } else if (value == 'edit') {
                    _showEditDialog(context, hall);
                  } else if (value == 'report') {
                    _showDailyReport(context, hall);
                  } else if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('حذف الصالة'),
                        content: Text(
                          'هل أنت متأكد من حذف "${hall.name}"؟\nسيتم حذف جميع الترابيزات المرتبطة بها.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('إلغاء'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            child: const Text('حذف'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await cubit.deleteHall(hall.id!);
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(hall.isActive ? 'تعطيل' : 'تفعيل'),
                  ),
                  const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                  const PopupMenuItem(
                    value: 'report',
                    child: Text('تقرير يومي'),
                  ),
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

  void _showDailyReport(BuildContext context, Hall hall) async {
    final cubit = context.read<HallsCubit>();
    final report = await cubit.getHallDailyReport(hall.id!, DateTime.now());
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تقرير ${hall.name} - اليوم'),
        content: _HallReportContent(report: report),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Hall hall) {
    final nameController = TextEditingController(text: hall.name);
    final capacityController = TextEditingController(
      text: hall.capacity > 0 ? '${hall.capacity}' : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الصالة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم الصالة'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'السعة'),
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
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final capacity = int.tryParse(capacityController.text) ?? 0;
              await context.read<HallsCubit>().updateHall(
                hall.copyWith(name: name, capacity: capacity),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _HallReportContent extends StatelessWidget {
  const _HallReportContent({required this.report});
  final HallDailyReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ReportRow(
          icon: Icons.receipt_long,
          label: 'عدد الطلبات',
          value: '${report.ordersCount}',
        ),
        const SizedBox(height: 12),
        _ReportRow(
          icon: Icons.attach_money,
          label: 'إجمالي الإيرادات',
          value: AppFormatters.money(report.totalRevenue),
          valueColor: AppColors.success,
        ),
        const SizedBox(height: 12),
        _ReportRow(
          icon: Icons.pending_actions,
          label: 'طلبات نشطة',
          value: '${report.activeOrdersCount}',
          valueColor: AppColors.warning,
        ),
        const SizedBox(height: 12),
        _ReportRow(
          icon: Icons.table_restaurant_outlined,
          label: 'الترابيزات',
          value: '${report.occupiedTablesCount} / ${report.tablesCount} مشغولة',
        ),
      ],
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

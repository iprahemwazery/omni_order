import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/queue_entry.dart';
import '../../../domain/repositories/store_repository.dart';
import '../../../shared/widgets/screen_header.dart';
import 'queue_cubit.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QueueCubit?>();
    if (cubit != null) {
      return BlocProvider.value(value: cubit, child: const _QueueView());
    }
    return BlocProvider(
      create: (_) =>
          QueueCubit(repository: context.read<StoreRepository>())..load(),
      child: const _QueueView(),
    );
  }
}

class _QueueView extends StatelessWidget {
  const _QueueView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'قائمة الانتظار',
            actions: [
              IconButton(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.person_add_outlined),
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<QueueCubit, QueueState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.queue_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'قائمة الانتظار فارغة',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Row(
                  children: [
                    // Waiting
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: AppColors.warning.withValues(alpha: 0.08),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.hourglass_empty,
                                  color: AppColors.warning,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ينتظر (${state.waiting.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: state.waiting.isEmpty
                                ? const Center(
                                    child: Text('لا أحد في الانتظار'),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(12),
                                    itemCount: state.waiting.length,
                                    itemBuilder: (context, idx) =>
                                        _QueueCard(entry: state.waiting[idx]),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    // Seating
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: AppColors.success.withValues(alpha: 0.08),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: AppColors.success,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'يجلس (${state.seating.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: state.seating.isEmpty
                                ? const Center(child: Text('لا أحد يجلس الآن'))
                                : ListView.builder(
                                    padding: const EdgeInsets.all(12),
                                    itemCount: state.seating.length,
                                    itemBuilder: (context, idx) =>
                                        _QueueCard(entry: state.seating[idx]),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _showAddDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final sizeCtrl = TextEditingController(text: '2');
    final noteCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة لقائمة الانتظار'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم العميل *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: sizeCtrl,
                decoration: const InputDecoration(labelText: 'عدد الأشخاص *'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              context.read<QueueCubit>().addEntry(
                QueueEntry(
                  customerName: nameCtrl.text.trim(),
                  customerPhone: phoneCtrl.text.trim(),
                  partySize: int.tryParse(sizeCtrl.text) ?? 2,
                  note: noteCtrl.text.trim(),
                ),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.entry});
  final QueueEntry entry;

  @override
  Widget build(BuildContext context) {
    final waitingMinutes = DateTime.now().difference(entry.createdAt).inMinutes;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: entry.status == QueueStatus.waiting
              ? AppColors.warning.withValues(alpha: 0.12)
              : AppColors.success.withValues(alpha: 0.12),
          child: Text(
            '${entry.partySize}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: entry.status == QueueStatus.waiting
                  ? AppColors.warning
                  : AppColors.success,
            ),
          ),
        ),
        title: Text(entry.customerName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.customerPhone.isNotEmpty)
              Text(entry.customerPhone, style: const TextStyle(fontSize: 12)),
            Text(
              'انتظر $waitingMinutes دقيقة',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.status == QueueStatus.waiting)
              IconButton(
                onPressed: () => context.read<QueueCubit>().updateStatus(
                  entry.id!,
                  QueueStatus.seating,
                ),
                icon: const Icon(Icons.check, color: AppColors.success),
                tooltip: 'يجلس',
              ),
            IconButton(
              onPressed: () => context.read<QueueCubit>().updateStatus(
                entry.id!,
                QueueStatus.done,
              ),
              icon: const Icon(Icons.done_all, color: AppColors.primary),
              tooltip: 'تم',
            ),
            IconButton(
              onPressed: () =>
                  context.read<QueueCubit>().deleteEntry(entry.id!),
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'حذف',
            ),
          ],
        ),
      ),
    );
  }
}

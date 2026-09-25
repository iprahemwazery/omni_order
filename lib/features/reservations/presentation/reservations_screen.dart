import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/reservation.dart';
import '../../../domain/models/restaurant_table.dart';
import '../../../domain/repositories/store_repository.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../tables/domain/usecases/tables_usecases.dart';
import 'reservations_cubit.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReservationsCubit?>();
    if (cubit != null) {
      return BlocProvider.value(value: cubit, child: const _ReservationsView());
    }
    return BlocProvider(
      create: (_) =>
          ReservationsCubit(repository: context.read<StoreRepository>())
            ..load(),
      child: const _ReservationsView(),
    );
  }
}

class _ReservationsView extends StatelessWidget {
  const _ReservationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'الحجوزات',
            actions: [
              IconButton(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<ReservationsCubit, ReservationsState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.reservations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد حجوزات',
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
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (state.active.isNotEmpty) ...[
                      const Text(
                        'حجوزات م confirms',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...state.active.map(
                        (r) => _ReservationCard(reservation: r),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (state.seated.isNotEmpty) ...[
                      const Text(
                        'جالسون الآن',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...state.seated.map(
                        (r) => _ReservationCard(reservation: r),
                      ),
                    ],
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
    final getTables = context.read<GetTables?>();
    final repository = context.read<StoreRepository>();
    final tables = getTables == null
        ? await repository.getTables()
        : await getTables();
    if (!context.mounted) return;

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final sizeCtrl = TextEditingController(text: '2');
    final noteCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    RestaurantTable? selectedTable;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('حجز جديد'),
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
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('التاريخ والوقت'),
                  subtitle: Text(
                    '${AppFormatters.date(selectedDate)} ${selectedTime.format(context)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                    if (!ctx.mounted) return;
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<RestaurantTable>(
                  initialValue: selectedTable,
                  decoration: const InputDecoration(labelText: 'التريبية *'),
                  items: tables
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            'تريبية ${t.number} (${t.capacity} أشخاص)',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedTable = val),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'ملاحظات'),
                  maxLines: 2,
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
                if (nameCtrl.text.trim().isEmpty || selectedTable == null) {
                  return;
                }
                final size = int.tryParse(sizeCtrl.text) ?? 2;
                final dateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                context.read<ReservationsCubit>().addReservation(
                  Reservation(
                    tableId: selectedTable!.id!,
                    tableNumber: selectedTable!.number,
                    customerName: nameCtrl.text.trim(),
                    customerPhone: phoneCtrl.text.trim(),
                    partySize: size,
                    reservationTime: dateTime,
                    note: noteCtrl.text.trim(),
                  ),
                );
                Navigator.of(ctx).pop();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.reservation});
  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (reservation.status) {
      ReservationStatus.confirmed => AppColors.primary,
      ReservationStatus.seated => AppColors.success,
      ReservationStatus.cancelled => AppColors.error,
      ReservationStatus.completed => AppColors.textSecondary,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Icon(Icons.event, color: statusColor, size: 20),
        ),
        title: Text(reservation.customerName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تريبية ${reservation.tableNumber} • ${reservation.partySize} أشخاص',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              AppFormatters.dateTime(reservation.reservationTime),
              style: const TextStyle(fontSize: 11),
            ),
            if (reservation.note.isNotEmpty)
              Text(reservation.note, style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: PopupMenuButton<ReservationStatus>(
          icon: Chip(
            label: Text(reservation.status.label),
            backgroundColor: statusColor.withValues(alpha: 0.12),
            labelStyle: TextStyle(color: statusColor, fontSize: 11),
            padding: EdgeInsets.zero,
          ),
          onSelected: (status) {
            context.read<ReservationsCubit>().updateStatus(
              reservation.id!,
              status,
            );
          },
          itemBuilder: (_) => ReservationStatus.values
              .where((s) => s != reservation.status)
              .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
              .toList(),
        ),
      ),
    );
  }
}

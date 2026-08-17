import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/payment_methods.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/shift.dart';
import '../../../domain/repositories/store_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../settings/presentation/settings_cubit.dart';
import 'shift_cubit.dart';
import 'shift_state.dart';
import 'widgets/shift_pdf_exporter.dart';

/// تقرير الوردية (Z-Report): ملخص مبيعات الكاشير للوردية الحالية،
/// مع إمكانية إغلاق الوردية وطباعة التقرير.
class ShiftScreen extends StatelessWidget {
  const ShiftScreen({super.key});

  String _cashierName(BuildContext context) =>
      context.read<AuthCubit>().state.admin?.username ?? '';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ShiftCubit(context.read<StoreRepository>())..init(_cashierName(context)),
      child: const _ShiftScreenBody(),
    );
  }
}

class _ShiftScreenBody extends StatelessWidget {
  const _ShiftScreenBody();

  @override
  Widget build(BuildContext context) {
    final cashierName =
        context.read<AuthCubit>().state.admin?.username ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الوردية (Z-Report)'),
        actions: [
          BlocBuilder<ShiftCubit, ShiftState>(
            builder: (context, state) {
              if (state.report == null) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'طباعة التقرير',
                onPressed: () => _exportPdf(context, state.report!),
                icon: const Icon(Icons.print_outlined),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<ShiftCubit, ShiftState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(
                child: Text(
                  state.error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              );
            }
            if (state.shift == null || state.report == null) {
              return _NoShiftView(
                onStart: () async {
                  final error = await context
                      .read<ShiftCubit>()
                      .startShift(cashierName);
                  if (error != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                  }
                },
              );
            }
            return _ReportView(
              report: state.report!,
              onClose: () => _confirmClose(context),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmClose(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إغلاق الوردية'),
        content: const Text('هل أنت متأكد من إغلاق الوردية؟ بعد الإغلاق لن '
            'تتضمن عمليات البيع الجديدة هذا التقرير.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إغلاق الوردية'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<ShiftCubit>();
    final error = await cubit.closeShift();
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('تم إغلاق الوردية بنجاح.')),
      );
    }
  }

  Future<void> _exportPdf(BuildContext context, ShiftReport report) async {
    final messenger = ScaffoldMessenger.of(context);
    final settings = context.read<SettingsCubit>().state.settings;
    final cashierName = report.shift.cashierName.isEmpty
        ? 'cashier'
        : report.shift.cashierName;
    final fileName =
        'shift_report_${cashierName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    messenger.showSnackBar(const SnackBar(content: Text('جارٍ إنشاء التقرير...')));
    try {
      final bytes = await ShiftPdfExporter.buildReport(
        report: report,
        settings: settings,
      );
      final location = await ShiftPdfExporter.saveToDownloads(bytes, fileName);
      await ShiftPdfExporter.openPdf(bytes, fileName);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            location == null
                ? 'تم إنشاء التقرير'
                : 'تم حفظ التقرير في $location',
          ),
        ),
      );
    } catch (_) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('تعذر إنشاء التقرير.')),
      );
    }
  }
}

class _NoShiftView extends StatelessWidget {
  const _NoShiftView({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EmptyState(
            icon: Icons.event_note_outlined,
            title: 'لا توجد وردية',
            subtitle: 'تبدأ الوردية تلقائيًا مع أول عملية بيع، '
                'أو ابدأها الآن يدويًا',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow),
            label: const Text('بدء الوردية الآن'),
          ),
        ],
      ),
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView({required this.report, required this.onClose});

  final ShiftReport report;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final shift = report.shift;
    final currency = context.read<SettingsCubit>().state.settings.currency;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'الكاشير: ${shift.cashierName.isEmpty ? 'غير معروف' : shift.cashierName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: shift.isOpen
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      shift.isOpen ? 'وردية مفتوحة' : 'مغلقة',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'البداية: ${AppFormatters.date(shift.openedAt)} • '
                '${AppFormatters.time(shift.openedAt)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (!shift.isOpen && shift.closedAt != null)
                Text(
                  'النهاية: ${AppFormatters.date(shift.closedAt!)} • '
                  '${AppFormatters.time(shift.closedAt!)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              const SizedBox(height: 16),
              Text(
                AppFormatters.money(report.totalSales, currency),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'إجمالي مبيعات الوردية',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.9,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          children: [
            _Stat(
              label: 'عدد الفواتير',
              value: '${report.salesCount}',
              icon: Icons.receipt_long_outlined,
              color: AppColors.primary,
            ),
            _Stat(
              label: 'مرتجعات',
              value: '${report.refundCount}',
              icon: Icons.assignment_return_outlined,
              color: AppColors.error,
            ),
            _Stat(
              label: 'نقد في الصندوق',
              value: AppFormatters.money(report.cashReceived, currency),
              icon: Icons.payments_outlined,
              color: AppColors.success,
            ),
            _Stat(
              label: 'محصلات الشبكة',
              value: AppFormatters.money(report.cardReceived, currency),
              icon: Icons.credit_card,
              color: AppColors.accent,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _breakdownRow(context, PaymentMethod.cash, report.cashTotal, currency),
              _breakdownRow(context, PaymentMethod.card, report.cardTotal, currency),
              _breakdownRow(context, PaymentMethod.wallet, report.walletTotal, currency),
              _breakdownRow(
                context,
                PaymentMethod.bankTransfer,
                report.transferTotal,
                currency,
              ),
              if (report.mixedTotal > 0) ...[
                _breakdownRow(
                  context,
                  'مختلط (نقدًا)',
                  report.mixedCashPortion,
                  currency,
                ),
                _breakdownRow(
                  context,
                  'مختلط (بالشبكة)',
                  report.mixedCardPortion,
                  currency,
                ),
              ],
              _breakdownRow(
                context,
                'آجل (دين)',
                report.deferredTotal,
                currency,
              ),
              const Divider(height: 20),
              _breakdownRow(
                context,
                'الباقي المُصرف',
                report.changeGiven,
                currency,
                color: AppColors.error,
              ),
              if (report.refundCount > 0)
                _breakdownRow(
                  context,
                  'مرتجعات (${report.refundCount})',
                  report.refundsTotal,
                  currency,
                  color: AppColors.error,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (shift.isOpen)
          FilledButton.icon(
            onPressed: onClose,
            icon: const Icon(Icons.lock_outline),
            label: const Text('إغلاق الوردية'),
          )
        else
          Center(
            child: Text(
              'تم إغلاق هذه الوردية',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ),
      ],
    );
  }

  Widget _breakdownRow(
    BuildContext context,
    String label,
    double amount,
    String currency, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          Text(
            AppFormatters.money(amount, currency),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

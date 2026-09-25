import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/payment_methods.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/sale.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../settings/presentation/settings_cubit.dart';
import 'receipt_screen.dart';
import 'sales_cubit.dart';

/// شاشة الفواتير الآجلة (المديونيات): عرض وسداد الفواتير غير المسددة.
class DeferredSalesScreen extends StatefulWidget {
  const DeferredSalesScreen({super.key});

  @override
  State<DeferredSalesScreen> createState() => _DeferredSalesScreenState();
}

class _DeferredSalesScreenState extends State<DeferredSalesScreen> {
  late Future<List<Sale>> _deferredFuture;

  @override
  void initState() {
    super.initState();
    _deferredFuture = context.read<SalesCubit>().getDeferredSales();
  }

  Future<void> _refresh() async {
    setState(() {
      _deferredFuture = context.read<SalesCubit>().getDeferredSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'الفواتير الآجلة',
            actions: [
              IconButton(
                onPressed: _refresh,
                tooltip: 'تحديث',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: SafeArea(
              top: false,
              child: FutureBuilder<List<Sale>>(
                future: _deferredFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final sales = snapshot.data ?? [];
                  if (sales.isEmpty) {
                    return const EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'لا توجد فواتير آجلة',
                      subtitle: 'جميع الفواتير مسددة',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: sales.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _DeferredSaleTile(sale: sales[index], onPaid: _refresh),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeferredSaleTile extends StatelessWidget {
  const _DeferredSaleTile({required this.sale, required this.onPaid});

  final Sale sale;
  final VoidCallback onPaid;

  @override
  Widget build(BuildContext context) {
    final currency = context.read<SettingsCubit>().state.settings.currency;

    final String typeLabel;
    final IconData typeIcon;
    final Color typeColor;
    switch (sale.orderType) {
      case 'صاله':
        typeLabel = 'صاله - تريبية ${sale.tableName}';
        typeIcon = Icons.restaurant_outlined;
        typeColor = Colors.teal;
      case 'دلفري':
        typeLabel = 'دلفري - ${sale.customerName}';
        typeIcon = Icons.delivery_dining_outlined;
        typeColor = Colors.orange;
      default:
        typeLabel = 'عميل عادي';
        typeIcon = Icons.person_outline;
        typeColor = AppColors.primary;
    }

    return Card(
      child: ListTile(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => ReceiptScreen(sale: sale))),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(typeIcon, color: AppColors.error, size: 26),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                AppFormatters.invoiceNumber(sale.id ?? 0),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'دين',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              typeLabel,
              style: TextStyle(
                color: typeColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${AppFormatters.dateTime(sale.createdAt)} • ${sale.itemsCount} أصناف',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: FilledButton.tonal(
          onPressed: () => _showPayDialog(context),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.success.withValues(alpha: 0.12),
            foregroundColor: AppColors.success,
          ),
          child: Text(
            AppFormatters.money(sale.total, currency),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
      ),
    );
  }

  void _showPayDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PaySettlementSheet(
        sale: sale,
        onPaid: () {
          onPaid();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _PaySettlementSheet extends StatefulWidget {
  const _PaySettlementSheet({required this.sale, required this.onPaid});

  final Sale sale;
  final VoidCallback onPaid;

  @override
  State<_PaySettlementSheet> createState() => _PaySettlementSheetState();
}

class _PaySettlementSheetState extends State<_PaySettlementSheet> {
  String _paymentMethod = PaymentMethod.cash;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final currency = context.read<SettingsCubit>().state.settings.currency;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'سداد فاتورة آجلة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(
                  'الفاتورة',
                  AppFormatters.invoiceNumber(widget.sale.id ?? 0),
                ),
                const SizedBox(height: 6),
                _infoRow('النوع', widget.sale.orderTypeLabel),
                if (widget.sale.tableName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _infoRow('التريبية', widget.sale.tableName),
                ],
                if (widget.sale.customerName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _infoRow('العميل', widget.sale.customerName),
                ],
                const Divider(height: 20),
                _infoRow(
                  'المبلغ المطلوب',
                  AppFormatters.money(widget.sale.total, currency),
                  highlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'طريقة السداد',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final method in PaymentMethod.settleMethods)
                ChoiceChip(
                  label: Text(method),
                  selected: _paymentMethod == method,
                  onSelected: (_) => setState(() => _paymentMethod = method),
                  selectedColor: AppColors.success,
                  labelStyle: TextStyle(
                    color: _paymentMethod == method
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _confirm,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_saving ? 'جارٍ السداد...' : 'تأكيد السداد'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
            fontSize: highlight ? 18 : 14,
            color: highlight ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final error = await context.read<SalesCubit>().settleSale(
      sale: widget.sale,
      paymentMethod: _paymentMethod,
      amountTendered: widget.sale.total,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم سداد الفاتورة بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onPaid();
    }
  }
}

extension on Sale {
  String get orderTypeLabel {
    switch (orderType) {
      case 'صاله':
        return 'صاله';
      case 'دلفري':
        return 'دلفري';
      default:
        return 'عميل عادي';
    }
  }
}

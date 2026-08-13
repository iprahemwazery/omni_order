import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/admin.dart';
import '../../../domain/models/sale.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../customers/presentation/customers_cubit.dart';
import '../../products/presentation/products_cubit.dart';
import '../../settings/presentation/settings_cubit.dart';
import 'receipt_screen.dart';
import 'sales_cubit.dart';

/// شاشة سجل المبيعات: الفواتير السابقة للرجوع إليها.
class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesCubit>().state.sales;

    return Scaffold(
      appBar: AppBar(title: const Text('المبيعات السابقة')),
      body: SafeArea(
        child: sales.isEmpty
            ? const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'لا توجد مبيعات بعد',
                subtitle: 'ابدأ ببيع الأصناف وستظهر الفواتير هنا',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sales.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final sale = sales[index];
                  return _SaleTile(sale: sale);
                },
              ),
      ),
    );
  }
}

class _SaleTile extends StatelessWidget {
  const _SaleTile({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final currency = context.read<SettingsCubit>().state.settings.currency;
    final canRefund =
        context.read<AuthCubit>().state.admin?.has(UserPermission.manageProducts) ??
            false;

    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ReceiptScreen(sale: sale)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: sale.refunded
                ? const Color(0xFFFBE9E9)
                : const Color(0xFFE8F1EF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            sale.refunded ? Icons.replay : Icons.receipt_long,
            color: sale.refunded ? AppColors.error : AppColors.primary,
          ),
        ),
        title: Text(
          '${AppFormatters.invoiceNumber(sale.id ?? 0)}'
          '${sale.refunded ? ' (مرتجع)' : ''}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: sale.refunded ? AppColors.textSecondary : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${AppFormatters.dateTime(sale.createdAt)} • ${sale.itemsCount} أصناف',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canRefund && !sale.refunded)
              IconButton(
                onPressed: () => _confirmRefund(context),
                tooltip: 'مرتجع',
                icon: const Icon(Icons.replay_outlined, color: AppColors.error),
              ),
            Text(
              AppFormatters.money(sale.total, currency),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: sale.refunded ? AppColors.textSecondary : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRefund(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل مرتجع؟'),
        content: const Text(
          'سيُعاد المبلغ إلى المخزون، وتُستبعد الفاتورة من الإيرادات.\n'
          'لا يمكن التراجع عن هذه العملية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('تسجيل المرتجع'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await context.read<SalesCubit>().refundSale(sale);
    if (!context.mounted) return;
    await Future.wait([
      context.read<ProductsCubit>().refresh(),
      context.read<CustomersCubit>().refresh(),
    ]);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'تم تسجيل المرتجع وإعادة البضاعة للمخزون'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/purchase.dart';
import '../../../domain/models/supplier.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../purchases/presentation/purchases_cubit.dart';
import '../../settings/presentation/settings_cubit.dart';
import 'supplier_details_screen.dart';
import 'suppliers_cubit.dart';

/// شاشة الموردين: إدارة الموردين والديون والتسديدات.
class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SuppliersCubit>().state;
    final totalDebts = state.totalDebts;
    final purchases = context.watch<PurchasesCubit>().state.purchases;
    final largestSupplier = state.suppliers.isEmpty
        ? null
        : state.suppliers.reduce((a, b) => a.balance >= b.balance ? a : b);
    final bestPurchase = purchases.isEmpty
        ? null
        : purchases.reduce((a, b) => a.total >= b.total ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الموردين'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Center(
              child: totalDebts > 0
                  ? Text(
                      'مستحقات: ${AppFormatters.money(totalDebts)}',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : const Text(
                      'لا توجد مستحقات',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSupplier(context),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('إضافة مورد'),
      ),
      body: SafeArea(
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                children: [
                  if (state.suppliers.isNotEmpty) ...[
                    _SupplierReportCard(
                      totalDebts: totalDebts,
                      largestSupplier: largestSupplier,
                      bestPurchase: bestPurchase,
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (state.suppliers.isEmpty)
                    const EmptyState(
                      icon: Icons.local_shipping_outlined,
                      title: 'لا يوجد موردين',
                      subtitle: 'أضف موردين لتتبع المشتريات والمديونيات',
                    )
                  else ...[
                    for (final supplier in state.suppliers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SupplierTile(supplier: supplier),
                      ),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _addSupplier(BuildContext context) async {
    final result =
        await showDialog<({String name, String phone, String address})>(
          context: context,
          builder: (context) {
            final name = TextEditingController();
            final phone = TextEditingController();
            final address = TextEditingController();
            return AlertDialog(
              title: const Text('إضافة مورد'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'اسم المورد *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف (اختياري)',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: address,
                    decoration: const InputDecoration(
                      labelText: 'العنوان (اختياري)',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop((
                    name: name.text,
                    phone: phone.text,
                    address: address.text,
                  )),
                  child: const Text('إضافة'),
                ),
              ],
            );
          },
        );

    if (result == null || !context.mounted) return;
    final error = await context.read<SuppliersCubit>().addSupplier(
      result.name,
      phone: result.phone,
      address: result.address,
    );
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _SupplierReportCard extends StatelessWidget {
  const _SupplierReportCard({
    required this.totalDebts,
    required this.largestSupplier,
    required this.bestPurchase,
  });

  final double totalDebts;
  final Supplier? largestSupplier;
  final Purchase? bestPurchase;

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsCubit>().state.settings.currency;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تقارير الموردين',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _ReportRow(
            label: 'إجمالي المديونية',
            value: AppFormatters.money(totalDebts, currency),
            color: AppColors.error,
          ),
          _ReportRow(
            label: 'أكبر مورد',
            value: largestSupplier == null
                ? '—'
                : '${largestSupplier!.name} • ${AppFormatters.money(largestSupplier!.balance, currency)}',
            color: AppColors.primary,
          ),
          _ReportRow(
            label: 'أفضل شراء',
            value: bestPurchase == null
                ? '—'
                : '${AppFormatters.money(bestPurchase!.total, currency)} • ${bestPurchase!.supplierName.isEmpty ? 'غير محدد' : bestPurchase!.supplierName}',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierTile extends StatelessWidget {
  const _SupplierTile({required this.supplier});

  final Supplier supplier;

  @override
  Widget build(BuildContext context) {
    final hasDebt = supplier.balance > 0;
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SupplierDetailsScreen(supplierId: supplier.id),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: hasDebt ? const Color(0xFFFBE9E9) : const Color(0xFFE8F1EF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.local_shipping_outlined,
            color: hasDebt ? AppColors.error : AppColors.primary,
          ),
        ),
        title: Text(
          supplier.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (supplier.phone.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                supplier.phone,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            if (supplier.address.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                supplier.address,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              hasDebt
                  ? 'مستحق: ${AppFormatters.money(supplier.balance)}'
                  : 'لا توجد مستحقات',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: hasDebt ? AppColors.error : AppColors.success,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') _confirmDelete(context);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المورد؟'),
        content: Text('هل أنت متأكد من حذف "${supplier.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<SuppliersCubit>().deleteSupplier(supplier);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تم حذف "${supplier.name}"')));
      }
    }
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/purchase.dart';
import '../../../domain/models/supplier.dart';
import '../../../domain/models/supplier_payment.dart';
import '../../purchases/presentation/purchase_form_screen.dart';
import '../../purchases/presentation/purchases_cubit.dart';
import '../../settings/presentation/settings_cubit.dart';
import 'suppliers_cubit.dart';

class SupplierDetailsScreen extends StatelessWidget {
  const SupplierDetailsScreen({super.key, required this.supplierId});

  final int? supplierId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SuppliersCubit>().state;
    final supplier = state.supplierById(supplierId);

    if (supplier == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('المورد')),
        body: const Center(child: Text('المورد غير موجود.')),
      );
    }

    final currency = context.watch<SettingsCubit>().state.settings.currency;
    final purchases = context
        .watch<PurchasesCubit>()
        .state
        .purchases
        .where((purchase) {
          if (purchase.supplierId != null) {
            return purchase.supplierId == supplier.id;
          }
          return purchase.supplierName.trim().toLowerCase() ==
              supplier.name.trim().toLowerCase();
        })
        .toList();
    final totalPurchases = purchases.fold(0.0, (sum, item) => sum + item.total);
    final totalPaid = purchases.fold(0.0, (sum, item) => sum + item.paidAmount);
    final accumulatedDebt = purchases.fold(
      0.0,
      (sum, item) => sum + item.remainingBalance,
    );
    final hasDebt = supplier.balance > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المورد')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PurchaseFormScreen(supplierName: supplier.name),
          ),
        ),
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text('إضافة فاتورة شراء'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(
              supplier: supplier,
              currency: currency,
              hasDebt: hasDebt,
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              totalPurchases: totalPurchases,
              totalPaid: totalPaid,
              accumulatedDebt: accumulatedDebt,
              balance: supplier.balance,
              currency: currency,
            ),
            const SizedBox(height: 16),
            if (hasDebt)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE9E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.26),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'الإجمالي المتراكم المتبقي للمورد: ${AppFormatters.money(accumulatedDebt, currency)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'فواتير الشراء الخاصة بهذا المورد',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _exportSupplierInvoices(
                    context,
                    supplier,
                    purchases,
                    currency,
                  ),
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('تصدير الكل'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (purchases.isEmpty)
              const _EmptyPurchases()
            else
              ...purchases.map(
                (purchase) => _PurchaseInvoiceTile(
                  purchase: purchase,
                  currency: currency,
                  onRecordPayment: purchase.remainingBalance > 0
                      ? () => _recordPayment(
                          context,
                          supplier,
                          purchase: purchase,
                        )
                      : null,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'سجل التسديدات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  hasDebt
                      ? 'مستحق: ${AppFormatters.money(supplier.balance, currency)}'
                      : 'لا توجد مديونية',
                  style: TextStyle(
                    color: hasDebt ? AppColors.error : AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<SupplierPayment>>(
              future: context.read<SuppliersCubit>().paymentsOf(supplier),
              builder: (context, snapshot) {
                final payments = snapshot.data ?? const [];
                if (payments.isEmpty) {
                  return const _EmptyPayments();
                }
                return Column(
                  children: [
                    for (final payment in payments)
                      _PaymentTile(
                        payment: payment,
                        currency: currency,
                        invoiceDate: _invoiceDateOf(
                          payment.purchaseId,
                          purchases,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            if (hasDebt) ...[
              FilledButton.icon(
                onPressed: () => _recordPayment(context, supplier),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('تسوية كامل الحساب'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  DateTime? _invoiceDateOf(int? purchaseId, List<Purchase> purchases) {
    if (purchaseId == null) return null;
    for (final purchase in purchases) {
      if (purchase.id == purchaseId) return purchase.createdAt;
    }
    return null;
  }

  Future<void> _recordPayment(
    BuildContext context,
    Supplier supplier, {
    Purchase? purchase,
  }) async {
    final controller = TextEditingController();
    final maxAmount = purchase?.remainingBalance ?? supplier.balance;
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(purchase == null ? 'تسجيل سداد للمورد' : 'سداد فاتورة شراء'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              purchase == null
                  ? 'المديونية الحالية: ${AppFormatters.money(supplier.balance)}'
                  : 'المتبقي على هذه الفاتورة: ${AppFormatters.money(maxAmount)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(hintText: 'المبلغ المسدد'),
              onSubmitted: (_) => Navigator.of(
                dialogContext,
              ).pop(double.tryParse(controller.text)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(double.tryParse(controller.text)),
            child: const Text('تسجيل'),
          ),
        ],
      ),
    );

    if (amount == null || !context.mounted) return;
    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('أدخل مبلغًا صحيحًا.')));
      return;
    }
    if (amount > maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('المبلغ أكبر من المستحق (${AppFormatters.money(maxAmount)}).')),
      );
      return;
    }
    final error = await context.read<SuppliersCubit>().recordSupplierPayment(
      supplier,
      amount,
      purchaseId: purchase?.id,
    );
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (context.mounted) {
      await context.read<PurchasesCubit>().refresh();
    }
  }

  Future<void> _exportSupplierInvoices(
    BuildContext context,
    Supplier supplier,
    List<Purchase> purchases,
    String currency,
  ) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pageContext) {
          final rows = <pw.TableRow>[
            pw.TableRow(
              children: [
                pw.Text(
                  'التاريخ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'الإجمالي',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'المدفوع',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'المتبقي',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            ...purchases.map(
              (purchase) => pw.TableRow(
                children: [
                  pw.Text(AppFormatters.date(purchase.createdAt)),
                  pw.Text(AppFormatters.money(purchase.total, currency)),
                  pw.Text(AppFormatters.money(purchase.paidAmount, currency)),
                  pw.Text(
                    AppFormatters.money(purchase.remainingBalance, currency),
                  ),
                ],
              ),
            ),
          ];

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'فواتير مورد: ${supplier.name}',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'إجمالي المديونية: ${AppFormatters.money(supplier.balance, currency)}',
              ),
              pw.SizedBox(height: 12),
              pw.Table(border: pw.TableBorder.all(), children: rows),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/supplier_${supplier.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await doc.save());

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حفظ تقرير المورد في: ${file.path}')),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.supplier,
    required this.currency,
    required this.hasDebt,
  });

  final Supplier supplier;
  final String currency;
  final bool hasDebt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: hasDebt
                        ? const Color(0xFFFBE9E9)
                        : const Color(0xFFE8F1EF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    color: hasDebt ? AppColors.error : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplier.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'المديونية',
                    value: AppFormatters.money(supplier.balance, currency),
                    color: hasDebt ? AppColors.error : AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'تاريخ الإضافة',
                    value: AppFormatters.dateTime(supplier.createdAt),
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.totalPurchases,
    required this.totalPaid,
    required this.accumulatedDebt,
    required this.balance,
    required this.currency,
  });

  final double totalPurchases;
  final double totalPaid;
  final double accumulatedDebt;
  final double balance;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'إجمالي الشراء',
            value: AppFormatters.money(totalPurchases, currency),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            label: 'إجمالي المدفوع',
            value: AppFormatters.money(totalPaid, currency),
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseInvoiceTile extends StatelessWidget {
  const _PurchaseInvoiceTile({
    required this.purchase,
    required this.currency,
    this.onRecordPayment,
  });

  final Purchase purchase;
  final String currency;
  final VoidCallback? onRecordPayment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: purchase.remainingBalance > 0
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1EF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        AppFormatters.money(purchase.total, currency),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (purchase.isFullyPaid) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F1EF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'مسدد',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'مدفوع: ${AppFormatters.money(purchase.paidAmount, currency)} • متبقي: ${AppFormatters.money(purchase.remainingBalance, currency)}',
                  style: TextStyle(
                    color: purchase.remainingBalance > 0
                        ? AppColors.error
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppFormatters.dateTime(purchase.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (purchase.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    purchase.note,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (onRecordPayment != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRecordPayment,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('سداد'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.payment,
    required this.currency,
    this.invoiceDate,
  });

  final SupplierPayment payment;
  final String currency;
  final DateTime? invoiceDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1EF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سداد: ${AppFormatters.money(payment.amount, currency)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  AppFormatters.dateTime(payment.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (invoiceDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'على فاتورة بتاريخ ${AppFormatters.date(invoiceDate!)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPurchases extends StatelessWidget {
  const _EmptyPurchases();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Text(
          'لا توجد فواتير شراء لهذا المورد بعد.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _EmptyPayments extends StatelessWidget {
  const _EmptyPayments();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Text(
          'لا توجد دفعات مسجلة لهذا المورد بعد.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

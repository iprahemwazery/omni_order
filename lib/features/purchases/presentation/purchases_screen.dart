import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/pdf_exporter.dart';
import '../../../domain/models/purchase.dart';
import '../../../domain/models/purchase_item.dart';
import '../../../domain/models/store_settings.dart';
import '../../../domain/models/supplier.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../settings/presentation/settings_cubit.dart';
import '../../suppliers/presentation/suppliers_cubit.dart';
import 'purchase_form_screen.dart';
import 'purchases_cubit.dart';
import 'purchases_state.dart';

/// شاشة المشتريات: سجل فواتير التوريد (الموردين).
class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المشتريات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PurchaseFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('فاتورة شراء'),
      ),
      body: SafeArea(
        child: BlocBuilder<PurchasesCubit, PurchasesState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.purchases.isEmpty) {
              return const EmptyState(
                icon: Icons.local_shipping_outlined,
                title: 'لا توجد مشتريات بعد',
                subtitle: 'سجّل فاتورة شراء جديدة عند استلام بضاعة',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              itemCount: state.purchases.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _PurchaseTile(purchase: state.purchases[index]),
            );
          },
        ),
      ),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  const _PurchaseTile({required this.purchase});

  final Purchase purchase;

  @override
  Widget build(BuildContext context) {
    final currency = context.read<SettingsCubit>().state.settings.currency;
    return Card(
      child: ListTile(
        onTap: () => _showDetails(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1EF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.local_shipping_outlined,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          purchase.supplierName.isEmpty ? 'فاتورة شراء' : purchase.supplierName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${AppFormatters.dateTime(purchase.createdAt)}'
          '${purchase.note.isNotEmpty ? ' • ${purchase.note}' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Text(
          AppFormatters.money(purchase.total, currency),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) async {
    final items = await context.read<PurchasesCubit>().purchaseItemsOf(
      purchase.id ?? 0,
    );
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PurchaseDetailsScreen(purchase: purchase, items: items),
      ),
    );
  }
}

class PurchaseDetailsScreen extends StatelessWidget {
  const PurchaseDetailsScreen({
    super.key,
    required this.purchase,
    required this.items,
  });

  final Purchase purchase;
  final List<PurchaseItem> items;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state.settings;
    final currency = settings.currency;
    final suppliers = context.watch<SuppliersCubit>().state.suppliers;
    final supplier = suppliers.firstWhere(
      (item) =>
          item.name.trim().toLowerCase() ==
          purchase.supplierName.trim().toLowerCase(),
      orElse: () => Supplier(name: ''),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل فاتورة الشراء'),
        actions: [
          IconButton(
            tooltip: 'طباعة الفاتورة',
            onPressed: () =>
                _exportPurchasePdf(context, purchase, items, settings),
            icon: const Icon(Icons.print_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.storefront,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          settings.storeName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    purchase.supplierName.isEmpty
                        ? 'فاتورة شراء عامة'
                        : purchase.supplierName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'التاريخ: ${AppFormatters.dateTime(purchase.createdAt)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (purchase.note.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'ملاحظة: ${purchase.note}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _DetailMetricCard(
                    label: 'الإجمالي',
                    value: AppFormatters.money(purchase.total, currency),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DetailMetricCard(
                    label: 'المدفوع',
                    value: AppFormatters.money(purchase.paidAmount, currency),
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _DetailMetricCard(
              label: 'المتبقي للمورد',
              value: AppFormatters.money(purchase.remainingBalance, currency),
              color: purchase.remainingBalance > 0
                  ? AppColors.error
                  : AppColors.success,
            ),
            if (supplier.id != null && supplier.name.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _DetailMetricCard(
                label: 'المديونية الحالية للمورد',
                value: AppFormatters.money(supplier.balance, currency),
                color: supplier.balance > 0
                    ? AppColors.error
                    : AppColors.success,
              ),
            ],
            const SizedBox(height: 18),
            const Text(
              'بنود الفاتورة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'لا توجد بنود في هذه الفاتورة.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...items.map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppFormatters.quantity(item.quantity, '')} × ${AppFormatters.money(item.price, currency)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        AppFormatters.money(item.subtotal, currency),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _exportPurchaseExcel(context, purchase, items),
                    icon: const Icon(Icons.table_view_outlined),
                    label: const Text('تصدير Excel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        _exportPurchasePdf(context, purchase, items, settings),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('طباعة الفاتورة'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPurchaseExcel(
    BuildContext context,
    Purchase purchase,
    List<PurchaseItem> items,
  ) async {
    final rows = [
      ['المورد', 'التاريخ', 'الإجمالي', 'المدفوع', 'المتبقي', 'ملاحظات'],
      [
        purchase.supplierName.isEmpty ? 'غير محدد' : purchase.supplierName,
        AppFormatters.date(purchase.createdAt),
        purchase.total.toStringAsFixed(2),
        purchase.paidAmount.toStringAsFixed(2),
        purchase.remainingBalance.toStringAsFixed(2),
        purchase.note.isEmpty ? '-' : purchase.note,
      ],
      ['الصنف', 'الكمية', 'سعر الشراء', 'الإجمالي'],
      for (final item in items)
        [
          item.name,
          item.quantity.toStringAsFixed(2),
          item.price.toStringAsFixed(2),
          item.subtotal.toStringAsFixed(2),
        ],
    ];

    final csv = rows
        .map(
          (row) =>
              row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(','),
        )
        .join('\n');

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/purchase_${purchase.id ?? DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csv);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حفظ ملف Excel في: ${file.path}')),
    );
  }

  Future<void> _exportPurchasePdf(
    BuildContext context,
    Purchase purchase,
    List<PurchaseItem> items,
    StoreSettings settings,
  ) async {
    final doc = await PdfExporter.newDocument();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pageContext) {
          final itemRows = <pw.TableRow>[
            pw.TableRow(
              children: [
                pw.Text(
                  'الصنف',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'الكمية',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'السعر',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'الإجمالي',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            ...items.map(
              (item) => pw.TableRow(
                children: [
                  pw.Text(item.name),
                  pw.Text(item.quantity.toStringAsFixed(2)),
                  pw.Text(AppFormatters.money(item.price, settings.currency)),
                  pw.Text(
                    AppFormatters.money(item.subtotal, settings.currency),
                  ),
                ],
              ),
            ),
          ];

          return PdfExporter.rtl(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.teal,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(12),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        settings.storeName,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (settings.phone.isNotEmpty)
                        pw.Text(
                          settings.phone,
                          style: pw.TextStyle(color: PdfColors.white),
                        ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'فاتورة شراء',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'المورد: ${purchase.supplierName.isEmpty ? 'غير محدد' : purchase.supplierName}',
                ),
                pw.Text('التاريخ: ${AppFormatters.dateTime(purchase.createdAt)}'),
                pw.Text(
                  'الإجمالي: ${AppFormatters.money(purchase.total, settings.currency)}',
                ),
                pw.Text(
                  'المدفوع: ${AppFormatters.money(purchase.paidAmount, settings.currency)}',
                ),
                pw.Text(
                  'المتبقي: ${AppFormatters.money(purchase.remainingBalance, settings.currency)}',
                ),
                if (purchase.note.isNotEmpty) pw.Text('ملاحظة: ${purchase.note}'),
                pw.SizedBox(height: 16),
                pw.Table(border: pw.TableBorder.all(), children: itemRows),
              ],
            ),
          );
        },
      ),
    );

    try {
      final bytes = await doc.save();
      final fileName =
          'purchase_${purchase.id ?? DateTime.now().millisecondsSinceEpoch}.pdf';
      final location = await PdfExporter.saveToDownloads(bytes, fileName);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              location == null
                  ? 'تعذر حفظ فاتورة الشراء في مجلد التنزيلات'
                  : 'تم حفظ فاتورة الشراء في $location: $fileName',
            ),
          ),
        );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(safeErrorMessage('تعذر حفظ فاتورة الشراء', e))),
        );
    }
  }
}

class _DetailMetricCard extends StatelessWidget {
  const _DetailMetricCard({
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
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

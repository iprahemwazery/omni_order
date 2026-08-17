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
import '../../../domain/models/supplier.dart';
import '../../purchases/presentation/purchases_cubit.dart';
import '../../settings/presentation/settings_cubit.dart';
import 'suppliers_cubit.dart';

class SupplierReportsScreen extends StatefulWidget {
  const SupplierReportsScreen({super.key});

  @override
  State<SupplierReportsScreen> createState() => _SupplierReportsScreenState();
}

class _SupplierReportsScreenState extends State<SupplierReportsScreen> {
  int? selectedSupplierId;
  DateTimeRange? customRange;
  int selectedRangeDays = 0;

  @override
  Widget build(BuildContext context) {
    final suppliers = context.watch<SuppliersCubit>().state.suppliers;
    final purchases = context.watch<PurchasesCubit>().state.purchases;
    final currency = context.watch<SettingsCubit>().state.settings.currency;

    final filteredPurchases = _filteredPurchases(purchases, suppliers);
    final totalPurchases = filteredPurchases.fold(
      0.0,
      (sum, item) => sum + item.total,
    );
    final invoiceCount = filteredPurchases.length;
    final averagePurchase = invoiceCount == 0
        ? 0.0
        : totalPurchases / invoiceCount;
    final largestSupplier = _largestSupplier(filteredPurchases, suppliers);
    final activeSuppliers = _supplierTotals(filteredPurchases, suppliers);
    final totalDebt = activeSuppliers.fold(
      0.0,
      (sum, item) => sum + item.balance,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الموردين'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () async {
              final suppliersCubit = context.read<SuppliersCubit>();
              final purchasesCubit = context.read<PurchasesCubit>();
              await suppliersCubit.refresh();
              await purchasesCubit.refresh();
            },
            icon: const Icon(Icons.refresh_outlined),
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
                      const Icon(
                        Icons.assessment_outlined,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ملخص الموردين',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    AppFormatters.money(totalPurchases, currency),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _MiniChip(
                        icon: Icons.receipt_long_outlined,
                        label: 'فواتير: $invoiceCount',
                      ),
                      _MiniChip(
                        icon: Icons.trending_up,
                        label:
                            'متوسط: ${AppFormatters.money(averagePurchase, currency)}',
                      ),
                      _MiniChip(
                        icon: Icons.account_balance_wallet_outlined,
                        label:
                            'ديون: ${AppFormatters.money(totalDebt, currency)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _FilterPanel(
              selectedSupplierId: selectedSupplierId,
              suppliers: suppliers,
              customRange: customRange,
              selectedRangeDays: selectedRangeDays,
              onSupplierChanged: (value) =>
                  setState(() => selectedSupplierId = value),
              onRangeChanged: (days) =>
                  setState(() => selectedRangeDays = days),
              onCustomRange: () async {
                final dateRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                  initialDateRange: customRange,
                  locale: const Locale('ar', 'SA'),
                );
                if (dateRange != null) {
                  setState(() {
                    customRange = dateRange;
                    selectedRangeDays = -1;
                  });
                }
              },
              onReset: () => setState(() {
                selectedSupplierId = null;
                customRange = null;
                selectedRangeDays = 0;
              }),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _exportExcel(
                      context,
                      filteredPurchases,
                      suppliers,
                      currency,
                    ),
                    icon: const Icon(Icons.table_view_outlined),
                    label: const Text('تصدير Excel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportPdf(
                      context,
                      filteredPurchases,
                      suppliers,
                      currency,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('تصدير PDF'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _StatsGrid(
              totalPurchases: totalPurchases,
              totalDebt: totalDebt,
              largestSupplier: largestSupplier,
              averagePurchase: averagePurchase,
              currency: currency,
            ),
            const SizedBox(height: 18),
            const Text(
              'تفاصيل الفواتير',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (filteredPurchases.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'لا توجد فواتير ضمن الفلتر الحالي.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...filteredPurchases.map(
                (purchase) =>
                    _PurchaseRow(purchase: purchase, currency: currency),
              ),
          ],
        ),
      ),
    );
  }

  List<Purchase> _filteredPurchases(
    List<Purchase> purchases,
    List<Supplier> suppliers,
  ) {
    var result = purchases;

    if (selectedSupplierId != null) {
      final targetSupplier = suppliers.firstWhere(
        (supplier) => supplier.id == selectedSupplierId,
        orElse: () => Supplier(name: ''),
      );
      final targetName = targetSupplier.name.trim().toLowerCase();
      result = result.where((purchase) {
        return purchase.supplierName.trim().toLowerCase() == targetName;
      }).toList();
    }

    if (selectedRangeDays > 0) {
      final cutoff = DateTime.now().subtract(Duration(days: selectedRangeDays));
      result = result
          .where((purchase) => purchase.createdAt.isAfter(cutoff))
          .toList();
    } else if (customRange != null) {
      final range = customRange!;
      result = result.where((purchase) {
        final created = purchase.createdAt;
        return !created.isBefore(range.start) && !created.isAfter(range.end);
      }).toList();
    }

    result = result.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Supplier? _largestSupplier(
    List<Purchase> purchases,
    List<Supplier> suppliers,
  ) {
    if (suppliers.isEmpty) return null;

    final totals = <String, double>{};
    for (final purchase in purchases) {
      final key = purchase.supplierName.trim();
      if (key.isEmpty) continue;
      totals[key] = (totals[key] ?? 0) + purchase.total;
    }

    Supplier? bestSupplier;
    double bestValue = -1;
    for (final supplier in suppliers) {
      final value = totals[supplier.name.trim()] ?? 0;
      if (value > bestValue) {
        bestValue = value;
        bestSupplier = supplier;
      }
    }
    return bestSupplier;
  }

  List<_SupplierBalance> _supplierTotals(
    List<Purchase> purchases,
    List<Supplier> suppliers,
  ) {
    final totals = <String, double>{};
    for (final purchase in purchases) {
      final key = purchase.supplierName.trim();
      if (key.isEmpty) continue;
      totals[key] = (totals[key] ?? 0) + purchase.total;
    }

    final list = <_SupplierBalance>[];
    for (final supplier in suppliers) {
      if (selectedSupplierId != null && supplier.id != selectedSupplierId) {
        continue;
      }
      if (supplier.name.trim().isEmpty) continue;
      list.add(
        _SupplierBalance(
          name: supplier.name,
          balance: supplier.balance,
          totalSpent: totals[supplier.name.trim()] ?? 0,
        ),
      );
    }

    return list;
  }

  Future<void> _exportExcel(
    BuildContext context,
    List<Purchase> purchases,
    List<Supplier> suppliers,
    String currency,
  ) async {
    final rows = [
      ['اسم المورد', 'التاريخ', 'الإجمالي', 'ملاحظات'],
      for (final purchase in purchases)
        [
          purchase.supplierName.isEmpty ? 'غير محدد' : purchase.supplierName,
          AppFormatters.date(purchase.createdAt),
          purchase.total.toStringAsFixed(2),
          purchase.note.isEmpty ? '-' : purchase.note,
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
      '${dir.path}/supplier_report_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csv);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حفظ ملف Excel في: ${file.path}')),
    );
  }

  Future<void> _exportPdf(
    BuildContext context,
    List<Purchase> purchases,
    List<Supplier> suppliers,
    String currency,
  ) async {
    final doc = await PdfExporter.newDocument();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pageContext) {
          final rows = <pw.TableRow>[
            pw.TableRow(
              children: [
                pw.Text(
                  'اسم المورد',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'التاريخ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'الإجمالي',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            ...purchases.map(
              (purchase) => pw.TableRow(
                children: [
                  pw.Text(
                    purchase.supplierName.isEmpty
                        ? 'غير محدد'
                        : purchase.supplierName,
                  ),
                  pw.Text(AppFormatters.date(purchase.createdAt)),
                  pw.Text(AppFormatters.money(purchase.total, currency)),
                ],
              ),
            ),
          ];

          return PdfExporter.rtl(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'تقرير الموردين',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text('عدد الفواتير: ${purchases.length}'),
                pw.SizedBox(height: 16),
                pw.Table(border: pw.TableBorder.all(), children: rows),
              ],
            ),
          );
        },
      ),
    );

    try {
      final bytes = await doc.save();
      final fileName =
          'supplier_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final location = await PdfExporter.saveToDownloads(bytes, fileName);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              location == null
                  ? 'تعذر حفظ تقرير الموردين في مجلد التنزيلات'
                  : 'تم حفظ تقرير الموردين في $location: $fileName',
            ),
          ),
        );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(safeErrorMessage('تعذر حفظ تقرير الموردين', e)),
          ),
        );
    }
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.selectedSupplierId,
    required this.suppliers,
    required this.customRange,
    required this.selectedRangeDays,
    required this.onSupplierChanged,
    required this.onRangeChanged,
    required this.onCustomRange,
    required this.onReset,
  });

  final int? selectedSupplierId;
  final List<Supplier> suppliers;
  final DateTimeRange? customRange;
  final int selectedRangeDays;
  final ValueChanged<int?> onSupplierChanged;
  final ValueChanged<int> onRangeChanged;
  final VoidCallback onCustomRange;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
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
            'تصفية حسب المورد',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            initialValue: selectedSupplierId,
            decoration: const InputDecoration(
              labelText: 'المورد',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('الكل')),
              for (final supplier in suppliers)
                DropdownMenuItem<int?>(
                  value: supplier.id,
                  child: Text(supplier.name),
                ),
            ],
            onChanged: onSupplierChanged,
          ),
          const SizedBox(height: 16),
          const Text(
            'الفترة الزمنية',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RangeChip(
                label: 'الكل',
                value: 0,
                selected: selectedRangeDays == 0 && customRange == null,
                onTap: () => onRangeChanged(0),
              ),
              _RangeChip(
                label: '7 أيام',
                value: 7,
                selected: selectedRangeDays == 7,
                onTap: () => onRangeChanged(7),
              ),
              _RangeChip(
                label: '30 يوم',
                value: 30,
                selected: selectedRangeDays == 30,
                onTap: () => onRangeChanged(30),
              ),
              _RangeChip(
                label: 'مخصص',
                value: -1,
                selected: customRange != null,
                onTap: onCustomRange,
              ),
            ],
          ),
          if (customRange != null) ...[
            const SizedBox(height: 8),
            Text(
              'الفترة المختارة: ${AppFormatters.date(customRange!.start)} - ${AppFormatters.date(customRange!.end)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.clear_all_outlined),
              label: const Text('إعادة الضبط'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.totalPurchases,
    required this.totalDebt,
    required this.largestSupplier,
    required this.averagePurchase,
    required this.currency,
  });

  final double totalPurchases;
  final double totalDebt;
  final Supplier? largestSupplier;
  final double averagePurchase;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, String value, Color color, IconData icon})>[
      (
        label: 'إجمالي المشتريات',
        value: AppFormatters.money(totalPurchases, currency),
        color: AppColors.primary,
        icon: Icons.shopping_cart_outlined,
      ),
      (
        label: 'متوسط الشراء',
        value: AppFormatters.money(averagePurchase, currency),
        color: AppColors.success,
        icon: Icons.bar_chart,
      ),
      (
        label: 'أكبر مورد',
        value: largestSupplier == null ? '—' : largestSupplier!.name,
        color: AppColors.warning,
        icon: Icons.local_shipping_outlined,
      ),
      (
        label: 'إجمالي الديون',
        value: AppFormatters.money(totalDebt, currency),
        color: AppColors.error,
        icon: Icons.account_balance_wallet_outlined,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
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
                  Icon(item.icon, color: item.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                item.value,
                style: TextStyle(
                  color: item.color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PurchaseRow extends StatelessWidget {
  const _PurchaseRow({required this.purchase, required this.currency});

  final Purchase purchase;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.supplierName.isEmpty
                      ? 'غير محدد'
                      : purchase.supplierName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.dateTime(purchase.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatters.money(purchase.total, currency),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (purchase.note.isNotEmpty)
                Text(
                  purchase.note,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupplierBalance {
  const _SupplierBalance({
    required this.name,
    required this.balance,
    required this.totalSpent,
  });

  final String name;
  final double balance;
  final double totalSpent;
}

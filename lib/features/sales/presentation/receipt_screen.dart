import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../domain/models/sale.dart';
import '../../../domain/models/sale_item.dart';
import '../../../domain/models/store_settings.dart';
import '../../customers/presentation/customers_cubit.dart';
import '../../customers/presentation/customers_state.dart';
import '../../settings/presentation/settings_cubit.dart';
import '../../settings/presentation/settings_state.dart';
import 'sales_cubit.dart';
import 'sales_history_screen.dart';
import 'widgets/receipt_pdf_exporter.dart';
import 'widgets/receipt_view.dart';

/// شاشة عرض الفاتورة بعد إتمام البيع أو من سجل المبيعات.
class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key, required this.sale});

  final Sale sale;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  /// يُنفَّذ استعلام بنود الفاتورة مرة واحدة فقط بدل إعادة تنفيذه
  /// مع كل إعادة بناء للشاشة.
  late final Future<List<SaleItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture =
        context.read<SalesCubit>().saleItemsOf(widget.sale.id ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF2F0),
      appBar: AppBar(
        title: const Text('الفاتورة'),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<List<SaleItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const [];
          return BlocBuilder<CustomersCubit, CustomersState>(
            builder: (context, customers) =>
                BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, settings) {
                final customerName = customers.customerById(widget.sale.customerId)?.name;
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        ReceiptView(
                          sale: widget.sale,
                          items: items,
                          settings: settings.settings,
                          customerName: customerName,
                        ),
                        const SizedBox(height: 24),
                        const _SuccessNote(),
                        const SizedBox(height: 16),
                        _SavePdfButton(
                          sale: widget.sale,
                          items: items,
                          settings: settings.settings,
                          customerName: customerName,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.add_shopping_cart),
                                label: const Text('فاتورة جديدة'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SalesHistoryScreen(),
                                  ),
                                ),
                                icon: const Icon(Icons.history),
                                label: const Text('المبيعات السابقة'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SuccessNote extends StatelessWidget {
  const _SuccessNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F5EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 20),
          SizedBox(width: 8),
          Text(
            'تم حفظ الفاتورة بنجاح',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// زر حفظ الفاتورة كملف PDF في مجلد التنزيلات وعرضها.
class _SavePdfButton extends StatefulWidget {
  const _SavePdfButton({
    required this.sale,
    required this.items,
    required this.settings,
    this.customerName,
  });

  final Sale sale;
  final List<SaleItem> items;
  final StoreSettings settings;
  final String? customerName;

  @override
  State<_SavePdfButton> createState() => _SavePdfButtonState();
}

class _SavePdfButtonState extends State<_SavePdfButton> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final bytes = await ReceiptPdfExporter.buildReceipt(
        sale: widget.sale,
        items: widget.items,
        settings: widget.settings,
        customerName: widget.customerName,
      );
      final fileName =
          'فاتورة_${widget.sale.id ?? DateTime.now().millisecondsSinceEpoch}.pdf';
      final location = await ReceiptPdfExporter.saveToDownloads(bytes, fileName);
      final opened = await ReceiptPdfExporter.openPdf(bytes, fileName);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              location == null
                  ? 'تعذر حفظ الفاتورة في مجلد التنزيلات'
                  : 'تم حفظ الفاتورة في $location: $fileName',
            ),
          ),
        );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الملف، لكنه محفوظ على الجهاز')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(safeErrorMessage('تعذر حفظ الفاتورة', e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.picture_as_pdf),
        label: Text(_saving ? 'جارٍ حفظ الفاتورة...' : 'حفظ PDF'),
      ),
    );
  }
}

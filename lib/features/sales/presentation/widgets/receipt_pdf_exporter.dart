import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/constants/payment_methods.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/pdf_exporter.dart';
import '../../../../domain/models/sale.dart';
import '../../../../domain/models/sale_item.dart';
import '../../../../domain/models/store_settings.dart';

/// يُنشئ فاتورة البيع كملف PDF (صفحة A4) ويحفظها في مجلد التنزيلات العام.
class ReceiptPdfExporter {
  ReceiptPdfExporter._();

  /// يبني بيانات الفاتورة كملف PDF جاهز للحفظ.
  static Future<Uint8List> buildReceipt({
    required Sale sale,
    required List<SaleItem> items,
    required StoreSettings settings,
    String? customerName,
  }) async {
    final doc = await PdfExporter.newDocument();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => PdfExporter.rtl(
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: _buildContent(sale, items, settings, customerName),
          ),
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildContent(
    Sale sale,
    List<SaleItem> items,
    StoreSettings settings,
    String? customerName,
  ) {
    final subtotal = sale.total + sale.discount;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Center(
          child: pw.Text(
            settings.storeName,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        if (settings.phone.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              settings.phone,
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFE8F1EF),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(16)),
            ),
            child: pw.Text(
              'فاتورة بيع',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal800,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _InfoCell(
              label: 'رقم الفاتورة',
              value: '#${sale.id ?? 0}',
            ),
            _InfoCell(label: 'التاريخ', value: AppFormatters.date(sale.createdAt)),
            _InfoCell(label: 'الوقت', value: AppFormatters.time(sale.createdAt)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            [
              'طريقة الدفع: ${sale.paymentMethod}',
              if (customerName != null) 'العميل: $customerName',
              if (sale.cashierName.isNotEmpty) 'الكاشير: ${sale.cashierName}',
            ].join('  •  '),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 12),
        pw.Text(
          'الأصناف',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(4),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(2),
            3: pw.FlexColumnWidth(2),
          },
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF1F5F4),
              ),
              children: [
                _cell('البيان', bold: true),
                _cell('الكمية', bold: true),
                _cell('السعر', bold: true),
                _cell('الإجمالي', bold: true),
              ],
            ),
            ...items.map(
              (item) => pw.TableRow(
                children: [
                  _cell(item.name),
                  _cell(AppFormatters.quantity(item.quantity, '')),
                  _cell(AppFormatters.money(item.price, settings.currency)),
                  _cell(AppFormatters.money(item.subtotal, settings.currency)),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        _TotalRow(label: 'الإجمالي', value: AppFormatters.money(subtotal, settings.currency)),
        if (sale.discount > 0) ...[
          pw.SizedBox(height: 6),
          _TotalRow(
            label: 'الخصم',
            value: AppFormatters.money(sale.discount, settings.currency),
            color: PdfColors.red600,
          ),
        ],
        if (sale.taxAmount > 0) ...[
          pw.SizedBox(height: 6),
          _TotalRow(
            label: 'قيمة الضريبة (${AppFormatters.percent(sale.taxRate)})',
            value: AppFormatters.money(sale.taxAmount, settings.currency),
            color: PdfColors.blueGrey700,
          ),
        ],
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'الصافي',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              AppFormatters.money(sale.total, settings.currency),
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal800,
              ),
            ),
          ],
        ),
        if (sale.taxAmount > 0) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            'شامل ضريبة القيمة المضافة',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
        if (sale.paymentMethod == PaymentMethod.mixed) ...[
          pw.SizedBox(height: 8),
          _TotalRow(
            label: 'نقدًا',
            value: AppFormatters.money(
              sale.total - sale.cardAmount,
              settings.currency,
            ),
          ),
          pw.SizedBox(height: 4),
          _TotalRow(
            label: 'بالشبكة',
            value: AppFormatters.money(sale.cardAmount, settings.currency),
            color: PdfColors.teal700,
          ),
        ] else if (sale.amountTendered > sale.total) ...[
          pw.SizedBox(height: 8),
          _TotalRow(
            label: 'المدفوع',
            value: AppFormatters.money(
              sale.amountTendered,
              settings.currency,
            ),
          ),
          pw.SizedBox(height: 4),
          _TotalRow(
            label: 'الباقي للعميل',
            value: AppFormatters.money(sale.changeDue, settings.currency),
            color: PdfColors.green700,
          ),
        ],
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF4F7F6),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Text(
            AppFormatters.amountInWords(sale.total, settings.currency),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
          ),
        ),
        if (sale.note.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'ملاحظة: ${sale.note}',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange700,
            ),
          ),
        ],
        if (sale.paymentMethod == PaymentMethod.deferred) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            customerName == null
                ? 'تم تسجيل المبلغ كدين'
                : 'تم تسجيل المبلغ دينًا على $customerName',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange700,
            ),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Text(
          'عدد الأصناف: ${sale.itemsCount}',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 14),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 12),
        pw.Text(
          'شكرًا لزيارتكم، نتمنى لكم يومًا سعيدًا',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'نظام أومني أوردر لإدارة المحلات',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
        ),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// يحفظ ملف PDF في مجلد التنزيلات العام (عبر MediaStore على أندرويد).
  /// يعيد وصف مكان الحفظ عند النجاح، أو null عند الفشل.
  static Future<String?> saveToDownloads(Uint8List bytes, String fileName) =>
      PdfExporter.saveToDownloads(bytes, fileName);

  /// يعرض ملف PDF عبر التطبيق المثبّت للعرض (نسخة داخل التطبيق).
  /// يعيد true إذا فُتح بنجاح.
  static Future<bool> openPdf(Uint8List bytes, String fileName) =>
      PdfExporter.openPdf(bytes, fileName);
}

class _InfoCell extends pw.StatelessWidget {
  _InfoCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }
}

class _TotalRow extends pw.StatelessWidget {
  _TotalRow({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final PdfColor? color;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 12)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

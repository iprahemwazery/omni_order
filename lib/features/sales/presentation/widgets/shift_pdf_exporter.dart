import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/constants/payment_methods.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/pdf_exporter.dart';
import '../../../../domain/models/shift.dart';
import '../../../../domain/models/store_settings.dart';

/// يُنشئ تقرير الوردية (Z-Report) كملف PDF ويحفظه في مجلد التنزيلات.
class ShiftPdfExporter {
  ShiftPdfExporter._();

  /// يبني تقرير الوردية كملف PDF جاهز للحفظ.
  static Future<Uint8List> buildReport({
    required ShiftReport report,
    required StoreSettings settings,
  }) async {
    final doc = await PdfExporter.newDocument();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => PdfExporter.rtl(
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: _buildContent(report, settings),
          ),
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildContent(
    ShiftReport report,
    StoreSettings settings,
  ) {
    final currency = settings.currency;
    final shift = report.shift;
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
              'تقرير الوردية (Z-Report)',
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
            _InfoCell(label: 'الكاشير', value: shift.cashierName),
            _InfoCell(
              label: 'البداية',
              value: '${AppFormatters.date(shift.openedAt)} '
                  '${AppFormatters.time(shift.openedAt)}',
            ),
            _InfoCell(
              label: shift.isOpen ? 'الحالة' : 'النهاية',
              value: shift.isOpen
                  ? 'مفتوحة'
                  : '${AppFormatters.date(shift.closedAt!)} '
                      '${AppFormatters.time(shift.closedAt!)}',
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _TotalRow(
              label: 'إجمالي مبيعات الوردية',
              value: AppFormatters.money(report.totalSales, currency),
              color: PdfColors.teal800,
            ),
            _TotalRow(
              label: 'عدد الفواتير',
              value: '${report.salesCount}',
            ),
          ],
        ),
        pw.SizedBox(height: 14),
        _reportRow(PaymentMethod.cash, report.cashTotal, currency),
        _reportRow(PaymentMethod.card, report.cardTotal, currency),
        _reportRow(PaymentMethod.wallet, report.walletTotal, currency),
        _reportRow(PaymentMethod.bankTransfer, report.transferTotal, currency),
        _reportRow('مختلط (نقدًا)', report.mixedCashPortion, currency),
        _reportRow('مختلط (بالشبكة)', report.mixedCardPortion, currency),
        _reportRow('آجل (دين)', report.deferredTotal, currency),
        pw.SizedBox(height: 6),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 6),
        _reportRow(
          'الباقي المُصرف للعملاء',
          report.changeGiven,
          currency,
          color: PdfColors.red600,
        ),
        if (report.refundCount > 0) ...[
          pw.SizedBox(height: 4),
          _reportRow(
            'مرتجعات (${report.refundCount})',
            -report.refundsTotal,
            currency,
            color: PdfColors.red700,
          ),
        ],
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF4F7F6),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              _TotalRow(
                label: 'النقد المتوقع في الصندوق',
                value: AppFormatters.money(report.cashReceived, currency),
              ),
              pw.SizedBox(height: 4),
              _TotalRow(
                label: 'محصلات الشبكة المتوقعة',
                value: AppFormatters.money(report.cardReceived, currency),
                color: PdfColors.teal700,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 12),
        pw.Text(
          shift.isOpen ? 'وردية مفتوحة' : 'تم إغلاق الوردية',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: shift.isOpen ? PdfColors.green700 : PdfColors.grey700,
          ),
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

  static pw.Widget _reportRow(
    String label,
    double amount,
    String currency, {
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12)),
          pw.Text(
            AppFormatters.money(amount, currency),
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// يحفظ التقرير في مجلد التنزيلات العام (يرجّع مكان الحفظ أو null).
  static Future<String?> saveToDownloads(
    Uint8List bytes,
    String fileName,
  ) {
    return PdfExporter.saveToDownloads(bytes, fileName);
  }

  /// يعرض التقرير عبر تطبيق عرض PDF. يعيد true عند النجاح.
  static Future<bool> openPdf(Uint8List bytes, String fileName) {
    return PdfExporter.openPdf(bytes, fileName);
  }
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
        pw.Text(label, style: pw.TextStyle(fontSize: 13)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

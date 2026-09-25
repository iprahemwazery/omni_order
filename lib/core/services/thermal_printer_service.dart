import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight;
import 'package:intl/intl.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

import '../../domain/models/order.dart';
import '../../domain/models/order_item.dart';

/// معلومات اتصال الطابعة المحفوظة.
class SavedPrinterInfo {
  final String name;
  final String address;
  final PaperSize paperSize;

  const SavedPrinterInfo({
    required this.name,
    required this.address,
    this.paperSize = PaperSize.mm80,
  });

  Map<String, String> toMap() => {
        'name': name,
        'address': address,
        'paperSize': paperSize.toString(),
      };

  factory SavedPrinterInfo.fromMap(Map<String, String> map) {
    return SavedPrinterInfo(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      paperSize: PaperSize.mm80,
    );
  }
}

/// خدمة الطابعة الحرارية — مسح البلوتوث، اتصال، وطباعة فواتير.
///
/// تدعم النص العربي عبر `rowRaster` مع `TextDirection.rtl`.
class ThermalPrinterService {
  ThermalPrinterService._();
  static final ThermalPrinterService instance = ThermalPrinterService._();

  final PrinterManager _manager = PrinterManager();
  final List<PrinterDevice> _discoveredPrinters = [];

  bool _isConnected = false;
  SavedPrinterInfo? _savedInfo;

  PrinterDevice? _connectedPrinter;
  PrinterDevice? get connectedPrinter => _connectedPrinter;

  List<PrinterDevice> get discoveredPrinters =>
      List.unmodifiable(_discoveredPrinters);
  bool get isConnected => _isConnected;
  SavedPrinterInfo? get savedInfo => _savedInfo;

  // ──────────────── Bluetooth scan ────────────────

  Future<List<PrinterDevice>> scanPrinters({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    _discoveredPrinters.clear();
    try {
      final printers = await _manager.scanPrinters(
        timeout: timeout,
        types: {PrinterConnectionType.bluetooth, PrinterConnectionType.ble},
      );
      _discoveredPrinters.addAll(printers);
      notifyListeners();
    } catch (e) {
      debugPrint('ThermalPrinterService scan error: $e');
    }
    return List.unmodifiable(_discoveredPrinters);
  }

  // ──────────────── Connect / Disconnect ────────────────

  Future<bool> connect(PrinterDevice printer) async {
    try {
      await _manager.connect(printer);
      _connectedPrinter = printer;
      _isConnected = true;

      final address = switch (printer) {
        BluetoothPrinterDevice p => p.address,
        BlePrinterDevice p => p.deviceId,
        _ => printer.name,
      };

      _savedInfo = SavedPrinterInfo(
        name: printer.name,
        address: address,
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ThermalPrinterService connect error: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _manager.disconnect();
    } catch (_) {}
    _connectedPrinter = null;
    _isConnected = false;
    _savedInfo = null;
    notifyListeners();
  }

  // ──────────────── Ticket helpers ────────────────

  Future<Ticket> _createTicket() async {
    return await Ticket.create(PaperSize.mm80);
  }

  /// يطبّع شكل (فاتورة) من بيانات الطلب.
  Future<bool> printReceipt({
    required RestaurantOrder order,
    required List<OrderItem> items,
    required String storeName,
    String currency = 'ج.م',
  }) async {
    if (!_isConnected || _connectedPrinter == null) {
      debugPrint('ThermalPrinterService: printer not connected');
      return false;
    }

    try {
      final ticket = await _createTicket();
      final now = order.createdAt;

      // ── رأس الفاتورة ──
      ticket.text(
        storeName,
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true, height: TextSize.size2, width: TextSize.size2),
      );
      ticket.separator();

      // التاريخ والوقت
      final dateStr = DateFormat('yyyy/MM/dd').format(now);
      final timeStr = DateFormat('hh:mm a').format(now);
      await ticket.rowRaster([
        PrintRasterColumn(
          text: 'التاريخ',
          flex: 1,
          textDirection: ui.TextDirection.rtl,
          align: PrintAlign.right,
        ),
        PrintRasterColumn(
          text: '$dateStr  $timeStr',
          flex: 1,
          align: PrintAlign.left,
        ),
      ]);

      // رقم الطلب
      await ticket.rowRaster([
        PrintRasterColumn(
          text: 'رقم الطلب',
          flex: 1,
          textDirection: ui.TextDirection.rtl,
          align: PrintAlign.right,
        ),
        PrintRasterColumn(
          text: '#${order.id}',
          flex: 1,
          align: PrintAlign.left,
        ),
      ]);

      // التريبية / رقم التريبية
      await ticket.rowRaster([
        PrintRasterColumn(
          text: 'التريبية',
          flex: 1,
          textDirection: ui.TextDirection.rtl,
          align: PrintAlign.right,
        ),
        PrintRasterColumn(
          text: order.isTakeaway ? 'تيك أواي' : '${order.tableId ?? "-"}',
          flex: 1,
          align: PrintAlign.left,
        ),
      ]);

      ticket.separator();

      // ── جدول البنود ──
      await ticket.rowRaster([
        PrintRasterColumn(
          text: 'الكمية',
          flex: 1,
          textDirection: ui.TextDirection.rtl,
          align: PrintAlign.right,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        PrintRasterColumn(
          text: 'العنصر',
          flex: 3,
          textDirection: ui.TextDirection.rtl,
          align: PrintAlign.right,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        PrintRasterColumn(
          text: 'السعر',
          flex: 2,
          textDirection: ui.TextDirection.rtl,
          align: PrintAlign.right,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ]);
      ticket.separator();

      for (final item in items) {
        final qty = item.quantity == item.quantity.roundToDouble()
            ? item.quantity.toInt().toString()
            : item.quantity.toStringAsFixed(1);
        await ticket.rowRaster([
          PrintRasterColumn(
            text: '$qty ${item.notes.isNotEmpty ? '*' : ''}',
            flex: 1,
            textDirection: ui.TextDirection.rtl,
            align: PrintAlign.right,
          ),
          PrintRasterColumn(
            text: item.name,
            flex: 3,
            textDirection: ui.TextDirection.rtl,
            align: PrintAlign.right,
          ),
          PrintRasterColumn(
            text: _formatMoney(item.subtotal, currency),
            flex: 2,
            textDirection: ui.TextDirection.rtl,
            align: PrintAlign.right,
          ),
        ]);
      }

      ticket.separator();

      // ── الملخص المالي ──
      if (order.discount > 0) {
        await _printSummaryRow(ticket, 'الخصم', '-${_formatMoney(order.discount, currency)}');
      }
      if (order.taxRate > 0) {
        await _printSummaryRow(
          ticket,
          'الضريبة (${order.taxRate.toStringAsFixed(0)}%)',
          _formatMoney(order.taxAmount, currency),
        );
      }
      await _printSummaryRow(
        ticket,
        'الإجمالي',
        _formatMoney(order.total, currency),
        bold: true,
      );

      ticket.separator();

      // طريقة الدفع
      await ticket.rowRaster([
        PrintRasterColumn(
          text: 'طريقة الدفع',
          flex: 1,
          textDirection: ui.TextDirection.rtl,
          align: PrintAlign.right,
        ),
        PrintRasterColumn(
          text: order.paymentMethod,
          flex: 1,
          align: PrintAlign.left,
        ),
      ]);

      // الكاشير
      if (order.cashierName.isNotEmpty) {
        await ticket.rowRaster([
          PrintRasterColumn(
            text: 'الكاشير',
            flex: 1,
            textDirection: ui.TextDirection.rtl,
            align: PrintAlign.right,
          ),
          PrintRasterColumn(
            text: order.cashierName,
            flex: 1,
            align: PrintAlign.left,
          ),
        ]);
      }

      ticket.separator();

      // ── رسالة الشكر ──
      ticket.emptyLines(1);
      await ticket.textRaster(
        'شكراً لزيارتكم',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        textDirection: ui.TextDirection.rtl,
        align: PrintAlign.center,
      );
      await ticket.textRaster(
        'نتطلع لخدمتكم مرة أخرى',
        textDirection: ui.TextDirection.rtl,
        align: PrintAlign.center,
      );

      ticket.feed(4);

      await _manager.printTicket(ticket);
      return true;
    } catch (e) {
      debugPrint('ThermalPrinterService printReceipt error: $e');
      return false;
    }
  }

  Future<void> _printSummaryRow(
    Ticket ticket,
    String label,
    String value, {
    bool bold = false,
  }) async {
    await ticket.rowRaster([
      PrintRasterColumn(
        text: label,
        flex: 2,
        textDirection: ui.TextDirection.rtl,
        align: PrintAlign.right,
        style: bold ? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold) : null,
      ),
      PrintRasterColumn(
        text: value,
        flex: 1,
        textDirection: ui.TextDirection.rtl,
        align: PrintAlign.right,
        style: bold ? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold) : null,
      ),
    ]);
  }

  /// يطبّع فاتورة اختبارية بسيطة.
  Future<bool> printTestReceipt(String storeName) async {
    if (!_isConnected || _connectedPrinter == null) return false;

    try {
      final ticket = await _createTicket();

      ticket.text(
        storeName,
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true, height: TextSize.size2, width: TextSize.size2),
      );
      ticket.separator();
      await ticket.textRaster(
        'فاتورة اختبارية',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        textDirection: ui.TextDirection.rtl,
        align: PrintAlign.center,
      );
      ticket.separator();
      ticket.emptyLines(1);

      await ticket.rowRaster([
        PrintRasterColumn(
          text: 'العنصر',
          flex: 2,
          textDirection: ui.TextDirection.rtl,
          align: PrintAlign.right,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        PrintRasterColumn(
          text: 'السعر',
          flex: 1,
          textDirection: ui.TextDirection.rtl,
          align: PrintAlign.right,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ]);
      ticket.separator();

      await ticket.rowRaster([
        PrintRasterColumn(
          text: '1',
          flex: 1,
          textDirection: ui.TextDirection.rtl,
          align: PrintAlign.right,
        ),
        PrintRasterColumn(
          text: 'وجبة تجريبية',
          flex: 2,
          textDirection: ui.TextDirection.rtl,
          align: PrintAlign.right,
        ),
        PrintRasterColumn(
          text: '100 ج.م',
          flex: 1,
          textDirection: ui.TextDirection.rtl,
          align: PrintAlign.right,
        ),
      ]);

      ticket.separator();
      await _printSummaryRow(ticket, 'الإجمالي', '100 ج.م', bold: true);
      ticket.separator();
      ticket.emptyLines(1);
      await ticket.textRaster(
        'شكراً لزيارتكم',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        textDirection: ui.TextDirection.rtl,
        align: PrintAlign.center,
      );
      ticket.feed(4);

      await _manager.printTicket(ticket);
      return true;
    } catch (e) {
      debugPrint('ThermalPrinterService printTest error: $e');
      return false;
    }
  }

  // ──────────────── Persistence (in-memory) ────────────────

  void loadSavedInfo(Map<String, String>? saved) {
    if (saved == null || saved.isEmpty) return;
    _savedInfo = SavedPrinterInfo.fromMap(saved);
  }

  Map<String, String>? saveInfoToMap() => _savedInfo?.toMap();

  // ──────────────── Observer (lightweight) ────────────────

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void notifyListeners() {
    for (final l in _listeners) {
      l();
    }
  }

  // ──────────────── Helpers ────────────────

  String _formatMoney(num value, String currency) {
    final isWhole = value == value.roundToDouble();
    final digits = isWhole ? value.toInt().toString() : value.toStringAsFixed(2);
    return '$digits $currency';
  }
}

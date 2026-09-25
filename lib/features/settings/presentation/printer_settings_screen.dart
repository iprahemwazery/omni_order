import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

import '../../../core/services/thermal_printer_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import 'settings_cubit.dart';

/// شاشة إعدادات طابعة الإيصال الحرارية.
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final _printer = ThermalPrinterService.instance;
  bool _scanning = false;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _printer.addListener(_onPrinterUpdate);
  }

  @override
  void dispose() {
    _printer.removeListener(_onPrinterUpdate);
    super.dispose();
  }

  void _onPrinterUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _scan() async {
    setState(() => _scanning = true);
    try {
      await _printer.scanPrinters();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(safeErrorMessage('تعذر البحث عن الطابعات', e))),
      );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _connect(PrinterDevice printer) async {
    final connected = await _printer.connect(printer);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(connected ? 'تم الاتصال بالطابعة' : 'تعذر الاتصال بالطابعة'),
        backgroundColor: connected ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _disconnect() async {
    await _printer.disconnect();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم قطع الاتصال')),
    );
  }

  Future<void> _testPrint() async {
    final settings = context.read<SettingsCubit>().state.settings;
    setState(() => _testing = true);
    final ok = await _printer.printTestReceipt(settings.storeName);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم إرسال فاتورة الاختبار' : 'تعذر إرسال فاتورة الاختبار'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
    setState(() => _testing = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state.settings;
    final connected = _printer.isConnected;
    final discovered = _printer.discoveredPrinters;

    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الطابعة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── حالة الاتصال ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    connected ? Icons.print : Icons.print_disabled,
                    size: 40,
                    color: connected ? AppColors.success : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connected ? 'متصل بالطابعة' : 'غير متصل',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: connected ? AppColors.success : AppColors.textSecondary,
                          ),
                        ),
                        if (connected && _printer.connectedPrinter != null)
                          Text(
                            _printer.connectedPrinter!.name,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── أزرار البحث والفصل ──
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _scanning ? null : _scan,
                  icon: _scanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bluetooth_searching),
                  label: Text(_scanning ? 'جارٍ البحث...' : 'البحث عن طابعات'),
                ),
              ),
              if (connected) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _disconnect,
                  icon: const Icon(Icons.link_off),
                  label: const Text('فصل'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // ── قائمة الطابعات المكتشفة ──
          if (discovered.isNotEmpty) ...[
            const Text(
              'الطابعات المكتشفة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...discovered.map((printer) => _PrinterTile(
                  printer: printer,
                  isConnected: connected &&
                      _printer.connectedPrinter?.name == printer.name,
                  onTap: () => _connect(printer),
                )),
          ] else if (!_scanning) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.bluetooth_disabled,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'اضغط "البحث عن طابعات" لمسح الطابعات القريبة',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // ── فاتورة اختبارية ──
          if (connected) ...[
            const Divider(),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _testing ? null : _testPrint,
              icon: _testing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.receipt_long),
              label: Text(_testing ? 'جارٍ الطباعة...' : 'طباعة اختبارية'),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'سيتم طباعة فاتورة اختبارية لـ ${settings.storeName}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrinterTile extends StatelessWidget {
  const _PrinterTile({
    required this.printer,
    required this.isConnected,
    required this.onTap,
  });

  final PrinterDevice printer;
  final bool isConnected;
  final VoidCallback onTap;

  String get _address {
    return switch (printer) {
      BluetoothPrinterDevice p => p.address,
      BlePrinterDevice p => p.deviceId,
      _ => printer.connectionType.name,
    };
  }

  String get _connectionLabel {
    return switch (printer) {
      BluetoothPrinterDevice() => 'بلوتوث',
      BlePrinterDevice() => 'BLE',
      NetworkPrinterDevice() => 'شبكة',
      UsbPrinterDevice() => 'USB',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isConnected ? Icons.print : Icons.print_outlined,
          color: isConnected ? AppColors.success : AppColors.primary,
        ),
        title: Text(
          printer.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$_connectionLabel — $_address',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: isConnected
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : const Icon(Icons.chevron_left, color: AppColors.textSecondary),
        onTap: isConnected ? null : onTap,
      ),
    );
  }
}

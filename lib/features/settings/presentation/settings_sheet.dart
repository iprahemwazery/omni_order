import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/admin.dart';
import '../../auth/presentation/admin_login_dialog.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../auth/presentation/users_screen.dart';
import 'backup_cubit.dart';
import 'printer_settings_screen.dart';
import 'settings_cubit.dart';

/// نافذة إعدادات المطعم (اسم المطعم، الهاتف، العملة) + إدارة المستخدمين.
Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _currency;
  late final TextEditingController _tax;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsCubit>().state.settings;
    _name = TextEditingController(text: settings.storeName);
    _phone = TextEditingController(text: settings.phone);
    _currency = TextEditingController(text: settings.currency);
    _tax = TextEditingController(text: settings.taxRate.toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _currency.dispose();
    _tax.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final settings = context.read<SettingsCubit>().state.settings;
    setState(() => _saving = true);
    await context.read<SettingsCubit>().saveSettings(
      settings.copyWith(
        storeName: _name.text.trim().isEmpty
            ? settings.storeName
            : _name.text.trim(),
        phone: _phone.text.trim(),
        currency: _currency.text.trim().isEmpty ? 'ج.م' : _currency.text.trim(),
        taxRate: double.tryParse(_tax.text) ?? 0,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  Future<void> _logout() async {
    final auth = context.read<AuthCubit>();
    Navigator.of(context).pop();
    await auth.logout();
  }

  /// تبديل الدور من داخل التطبيق:
  /// - أدمن -> كاشير مباشرة (مع تأكيد فقط).
  /// - كاشير -> أدمن بإدخال اسم المستخدم وكلمة السر.
  Future<void> _switchRole() async {
    final auth = context.read<AuthCubit>();
    final current = auth.state.admin;
    if (current == null) return;

    if (current.role == UserRole.cashier) {
      await showAdminLoginDialog(context);
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('التبديل إلى كاشير'),
        content: const Text(
          'ستنتقل إلى وضع الكاشير (البيع وسجل المبيعات فقط).\n'
          'للعودة إلى الأدمن ستحتاج اسم المستخدم وكلمة السر.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('تبديل'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await auth.switchToCashier();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _openUsers() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const UsersScreen()));
  }

  void _openPrinterSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()));
  }

  /// ينفذ عملية نسخ احتياطي عبر [BackupCubit] ويعرض النتيجة،
  /// مع منع تكرار التنفيذ أثناء انشغال عملية سابقة.
  Future<void> _runBackup(Future<BackupOutcome> Function() action) async {
    final cubit = context.read<BackupCubit>();
    if (cubit.state.isBusy) return;
    final outcome = await action();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(outcome.message)));
    if (outcome.popsSheet) Navigator.of(context).pop();
  }

  Future<void> _createBackup() =>
      _runBackup(context.read<BackupCubit>().createLocalBackup);

  Future<void> _restoreBackup() async {
    final cubit = context.read<BackupCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة نسخة احتياطية'),
        content: const Text(
          'سيتم استبدال قاعدة البيانات الحالية بأحدث نسخة احتياطية متاحة. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('استعادة نسخة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _runBackup(cubit.restoreLatestBackup);
  }

  Future<void> _exportBackupToDownloads() =>
      _runBackup(context.read<BackupCubit>().exportToDownloads);

  Future<void> _cloudSync() async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('المزامنة السحابية'),
        content: const Text(
          'ارفع أحدث نسخة من بياناتك إلى السحابة، أو اسحب آخر نسخة محفوظة واستعدها على هذا الجهاز.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('upload'),
            child: const Text('رفع نسخة'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('download'),
            child: const Text('سحب واستعادة'),
          ),
        ],
      ),
    );
    if (action == null || !mounted) return;

    final cubit = context.read<BackupCubit>();
    await _runBackup(
      action == 'upload' ? cubit.uploadToCloud : cubit.downloadAndRestoreFromCloud,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final canManageSettings =
        auth.admin?.has(UserPermission.manageSettings) ?? false;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text(
                'الإعدادات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 20),
            if (canManageSettings) ...[
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'اسم المطعم',
                  prefixIcon: Icon(Icons.restaurant_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف (اختياري)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _currency,
                decoration: const InputDecoration(
                  labelText: 'العملة',
                  prefixIcon: Icon(Icons.currency_exchange),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _tax,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'نسبة الضريبة % (اختياري)',
                  hintText: 'مثال: 14',
                  prefixIcon: Icon(Icons.percent),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ'),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 6),
            ],
            if (auth.isSuperAdmin) ...[
              _SheetAction(
                icon: Icons.admin_panel_settings_outlined,
                title: 'إدارة المستخدمين',
                subtitle: 'إضافة مستخدمين وتغيير الأدوار والصلاحيات',
                onTap: _openUsers,
              ),
              const SizedBox(height: 10),
            ],
            _SheetAction(
              icon: Icons.backup_outlined,
              title: 'نسخ احتياطي',
              subtitle: 'حفظ نسخة آمنة من بيانات المطعم الآن',
              onTap: _createBackup,
            ),
            const SizedBox(height: 10),
            _SheetAction(
              icon: Icons.restore_outlined,
              title: 'استعادة نسخة',
              subtitle: 'استرجاع آخر نسخة احتياطية محفوظة',
              onTap: _restoreBackup,
            ),
            const SizedBox(height: 10),
            _SheetAction(
              icon: Icons.download_outlined,
              title: 'تصدير للتنزيلات',
              subtitle: 'حفظ نسخة من البيانات في مجلد التنزيلات',
              onTap: _exportBackupToDownloads,
            ),
            const SizedBox(height: 10),
            _SheetAction(
              icon: Icons.cloud_upload_outlined,
              title: 'مزامنة سحابية',
              subtitle: 'رفع نسخة أو استعادتها عبر Supabase',
              onTap: _cloudSync,
            ),
            const SizedBox(height: 10),
            _SheetAction(
              icon: Icons.print,
              title: 'إعدادات الطابعة',
              subtitle: 'ربط طابعة حرارية وطباعة الفواتير',
              onTap: _openPrinterSettings,
            ),
            const SizedBox(height: 10),
            _SheetAction(
              icon: Icons.swap_horiz,
              title: 'تبديل الدور',
              subtitle: auth.admin?.role == UserRole.cashier
                  ? 'التحول إلى وضع الأدمن (يلزم كلمة السر)'
                  : 'التحول إلى وضع الكاشير (البيع فقط)',
              onTap: _switchRole,
            ),
            const SizedBox(height: 10),
            _SheetAction(
              icon: Icons.logout,
              title: 'تسجيل الخروج',
              subtitle: 'تسجيل خروج كـ ${auth.admin?.username ?? ''}',
              color: AppColors.error,
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: color ?? AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: color ?? AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

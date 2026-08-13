import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/services/backup_service.dart';
import '../../../domain/models/admin.dart';
import '../../auth/presentation/admin_login_dialog.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../auth/presentation/users_screen.dart';
import 'settings_cubit.dart';

/// نافذة إعدادات المتجر (اسم المتجر، الهاتف، العملة) + إدارة المستخدمين.
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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsCubit>().state.settings;
    _name = TextEditingController(text: settings.storeName);
    _phone = TextEditingController(text: settings.phone);
    _currency = TextEditingController(text: settings.currency);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _currency.dispose();
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
      await showAdminLoginDialog(context, switching: true);
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

  Future<void> _createBackup() async {
    try {
      final path = await BackupService.createBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم إنشاء نسخة احتياطية: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إنشاء النسخة الاحتياطية: $e')),
      );
    }
  }

  Future<void> _restoreBackup() async {
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

    try {
      final restored = await BackupService.restoreLatestBackup();
      if (!mounted) return;
      if (restored) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت استعادة النسخة الاحتياطية بنجاح.')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد نسخ احتياطية متاحة.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذرت الاستعادة: $e')));
    }
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
                  labelText: 'اسم المتجر',
                  prefixIcon: Icon(Icons.storefront_outlined),
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
              subtitle: 'حفظ نسخة آمنة من بيانات المتجر الآن',
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

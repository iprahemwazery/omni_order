import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import 'admin_login_dialog.dart';
import 'auth_cubit.dart';

/// شاشة اختيار الدور بعد نجاح تسجيل الدخول من Supabase:
/// يدخل المستخدم كأدمن (كل الصلاحيات) أو ككاشير (البيع فقط).
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _submitting = false;
  String? _error;

  Future<void> _selectCashier() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await context.read<AuthCubit>().loginAsCashier();
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  /// الدخول كأدمن: يُطلب اسم المستخدم وكلمة السر.
  /// لو مفيش أدمن خالص يظهر نموذج إنشاء جديد (زي الفكرة القديمة).
  Future<void> _promptAdminLogin() async {
    if (_submitting) return;
    await showAdminLoginDialog(context, switching: false);
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthCubit, String?>(
      (cubit) => cubit.state.pendingEmail,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('اختيار الدور')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  const Text(
                    'تم تسجيل الدخول بنجاح',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اختر طريقة الدخول: ${email ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _RoleCard(
                    title: 'دخول كأدمن',
                    subtitle: 'كل الصلاحيات وإدارة النظام',
                    icon: Icons.admin_panel_settings,
                    gradient: const [AppColors.primary, AppColors.primaryDark],
                    onTap: _promptAdminLogin,
                  ),
                  const SizedBox(height: 14),
                  _RoleCard(
                    title: 'دخول ككاشير',
                    subtitle: 'البيع وسجل المبيعات فقط',
                    icon: Icons.point_of_sale,
                    onTap: _selectCashier,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_submitting) ...[
                    const SizedBox(height: 20),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.gradient,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    final isGradient = gradient != null;
    return Material(
      color: isGradient ? null : AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient:
                isGradient ? LinearGradient(colors: gradient!) : null,
            borderRadius: BorderRadius.circular(18),
            border: isGradient ? null : Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isGradient
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFE8F1EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isGradient ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color:
                            isGradient ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isGradient
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: isGradient ? Colors.white70 : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

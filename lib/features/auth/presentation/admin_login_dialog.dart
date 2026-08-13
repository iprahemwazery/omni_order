import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import 'auth_cubit.dart';

/// نافذة الدخول كأدمن (أو إنشاء الأدمن الأساسي أول مرة).
///
/// تُستخدم من شاشة اختيار الدور (بعد تسجيل الدخول) ومن تبديل الدور
/// داخل التطبيق. لو `switching` صحيح يتم التبديل من كاشير إلى أدمن.
Future<void> showAdminLoginDialog(
  BuildContext context, {
  required bool switching,
}) async {
  final cubit = context.read<AuthCubit>();
  final needsCreation = switching
      ? await cubit.needsAdminAccount()
      : await cubit.needsAdminCreation();
  if (!context.mounted) return;

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool obscure = true;
  String? error;

  void submit(StateSetter setDialogState, BuildContext dialogContext) async {
    setDialogState(() => error = null);
    final result = switching
        ? await cubit.switchToAdmin(
            username: usernameController.text,
            password: passwordController.text,
            confirmPassword: confirmController.text,
          )
        : await cubit.loginAsAdmin(
            username: usernameController.text,
            password: passwordController.text,
            confirmPassword: confirmController.text,
          );
    if (!dialogContext.mounted) return;
    if (result != null) {
      setDialogState(() => error = result);
    } else {
      Navigator.of(dialogContext).pop();
    }
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return AlertDialog(
          title: Text(needsCreation ? 'إنشاء الأدمن الأساسي' : 'دخول الأدمن'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'أدخل اسم المستخدم وكلمة السر.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('admin_username'),
                  controller: usernameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    hintText: 'اكتب اسم المستخدم',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('admin_password'),
                  controller: passwordController,
                  obscureText: obscure,
                  textInputAction:
                      needsCreation ? TextInputAction.next : TextInputAction.done,
                  onSubmitted:
                      needsCreation ? null : (_) => submit(setDialogState, dialogContext),
                  decoration: InputDecoration(
                    labelText: 'كلمة السر',
                    hintText: 'اكتب كلمة السر',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setDialogState(() {
                        obscure = !obscure;
                      }),
                    ),
                  ),
                ),
                if (needsCreation) ...[
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('admin_confirm'),
                    controller: confirmController,
                    obscureText: obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submit(setDialogState, dialogContext),
                    decoration: const InputDecoration(
                      labelText: 'تأكيد كلمة السر',
                      hintText: 'أعد كتابة كلمة السر',
                      prefixIcon: Icon(Icons.verified_user_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => submit(setDialogState, dialogContext),
              child: Text(needsCreation ? 'إنشاء ودخول' : 'دخول'),
            ),
          ],
        );
      },
    ),
  );
}

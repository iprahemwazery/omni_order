import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/admin.dart';
import '../presentation/auth_cubit.dart';
import '../presentation/auth_state.dart';

/// إدارة المستخدمين: إضافة مستخدمين جدد، تغيير الأدوار، والحذف.
/// تظهر فقط للأدمن الأساسي.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().loadUsers();
  }

  Future<void> _addUser() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _UserFormDialog(),
    );
  }

  Future<void> _changeRole(Admin user) async {
    final role = await _pickRole(user);
    if (role == null || !mounted) return;
    final error = await context.read<AuthCubit>().updateRole(user, role);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<UserRole?> _pickRole(Admin user) async {
    return showModalBottomSheet<UserRole>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'تغيير دور المستخدم',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            for (final role in [UserRole.admin, UserRole.cashier]) ...[
              ListTile(
                leading: Icon(
                  role == UserRole.admin
                      ? Icons.admin_panel_settings_outlined
                      : Icons.person_outline,
                  color: AppColors.primary,
                ),
                title: Text(role.label),
                subtitle: Text(_roleDescription(role)),
                trailing: user.role == role
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : null,
                onTap: () => Navigator.of(context).pop(role),
              ),
              const Divider(height: 1),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _roleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'كل الصلاحيات عدا إدارة المستخدمين';
      case UserRole.cashier:
        return 'البيع وسجل المبيعات فقط';
      case UserRole.superAdmin:
        return '';
    }
  }

  Future<void> _deleteUser(Admin user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستخدم'),
        content: Text('هل تريد حذف المستخدم "${user.username}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error = await context.read<AuthCubit>().deleteUser(user);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المستخدمين')),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final current = state.admin;
          if (state.admins.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.admins.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = state.admins[index];
              final isSelf = user.id == current?.id;
              return _UserTile(
                user: user,
                isSelf: isSelf,
                onEditRole: user.isSuperAdmin ? null : () => _changeRole(user),
                onDelete: user.isSuperAdmin ? null : () => _deleteUser(user),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUser,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('إضافة مستخدم'),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.isSelf,
    this.onEditRole,
    this.onDelete,
  });

  final Admin user;
  final bool isSelf;
  final VoidCallback? onEditRole;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final primaryChar = user.username.isEmpty ? '؟' : user.username[0];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: user.isSuperAdmin
                ? AppColors.primary
                : const Color(0xFFE8F1EF),
            child: Text(
              primaryChar,
              style: TextStyle(
                color: user.isSuperAdmin ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.username,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      const Text(
                        '(أنت)',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                _RoleBadge(role: user.role),
              ],
            ),
          ),
          if (onEditRole != null)
            IconButton(
              onPressed: onEditRole,
              tooltip: 'تغيير الدور',
              icon: const Icon(Icons.swap_horiz),
            ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              tooltip: 'حذف',
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error),
            ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      UserRole.superAdmin => AppColors.primary,
      UserRole.admin => const Color(0xFF3D6B99),
      UserRole.cashier => const Color(0xFF8A6F3D),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// نافذة إضافة مستخدم جديد (أدمن أو كاشير).
class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog();

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  UserRole _role = UserRole.cashier;
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await context.read<AuthCubit>().createUser(
          username: _username.text,
          password: _password.text,
          confirmPassword: _confirm.text,
          role: _role,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _submitting = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة مستخدم'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _username,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'كلمة السر',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'تأكيد كلمة السر',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'الدور',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              items: [
                for (final role in [UserRole.admin, UserRole.cashier])
                  DropdownMenuItem(value: role, child: Text(role.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _role = value);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
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
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _save,
          child: Text(_submitting ? 'جارٍ الإضافة...' : 'إضافة'),
        ),
      ],
    );
  }
}

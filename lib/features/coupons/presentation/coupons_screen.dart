import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/coupon.dart';
import '../../../shared/widgets/screen_header.dart';
import 'coupons_cubit.dart';

class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'الكوبونات والخصومات',
            actions: [
              IconButton(
                onPressed: () => context.read<CouponsCubit>().init(),
                icon: const Icon(Icons.refresh),
                tooltip: 'تحديث',
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<CouponsCubit, CouponsState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.error != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.read<CouponsCubit>().init(),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }
                if (state.coupons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_offer_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لا يوجد كوبونات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'اضغط على + لإضافة كوبون جديد',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            label: 'إجمالي',
                            value: '${state.coupons.length}',
                            color: AppColors.primary,
                          ),
                          _StatItem(
                            label: 'نشط',
                            value: '${state.activeCount}',
                            color: AppColors.success,
                          ),
                          _StatItem(
                            label: 'غير نشط',
                            value:
                                '${state.coupons.length - state.activeCount}',
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.coupons.length,
                        itemBuilder: (context, index) =>
                            _CouponCard(coupon: state.coupons[index]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCouponDialog(context),
        tooltip: 'إضافة كوبون',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCouponDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    final minOrderCtrl = TextEditingController(text: '0');
    final maxUsesCtrl = TextEditingController(text: '0');
    CouponType discountType = CouponType.percent;
    DateTime? expiresAt;
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة كوبون جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'كود الكوبون',
                    hintText: 'مثلاً: RAMADAN25',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  autofocus: true,
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الوصف (اختياري)',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<CouponType>(
                        initialValue: discountType,
                        decoration: const InputDecoration(
                          labelText: 'نوع الخصم',
                        ),
                        items: CouponType.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.label),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => discountType = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: discountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'قيمة الخصم',
                          hintText: discountType == CouponType.percent
                              ? '25'
                              : '50',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minOrderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الحد الأدنى للطلب',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxUsesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'عدد الاستخدامات (0 = غير محدود)',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تاريخ الانتهاء'),
                  subtitle: Text(
                    expiresAt != null
                        ? '${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}'
                        : 'بدون انتهاء',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (expiresAt != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () =>
                              setDialogState(() => expiresAt = null),
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today, size: 20),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now().add(
                              const Duration(days: 30),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => expiresAt = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final code = codeCtrl.text.trim();
                if (code.isEmpty) return;
                final discountValue = double.tryParse(discountCtrl.text) ?? 0;
                if (discountValue <= 0) return;
                final result = await context.read<CouponsCubit>().addCoupon(
                  Coupon(
                    code: code,
                    description: descCtrl.text.trim(),
                    discountType: discountType,
                    discountValue: discountValue,
                    minOrder: double.tryParse(minOrderCtrl.text) ?? 0,
                    maxUses: int.tryParse(maxUsesCtrl.text) ?? 0,
                    expiresAt: expiresAt,
                  ),
                );
                if (result != null) {
                  setDialogState(() => errorText = result);
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.coupon});
  final Coupon coupon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    coupon.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.accent,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (coupon.isUsable
                                ? AppColors.success
                                : AppColors.textSecondary)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    coupon.isUsable ? 'نشط' : 'غير نشط',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: coupon.isUsable
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    final cubit = context.read<CouponsCubit>();
                    if (value == 'toggle') {
                      await cubit.toggleActive(coupon);
                    } else if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dctx) => AlertDialog(
                          title: const Text('حذف الكوبون'),
                          content: Text(
                            'هل أنت متأكد من حذف "${coupon.code}"؟',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dctx, false),
                              child: const Text('إلغاء'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(dctx, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.error,
                              ),
                              child: const Text('حذف'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await cubit.deleteCoupon(coupon.id!);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(coupon.isActive ? 'تعطيل' : 'تفعيل'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'حذف',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (coupon.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                coupon.description,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.discount_outlined,
                  label: coupon.discountType == CouponType.percent
                      ? '${coupon.discountValue.toStringAsFixed(0)}%'
                      : AppFormatters.money(coupon.discountValue),
                ),
                const SizedBox(width: 8),
                if (coupon.minOrder > 0)
                  _InfoChip(
                    icon: Icons.shopping_cart_outlined,
                    label: 'حد أدنى: ${AppFormatters.money(coupon.minOrder)}',
                  ),
                const SizedBox(width: 8),
                if (coupon.maxUses > 0)
                  _InfoChip(
                    icon: Icons.repeat,
                    label: '${coupon.usedCount}/${coupon.maxUses}',
                  ),
              ],
            ),
            if (coupon.expiresAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: coupon.isExpired
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    coupon.isExpired
                        ? 'منتهي الصلاحية'
                        : 'ينتهي: ${coupon.expiresAt!.day}/${coupon.expiresAt!.month}/${coupon.expiresAt!.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: coupon.isExpired
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

/// رسم بياني بسيط لاتجاه المبيعات اليومية (آخر 30 يومًا) بدون مكتبات خارجية.
class RevenueTrendChart extends StatelessWidget {
  const RevenueTrendChart({
    super.key,
    required this.values,
    required this.currency,
    this.days = const [],
  });

  /// إيراد كل يوم (من الأقدم للأحدث).
  final List<double> values;

  /// تاريخ كل يوم (اختياري — يُعرض كل أسبوع).
  final List<DateTime> days;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'لا توجد بيانات بعد',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final maxValue = values.fold<double>(0, (m, v) => v > m ? v : m);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الأعلى هذا الشهر: ${AppFormatters.money(maxValue, currency)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 4 + (values[i] / safeMax) * 110,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: values[i] > 0
                                ? AppColors.primary
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (i % 7 == 0 && i < days.length)
                          Text(
                            days[i].day.toString(),
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'آخر 30 يومًا',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
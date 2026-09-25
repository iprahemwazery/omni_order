import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// رأس شاشة داخلي يظهر داخل منطقة المحتوى في الهيكل الثابت
/// (بديل عن AppBar حتى لا تُفتح صفحة فوق صفحة).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ...actions,
        ],
      ),
    );
  }
}

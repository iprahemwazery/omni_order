import 'package:flutter/material.dart';

/// نافذة إضافة عميل (اسم + هاتف اختياري).
/// تُرجِع (الاسم، الهاتف) أو null عند الإلغاء.
Future<(String, String)?> showAddCustomerDialog(BuildContext context) {
  final name = TextEditingController();
  final phone = TextEditingController();
  return showDialog<(String, String)>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('إضافة عميل'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'اسم العميل *',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم الهاتف (اختياري)',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((name.text, phone.text)),
          child: const Text('إضافة'),
        ),
      ],
    ),
  );
}

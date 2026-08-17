import 'package:flutter/material.dart';

import '../../../../core/constants/payment_methods.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/sale.dart';
import '../../../../domain/models/sale_item.dart';
import '../../../../domain/models/store_settings.dart';

/// تصميم الفاتورة (شيك) بشكل ورقي مريح للعين.
class ReceiptView extends StatelessWidget {
  const ReceiptView({
    super.key,
    required this.sale,
    required this.items,
    required this.settings,
    this.customerName,
  });

  final Sale sale;
  final List<SaleItem> items;
  final StoreSettings settings;
  final String? customerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          const DashedDivider(),
          const SizedBox(height: 12),
          _buildInfo(context),
          const SizedBox(height: 12),
          const DashedDivider(),
          const SizedBox(height: 12),
          _buildItems(context),
          const SizedBox(height: 12),
          const DashedDivider(),
          const SizedBox(height: 14),
          _buildTotal(context),
          const SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F1EF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.storefront,
            color: AppColors.primary,
            size: 30,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          settings.storeName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        if (settings.phone.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            settings.phone,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1EF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'فاتورة بيع',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoCell(label: 'رقم الفاتورة', value: '#${sale.id ?? 0}'),
            ),
            Expanded(
              child: _InfoCell(
                label: 'التاريخ',
                value: AppFormatters.date(sale.createdAt),
              ),
            ),
            Expanded(
              child: _InfoCell(
                label: 'الوقت',
                value: AppFormatters.time(sale.createdAt),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _InfoChip(icon: Icons.payment, text: sale.paymentMethod),
            if (customerName != null) ...[
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.person_outline, text: customerName!),
            ],
            if (sale.cashierName.isNotEmpty) ...[
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.badge_outlined, text: sale.cashierName),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildItems(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _ItemRow(item: items[i], settings: settings),
        ],
      ],
    );
  }

  Widget _buildTotal(BuildContext context) {
    final subtotal = sale.total + sale.discount;
    return Column(
      children: [
        _TotalLine(
          label: 'الإجمالي',
          value: AppFormatters.money(subtotal, settings.currency),
        ),
        if (sale.discount > 0) ...[
          const SizedBox(height: 6),
          _TotalLine(
            label: 'الخصم',
            value: AppFormatters.money(sale.discount, settings.currency),
            highlight: AppColors.error,
          ),
        ],
        if (sale.taxAmount > 0) ...[
          const SizedBox(height: 6),
          _TotalLine(
            label: 'قيمة الضريبة (${AppFormatters.percent(sale.taxRate)})',
            value: AppFormatters.money(sale.taxAmount, settings.currency),
          ),
        ],
        const SizedBox(height: 10),
        const DashedDivider(),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'الصافي',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                AppFormatters.money(sale.total, settings.currency),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        if (sale.taxAmount > 0) ...[
          const SizedBox(height: 2),
          const Text(
            'شامل ضريبة القيمة المضافة',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
        if (sale.paymentMethod == PaymentMethod.mixed) ...[
          const SizedBox(height: 8),
          _TotalLine(
            label: 'نقدًا',
            value: AppFormatters.money(
              sale.total - sale.cardAmount,
              settings.currency,
            ),
          ),
          const SizedBox(height: 4),
          _TotalLine(
            label: 'بالشبكة',
            value: AppFormatters.money(sale.cardAmount, settings.currency),
            highlight: AppColors.primary,
          ),
        ] else if (sale.amountTendered > sale.total) ...[
          const SizedBox(height: 8),
          _TotalLine(
            label: 'المدفوع',
            value: AppFormatters.money(
              sale.amountTendered,
              settings.currency,
            ),
          ),
          const SizedBox(height: 4),
          _TotalLine(
            label: 'الباقي للعميل',
            value: AppFormatters.money(sale.changeDue, settings.currency),
            highlight: AppColors.success,
          ),
        ],
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            AppFormatters.amountInWords(sale.total, settings.currency),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (sale.note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'ملاحظة: ${sale.note}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (sale.paymentMethod == PaymentMethod.deferred) ...[
          const SizedBox(height: 8),
          Text(
            customerName == null
                ? 'تم تسجيل المبلغ كدين'
                : 'تم تسجيل المبلغ دينًا على $customerName',
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          'عدد الأصناف: ${sale.itemsCount}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const DashedDivider(),
        const SizedBox(height: 12),
        const Text(
          'شكرًا لزيارتكم، نتمنى لكم يومًا سعيدًا 🌟',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'نظام أومني أوردر لإدارة المحلات',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.border, fontSize: 10),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.settings});

  final SaleItem item;
  final StoreSettings settings;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                '${AppFormatters.quantity(item.quantity, '')} × ${AppFormatters.money(item.price, settings.currency)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          AppFormatters.money(item.subtotal, settings.currency),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ],
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({required this.label, required this.value, this.highlight});

  final String label;
  final String value;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: highlight ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// خط متقطع مريح للعين يفصل أقسام الفاتورة.
class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedPainter(),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.4;
    const dashWidth = 6.0;
    const dashSpace = 5.0;
    var startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset((startX + dashWidth).clamp(0, size.width), 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

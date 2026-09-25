import 'package:flutter/material.dart';

/// إدارة اللغات المتعددة (عربي + إنجليزي).
class AppLocalizations {
  AppLocalizations._();
  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static Locale? _locale;

  static void setLocale(Locale locale) {
    _locale = locale;
  }

  static Locale get locale => _locale ?? const Locale('ar');

  static bool get isArabic => locale.languageCode == 'ar';

  bool get isRtl => isArabic;

  // ── Navigation ──
  String get home => isArabic ? 'الرئيسية' : 'Home';
  String get settings => isArabic ? 'الإعدادات' : 'Settings';
  String get reports => isArabic ? 'التقارير' : 'Reports';
  String get sales => isArabic ? 'المبيعات' : 'Sales';

  // ── Actions ──
  String get save => isArabic ? 'حفظ' : 'Save';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get delete => isArabic ? 'حذف' : 'Delete';
  String get edit => isArabic ? 'تعديل' : 'Edit';
  String get add => isArabic ? 'إضافة' : 'Add';
  String get confirm => isArabic ? 'تأكيد' : 'Confirm';
  String get search => isArabic ? 'بحث' : 'Search';
  String get refresh => isArabic ? 'تحديث' : 'Refresh';

  // ── Products ──
  String get products => isArabic ? 'الأصناف' : 'Products';
  String get productName => isArabic ? 'اسم الصنف' : 'Product Name';
  String get price => isArabic ? 'السعر' : 'Price';
  String get stock => isArabic ? 'المخزون' : 'Stock';
  String get category => isArabic ? 'التصنيف' : 'Category';
  String get noProducts => isArabic ? 'لا توجد أصناف' : 'No Products';

  // ── Sales ──
  String get cart => isArabic ? 'السلة' : 'Cart';
  String get checkout => isArabic ? 'الدفع' : 'Checkout';
  String get total => isArabic ? 'الإجمالي' : 'Total';
  String get subtotal => isArabic ? 'المجموع' : 'Subtotal';
  String get discount => isArabic ? 'الخصم' : 'Discount';
  String get tax => isArabic ? 'الضريبة' : 'Tax';
  String get tip => isArabic ? 'البقشيش' : 'Tip';
  String get payment => isArabic ? 'الدفع' : 'Payment';
  String get cash => isArabic ? 'نقدي' : 'Cash';
  String get card => isArabic ? 'شبكة' : 'Card';
  String get splitBill => isArabic ? 'تقسيم الفاتورة' : 'Split Bill';

  // ── Orders ──
  String get orders => isArabic ? 'الطلبات' : 'Orders';
  String get kitchen => isArabic ? 'المطبخ' : 'Kitchen';
  String get pending => isArabic ? 'قيد الانتظار' : 'Pending';
  String get preparing => isArabic ? 'يُحضّر' : 'Preparing';
  String get ready => isArabic ? 'جاهز' : 'Ready';
  String get served => isArabic ? 'تم التقديم' : 'Served';

  // ── Tables ──
  String get tables => isArabic ? 'الترابيزات' : 'Tables';
  String get available => isArabic ? 'متاحة' : 'Available';
  String get occupied => isArabic ? 'مشغولة' : 'Occupied';
  String get reserved => isArabic ? 'محجوزة' : 'Reserved';

  // ── Reservations ──
  String get reservations => isArabic ? 'الحجوزات' : 'Reservations';
  String get customerName => isArabic ? 'اسم العميل' : 'Customer Name';
  String get phone => isArabic ? 'رقم الهاتف' : 'Phone Number';
  String get partySize => isArabic ? 'عدد الأشخاص' : 'Party Size';

  // ── Queue ──
  String get queue => isArabic ? 'قائمة الانتظار' : 'Queue';
  String get waiting => isArabic ? 'ينتظر' : 'Waiting';
  String get seating => isArabic ? 'يجلس' : 'Seating';

  // ── Reports ──
  String get dailyReport => isArabic ? 'تقرير يومي' : 'Daily Report';
  String get monthlyReport => isArabic ? 'تقرير شهري' : 'Monthly Report';
  String get taxReport => isArabic ? 'تقرير ضريبي' : 'Tax Report';
  String get profit => isArabic ? 'الربح' : 'Profit';

  // ── Employees ──
  String get employees => isArabic ? 'الموظفون' : 'Employees';
  String get name => isArabic ? 'الاسم' : 'Name';
  String get role => isArabic ? 'الدور' : 'Role';

  // ── Messages ──
  String get noData => isArabic ? 'لا توجد بيانات' : 'No Data';
  String get error => isArabic ? 'حدث خطأ' : 'Error';
  String get success => isArabic ? 'تم بنجاح' : 'Success';
  String get loading => isArabic ? 'جارٍ التحميل...' : 'Loading...';
  String get confirmDelete => isArabic ? 'هل أنت متأكد من الحذف؟' : 'Are you sure you want to delete?';

  // ── Waiter ──
  String get waiterOrder => isArabic ? 'طلب من الترابيزة' : 'Waiter Order';
  String get selectTable => isArabic ? 'اختر التربيزة' : 'Select Table';
  String get sendOrder => isArabic ? 'إرسال الطلب' : 'Send Order';

  // ── Receipt ──
  String get receipt => isArabic ? 'الفاتورة' : 'Receipt';
  String get invoice => isArabic ? 'رقم الفاتورة' : 'Invoice Number';
  String get date => isArabic ? 'التاريخ' : 'Date';
  String get thankYou => isArabic ? 'شكراً لزيارتكم' : 'Thank you for your visit';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations.setLocale(locale);
    return AppLocalizations._();
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

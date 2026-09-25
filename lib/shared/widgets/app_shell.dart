import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/models/admin.dart';
import '../../features/auth/presentation/auth_cubit.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/coupons/presentation/coupons_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/delivery/presentation/delivery_screen.dart';
import '../../features/employees/presentation/employees_screen.dart';
import '../../features/expenses/presentation/expenses_screen.dart';
import '../../features/halls/presentation/halls_screen.dart';
import '../../features/kitchen/presentation/kitchen_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/queue/presentation/queue_screen.dart';
import '../../features/rider_balance/presentation/rider_balance_screen.dart';
import '../../features/recipes/presentation/recipes_screen.dart';
import '../../features/reservations/presentation/reservations_screen.dart';
import '../../features/sales/presentation/deferred_sales_screen.dart';
import '../../features/sales/presentation/reports_screen.dart';
import '../../features/sales/presentation/sales_screen.dart';
import '../../features/sales/presentation/shift_screen.dart';
import '../../features/settings/presentation/settings_cubit.dart';
import '../../features/settings/presentation/settings_sheet.dart';
import '../../features/suppliers/presentation/suppliers_screen.dart';
import '../../features/tables/presentation/tables_screen.dart';
import '../../features/waiter/presentation/waiter_order_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import 'shell_section.dart';

export 'shell_section.dart';

class _SectionSpec {
  const _SectionSpec(
    this.section,
    this.group,
    this.title,
    this.icon, [
    this.permission,
  ]);

  final ShellSection section;
  final String group;
  final String title;
  final IconData icon;
  final UserPermission? permission;

  bool visibleFor(Admin? admin) {
    if (permission == null) return true;
    return admin != null && admin.has(permission!);
  }
}

const List<_SectionSpec> _kSections = [
  // نقاط البيع
  _SectionSpec(
    ShellSection.sales,
    'نقطة البيع',
    'طلب جديد',
    Icons.add_shopping_cart_outlined,
    UserPermission.makeSales,
  ),
  _SectionSpec(
    ShellSection.delivery,
    'نقطة البيع',
    'أوردر الدليفري',
    Icons.delivery_dining_outlined,
    UserPermission.makeSales,
  ),
  // الطلبات
  _SectionSpec(
    ShellSection.waiterOrders,
    'الطلبات',
    'طلب من الترابيزة',
    Icons.table_restaurant_outlined,
    UserPermission.makeSales,
  ),
  _SectionSpec(
    ShellSection.kitchen,
    'الطلبات',
    'المطبخ',
    Icons.kitchen_outlined,
  ),
  _SectionSpec(
    ShellSection.ordersHistory,
    'الطلبات',
    'الطلبات السابقة',
    Icons.history_outlined,
    UserPermission.viewSales,
  ),
  _SectionSpec(
    ShellSection.deferredSales,
    'الطلبات',
    'الفواتير الآجلة',
    Icons.account_balance_wallet_outlined,
    UserPermission.viewSales,
  ),
  // المخزون والمشتريات
  _SectionSpec(
    ShellSection.products,
    'المخزون والمشتريات',
    'المنيو',
    Icons.restaurant_menu,
    UserPermission.manageProducts,
  ),
  _SectionSpec(
    ShellSection.recipes,
    'المخزون والمشتريات',
    'الوصفات',
    Icons.menu_book_outlined,
    UserPermission.makeSales,
  ),
  _SectionSpec(
    ShellSection.suppliers,
    'المخزون والمشتريات',
    'الموردين',
    Icons.local_shipping_outlined,
    UserPermission.manageExpenses,
  ),
  // خدمات العملاء
  _SectionSpec(
    ShellSection.customers,
    'خدمات العملاء',
    'العملاء',
    Icons.people_outline,
    UserPermission.viewSales,
  ),
  _SectionSpec(
    ShellSection.reservations,
    'خدمات العملاء',
    'الحجوزات',
    Icons.event_note_outlined,
    UserPermission.viewSales,
  ),
  _SectionSpec(
    ShellSection.queue,
    'خدمات العملاء',
    'قائمة الانتظار',
    Icons.queue_outlined,
    UserPermission.viewSales,
  ),
  // الصالات والترابيزات
  _SectionSpec(
    ShellSection.halls,
    'الصالات والترابيزات',
    'الصالات',
    Icons.room_service_outlined,
    UserPermission.manageHalls,
  ),
  _SectionSpec(
    ShellSection.tables,
    'الصالات والترابيزات',
    'الترابيزات',
    Icons.table_restaurant_outlined,
    UserPermission.manageTables,
  ),
  // الحسابات والتقارير
  _SectionSpec(
    ShellSection.shift,
    'الحسابات والتقارير',
    'الوردية',
    Icons.event_note_outlined,
    UserPermission.viewSales,
  ),
  _SectionSpec(
    ShellSection.reports,
    'الحسابات والتقارير',
    'التقارير',
    Icons.bar_chart,
    UserPermission.viewReports,
  ),
  _SectionSpec(
    ShellSection.expenses,
    'الحسابات والتقارير',
    'المصروفات',
    Icons.request_quote_outlined,
    UserPermission.manageExpenses,
  ),
  _SectionSpec(
    ShellSection.coupons,
    'الحسابات والتقارير',
    'الكوبونات',
    Icons.local_offer_outlined,
    UserPermission.manageExpenses,
  ),
  _SectionSpec(
    ShellSection.riderBalance,
    'الحسابات والتقارير',
    'مندوبين التوصيل',
    Icons.account_balance_wallet_outlined,
    UserPermission.manageEmployees,
  ),
  _SectionSpec(
    ShellSection.employees,
    'الحسابات والتقارير',
    'الموظفين',
    Icons.people_outline,
    UserPermission.manageEmployees,
  ),
];

_SectionSpec? _specOf(ShellSection section) {
  for (final spec in _kSections) {
    if (spec.section == section) return spec;
  }
  return null;
}

/// هيكل التطبيق الثابت:
/// - القائمة الجانبية لا تتغير أبدًا.
/// - الشريط العلوي لا يتغير أبدًا.
/// - عند اختيار أي ميزة يتغير **المحتوى فقط** داخل نفس الصفحة
///   (IndexedStack يحافظ على حالة كل شاشة، ولا يُفتح أي route فوق الآخر).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  ShellSection _selected = ShellSection.dashboard;

  /// الأقسام التي فُتحت من قبل؛ تُبنى مرة واحدة وتبقى حية في IndexedStack
  /// حتى لا تفقد شاشة مثل "طلب من الترابيزة" سلتها عند التنقل.
  final List<ShellSection> _created = [];

  Admin? _cachedForAdmin;

  bool _visible(ShellSection section, Admin? admin) {
    if (section == ShellSection.dashboard) return true;
    return _specOf(section)?.visibleFor(admin) ?? false;
  }

  void _select(ShellSection section) {
    if (!_visible(section, context.read<AuthCubit>().state.admin)) return;
    setState(() => _selected = section);
  }

  Widget _buildSection(BuildContext context, ShellSection section) {
    switch (section) {
      case ShellSection.dashboard:
        return DashboardView(onSectionSelected: _select);
      case ShellSection.sales:
        return const SalesScreen();
      case ShellSection.delivery:
        return const DeliveryScreen();
      case ShellSection.waiterOrders:
        return const WaiterOrderScreen();
      case ShellSection.kitchen:
        return const KitchenScreen();
      case ShellSection.ordersHistory:
        return const OrdersHistoryScreen();
      case ShellSection.deferredSales:
        return const DeferredSalesScreen();
      case ShellSection.shift:
        return const ShiftScreen();
      case ShellSection.reports:
        return const ReportsScreen();
      case ShellSection.products:
        return const ProductsScreen();
      case ShellSection.recipes:
        return const RecipesScreen();
      case ShellSection.suppliers:
        return const SuppliersScreen();
      case ShellSection.customers:
        return const CustomersScreen();
      case ShellSection.reservations:
        return const ReservationsScreen();
      case ShellSection.queue:
        return const QueueScreen();
      case ShellSection.halls:
        return const HallsScreen();
      case ShellSection.tables:
        return const TablesScreen();
      case ShellSection.expenses:
        return const ExpensesScreen();
      case ShellSection.coupons:
        return const CouponsScreen();
      case ShellSection.riderBalance:
        return const RiderBalanceScreen();
      case ShellSection.employees:
        return const EmployeesScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        final admin = auth.admin;

        // إذا تغيّر المستخدم/الدور نعيد بناء الأقسام المفتوحة من الصفر
        // (صلاحيات جديدة = قائمة جديدة).
        if (_cachedForAdmin != admin) {
          _cachedForAdmin = admin;
          _created.clear();
          if (_selected != ShellSection.dashboard &&
              !_visible(_selected, admin)) {
            _selected = ShellSection.dashboard;
          }
        }
        if (!_created.contains(_selected)) {
          _created.add(_selected);
        }

        final storeName = context
            .watch<SettingsCubit>()
            .state
            .settings
            .storeName;

        return LayoutBuilder(
          builder: (context, constraints) {
            // على الشاشات العريضة تبقى القائمة ظاهرة دائمًا،
            // وعلى الضيقة تصبح Drawer تُفتح من زر ☰ في البار الثابت.
            final isWide = constraints.maxWidth >= 1000;

            final content = Expanded(
              child: IndexedStack(
                index: _created.indexOf(_selected),
                children: [
                  for (final section in _created)
                    KeyedSubtree(
                      key: ValueKey(section),
                      child: _buildSection(context, section),
                    ),
                ],
              ),
            );

            final topBar = _TopBar(storeName: storeName, showMenu: !isWide);

            if (isWide) {
              return Scaffold(
                body: SafeArea(
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      _SideRail(
                        admin: admin,
                        selected: _selected,
                        onSelect: _select,
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: Column(children: [topBar, content])),
                    ],
                  ),
                ),
              );
            }

            return Scaffold(
              drawer: _SideRail(
                admin: admin,
                selected: _selected,
                onSelect: (section) {
                  Navigator.of(context).pop(); // إغلاق الـ Drawer
                  _select(section);
                },
              ),
              body: SafeArea(child: Column(children: [topBar, content])),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// الشريط العلوي الثابت
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.storeName, required this.showMenu});

  final String storeName;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          if (showMenu)
            Builder(
              builder: (innerContext) => IconButton(
                onPressed: () => Scaffold.of(innerContext).openDrawer(),
                tooltip: 'الميزات',
                icon: const Icon(Icons.menu, size: 22),
              ),
            ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.restaurant_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              storeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => showSettingsSheet(context),
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.settings_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// القائمة الجانبية الثابتة
// ---------------------------------------------------------------------------

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.admin,
    required this.selected,
    required this.onSelect,
  });

  final Admin? admin;
  final ShellSection selected;
  final ValueChanged<ShellSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final inDrawer = Scaffold.maybeOf(context)?.hasDrawer ?? false;
    final width = inDrawer ? null : 240.0;

    final header = Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ocean Catch',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'كل الميزات',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final menuList = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NavItem(
            label: 'الرئيسية',
            icon: Icons.home_outlined,
            selected: selected == ShellSection.dashboard,
            onTap: () => onSelect(ShellSection.dashboard),
          ),
          for (final group in _groupedSections()) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                group.title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final item in group.items)
              _NavItem(
                label: item.title,
                icon: item.icon,
                selected: selected == item.section,
                onTap: () => onSelect(item.section),
              ),
          ],
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Ocean Catch - نظام إدارة المطاعم',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );

    return Container(
      width: width,
      color: AppColors.surface,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Expanded(child: menuList),
          ],
        ),
      ),
    );
  }

  List<_Group> _groupedSections() {
    final groups = <String, List<_Item>>{};
    for (final spec in _kSections) {
      if (!spec.visibleFor(admin)) continue;
      (groups[spec.group] ??= []).add(
        _Item(spec.section, spec.title, spec.icon),
      );
    }
    return [for (final e in groups.entries) _Group(e.key, e.value)];
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary.withValues(alpha: 0.14) : null;
    final fg = selected ? AppColors.primary : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(icon, size: 19, color: fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.chevron_left,
                    size: 16,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Item {
  const _Item(this.section, this.title, this.icon);
  final ShellSection section;
  final String title;
  final IconData icon;
}

class _Group {
  const _Group(this.title, this.items);
  final String title;
  final List<_Item> items;
}

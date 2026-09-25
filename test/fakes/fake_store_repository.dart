import 'package:omni_order/core/constants/payment_methods.dart';
import 'package:omni_order/domain/models/admin.dart';
import 'package:omni_order/domain/models/category.dart';
import 'package:omni_order/domain/models/coupon.dart';
import 'package:omni_order/domain/models/customer.dart';
import 'package:omni_order/domain/models/employee.dart';
import 'package:omni_order/domain/models/employee_advance.dart';
import 'package:omni_order/domain/models/expense.dart';
import 'package:omni_order/domain/models/hall.dart';
import 'package:omni_order/domain/models/held_cart.dart';
import 'package:omni_order/domain/models/order.dart';
import 'package:omni_order/domain/models/order_item.dart';
import 'package:omni_order/domain/models/order_status_history.dart';
import 'package:omni_order/domain/models/product.dart';
import 'package:omni_order/domain/models/purchase.dart';
import 'package:omni_order/domain/models/purchase_item.dart';
import 'package:omni_order/domain/models/queue_entry.dart';
import 'package:omni_order/domain/models/recipe.dart';
import 'package:omni_order/domain/models/reservation.dart';
import 'package:omni_order/domain/models/restaurant_table.dart';
import 'package:omni_order/domain/models/rider_transaction.dart';
import 'package:omni_order/domain/models/sale.dart';
import 'package:omni_order/domain/models/sale_item.dart';
import 'package:omni_order/domain/models/shift.dart';
import 'package:omni_order/domain/models/store_settings.dart';
import 'package:omni_order/domain/models/summaries.dart';
import 'package:omni_order/domain/models/supplier.dart';
import 'package:omni_order/domain/models/supplier_payment.dart';
import 'package:omni_order/domain/repositories/store_repository.dart';

/// مستودع تجريبي بالذاكرة للاختبارات (بدون SQLite).
class FakeStoreRepository implements StoreRepository {
  final List<Admin> admins = [];
  final List<Product> products = [];
  final List<Category> categories = [];
  final List<Expense> expenses = [];
  final List<Sale> sales = [];
  final Map<int, List<SaleItem>> saleItems = {};
  final Map<String, String> settings = {};
  final List<Shift> shifts = [];
  final List<HeldCart> heldCarts = [];
  final Map<int, List<HeldCartItem>> heldCartItems = {};
  final List<OrderStatusHistory> orderStatusHistory = [];

  // =====Restaurant entities=====
  final List<Hall> halls = [];
  final List<RestaurantTable> tables = [];
  final List<Employee> employees = [];
  final List<RestaurantOrder> orders = [];
  final Map<int, List<OrderItem>> orderItems = {};

  int _nextShiftId = 1;
  int _nextHeldCartId = 1;
  int _nextHeldCartItemId = 1;

  int _nextProductId = 1;
  int _nextCategoryId = 1;
  int _nextExpenseId = 1;
  int _nextSaleId = 1;
  int _nextAdminId = 1;
  int _nextHallId = 1;
  int _nextTableId = 1;
  int _nextEmployeeId = 1;
  int _nextOrderId = 1;
  int _nextOrderItemId = 1;

  @override
  Future<void> init() async {}

  // ---- الأدمن ----

  @override
  Future<List<Admin>> getAdmins() async => List.of(admins);

  @override
  Future<Admin?> getAdminByUsername(String username) async {
    for (final admin in admins) {
      if (admin.username == username) return admin;
    }
    return null;
  }

  @override
  Future<int> addAdmin(Admin admin) async {
    final id = _nextAdminId++;
    admins.add(admin.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateAdmin(Admin admin) async {
    final index = admins.indexWhere((a) => a.id == admin.id);
    if (index >= 0) admins[index] = admin;
  }

  @override
  Future<void> deleteAdmin(int id) async {
    admins.removeWhere((a) => a.id == id);
  }

  // ---- المنتجات ----

  @override
  Future<List<Product>> getProducts() async => List.of(products);

  @override
  Future<int> addProduct(Product product) async {
    final id = _nextProductId++;
    final created = product.copyWith(id: id);
    products.insert(0, created);
    return id;
  }

  @override
  Future<void> updateProduct(Product product) async {
    final index = products.indexWhere((p) => p.id == product.id);
    if (index >= 0) products[index] = product;
  }

  @override
  Future<void> deleteProduct(int id) async {
    products.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> updateStock(int productId, double delta) async {
    final index = products.indexWhere((p) => p.id == productId);
    if (index >= 0) {
      final stock = (products[index].stock + delta)
          .clamp(0, double.infinity)
          .toDouble();
      products[index] = products[index].copyWith(stock: stock);
    }
  }

  // ---- التصنيفات ----

  @override
  Future<List<Category>> getCategories() async => List.of(categories);

  @override
  Future<int> addCategory(Category category) async {
    final id = _nextCategoryId++;
    categories.add(category.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateCategory(Category category) async {
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index >= 0) categories[index] = category;
  }

  @override
  Future<void> deleteCategory(int id) async {
    categories.removeWhere((c) => c.id == id);
    for (var i = 0; i < products.length; i++) {
      if (products[i].categoryId == id) {
        products[i] = products[i].copyWith(categoryId: null);
      }
    }
  }

  // ---- المصروفات ----

  @override
  Future<List<Expense>> getExpenses({int? limit}) async {
    final list = List.of(expenses);
    return limit != null && list.length > limit ? list.sublist(0, limit) : list;
  }

  @override
  Future<int> addExpense(Expense expense) async {
    final id = _nextExpenseId++;
    expenses.insert(0, expense.copyWith(id: id));
    return id;
  }

  @override
  Future<void> deleteExpense(int id) async {
    expenses.removeWhere((e) => e.id == id);
  }

  // ---- المبيعات ----

  @override
  Future<List<Sale>> getSales({int? limit}) async {
    final list = List.of(sales);
    return limit != null && list.length > limit ? list.sublist(0, limit) : list;
  }

  @override
  Future<Sale?> getSale(int id) async {
    for (final sale in sales) {
      if (sale.id == id) return sale;
    }
    return null;
  }

  @override
  Future<List<SaleItem>> getSaleItems(int saleId) async =>
      List.of(saleItems[saleId] ?? const []);

  static String _dayKey(DateTime day) =>
      DateTime(day.year, day.month, day.day).toIso8601String();

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Future<SalesTotals> getSalesTotals() async {
    final now = DateTime.now();
    double cashToday = 0, deferredToday = 0;
    double cashMonth = 0, deferredMonth = 0;
    double totalCash = 0, totalDeferred = 0;
    int countToday = 0, countMonth = 0, countTotal = 0;
    for (final sale in sales) {
      if (sale.refunded) continue;
      final isCash = sale.paymentMethod != 'آجل';
      final isToday = _sameDay(sale.createdAt, now);
      final isMonth =
          sale.createdAt.year == now.year && sale.createdAt.month == now.month;
      if (isCash) {
        totalCash += sale.total;
        if (isMonth) cashMonth += sale.total;
        if (isToday) cashToday += sale.total;
      } else {
        totalDeferred += sale.total;
        if (isMonth) deferredMonth += sale.total;
        if (isToday) deferredToday += sale.total;
      }
      countTotal++;
      if (isMonth) countMonth++;
      if (isToday) countToday++;
    }
    return SalesTotals(
      cashToday: cashToday,
      deferredToday: deferredToday,
      cashMonth: cashMonth,
      deferredMonth: deferredMonth,
      totalCash: totalCash,
      totalDeferred: totalDeferred,
      countToday: countToday,
      countMonth: countMonth,
      countTotal: countTotal,
    );
  }

  @override
  Future<List<DailySaleTotals>> getDailySalesTotals(int days) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days - 1));
    final totals = <String, DailySaleTotals>{};
    for (final sale in sales) {
      if (sale.refunded || sale.createdAt.isBefore(start)) continue;
      final key = _dayKey(sale.createdAt);
      final day = DateTime(
        sale.createdAt.year,
        sale.createdAt.month,
        sale.createdAt.day,
      );
      final existing = totals.putIfAbsent(key, () => DailySaleTotals(day: day));
      if (sale.paymentMethod == 'آجل') {
        totals[key] = DailySaleTotals(
          day: day,
          cash: existing.cash,
          deferred: existing.deferred + sale.total,
        );
      } else {
        totals[key] = DailySaleTotals(
          day: day,
          cash: existing.cash + sale.total,
          deferred: existing.deferred,
        );
      }
    }
    final list = totals.values.toList()..sort((a, b) => a.day.compareTo(b.day));
    return list;
  }

  @override
  Future<List<Sale>> getSalesOn(DateTime day) async => [
    for (final sale in sales)
      if (_sameDay(sale.createdAt, day)) sale,
  ];

  @override
  Future<List<DayHistoryEntry>> getDayHistory() async {
    final today = DateTime.now();
    final byDay = <DateTime, DayHistoryEntry>{};
    for (final sale in sales) {
      if (_sameDay(sale.createdAt, today)) continue;
      final key = DateTime(
        sale.createdAt.year,
        sale.createdAt.month,
        sale.createdAt.day,
      );
      final existing = byDay[key];
      byDay[key] = DayHistoryEntry(
        day: key,
        salesTotal: (existing?.salesTotal ?? 0) + sale.total,
        salesCount: (existing?.salesCount ?? 0) + 1,
        expensesTotal: existing?.expensesTotal ?? 0,
        expensesCount: existing?.expensesCount ?? 0,
      );
    }
    for (final expense in expenses) {
      if (_sameDay(expense.createdAt, today)) continue;
      final key = DateTime(
        expense.createdAt.year,
        expense.createdAt.month,
        expense.createdAt.day,
      );
      final existing = byDay[key];
      byDay[key] = DayHistoryEntry(
        day: key,
        salesTotal: existing?.salesTotal ?? 0,
        salesCount: existing?.salesCount ?? 0,
        expensesTotal: (existing?.expensesTotal ?? 0) + expense.amount,
        expensesCount: (existing?.expensesCount ?? 0) + 1,
      );
    }
    final list = byDay.values.toList()..sort((a, b) => b.day.compareTo(a.day));
    return list;
  }

  @override
  Future<ExpenseTotals> getExpenseTotals() async {
    final now = DateTime.now();
    double today = 0, month = 0, total = 0;
    int count = 0;
    for (final expense in expenses) {
      total += expense.amount;
      count++;
      if (expense.createdAt.year == now.year &&
          expense.createdAt.month == now.month) {
        month += expense.amount;
      }
      if (_sameDay(expense.createdAt, now)) today += expense.amount;
    }
    return ExpenseTotals(
      today: today,
      month: month,
      total: total,
      count: count,
    );
  }

  @override
  Future<List<Expense>> getExpensesOn(DateTime day) async => [
    for (final expense in expenses)
      if (_sameDay(expense.createdAt, day)) expense,
  ];

  @override
  Future<ProfitAnalytics> getProfitAnalytics() async {
    double cashRevenue = 0;
    double cogs = 0;
    for (final sale in sales) {
      if (sale.refunded || sale.paymentMethod == 'آجل') continue;
      cashRevenue += sale.total;
      for (final item in saleItems[sale.id] ?? const []) {
        cogs += item.costPrice * item.quantity;
      }
    }
    return ProfitAnalytics(cashRevenue: cashRevenue, cogs: cogs);
  }

  @override
  Future<List<TopProduct>> topProducts({int limit = 5}) async {
    final totals = <String, ({double qty, double revenue})>{};
    for (final items in saleItems.values) {
      for (final item in items) {
        final current = totals[item.name];
        totals[item.name] = (
          qty: (current?.qty ?? 0) + item.quantity,
          revenue: (current?.revenue ?? 0) + item.subtotal,
        );
      }
    }
    final ranked = totals.entries.toList()
      ..sort((a, b) => b.value.qty.compareTo(a.value.qty));
    return [
      for (final entry in ranked.take(limit))
        (
          name: entry.key,
          quantity: entry.value.qty,
          revenue: entry.value.revenue,
        ),
    ];
  }

  @override
  Future<int> createSale({
    required Sale sale,
    required List<SaleItem> items,
  }) async {
    final id = _nextSaleId++;
    final created = Sale(
      id: id,
      total: sale.total,
      itemsCount: sale.itemsCount,
      discount: sale.discount,
      taxRate: sale.taxRate,
      taxAmount: sale.taxAmount,
      paymentMethod: sale.paymentMethod,
      customerId: sale.customerId,
      cashierName: sale.cashierName,
      note: sale.note,
      refunded: sale.refunded,
      amountTendered: sale.amountTendered,
      cardAmount: sale.cardAmount,
      orderType: sale.orderType,
      tableName: sale.tableName,
      customerName: sale.customerName,
      createdAt: sale.createdAt,
      invoiceNumber: sale.invoiceNumber,
    );
    sales.insert(0, created);
    saleItems[id] = [
      for (final item in items)
        SaleItem(
          saleId: id,
          productId: item.productId,
          name: item.name,
          price: item.price,
          costPrice: item.costPrice,
          quantity: item.quantity,
          subtotal: item.subtotal,
        ),
    ];
    for (final item in items) {
      await updateStock(item.productId, -item.quantity);
    }
    return id;
  }

  @override
  Future<List<Sale>> getDeferredSales() async {
    return sales
        .where((s) => s.paymentMethod == PaymentMethod.deferred && !s.refunded)
        .toList();
  }

  @override
  Future<void> settleSale({
    required int saleId,
    required String paymentMethod,
    required double amountTendered,
  }) async {
    final index = sales.indexWhere((s) => s.id == saleId);
    if (index < 0) return;
    sales[index] = sales[index].copyWith(
      paymentMethod: paymentMethod,
      amountTendered: amountTendered,
    );
  }

  @override
  Future<void> refundSale(int saleId) async {
    final index = sales.indexWhere((s) => s.id == saleId);
    if (index < 0 || sales[index].refunded) return;
    final sale = sales[index];
    final now = DateTime.now();
    final fifteenDaysAgo = now.subtract(const Duration(days: 15));
    if (sale.createdAt.isBefore(fifteenDaysAgo)) {
      sales[index] = sale.copyWith(refunded: false);
      return;
    }
    sales[index] = sale.copyWith(refunded: true, refundedAt: DateTime.now());
    for (final item in saleItems[saleId] ?? const []) {
      await updateStock(item.productId, item.quantity);
    }
  }

  // ---- الوردية (Z-Report) ----

  @override
  Future<Shift?> getOpenShift(String cashierName) async {
    for (final shift in shifts) {
      if (shift.cashierName == cashierName && shift.isOpen) return shift;
    }
    return null;
  }

  @override
  Future<Shift?> getLatestShift(String cashierName) async {
    Shift? latest;
    for (final shift in shifts) {
      if (shift.cashierName != cashierName) continue;
      if (latest == null || shift.openedAt.isAfter(latest.openedAt)) {
        latest = shift;
      }
    }
    return latest;
  }

  @override
  Future<Shift> ensureOpenShift(
    String cashierName, {
    DateTime? openedAt,
  }) async {
    final existing = await getOpenShift(cashierName);
    if (existing != null) return existing;
    final shift = Shift(
      id: _nextShiftId++,
      cashierName: cashierName,
      openedAt: openedAt ?? DateTime.now(),
    );
    shifts.add(shift);
    return shift;
  }

  @override
  Future<ShiftReport> getShiftReport(Shift shift) async {
    var salesCount = 0;
    var refundCount = 0;
    var cashTotal = 0.0;
    var cardTotal = 0.0;
    var walletTotal = 0.0;
    var transferTotal = 0.0;
    var mixedTotal = 0.0;
    var mixedCardPortion = 0.0;
    var deferredTotal = 0.0;
    var changeGiven = 0.0;
    var refundsTotal = 0.0;

    final from = shift.openedAt;
    final to = shift.closedAt ?? DateTime.now();
    for (final sale in sales) {
      if (sale.cashierName != shift.cashierName) continue;
      if (sale.refunded) {
        final refundedAt = sale.refundedAt;
        if (refundedAt != null &&
            !refundedAt.isBefore(from) &&
            refundedAt.isBefore(to)) {
          refundCount++;
          refundsTotal += sale.total;
        }
        continue;
      }
      if (sale.createdAt.isBefore(from) || !sale.createdAt.isBefore(to)) {
        continue;
      }
      salesCount++;
      changeGiven += sale.changeDue;
      switch (sale.paymentMethod) {
        case 'نقدي':
          cashTotal += sale.total;
          break;
        case 'شبكة':
          cardTotal += sale.total;
          break;
        case 'محفظة':
          walletTotal += sale.total;
          break;
        case 'تحويل بنكي':
          transferTotal += sale.total;
          break;
        case 'مختلط':
          mixedTotal += sale.total;
          mixedCardPortion += sale.cardAmount;
          break;
        case 'آجل':
          deferredTotal += sale.total;
          break;
      }
    }

    return ShiftReport(
      shift: shift,
      salesCount: salesCount,
      refundCount: refundCount,
      cashTotal: cashTotal,
      cardTotal: cardTotal,
      walletTotal: walletTotal,
      transferTotal: transferTotal,
      mixedTotal: mixedTotal,
      mixedCardPortion: mixedCardPortion,
      deferredTotal: deferredTotal,
      changeGiven: changeGiven,
      refundsTotal: refundsTotal,
    );
  }

  @override
  Future<Shift?> closeShift(String cashierName) async {
    final open = await getOpenShift(cashierName);
    if (open == null) return null;
    final index = shifts.indexWhere((s) => s.id == open.id);
    if (index >= 0) {
      final closed = open.copyWith(closedAt: DateTime.now());
      shifts[index] = closed;
      return closed;
    }
    return null;
  }

  // ---- الفواتير المعلقة (Hold Invoice) ----

  @override
  Future<int> holdCart({
    required HeldCart cart,
    required List<HeldCartItem> items,
  }) async {
    final id = _nextHeldCartId++;
    heldCarts.insert(
      0,
      HeldCart(
        id: id,
        savedAt: cart.savedAt,
        discount: cart.discount,
        paymentMethod: cart.paymentMethod,
        customerId: cart.customerId,
        note: cart.note,
        cashierName: cart.cashierName,
        itemsCount: cart.itemsCount,
        total: cart.total,
      ),
    );
    heldCartItems[id] = [
      for (final item in items)
        HeldCartItem(
          id: _nextHeldCartItemId++,
          heldCartId: id,
          productId: item.productId,
          name: item.name,
          price: item.price,
          costPrice: item.costPrice,
          quantity: item.quantity,
          subtotal: item.subtotal,
        ),
    ];
    return id;
  }

  @override
  Future<List<HeldCart>> getHeldCarts() async => List.of(heldCarts);

  @override
  Future<List<HeldCartItem>> getHeldCartItems(int heldCartId) async =>
      List.of(heldCartItems[heldCartId] ?? const []);

  @override
  Future<void> deleteHeldCart(int heldCartId) async {
    heldCarts.removeWhere((c) => c.id == heldCartId);
    heldCartItems.remove(heldCartId);
  }

  // ===== إدارة الصالات =====

  @override
  Future<List<Hall>> getHalls() async => List.of(halls);

  @override
  Future<int> addHall(Hall hall) async {
    final id = _nextHallId++;
    halls.add(hall.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateHall(Hall hall) async {
    final index = halls.indexWhere((h) => h.id == hall.id);
    if (index >= 0) halls[index] = hall;
  }

  @override
  Future<void> deleteHall(int id) async {
    halls.removeWhere((h) => h.id == id);
  }

  @override
  Future<HallDailyReport> getHallDailyReport(int hallId, DateTime date) async {
    final hall = halls.firstWhere(
      (h) => h.id == hallId,
      orElse: () => Hall(name: ''),
    );
    final dayOrders = orders
        .where(
          (o) =>
              o.hallId == hallId &&
              o.createdAt.year == date.year &&
              o.createdAt.month == date.month &&
              o.createdAt.day == date.day,
        )
        .toList();
    return HallDailyReport(
      hallName: hall.name,
      date: date,
      ordersCount: dayOrders.length,
      totalRevenue: dayOrders.fold<double>(0, (s, o) => s + o.total),
    );
  }

  // ===== إدارة الترابيزات =====

  @override
  Future<List<RestaurantTable>> getTables() async => List.of(tables);

  @override
  Future<List<RestaurantTable>> getTablesByHall(int hallId) async =>
      tables.where((t) => t.hallId == hallId).toList();

  @override
  Future<int> addTable(RestaurantTable table) async {
    final id = _nextTableId++;
    tables.add(table.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateTable(RestaurantTable table) async {
    final index = tables.indexWhere((t) => t.id == table.id);
    if (index >= 0) tables[index] = table;
  }

  @override
  Future<void> deleteTable(int id) async {
    tables.removeWhere((t) => t.id == id);
  }

  @override
  Future<void> updateTableStatus(
    int tableId,
    TableStatus status, {
    int? orderId,
  }) async {
    final index = tables.indexWhere((t) => t.id == tableId);
    if (index >= 0) {
      tables[index] = tables[index].copyWith(
        status: status,
        currentOrderId: orderId ?? tables[index].currentOrderId,
      );
    }
  }

  @override
  Future<RestaurantTable?> getTable(int id) async {
    for (final t in tables) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  Future<List<RestaurantOrder>> getTableOrders(int tableId) async => orders
      .where(
        (o) =>
            o.tableId == tableId &&
            o.status != 'cancelled' &&
            o.status != 'paid' &&
            o.status != 'delivered' &&
            o.status != 'handedOver',
      )
      .toList();

  @override
  Future<double> payTable(int tableId, String paymentMethod) async {
    double total = 0;
    for (var i = 0; i < orders.length; i++) {
      final o = orders[i];
      if (o.tableId == tableId &&
          o.status != 'cancelled' &&
          o.status != 'paid' &&
          o.status != 'delivered' &&
          o.status != 'handedOver') {
        total += o.total;
        orders[i] = o.copyWith(
          status: OrderStatus.paid.name,
          paymentMethod: paymentMethod,
          completedAt: DateTime.now(),
        );
      }
    }
    final idx = tables.indexWhere((t) => t.id == tableId);
    if (idx >= 0 && total > 0) {
      final table = tables[idx];
      tables[idx] = RestaurantTable(
        id: table.id,
        hallId: table.hallId,
        number: table.number,
        capacity: table.capacity,
        status: TableStatus.available,
        createdAt: table.createdAt,
      );
    }
    return total;
  }

  // ===== إدارة الموظفين =====

  @override
  Future<List<Employee>> getEmployees() async => List.of(employees);

  @override
  Future<List<Employee>> getActiveEmployees() async =>
      employees.where((e) => e.isActive).toList();

  @override
  Future<int> addEmployee(Employee employee) async {
    final id = _nextEmployeeId++;
    employees.add(employee.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    final index = employees.indexWhere((e) => e.id == employee.id);
    if (index >= 0) employees[index] = employee;
  }

  @override
  Future<void> deleteEmployee(int id) async {
    employees.removeWhere((e) => e.id == id);
  }

  @override
  Future<Employee?> getEmployee(int id) async {
    for (final e in employees) {
      if (e.id == id) return e;
    }
    return null;
  }

  // ===== نظام الطلبات =====

  @override
  Future<List<RestaurantOrder>> getOrders({
    int? limit,
    String? status,
    String? orderType,
  }) async {
    var list = List.of(orders);
    if (status != null) {
      list = list.where((o) => o.status == status).toList();
    }
    if (orderType != null) {
      list = list.where((o) => o.orderType == orderType).toList();
    }
    return limit != null && list.length > limit ? list.sublist(0, limit) : list;
  }

  @override
  Future<RestaurantOrder?> getOrder(int id) async {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  @override
  Future<List<OrderItem>> getOrderItems(int orderId) async =>
      List.of(orderItems[orderId] ?? const []);

  @override
  Future<int> createOrder({
    required RestaurantOrder order,
    required List<OrderItem> items,
  }) async {
    final id = _nextOrderId++;
    orders.insert(0, order.copyWith(id: id));
    orderItems[id] = [
      for (final item in items)
        OrderItem(
          id: _nextOrderItemId++,
          orderId: id,
          productId: item.productId,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
          subtotal: item.subtotal,
          notes: item.notes,
          status: item.status,
        ),
    ];
    return id;
  }

  @override
  Future<void> updateOrderStatus(
    int orderId,
    OrderStatus status, {
    String note = '',
  }) async {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      orders[index] = orders[index].copyWith(status: status.name);
    }
    await addOrderStatusHistory(
      OrderStatusHistory(orderId: orderId, status: status.name, note: note),
    );
  }

  @override
  Future<void> addOrderStatusHistory(OrderStatusHistory entry) async {
    orderStatusHistory.add(entry);
  }

  @override
  Future<List<OrderStatusHistory>> getOrderStatusHistory(int orderId) async {
    return orderStatusHistory.where((e) => e.orderId == orderId).toList();
  }

  @override
  Future<void> updateOrderItemStatus(int orderItemId, String status) async {
    for (final items in orderItems.values) {
      for (var i = 0; i < items.length; i++) {
        if (items[i].id == orderItemId) {
          items[i] = items[i].copyWith(status: status);
        }
      }
    }
  }

  @override
  Future<void> cancelOrder(int orderId) async {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      final order = orders[index];
      orders[index] = order.copyWith(status: OrderStatus.cancelled.name);
      if (order.tableId != null) {
        await updateTableStatus(order.tableId!, TableStatus.available);
      }
    }
  }

  @override
  Future<List<RestaurantOrder>> getActiveOrders() async => orders
      .where(
        (o) =>
            o.status == OrderStatus.pending.name ||
            o.status == OrderStatus.preparing.name,
      )
      .toList();

  @override
  Future<int> getActiveOrdersCount() async => (await getActiveOrders()).length;

  @override
  Future<int> getOccupiedTablesCount() async =>
      tables.where((t) => t.status == TableStatus.occupied).length;

  @override
  Future<int> getActiveEmployeesCount() async =>
      employees.where((e) => e.isActive).length;

  // ---- إعدادات المتجر ----

  @override
  Future<String?> getSetting(String key) async => settings[key];

  @override
  Future<void> setSetting(String key, String value) async {
    settings[key] = value;
  }

  @override
  Future<StoreSettings> getSettings() async {
    return StoreSettings(
      storeName: settings['store_name'] ?? 'متجري',
      phone: settings['store_phone'] ?? '',
      currency: settings['currency'] ?? 'ج.م',
      darkMode: settings['dark_mode'] == '1',
      fontScale: double.tryParse(settings['font_scale'] ?? '') ?? 1.0,
      taxRate: double.tryParse(settings['tax_rate'] ?? '') ?? 0,
    );
  }

  @override
  Future<void> saveSettings(StoreSettings value) async {
    settings['store_name'] = value.storeName;
    settings['store_phone'] = value.phone;
    settings['currency'] = value.currency;
    settings['dark_mode'] = value.darkMode ? '1' : '0';
    settings['font_scale'] = '${value.fontScale}';
    settings['tax_rate'] = '${value.taxRate}';
  }

  // ===== Methods added for v15 =====

  @override
  Future<List<int>> addProductsBulk(List<Product> newProducts) async {
    final ids = <int>[];
    for (final p in newProducts) {
      final id = _nextProductId++;
      products.add(p.copyWith(id: id));
      ids.add(id);
    }
    return ids;
  }

  @override
  Future<List<Employee>> getDeliveryPersons() async => employees
      .where((e) => e.role == EmployeeRole.delivery && e.isActive)
      .toList();

  final List<EmployeeAdvance> _advances = [];

  @override
  Future<int> addEmployeeAdvance(EmployeeAdvance advance) async {
    _advances.add(advance);
    return _advances.length;
  }

  @override
  Future<List<EmployeeAdvance>> getEmployeeAdvances(
    int employeeId, {
    DateTime? date,
  }) async => _advances.where((a) => a.employeeId == employeeId).toList();

  @override
  Future<DailyEmployeeReport> getEmployeeDailyReport(
    int employeeId,
    DateTime date,
  ) async {
    final emp = employees.firstWhere(
      (e) => e.id == employeeId,
      orElse: () => Employee(name: ''),
    );
    return DailyEmployeeReport(
      employeeName: emp.name,
      date: date,
      salary: emp.salary,
    );
  }

  @override
  Future<List<RestaurantOrder>> getActiveDeliveryOrders() async => orders
      .where(
        (o) =>
            o.orderType == 'delivery' &&
            (o.status == 'pending' || o.status == 'preparing'),
      )
      .toList();

  @override
  Future<List<RestaurantOrder>> getKitchenOrders() async => orders
      .where(
        (o) =>
            o.status == 'pending' ||
            o.status == 'preparing' ||
            o.status == 'ready',
      )
      .toList();

  final List<RiderTransaction> _riderTransactions = [];

  @override
  Future<List<RiderTransaction>> getRiderTransactions(int riderId) async =>
      _riderTransactions.where((t) => t.riderId == riderId).toList();

  @override
  Future<double> getRiderBalance(int riderId) async {
    final txns = _riderTransactions.where((t) => t.riderId == riderId);
    final collected = txns
        .where((t) => t.type == RiderTransactionType.orderCollection)
        .fold<double>(0, (s, t) => s + t.amount);
    final paid = txns
        .where(
          (t) =>
              t.type == RiderTransactionType.settlement ||
              t.type == RiderTransactionType.advance,
        )
        .fold<double>(0, (s, t) => s + t.amount);
    return collected - paid;
  }

  @override
  Future<int> addRiderTransaction(RiderTransaction transaction) async {
    _riderTransactions.add(transaction);
    return _riderTransactions.length;
  }

  @override
  Future<List<RestaurantOrder>> getRiderOutstandingOrders(int riderId) async =>
      orders
          .where(
            (o) =>
                o.riderId == riderId &&
                o.orderType == 'delivery' &&
                (o.status == 'delivered' || o.status == 'handedOver'),
          )
          .toList();

  // ===== الموردين والمشتريات =====
  final List<Supplier> suppliersList = [];
  final List<Purchase> purchasesList = [];
  final Map<int, List<PurchaseItem>> purchaseItemsMap = {};
  final List<SupplierPayment> supplierPaymentsList = [];

  @override
  Future<List<Supplier>> getSuppliers() async => List.of(suppliersList);

  @override
  Future<int> addSupplier(Supplier supplier) async {
    suppliersList.add(supplier);
    return suppliersList.length;
  }

  @override
  Future<void> updateSupplier(Supplier supplier) async {
    final idx = suppliersList.indexWhere((s) => s.id == supplier.id);
    if (idx != -1) suppliersList[idx] = supplier;
  }

  @override
  Future<void> deleteSupplier(int id) async {
    suppliersList.removeWhere((s) => s.id == id);
  }

  @override
  Future<Supplier?> getSupplier(int id) async => suppliersList
      .cast<Supplier?>()
      .firstWhere((s) => s?.id == id, orElse: () => null);

  @override
  Future<List<Purchase>> getPurchases({int? limit}) async {
    final list = List.of(purchasesList);
    if (limit != null && list.length > limit) return list.sublist(0, limit);
    return list;
  }

  @override
  Future<Purchase?> getPurchase(int id) async => purchasesList
      .cast<Purchase?>()
      .firstWhere((p) => p?.id == id, orElse: () => null);

  @override
  Future<List<PurchaseItem>> getPurchaseItems(int purchaseId) async =>
      purchaseItemsMap[purchaseId] ?? [];

  @override
  Future<int> createPurchase({
    required Purchase purchase,
    required List<PurchaseItem> items,
  }) async {
    final id = purchasesList.length + 1;
    purchasesList.add(purchase.copyWith(id: id));
    purchaseItemsMap[id] = items
        .map((i) => i.copyWith(purchaseId: id))
        .toList();
    // مطابق لسلوك المستودع الحقيقي: الشراء يزيد المخزون ويحدّث التكلفة.
    for (final item in items) {
      if (item.productId != null && item.stockQuantity != 0) {
        await updateStock(item.productId!, item.stockQuantity);
        if (item.price > 0) {
          final idx = products.indexWhere((p) => p.id == item.productId);
          if (idx >= 0) {
            products[idx] = products[idx].copyWith(
              costPrice: item.baseUnitCost,
            );
          }
        }
      }
    }
    return id;
  }

  @override
  Future<void> settlePurchase({
    required int purchaseId,
    required double amount,
  }) async {
    final idx = purchasesList.indexWhere((p) => p.id == purchaseId);
    if (idx != -1) {
      final p = purchasesList[idx];
      purchasesList[idx] = p.copyWith(paidAmount: p.paidAmount + amount);
    }
  }

  @override
  Future<List<SupplierPayment>> getSupplierPayments(int supplierId) async =>
      supplierPaymentsList.where((p) => p.supplierId == supplierId).toList();

  // ===== الكوبونات =====
  final List<Coupon> couponsList = [];

  @override
  Future<List<Coupon>> getCoupons() async => List.of(couponsList);

  @override
  Future<int> addCoupon(Coupon coupon) async {
    couponsList.add(coupon);
    return couponsList.length;
  }

  @override
  Future<void> updateCoupon(Coupon coupon) async {
    final idx = couponsList.indexWhere((c) => c.id == coupon.id);
    if (idx != -1) couponsList[idx] = coupon;
  }

  @override
  Future<void> deleteCoupon(int id) async {
    couponsList.removeWhere((c) => c.id == id);
  }

  @override
  Future<Coupon?> getCouponByCode(String code) async =>
      couponsList.cast<Coupon?>().firstWhere(
        (c) => c?.code.toUpperCase() == code.toUpperCase(),
        orElse: () => null,
      );

  @override
  Future<void> useCoupon(int couponId) async {
    final idx = couponsList.indexWhere((c) => c.id == couponId);
    if (idx != -1) {
      final c = couponsList[idx];
      couponsList[idx] = c.copyWith(usedCount: c.usedCount + 1);
    }
  }

  // ===== العملاء =====
  final List<Customer> customersList = [];

  @override
  Future<List<Customer>> getCustomers() async => List.of(customersList);

  @override
  Future<int> addCustomer(Customer customer) async {
    customersList.add(customer);
    return customersList.length;
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    final idx = customersList.indexWhere((c) => c.id == customer.id);
    if (idx != -1) customersList[idx] = customer;
  }

  @override
  Future<void> deleteCustomer(int id) async {
    customersList.removeWhere((c) => c.id == id);
  }

  @override
  Future<Customer?> getCustomer(int id) async => customersList
      .cast<Customer?>()
      .firstWhere((c) => c?.id == id, orElse: () => null);

  @override
  Future<Customer?> getCustomerByPhone(String phone) async => customersList
      .cast<Customer?>()
      .firstWhere((c) => c?.phone == phone, orElse: () => null);

  @override
  Future<void> addLoyaltyPoints(int customerId, int points) async {
    final idx = customersList.indexWhere((c) => c.id == customerId);
    if (idx != -1) {
      final c = customersList[idx];
      customersList[idx] = c.copyWith(loyaltyPoints: c.loyaltyPoints + points);
    }
  }

  // ===== إدارة الحجوزات =====
  final List<Reservation> _reservationsList = [];

  @override
  Future<List<Reservation>> getReservations() async =>
      List.of(_reservationsList);

  @override
  Future<int> createReservation(Reservation reservation) async {
    final id = _reservationsList.length + 1;
    _reservationsList.add(reservation.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateReservationStatus(int id, ReservationStatus status) async {
    final idx = _reservationsList.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reservationsList[idx] = _reservationsList[idx].copyWith(status: status);
    }
  }

  @override
  Future<void> deleteReservation(int id) async {
    _reservationsList.removeWhere((r) => r.id == id);
  }

  // ===== إدارة قائمة الانتظار =====
  final List<QueueEntry> _queueEntries = [];

  @override
  Future<List<QueueEntry>> getQueueEntries() async => List.of(_queueEntries);

  @override
  Future<int> addQueueEntry(QueueEntry entry) async {
    final id = _queueEntries.length + 1;
    _queueEntries.add(entry.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateQueueEntryStatus(int id, QueueStatus status) async {
    final idx = _queueEntries.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _queueEntries[idx] = _queueEntries[idx].copyWith(status: status);
    }
  }

  @override
  Future<void> deleteQueueEntry(int id) async {
    _queueEntries.removeWhere((e) => e.id == id);
  }

  // ===== إدارة الوصفات =====
  final List<Recipe> _recipesList = [];
  final List<RecipeItem> _recipeItemsList = [];

  @override
  Future<List<Recipe>> getRecipes() async => List.of(_recipesList);

  @override
  Future<int> createRecipe(Recipe recipe) async {
    final id = _recipesList.length + 1;
    final newRecipe = recipe.copyWith(id: id);
    _recipesList.add(newRecipe);
    for (final item in recipe.items) {
      final itemId = _recipeItemsList.length + 1;
      _recipeItemsList.add(item.copyWith(id: itemId, recipeId: id));
    }
    return id;
  }

  @override
  Future<void> updateRecipe(Recipe recipe) async {
    final idx = _recipesList.indexWhere((r) => r.id == recipe.id);
    if (idx != -1) {
      _recipesList[idx] = recipe;
      _recipeItemsList.removeWhere((i) => i.recipeId == recipe.id);
      for (final item in recipe.items) {
        final itemId = _recipeItemsList.length + 1;
        _recipeItemsList.add(item.copyWith(id: itemId, recipeId: recipe.id!));
      }
    }
  }

  @override
  Future<void> deleteRecipe(int id) async {
    _recipesList.removeWhere((r) => r.id == id);
    _recipeItemsList.removeWhere((i) => i.recipeId == id);
  }

  @override
  Future<List<RecipeItem>> getRecipeItems(int recipeId) async =>
      _recipeItemsList.where((i) => i.recipeId == recipeId).toList();

  @override
  Future<void> addRecipeItem(RecipeItem item) async {
    final id = _recipeItemsList.length + 1;
    _recipeItemsList.add(item.copyWith(id: id));
  }

  @override
  Future<void> deleteRecipeItem(int id) async {
    _recipeItemsList.removeWhere((i) => i.id == id);
  }
}

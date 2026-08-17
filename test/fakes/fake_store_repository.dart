import 'package:omni_order/domain/models/admin.dart';
import 'package:omni_order/domain/models/category.dart';
import 'package:omni_order/domain/models/customer.dart';
import 'package:omni_order/domain/models/customer_payment.dart';
import 'package:omni_order/domain/models/expense.dart';
import 'package:omni_order/domain/models/held_cart.dart';
import 'package:omni_order/domain/models/product.dart';
import 'package:omni_order/domain/models/purchase.dart';
import 'package:omni_order/domain/models/purchase_item.dart';
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
  final List<Customer> customers = [];
  final List<Supplier> suppliers = [];
  final List<Expense> expenses = [];
  final List<Sale> sales = [];
  final Map<int, List<SaleItem>> saleItems = {};
  final List<Purchase> purchases = [];
  final Map<int, List<PurchaseItem>> purchaseItems = {};
  final Map<int, List<CustomerPayment>> customerPayments = {};
  final Map<int, List<SupplierPayment>> supplierPayments = {};
  final Map<String, String> settings = {};
  final List<Shift> shifts = [];
  final List<HeldCart> heldCarts = [];
  final Map<int, List<HeldCartItem>> heldCartItems = {};

  int _nextShiftId = 1;
  int _nextHeldCartId = 1;
  int _nextHeldCartItemId = 1;

  int _nextProductId = 1;
  int _nextCategoryId = 1;
  int _nextCustomerId = 1;
  int _nextSupplierId = 1;
  int _nextExpenseId = 1;
  int _nextSaleId = 1;
  int _nextAdminId = 1;
  int _nextPurchaseId = 1;
  int _nextPaymentId = 1;
  int _nextSupplierPaymentId = 1;

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

  // ---- العملاء ----

  @override
  Future<List<Customer>> getCustomers() async => List.of(customers);

  @override
  Future<int> addCustomer(Customer customer) async {
    final id = _nextCustomerId++;
    customers.add(customer.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    final index = customers.indexWhere((c) => c.id == customer.id);
    if (index >= 0) customers[index] = customer;
  }

  @override
  Future<void> deleteCustomer(int id) async {
    customers.removeWhere((c) => c.id == id);
  }

  // ---- الموردين ----

  @override
  Future<List<Supplier>> getSuppliers() async => List.of(suppliers);

  @override
  Future<int> addSupplier(Supplier supplier) async {
    final id = _nextSupplierId++;
    suppliers.add(supplier.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateSupplier(Supplier supplier) async {
    final index = suppliers.indexWhere((s) => s.id == supplier.id);
    if (index >= 0) suppliers[index] = supplier;
  }

  @override
  Future<void> deleteSupplier(int id) async {
    suppliers.removeWhere((s) => s.id == id);
  }

  // ---- دفعات العملاء ----

  @override
  Future<List<CustomerPayment>> getCustomerPayments(int customerId) async =>
      List.of(customerPayments[customerId] ?? const []);

  @override
  Future<void> addCustomerPayment(CustomerPayment payment) async {
    final id = _nextPaymentId++;
    customerPayments[payment.customerId] ??= [];
    customerPayments[payment.customerId]!.insert(0, payment.copyWith(id: id));
    final index = customers.indexWhere((c) => c.id == payment.customerId);
    if (index >= 0) {
      final balance = (customers[index].balance - payment.amount)
          .clamp(0, double.infinity)
          .toDouble();
      customers[index] = customers[index].copyWith(balance: balance);
    }
  }

  @override
  Future<List<SupplierPayment>> getSupplierPayments(int supplierId) async =>
      List.of(supplierPayments[supplierId] ?? const []);

  @override
  Future<void> addSupplierPayment(SupplierPayment payment) async {
    final id = _nextSupplierPaymentId++;
    var allocatedFirstPurchaseId = payment.purchaseId;
    var remaining = payment.amount;
    final targetedIds = <int>{};

    if (payment.purchaseId != null && remaining > 0) {
      final index = purchases.indexWhere(
        (p) => p.id == payment.purchaseId && p.supplierId == payment.supplierId,
      );
      if (index >= 0) {
        final target = purchases[index];
        final capacity = (target.total - target.paidAmount)
            .clamp(0.0, double.infinity)
            .toDouble();
        if (capacity > 0) {
          final allocate = remaining >= capacity ? capacity : remaining;
          purchases[index] = target.copyWith(
            paidAmount: target.paidAmount + allocate,
          );
          allocatedFirstPurchaseId = payment.purchaseId;
          targetedIds.add(payment.purchaseId!);
          remaining -= allocate;
        }
      }
    }

    if (remaining > 0) {
      final unpaid = purchases
          .where(
            (p) =>
                p.supplierId == payment.supplierId &&
                !targetedIds.contains(p.id) &&
                p.remainingBalance > 0,
          )
          .toList()
        ..sort((a, b) {
          final byDate = a.createdAt.compareTo(b.createdAt);
          return byDate != 0 ? byDate : (a.id ?? 0).compareTo(b.id ?? 0);
        });
      for (final purchase in unpaid) {
        if (remaining <= 0) break;
        final index = purchases.indexWhere((p) => p.id == purchase.id);
        if (index < 0) continue;
        final current = purchases[index];
        final capacity = (current.total - current.paidAmount)
            .clamp(0.0, double.infinity)
            .toDouble();
        if (capacity <= 0) continue;
        final allocate = remaining >= capacity ? capacity : remaining;
        purchases[index] = current.copyWith(
          paidAmount: current.paidAmount + allocate,
        );
        allocatedFirstPurchaseId ??= purchase.id;
        remaining -= allocate;
      }
    }

    supplierPayments[payment.supplierId] ??= [];
    supplierPayments[payment.supplierId]!.insert(
      0,
      payment.copyWith(id: id, purchaseId: allocatedFirstPurchaseId),
    );
    final index = suppliers.indexWhere((s) => s.id == payment.supplierId);
    if (index >= 0) {
      final balance = (suppliers[index].balance - payment.amount)
          .clamp(0, double.infinity)
          .toDouble();
      suppliers[index] = suppliers[index].copyWith(balance: balance);
    }
  }

  // ---- المشتريات ----

  @override
  Future<List<Purchase>> getPurchases() async => List.of(purchases);

  @override
  Future<List<PurchaseItem>> getPurchaseItems(int purchaseId) async =>
      List.of(purchaseItems[purchaseId] ?? const []);

  @override
  Future<int> createPurchase({
    required Purchase purchase,
    required List<PurchaseItem> items,
  }) async {
    var supplierId = purchase.supplierId;
    var supplierName = purchase.supplierName.trim();
    if (supplierId == null && supplierName.isNotEmpty) {
      final matchIndex = suppliers.indexWhere(
        (s) => s.name.trim().toLowerCase() == supplierName.toLowerCase(),
      );
      if (matchIndex >= 0) supplierId = suppliers[matchIndex].id;
    }
    if (supplierId != null && supplierName.isEmpty) {
      final matchIndex = suppliers.indexWhere((s) => s.id == supplierId);
      if (matchIndex >= 0) supplierName = suppliers[matchIndex].name.trim();
    }

    final id = _nextPurchaseId++;
    final created = Purchase(
      id: id,
      supplierId: supplierId,
      supplierName: supplierName,
      total: purchase.total,
      paidAmount: purchase.paidAmount,
      note: purchase.note,
      createdAt: purchase.createdAt,
    );
    purchases.insert(0, created);
    purchaseItems[id] = [
      for (final item in items)
        PurchaseItem(
          purchaseId: id,
          productId: item.productId,
          name: item.name,
          quantity: item.quantity,
          price: item.price,
          subtotal: item.subtotal,
        ),
    ];
    for (final item in items) {
      await updateStock(item.productId, item.quantity);
      final index = products.indexWhere((p) => p.id == item.productId);
      if (index >= 0) {
        products[index] = products[index].copyWith(costPrice: item.price);
      }
    }

    if (supplierId != null) {
      final index = suppliers.indexWhere((s) => s.id == supplierId);
      if (index >= 0) {
        final current = suppliers[index].balance;
        final remaining = (purchase.total - purchase.paidAmount).clamp(
          0.0,
          double.infinity,
        );
        suppliers[index] = suppliers[index].copyWith(
          balance: current + remaining,
        );
      }
    }

    return id;
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
      final existing = totals.putIfAbsent(
        key,
        () => DailySaleTotals(day: day),
      );
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
    if (sale.paymentMethod == 'آجل' && sale.customerId != null) {
      final cIndex = customers.indexWhere((c) => c.id == sale.customerId);
      if (cIndex >= 0) {
        customers[cIndex] = customers[cIndex].copyWith(
          balance: customers[cIndex].balance + sale.total,
        );
      }
    }
    return id;
  }

  @override
  Future<void> refundSale(int saleId) async {
    final index = sales.indexWhere((s) => s.id == saleId);
    if (index < 0 || sales[index].refunded) return;
    final sale = sales[index];
    // Check 15-day return window
    final now = DateTime.now();
    final fifteenDaysAgo = now.subtract(const Duration(days: 15));
    if (sale.createdAt.isBefore(fifteenDaysAgo)) {
      // Sale is older than 15 days - cannot refund
      sales[index] = sale.copyWith(refunded: false);
      return;
    }
    sales[index] = sale.copyWith(refunded: true, refundedAt: DateTime.now());
    for (final item in saleItems[saleId] ?? const []) {
      await updateStock(item.productId, item.quantity);
    }
    if (sale.paymentMethod == 'آجل' && sale.customerId != null) {
      final cIndex = customers.indexWhere((c) => c.id == sale.customerId);
      if (cIndex >= 0) {
        final balance = (customers[cIndex].balance - sale.total)
            .clamp(0, double.infinity)
            .toDouble();
        customers[cIndex] = customers[cIndex].copyWith(balance: balance);
      }
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
  Future<Shift> ensureOpenShift(String cashierName, {DateTime? openedAt}) async {
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
}

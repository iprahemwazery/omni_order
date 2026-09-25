import 'package:sqflite/sqflite.dart';

import '../../core/constants/payment_methods.dart';
import '../../domain/models/admin.dart';
import '../../domain/models/category.dart';
import '../../domain/models/coupon.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/employee.dart';
import '../../domain/models/employee_advance.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/hall.dart';
import '../../domain/models/held_cart.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_item.dart';
import '../../domain/models/order_status_history.dart';
import '../../domain/models/product.dart';
import '../../domain/models/purchase.dart';
import '../../domain/models/purchase_item.dart';
import '../../domain/models/queue_entry.dart';
import '../../domain/models/recipe.dart';
import '../../domain/models/reservation.dart';
import '../../domain/models/restaurant_table.dart';
import '../../domain/models/rider_transaction.dart';
import '../../domain/models/sale.dart';
import '../../domain/models/sale_item.dart';
import '../../domain/models/shift.dart';
import '../../domain/models/store_settings.dart';
import '../../domain/models/summaries.dart';
import '../../domain/models/supplier.dart';
import '../../domain/models/supplier_payment.dart';
import '../../domain/repositories/store_repository.dart';
import '../database/app_database.dart';

const _settledOrderStatuses = "'cancelled', 'paid', 'delivered', 'handedOver'";

/// تنفيذ المستودع باستخدام SQLite.
class StoreRepositoryImpl implements StoreRepository {
  final AppDatabase _database;

  StoreRepositoryImpl(this._database);

  Future<Database> get _db async => _database.database;

  @override
  Future<void> init() async => _db;

  // ---- الأدمن ----

  @override
  Future<List<Admin>> getAdmins() async {
    final rows = await (await _db).query('admins', orderBy: 'created_at ASC');
    return rows.map(Admin.fromMap).toList();
  }

  @override
  Future<Admin?> getAdminByUsername(String username) async {
    final rows = await (await _db).query(
      'admins',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return rows.isEmpty ? null : Admin.fromMap(rows.first);
  }

  @override
  Future<int> addAdmin(Admin admin) async {
    return (await _db).insert('admins', admin.toMap());
  }

  @override
  Future<void> updateAdmin(Admin admin) async {
    await (await _db).update(
      'admins',
      admin.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [admin.id],
    );
  }

  @override
  Future<void> deleteAdmin(int id) async {
    await (await _db).delete('admins', where: 'id = ?', whereArgs: [id]);
  }

  // ---- المنتجات ----

  @override
  Future<List<Product>> getProducts() async {
    final rows = await (await _db).query(
      'products',
      orderBy: 'created_at DESC',
    );
    return rows.map(Product.fromMap).toList();
  }

  @override
  Future<int> addProduct(Product product) async {
    return (await _db).insert('products', product.toMap());
  }

  @override
  Future<void> updateProduct(Product product) async {
    await (await _db).update(
      'products',
      product.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  @override
  Future<void> deleteProduct(int id) async {
    await (await _db).delete('products', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<int>> addProductsBulk(List<Product> products) async {
    final db = await _db;
    final ids = <int>[];
    await db.transaction((txn) async {
      for (final product in products) {
        final id = await txn.insert('products', product.toMap());
        ids.add(id);
      }
    });
    return ids;
  }

  @override
  Future<void> updateStock(int productId, double delta) async {
    await (await _db).rawUpdate(
      'UPDATE products SET stock = stock + ? WHERE id = ?',
      [delta, productId],
    );
  }

  // ---- التصنيفات ----

  @override
  Future<List<Category>> getCategories() async {
    final rows = await (await _db).query(
      'categories',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Category.fromMap).toList();
  }

  @override
  Future<int> addCategory(Category category) async {
    return (await _db).insert('categories', category.toMap());
  }

  @override
  Future<void> updateCategory(Category category) async {
    await (await _db).update(
      'categories',
      category.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<void> deleteCategory(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(
        'products',
        {'category_id': null},
        where: 'category_id = ?',
        whereArgs: [id],
      );
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
  }

  // ---- المصروفات ----

  @override
  Future<List<Expense>> getExpenses({int? limit}) async {
    final rows = await (await _db).query(
      'expenses',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(Expense.fromMap).toList();
  }

  @override
  Future<int> addExpense(Expense expense) async {
    return (await _db).insert('expenses', expense.toMap());
  }

  @override
  Future<void> deleteExpense(int id) async {
    await (await _db).delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ---- المبيعات ----

  @override
  Future<List<Sale>> getSales({int? limit}) async {
    final rows = await (await _db).query(
      'sales',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(Sale.fromMap).toList();
  }

  @override
  Future<Sale?> getSale(int id) async {
    final rows = await (await _db).query(
      'sales',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : Sale.fromMap(rows.first);
  }

  @override
  Future<List<SaleItem>> getSaleItems(int saleId) async {
    final rows = await (await _db).query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return rows.map(SaleItem.fromMap).toList();
  }

  @override
  Future<SalesTotals> getSalesTotals() async {
    final db = await _db;
    final now = DateTime.now();
    final todayStart = _dayKey(now);
    final todayEnd = _dayKey(now.add(const Duration(days: 1)));
    final monthStart = _dayKey(DateTime(now.year, now.month, 1));
    final monthEnd = _dayKey(DateTime(now.year, now.month + 1, 1));

    Future<({double cash, double deferred, int count})> slice(
      String? from,
      String? to,
    ) async {
      var sql =
          "SELECT "
          "COALESCE(SUM(CASE WHEN payment_method != '${PaymentMethod.deferred}' THEN total END), 0) AS cash, "
          "COALESCE(SUM(CASE WHEN payment_method = '${PaymentMethod.deferred}' THEN total END), 0) AS deferred, "
          'COUNT(*) AS cnt '
          'FROM sales WHERE refunded = 0';
      final args = <Object?>[];
      if (from != null) {
        sql += ' AND created_at >= ?';
        args.add(from);
      }
      if (to != null) {
        sql += ' AND created_at < ?';
        args.add(to);
      }
      final row = (await db.rawQuery(sql, args)).first;
      return (
        cash: (row['cash'] as num?)?.toDouble() ?? 0,
        deferred: (row['deferred'] as num?)?.toDouble() ?? 0,
        count: row['cnt'] as int? ?? 0,
      );
    }

    final today = await slice(todayStart, todayEnd);
    final month = await slice(monthStart, monthEnd);
    final all = await slice(null, null);

    return SalesTotals(
      cashToday: today.cash,
      deferredToday: today.deferred,
      countToday: today.count,
      cashMonth: month.cash,
      deferredMonth: month.deferred,
      countMonth: month.count,
      totalCash: all.cash,
      totalDeferred: all.deferred,
      countTotal: all.count,
    );
  }

  @override
  Future<List<DailySaleTotals>> getDailySalesTotals(int days) async {
    final db = await _db;
    final start = DateTime.now().subtract(Duration(days: days - 1));
    final rows = await db.rawQuery(
      '''
      SELECT substr(created_at, 1, 10) AS day,
        COALESCE(SUM(CASE WHEN payment_method != '${PaymentMethod.deferred}' THEN total END), 0) AS cash,
        COALESCE(SUM(CASE WHEN payment_method = '${PaymentMethod.deferred}' THEN total END), 0) AS deferred
      FROM sales
      WHERE refunded = 0 AND created_at >= ?
      GROUP BY day
      ''',
      [_dayKey(start)],
    );
    return rows
        .map(
          (row) => DailySaleTotals(
            day: _parseDayKey(row['day'] as String),
            cash: (row['cash'] as num?)?.toDouble() ?? 0,
            deferred: (row['deferred'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList();
  }

  @override
  Future<List<Sale>> getSalesOn(DateTime day) async {
    final rows = await (await _db).query(
      'sales',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [_dayKey(day), _dayKey(day.add(const Duration(days: 1)))],
      orderBy: 'created_at DESC',
    );
    return rows.map(Sale.fromMap).toList();
  }

  @override
  Future<List<DayHistoryEntry>> getDayHistory() async {
    final db = await _db;
    final todayKey = _dayKey(DateTime.now());
    final saleRows = await db.rawQuery(
      '''
      SELECT substr(created_at, 1, 10) AS day,
        SUM(total) AS total,
        COUNT(*) AS cnt
      FROM sales
      WHERE refunded = 0 AND substr(created_at, 1, 10) != ?
      GROUP BY day
      ''',
      [todayKey],
    );
    final expenseRows = await db.rawQuery(
      '''
      SELECT substr(created_at, 1, 10) AS day,
        SUM(amount) AS total,
        COUNT(*) AS cnt
      FROM expenses
      WHERE substr(created_at, 1, 10) != ?
      GROUP BY day
      ''',
      [todayKey],
    );

    final byDay = <String, DayHistoryEntry>{};
    for (final row in saleRows) {
      final key = row['day'] as String;
      byDay[key] = DayHistoryEntry(
        day: _parseDayKey(key),
        salesTotal: (row['total'] as num?)?.toDouble() ?? 0,
        salesCount: row['cnt'] as int? ?? 0,
      );
    }
    for (final row in expenseRows) {
      final key = row['day'] as String;
      final existing = byDay[key];
      byDay[key] = DayHistoryEntry(
        day: _parseDayKey(key),
        salesTotal: existing?.salesTotal ?? 0,
        salesCount: existing?.salesCount ?? 0,
        expensesTotal: (row['total'] as num?)?.toDouble() ?? 0,
        expensesCount: row['cnt'] as int? ?? 0,
      );
    }

    final entries = byDay.values.toList()
      ..sort((a, b) => b.day.compareTo(a.day));
    return entries;
  }

  @override
  Future<ExpenseTotals> getExpenseTotals() async {
    final db = await _db;
    final now = DateTime.now();
    final todayStart = _dayKey(now);
    final todayEnd = _dayKey(now.add(const Duration(days: 1)));
    final monthStart = _dayKey(DateTime(now.year, now.month, 1));
    final monthEnd = _dayKey(DateTime(now.year, now.month + 1, 1));

    Future<({double amount, int count})> slice(String? from, String? to) async {
      var sql =
          'SELECT COALESCE(SUM(amount), 0) AS amt, COUNT(*) AS cnt '
          'FROM expenses';
      final args = <Object?>[];
      if (from != null) {
        sql += ' WHERE created_at >= ?';
        args.add(from);
      }
      if (to != null) {
        sql += ' AND created_at < ?';
        args.add(to);
      }
      final row = (await db.rawQuery(sql, args)).first;
      return (
        amount: (row['amt'] as num?)?.toDouble() ?? 0,
        count: row['cnt'] as int? ?? 0,
      );
    }

    final today = await slice(todayStart, todayEnd);
    final month = await slice(monthStart, monthEnd);
    final all = await slice(null, null);
    return ExpenseTotals(
      today: today.amount,
      month: month.amount,
      total: all.amount,
      count: all.count,
    );
  }

  @override
  Future<List<Expense>> getExpensesOn(DateTime day) async {
    final rows = await (await _db).query(
      'expenses',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [_dayKey(day), _dayKey(day.add(const Duration(days: 1)))],
      orderBy: 'created_at DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  @override
  Future<ProfitAnalytics> getProfitAnalytics() async {
    final row = (await (await _db).rawQuery('''
      SELECT
        COALESCE(SUM(s.total), 0) AS cash_revenue,
        COALESCE(SUM(si.cost_price * si.quantity), 0) AS cogs
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
      WHERE s.refunded = 0 AND s.payment_method != '${PaymentMethod.deferred}'
    ''')).first;
    return ProfitAnalytics(
      cashRevenue: (row['cash_revenue'] as num?)?.toDouble() ?? 0,
      cogs: (row['cogs'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Future<List<TopProduct>> topProducts({int limit = 5}) async {
    final rows = await (await _db).rawQuery(
      '''
      SELECT si.name AS name,
        SUM(si.quantity) AS qty,
        SUM(si.subtotal) AS revenue
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
      WHERE s.refunded = 0
      GROUP BY si.name
      ORDER BY qty DESC
      LIMIT ?
      ''',
      [limit],
    );
    return rows
        .map(
          (row) => (
            name: row['name'] as String,
            quantity: (row['qty'] as num?)?.toDouble() ?? 0,
            revenue: (row['revenue'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList();
  }

  @override
  Future<int> createSale({
    required Sale sale,
    required List<SaleItem> items,
  }) async {
    // أول عملية بيع للكاشير تفتح وردية تلقائيًا (تُغلق من تقرير الوردية).
    // تُفتح الوردية بوقت الفاتورة نفسها لضمان احتسابها ضمن نطاق الوردية.
    if (sale.cashierName.isNotEmpty) {
      await ensureOpenShift(sale.cashierName, openedAt: sale.createdAt);
    }
    final db = await _db;
    return db.transaction((txn) async {
      // Generate invoice number if not set
      if (sale.invoiceNumber == 0) {
        final maxRow = await txn.rawQuery(
          'SELECT MAX(invoice_number) as max_num FROM sales',
        );
        final maxNum = maxRow.first['max_num'] as int? ?? 0;
        sale = sale.copyWith(invoiceNumber: maxNum + 1);
      }
      final saleId = await txn.insert('sales', sale.toMap());
      for (final item in items) {
        await txn.insert('sale_items', item.toMap()..['sale_id'] = saleId);
        await txn.rawUpdate(
          'UPDATE products SET stock = MAX(stock - ?, 0) WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
      return saleId;
    });
  }

  @override
  Future<List<Sale>> getDeferredSales() async {
    final db = await _db;
    final rows = await db.query(
      'sales',
      where: "payment_method = ? AND refunded = 0",
      whereArgs: [PaymentMethod.deferred],
      orderBy: 'created_at DESC',
    );
    return rows.map(Sale.fromMap).toList();
  }

  @override
  Future<void> settleSale({
    required int saleId,
    required String paymentMethod,
    required double amountTendered,
  }) async {
    final db = await _db;
    await db.update(
      'sales',
      {'payment_method': paymentMethod, 'amount_tendered': amountTendered},
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  Future<void> updateSaleItemCostPrice(int saleItemId, double costPrice) async {
    final db = await _db;
    await db.update(
      'sale_items',
      {'cost_price': costPrice},
      where: 'id = ?',
      whereArgs: [saleItemId],
    );
  }

  @override
  Future<void> refundSale(int saleId) async {
    final db = await _db;
    await db.transaction((txn) async {
      final saleRows = await txn.query(
        'sales',
        where: 'id = ?',
        whereArgs: [saleId],
        limit: 1,
      );
      if (saleRows.isEmpty) return;
      final sale = Sale.fromMap(saleRows.first);

      // Check 15-day return window
      final now = DateTime.now();
      final fifteenDaysAgo = now.subtract(const Duration(days: 15));
      if (sale.createdAt.isBefore(fifteenDaysAgo)) {
        // Sale is older than 15 days - cannot refund, reset refunded flag
        await txn.update(
          'sales',
          {'refunded': 0},
          where: 'id = ?',
          whereArgs: [saleId],
        );
        return;
      }

      if (sale.refunded) return;

      final itemRows = await txn.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      for (final row in itemRows) {
        final item = SaleItem.fromMap(row);
        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }

      await txn.update(
        'sales',
        {'refunded': 1, 'refunded_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [saleId],
      );
    });
  }

  // ---- الوردية (Z-Report) ----

  @override
  Future<Shift?> getOpenShift(String cashierName) async {
    final rows = await (await _db).query(
      'shifts',
      where: 'cashier_name = ? AND closed_at IS NULL',
      whereArgs: [cashierName],
      orderBy: 'opened_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : Shift.fromMap(rows.first);
  }

  @override
  Future<Shift?> getLatestShift(String cashierName) async {
    final rows = await (await _db).query(
      'shifts',
      where: 'cashier_name = ?',
      whereArgs: [cashierName],
      orderBy: 'opened_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : Shift.fromMap(rows.first);
  }

  @override
  Future<Shift> ensureOpenShift(
    String cashierName, {
    DateTime? openedAt,
  }) async {
    final existing = await getOpenShift(cashierName);
    if (existing != null) return existing;
    final shift = Shift(
      cashierName: cashierName,
      openedAt: openedAt ?? DateTime.now(),
    );
    final id = await (await _db).insert('shifts', shift.toMap());
    return Shift(id: id, cashierName: cashierName, openedAt: shift.openedAt);
  }

  @override
  Future<ShiftReport> getShiftReport(Shift shift) async {
    final db = await _db;
    final from = shift.openedAt.toIso8601String();
    final to = (shift.closedAt ?? DateTime.now()).toIso8601String();
    final args = [shift.cashierName, from, to];

    final methodRows = await db.rawQuery('''
      SELECT payment_method,
        COUNT(*) AS cnt,
        COALESCE(SUM(total), 0) AS total,
        COALESCE(SUM(card_amount), 0) AS card,
        COALESCE(
          SUM(CASE WHEN amount_tendered > total THEN amount_tendered - total END),
          0
        ) AS change_given
      FROM sales
      WHERE cashier_name = ? AND refunded = 0
        AND created_at >= ? AND created_at < ?
      GROUP BY payment_method
      ''', args);

    double totalOf(String method, String column) {
      for (final row in methodRows) {
        if (row['payment_method'] == method) {
          return (row[column] as num?)?.toDouble() ?? 0;
        }
      }
      return 0;
    }

    final refundRows = await db.rawQuery('''
      SELECT COUNT(*) AS cnt, COALESCE(SUM(total), 0) AS total
      FROM sales
      WHERE cashier_name = ? AND refunded = 1
        AND refunded_at >= ? AND refunded_at < ?
      ''', args);
    final refundRow = refundRows.first;

    return ShiftReport(
      shift: shift,
      salesCount: methodRows.fold<int>(
        0,
        (sum, row) => sum + (row['cnt'] as int? ?? 0),
      ),
      refundCount: refundRow['cnt'] as int? ?? 0,
      cashTotal: totalOf(PaymentMethod.cash, 'total'),
      cardTotal: totalOf(PaymentMethod.card, 'total'),
      walletTotal: totalOf(PaymentMethod.wallet, 'total'),
      transferTotal: totalOf(PaymentMethod.bankTransfer, 'total'),
      mixedTotal: totalOf(PaymentMethod.mixed, 'total'),
      mixedCardPortion: totalOf(PaymentMethod.mixed, 'card'),
      deferredTotal: totalOf(PaymentMethod.deferred, 'total'),
      changeGiven: methodRows.fold<double>(
        0,
        (sum, row) => sum + ((row['change_given'] as num?)?.toDouble() ?? 0),
      ),
      refundsTotal: (refundRow['total'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Future<Shift?> closeShift(String cashierName) async {
    final open = await getOpenShift(cashierName);
    if (open == null) return null;
    final closedAt = DateTime.now();
    await (await _db).update(
      'shifts',
      {'closed_at': closedAt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [open.id],
    );
    return open.copyWith(closedAt: closedAt);
  }

  // ---- الفواتير المعلقة (Hold Invoice) ----

  @override
  Future<int> holdCart({
    required HeldCart cart,
    required List<HeldCartItem> items,
  }) async {
    final db = await _db;
    return db.transaction((txn) async {
      final id = await txn.insert('held_carts', cart.toMap());
      for (final item in items) {
        await txn.insert(
          'held_cart_items',
          item.toMap()..['held_cart_id'] = id,
        );
      }
      return id;
    });
  }

  @override
  Future<List<HeldCart>> getHeldCarts() async {
    final rows = await (await _db).query(
      'held_carts',
      orderBy: 'saved_at DESC',
    );
    return rows.map(HeldCart.fromMap).toList();
  }

  @override
  Future<List<HeldCartItem>> getHeldCartItems(int heldCartId) async {
    final rows = await (await _db).query(
      'held_cart_items',
      where: 'held_cart_id = ?',
      whereArgs: [heldCartId],
    );
    return rows.map(HeldCartItem.fromMap).toList();
  }

  @override
  Future<void> deleteHeldCart(int heldCartId) async {
    await (await _db).delete(
      'held_carts',
      where: 'id = ?',
      whereArgs: [heldCartId],
    );
  }

  // ---- إعدادات المتجر ----

  @override
  Future<String?> getSetting(String key) async {
    final rows = await (await _db).query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  @override
  Future<void> setSetting(String key, String value) async {
    final db = await _db;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<StoreSettings> getSettings() async {
    final db = await _db;
    final rows = await db.query('settings');
    final map = {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
    return StoreSettings(
      storeName: map['store_name'] ?? StoreSettings.empty.storeName,
      phone: map['store_phone'] ?? StoreSettings.empty.phone,
      currency: map['currency'] ?? StoreSettings.empty.currency,
      darkMode: map['dark_mode'] == '1',
      fontScale: double.tryParse(map['font_scale'] ?? '') ?? 1.0,
      taxRate: double.tryParse(map['tax_rate'] ?? '') ?? 0,
    );
  }

  @override
  Future<void> saveSettings(StoreSettings settings) async {
    await setSetting('store_name', settings.storeName);
    await setSetting('store_phone', settings.phone);
    await setSetting('currency', settings.currency);
    await setSetting('dark_mode', settings.darkMode ? '1' : '0');
    await setSetting('font_scale', '${settings.fontScale}');
    await setSetting('tax_rate', '${settings.taxRate}');
  }

  // ===== إدارة الصالات =====

  @override
  Future<List<Hall>> getHalls() async {
    final rows = await (await _db).query('halls', orderBy: 'created_at ASC');
    return rows.map(Hall.fromMap).toList();
  }

  @override
  Future<int> addHall(Hall hall) async {
    return (await _db).insert('halls', hall.toMap());
  }

  @override
  Future<void> updateHall(Hall hall) async {
    await (await _db).update(
      'halls',
      hall.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [hall.id],
    );
  }

  @override
  Future<void> deleteHall(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'restaurant_tables',
        where: 'hall_id = ?',
        whereArgs: [id],
      );
      await txn.delete('halls', where: 'id = ?', whereArgs: [id]);
    });
  }

  // ===== إدارة الترابيزات =====

  @override
  Future<List<RestaurantTable>> getTables() async {
    final rows = await (await _db).query(
      'restaurant_tables',
      orderBy: 'number ASC',
    );
    return rows.map(RestaurantTable.fromMap).toList();
  }

  @override
  Future<List<RestaurantTable>> getTablesByHall(int hallId) async {
    final rows = await (await _db).query(
      'restaurant_tables',
      where: 'hall_id = ?',
      whereArgs: [hallId],
      orderBy: 'number ASC',
    );
    return rows.map(RestaurantTable.fromMap).toList();
  }

  @override
  Future<int> addTable(RestaurantTable table) async {
    return (await _db).insert('restaurant_tables', table.toMap());
  }

  @override
  Future<void> updateTable(RestaurantTable table) async {
    await (await _db).update(
      'restaurant_tables',
      table.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [table.id],
    );
  }

  @override
  Future<void> deleteTable(int id) async {
    await (await _db).delete(
      'restaurant_tables',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateTableStatus(
    int tableId,
    TableStatus status, {
    int? orderId,
  }) async {
    final map = <String, Object?>{'status': status.name};
    if (orderId != null) {
      map['current_order_id'] = orderId;
    } else if (status == TableStatus.available) {
      map['current_order_id'] = null;
    }
    await (await _db).update(
      'restaurant_tables',
      map,
      where: 'id = ?',
      whereArgs: [tableId],
    );
  }

  @override
  Future<RestaurantTable?> getTable(int id) async {
    final rows = await (await _db).query(
      'restaurant_tables',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : RestaurantTable.fromMap(rows.first);
  }

  @override
  Future<List<RestaurantOrder>> getTableOrders(int tableId) async {
    final rows = await (await _db).query(
      'orders',
      where: "table_id = ? AND status NOT IN ($_settledOrderStatuses)",
      whereArgs: [tableId],
      orderBy: 'created_at ASC',
    );
    return rows.map(RestaurantOrder.fromMap).toList();
  }

  @override
  Future<double> payTable(int tableId, String paymentMethod) async {
    final db = await _db;
    return db.transaction((txn) async {
      final orderRows = await txn.query(
        'orders',
        where: "table_id = ? AND status NOT IN ($_settledOrderStatuses)",
        whereArgs: [tableId],
      );
      if (orderRows.isEmpty) return 0;

      final now = DateTime.now().toIso8601String();
      var totalAmount = 0.0;
      for (final row in orderRows) {
        totalAmount += (row['total'] as num).toDouble();
        final orderId = row['id'] as int;
        await txn.update(
          'orders',
          {
            'status': OrderStatus.paid.name,
            'completed_at': now,
            'payment_method': paymentMethod,
          },
          where: 'id = ?',
          whereArgs: [orderId],
        );
        await txn.insert(
          'order_status_history',
          OrderStatusHistory(
            orderId: orderId,
            status: OrderStatus.paid.name,
          ).toMap(),
        );
      }

      await txn.update(
        'restaurant_tables',
        {'status': TableStatus.available.name, 'current_order_id': null},
        where: 'id = ?',
        whereArgs: [tableId],
      );

      return totalAmount;
    });
  }

  // ===== إدارة الموظفين =====

  @override
  Future<List<Employee>> getEmployees() async {
    final rows = await (await _db).query(
      'employees',
      orderBy: 'created_at ASC',
    );
    return rows.map(Employee.fromMap).toList();
  }

  @override
  Future<List<Employee>> getActiveEmployees() async {
    final rows = await (await _db).query(
      'employees',
      where: 'is_active = 1',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Employee.fromMap).toList();
  }

  @override
  Future<List<Employee>> getDeliveryPersons() async {
    final rows = await (await _db).query(
      'employees',
      where: "is_active = 1 AND role = 'delivery'",
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Employee.fromMap).toList();
  }

  @override
  Future<int> addEmployee(Employee employee) async {
    return (await _db).insert('employees', employee.toMap());
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    await (await _db).update(
      'employees',
      employee.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  @override
  Future<void> deleteEmployee(int id) async {
    await (await _db).delete('employees', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Employee?> getEmployee(int id) async {
    final rows = await (await _db).query(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Employee.fromMap(rows.first);
  }

  // ===== سلف الموظفين =====

  @override
  Future<int> addEmployeeAdvance(EmployeeAdvance advance) async {
    return (await _db).insert('employee_advances', advance.toMap());
  }

  @override
  Future<List<EmployeeAdvance>> getEmployeeAdvances(
    int employeeId, {
    DateTime? date,
  }) async {
    final db = await _db;
    String? where;
    List<Object?>? whereArgs;
    if (date != null) {
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      where = 'employee_id = ? AND created_at >= ? AND created_at < ?';
      whereArgs = [
        employeeId,
        dayStart.toIso8601String(),
        dayEnd.toIso8601String(),
      ];
    } else {
      where = 'employee_id = ?';
      whereArgs = [employeeId];
    }
    final rows = await db.query(
      'employee_advances',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return rows.map(EmployeeAdvance.fromMap).toList();
  }

  @override
  Future<DailyEmployeeReport> getEmployeeDailyReport(
    int employeeId,
    DateTime date,
  ) async {
    final db = await _db;
    final employee = await getEmployee(employeeId);
    final employeeName = employee?.name ?? '';
    final salary = employee?.salary ?? 0;

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final from = dayStart.toIso8601String();
    final to = dayEnd.toIso8601String();

    // عدد الأوردرات وإجمالي المبيعات
    final orderRows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS cnt, COALESCE(SUM(total), 0) AS total
      FROM orders
      WHERE employee_id = ? AND created_at >= ? AND created_at < ?
        AND status != 'cancelled' AND refunded = 0
      ''',
      [employeeId, from, to],
    );
    final ordersCount = orderRows.first['cnt'] as int? ?? 0;
    final totalSales = (orderRows.first['total'] as num?)?.toDouble() ?? 0;

    // السلف
    final advanceRows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM employee_advances
      WHERE employee_id = ? AND type = 'advance'
        AND created_at >= ? AND created_at < ?
      ''',
      [employeeId, from, to],
    );
    final advancesTaken = (advanceRows.first['total'] as num?)?.toDouble() ?? 0;

    // الخصومات
    final deductionRows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM employee_advances
      WHERE employee_id = ? AND type = 'deduction'
        AND created_at >= ? AND created_at < ?
      ''',
      [employeeId, from, to],
    );
    final deductions = (deductionRows.first['total'] as num?)?.toDouble() ?? 0;

    return DailyEmployeeReport(
      employeeName: employeeName,
      date: date,
      ordersCount: ordersCount,
      totalSales: totalSales,
      advancesTaken: advancesTaken,
      deductions: deductions,
      salary: salary,
    );
  }

  // ===== تقرير الصالة اليومي =====

  @override
  Future<HallDailyReport> getHallDailyReport(int hallId, DateTime date) async {
    final db = await _db;
    final hallRows = await db.query(
      'halls',
      where: 'id = ?',
      whereArgs: [hallId],
      limit: 1,
    );
    final hallName = hallRows.isNotEmpty
        ? hallRows.first['name'] as String
        : '';

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final from = dayStart.toIso8601String();
    final to = dayEnd.toIso8601String();

    // عدد الطلبات وإجمالي الإيرادات في الصالة نهارًا
    final orderRows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS cnt, COALESCE(SUM(total), 0) AS total
      FROM orders
      WHERE hall_id = ? AND created_at >= ? AND created_at < ?
        AND status != 'cancelled' AND refunded = 0
      ''',
      [hallId, from, to],
    );
    final ordersCount = orderRows.first['cnt'] as int? ?? 0;
    final totalRevenue = (orderRows.first['total'] as num?)?.toDouble() ?? 0;

    // عدد الطلبات النشطة (المعلقة على الترابيزات)
    final activeRows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS cnt
      FROM orders o
      INNER JOIN restaurant_tables rt ON rt.id = o.table_id
      WHERE rt.hall_id = ? AND o.status IN ('pending', 'preparing')
      ''',
      [hallId],
    );
    final activeOrdersCount = activeRows.first['cnt'] as int? ?? 0;

    // عدد الترابيزات الكلي والمشغول
    final tablesRows = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM restaurant_tables WHERE hall_id = ?',
      [hallId],
    );
    final tablesCount = tablesRows.first['cnt'] as int? ?? 0;

    final occupiedRows = await db.rawQuery(
      "SELECT COUNT(*) AS cnt FROM restaurant_tables WHERE hall_id = ? AND status = 'occupied'",
      [hallId],
    );
    final occupiedTablesCount = occupiedRows.first['cnt'] as int? ?? 0;

    return HallDailyReport(
      hallName: hallName,
      date: date,
      ordersCount: ordersCount,
      totalRevenue: totalRevenue,
      activeOrdersCount: activeOrdersCount,
      tablesCount: tablesCount,
      occupiedTablesCount: occupiedTablesCount,
    );
  }

  // ===== نظام الطلبات =====

  @override
  Future<List<RestaurantOrder>> getOrders({
    int? limit,
    String? status,
    String? orderType,
  }) async {
    final conditions = <String>[];
    final args = <Object?>[];
    if (status != null) {
      conditions.add('status = ?');
      args.add(status);
    }
    if (orderType != null) {
      conditions.add('order_type = ?');
      args.add(orderType);
    }
    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    final rows = await (await _db).query(
      'orders',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(RestaurantOrder.fromMap).toList();
  }

  @override
  Future<RestaurantOrder?> getOrder(int id) async {
    final rows = await (await _db).query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : RestaurantOrder.fromMap(rows.first);
  }

  @override
  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final rows = await (await _db).query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    return rows.map(OrderItem.fromMap).toList();
  }

  @override
  Future<int> createOrder({
    required RestaurantOrder order,
    required List<OrderItem> items,
  }) async {
    final db = await _db;
    return db.transaction((txn) async {
      final orderMap = order.toMap()..remove('id');
      final orderId = await txn.insert('orders', orderMap);

      // سجل الحالة الأولى
      await txn.insert('order_status_history', {
        'order_id': orderId,
        'status': OrderStatus.pending.name,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (final item in items) {
        await txn.insert('order_items', item.toMap()..['order_id'] = orderId);
      }

      // ربط الطلب بالتريبية وتحديث حالتها (فقط لو التريبية فاضية)
      if (order.tableId != null) {
        final tableRows = await txn.query(
          'restaurant_tables',
          where: 'id = ?',
          whereArgs: [order.tableId],
          limit: 1,
        );
        if (tableRows.isNotEmpty) {
          final currentStatus = tableRows.first['status'] as String;
          if (currentStatus == TableStatus.available.name) {
            await txn.update(
              'restaurant_tables',
              {
                'status': TableStatus.occupied.name,
                'current_order_id': orderId,
              },
              where: 'id = ?',
              whereArgs: [order.tableId],
            );
          }
        }
      }

      return orderId;
    });
  }

  @override
  Future<void> updateOrderStatus(
    int orderId,
    OrderStatus status, {
    String note = '',
  }) async {
    final updates = <String, Object?>{'status': status.name};
    final terminalStatuses = {
      OrderStatus.served,
      OrderStatus.cancelled,
      OrderStatus.paid,
      OrderStatus.handedOver,
      OrderStatus.delivered,
      OrderStatus.awaitingPayment,
    };
    if (terminalStatuses.contains(status)) {
      updates['completed_at'] = DateTime.now().toIso8601String();
    }

    final freesTableStatuses = {
      OrderStatus.cancelled,
      OrderStatus.paid,
      OrderStatus.handedOver,
      OrderStatus.delivered,
    };
    final db = await _db;
    await db.transaction((txn) async {
      final updated = await txn.update(
        'orders',
        updates,
        where: 'id = ?',
        whereArgs: [orderId],
      );
      if (updated == 0) return;
      await txn.insert(
        'order_status_history',
        OrderStatusHistory(
          orderId: orderId,
          status: status.name,
          note: note,
        ).toMap(),
      );

      if (!freesTableStatuses.contains(status)) return;
      final orderRows = await txn.query(
        'orders',
        where: 'id = ?',
        whereArgs: [orderId],
        limit: 1,
      );
      if (orderRows.isEmpty) return;
      final tableId = orderRows.first['table_id'] as int?;
      if (tableId == null) return;

      final activeRows = await txn.query(
        'orders',
        where:
            "table_id = ? AND id != ? AND status NOT IN ($_settledOrderStatuses)",
        whereArgs: [tableId, orderId],
        limit: 1,
      );
      if (activeRows.isEmpty) {
        await txn.update(
          'restaurant_tables',
          {'status': TableStatus.available.name, 'current_order_id': null},
          where: 'id = ?',
          whereArgs: [tableId],
        );
      }
    });
  }

  @override
  Future<void> addOrderStatusHistory(OrderStatusHistory entry) async {
    await (await _db).insert('order_status_history', entry.toMap());
  }

  @override
  Future<List<OrderStatusHistory>> getOrderStatusHistory(int orderId) async {
    final rows = await (await _db).query(
      'order_status_history',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'created_at ASC',
    );
    return rows.map(OrderStatusHistory.fromMap).toList();
  }

  @override
  Future<void> updateOrderItemStatus(int orderItemId, String status) async {
    await (await _db).update(
      'order_items',
      {'status': status},
      where: 'id = ?',
      whereArgs: [orderItemId],
    );
  }

  @override
  Future<void> cancelOrder(int orderId) async {
    final db = await _db;
    await db.transaction((txn) async {
      final orderRows = await txn.query(
        'orders',
        where: 'id = ?',
        whereArgs: [orderId],
        limit: 1,
      );
      if (orderRows.isEmpty) return;
      final order = RestaurantOrder.fromMap(orderRows.first);
      if (const {
        OrderStatus.paid,
        OrderStatus.delivered,
        OrderStatus.handedOver,
      }.contains(order.orderStatus)) {
        throw StateError('لا يمكن إلغاء طلب تم تسويده');
      }

      await txn.update(
        'orders',
        {
          'status': OrderStatus.cancelled.name,
          'completed_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );
      await txn.insert(
        'order_status_history',
        OrderStatusHistory(
          orderId: orderId,
          status: OrderStatus.cancelled.name,
        ).toMap(),
      );

      if (order.tableId != null) {
        final activeRows = await txn.query(
          'orders',
          where:
              "table_id = ? AND id != ? AND status NOT IN ($_settledOrderStatuses)",
          whereArgs: [order.tableId, orderId],
          limit: 1,
        );
        if (activeRows.isEmpty) {
          await txn.update(
            'restaurant_tables',
            {'status': TableStatus.available.name, 'current_order_id': null},
            where: 'id = ?',
            whereArgs: [order.tableId],
          );
        }
      }
    });
  }

  @override
  Future<List<RestaurantOrder>> getActiveOrders() async {
    final rows = await (await _db).query(
      'orders',
      where: "status IN ('pending', 'preparing')",
      orderBy: 'created_at ASC',
    );
    return rows.map(RestaurantOrder.fromMap).toList();
  }

  @override
  Future<List<RestaurantOrder>> getActiveDeliveryOrders() async {
    final rows = await (await _db).query(
      'orders',
      where: "order_type = 'delivery' AND status IN ('pending', 'preparing')",
      orderBy: 'created_at ASC',
    );
    return rows.map(RestaurantOrder.fromMap).toList();
  }

  @override
  Future<List<RestaurantOrder>> getKitchenOrders() async {
    final rows = await (await _db).query(
      'orders',
      where: "status IN ('pending', 'preparing', 'ready')",
      orderBy: 'created_at ASC',
    );
    return rows.map(RestaurantOrder.fromMap).toList();
  }

  @override
  Future<int> getActiveOrdersCount() async {
    final rows = await (await _db).rawQuery(
      "SELECT COUNT(*) AS cnt FROM orders WHERE status IN ('pending', 'preparing')",
    );
    return rows.first['cnt'] as int? ?? 0;
  }

  @override
  Future<int> getOccupiedTablesCount() async {
    final rows = await (await _db).rawQuery(
      "SELECT COUNT(*) AS cnt FROM restaurant_tables WHERE status = 'occupied'",
    );
    return rows.first['cnt'] as int? ?? 0;
  }

  @override
  Future<int> getActiveEmployeesCount() async {
    final rows = await (await _db).rawQuery(
      'SELECT COUNT(*) AS cnt FROM employees WHERE is_active = 1',
    );
    return rows.first['cnt'] as int? ?? 0;
  }

  /// مفتاح يوم بصيغة ISO قابلة للمقارنة: 'yyyy-MM-ddT00:00:00.000'.
  static String _dayKey(DateTime day) =>
      DateTime(day.year, day.month, day.day).toIso8601String();

  /// يحوّل مفتاح 'yyyy-MM-dd' إلى تاريخ محلي.
  static DateTime _parseDayKey(String key) => DateTime.parse('${key}T00:00:00');

  // ===== رصيد المندوبين =====

  @override
  Future<List<RiderTransaction>> getRiderTransactions(int riderId) async {
    final rows = await (await _db).query(
      'rider_transactions',
      where: 'rider_id = ?',
      whereArgs: [riderId],
      orderBy: 'created_at DESC',
    );
    return rows.map(RiderTransaction.fromMap).toList();
  }

  @override
  Future<double> getRiderBalance(int riderId) async {
    final rows = await (await _db).rawQuery(
      '''SELECT
           COALESCE(SUM(CASE WHEN type = 'order_collection' THEN amount ELSE 0 END), 0)
           - COALESCE(SUM(CASE WHEN type IN ('settlement', 'advance') THEN amount ELSE 0 END), 0)
           AS balance
         FROM rider_transactions
         WHERE rider_id = ?''',
      [riderId],
    );
    return (rows.first['balance'] as num?)?.toDouble() ?? 0;
  }

  @override
  Future<int> addRiderTransaction(RiderTransaction transaction) async {
    return (await _db).insert('rider_transactions', transaction.toMap());
  }

  @override
  Future<List<RestaurantOrder>> getRiderOutstandingOrders(int riderId) async {
    final rows = await (await _db).query(
      'orders',
      where: '''rider_id = ?
        AND order_type = 'delivery'
        AND status IN ('delivered', 'handedOver')
        AND id NOT IN (
          SELECT DISTINCT order_id FROM rider_transactions
          WHERE rider_id = ? AND order_id IS NOT NULL AND type = 'order_collection'
        )''',
      whereArgs: [riderId, riderId],
      orderBy: 'created_at DESC',
    );
    return rows.map(RestaurantOrder.fromMap).toList();
  }

  // ===== إدارة الموردين =====

  @override
  Future<List<Supplier>> getSuppliers() async {
    final rows = await (await _db).query('suppliers', orderBy: 'name ASC');
    return rows.map(Supplier.fromMap).toList();
  }

  @override
  Future<int> addSupplier(Supplier supplier) async {
    return (await _db).insert('suppliers', supplier.toMap());
  }

  @override
  Future<void> updateSupplier(Supplier supplier) async {
    await (await _db).update(
      'suppliers',
      supplier.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  @override
  Future<void> deleteSupplier(int id) async {
    await (await _db).delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Supplier?> getSupplier(int id) async {
    final rows = await (await _db).query(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Supplier.fromMap(rows.first);
  }

  // ===== إدارة المشتريات =====

  @override
  Future<List<Purchase>> getPurchases({int? limit}) async {
    final rows = await (await _db).query(
      'purchases',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(Purchase.fromMap).toList();
  }

  @override
  Future<Purchase?> getPurchase(int id) async {
    final rows = await (await _db).query(
      'purchases',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Purchase.fromMap(rows.first);
  }

  @override
  Future<List<PurchaseItem>> getPurchaseItems(int purchaseId) async {
    final rows = await (await _db).query(
      'purchase_items',
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
    return rows.map(PurchaseItem.fromMap).toList();
  }

  @override
  Future<int> createPurchase({
    required Purchase purchase,
    required List<PurchaseItem> items,
  }) async {
    return (await _db).transaction((txn) async {
      final purchaseId = await txn.insert('purchases', purchase.toMap());
      for (final item in items) {
        final itemMap = item.copyWith(purchaseId: purchaseId).toMap();
        await txn.insert('purchase_items', itemMap);
        // زيادة مخزون الصنف بالكمية المحوّلة لوحدة المخزون الأساسية
        // (مثلًا: 8 كراتين × 24 قطعة = 192 قطعة).
        if (item.productId != null && item.stockQuantity != 0) {
          await txn.rawUpdate(
            'UPDATE products SET stock = MAX(stock + ?, 0) WHERE id = ?',
            [item.stockQuantity, item.productId],
          );
          // تحديث سعر تكلفة الوحدة الأساسية من سعر الشراء الأخير.
          if (item.price > 0) {
            await txn.update(
              'products',
              {'cost_price': item.baseUnitCost},
              where: 'id = ?',
              whereArgs: [item.productId],
            );
          }
        }
      }
      return purchaseId;
    });
  }

  @override
  Future<void> settlePurchase({
    required int purchaseId,
    required double amount,
  }) async {
    await (await _db).transaction((txn) async {
      final rows = await txn.query(
        'purchases',
        where: 'id = ?',
        whereArgs: [purchaseId],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final current = Purchase.fromMap(rows.first);
      final newPaid = current.paidAmount + amount;
      await txn.update(
        'purchases',
        {'paid_amount': newPaid},
        where: 'id = ?',
        whereArgs: [purchaseId],
      );
      if (current.supplierId != null) {
        await txn.rawUpdate(
          'UPDATE suppliers SET balance = balance - ? WHERE id = ?',
          [amount, current.supplierId],
        );
      }
    });
  }

  @override
  Future<List<SupplierPayment>> getSupplierPayments(int supplierId) async {
    final rows = await (await _db).query(
      'supplier_payments',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'created_at DESC',
    );
    return rows.map(SupplierPayment.fromMap).toList();
  }

  // ===== إدارة الكوبونات =====

  @override
  Future<List<Coupon>> getCoupons() async {
    final rows = await (await _db).query('coupons', orderBy: 'created_at DESC');
    return rows.map(Coupon.fromMap).toList();
  }

  @override
  Future<int> addCoupon(Coupon coupon) async {
    return (await _db).insert('coupons', coupon.toMap());
  }

  @override
  Future<void> updateCoupon(Coupon coupon) async {
    await (await _db).update(
      'coupons',
      coupon.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [coupon.id],
    );
  }

  @override
  Future<void> deleteCoupon(int id) async {
    await (await _db).delete('coupons', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Coupon?> getCouponByCode(String code) async {
    final rows = await (await _db).query(
      'coupons',
      where: 'UPPER(code) = ?',
      whereArgs: [code.toUpperCase()],
      limit: 1,
    );
    return rows.isEmpty ? null : Coupon.fromMap(rows.first);
  }

  @override
  Future<void> useCoupon(int couponId) async {
    await (await _db).rawUpdate(
      'UPDATE coupons SET used_count = used_count + 1 WHERE id = ?',
      [couponId],
    );
  }

  // ===== إدارة العملاء =====

  @override
  Future<List<Customer>> getCustomers() async {
    final rows = await (await _db).query('customers', orderBy: 'name ASC');
    return rows.map(Customer.fromMap).toList();
  }

  @override
  Future<int> addCustomer(Customer customer) async {
    return (await _db).insert('customers', customer.toMap());
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    await (await _db).update(
      'customers',
      customer.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  @override
  Future<void> deleteCustomer(int id) async {
    await (await _db).delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Customer?> getCustomer(int id) async {
    final rows = await (await _db).query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Customer.fromMap(rows.first);
  }

  @override
  Future<Customer?> getCustomerByPhone(String phone) async {
    final rows = await (await _db).query(
      'customers',
      where: 'phone = ?',
      whereArgs: [phone],
      limit: 1,
    );
    return rows.isEmpty ? null : Customer.fromMap(rows.first);
  }

  @override
  Future<void> addLoyaltyPoints(int customerId, int points) async {
    await (await _db).rawUpdate(
      'UPDATE customers SET loyalty_points = loyalty_points + ? WHERE id = ?',
      [points, customerId],
    );
  }

  // ===== إدارة الحجوزات =====
  @override
  Future<List<Reservation>> getReservations() async {
    final maps = await (await _db).query(
      'reservations',
      orderBy: 'reservation_time DESC',
    );
    return [for (final m in maps) Reservation.fromMap(m)];
  }

  @override
  Future<int> createReservation(Reservation reservation) async {
    return await (await _db).insert('reservations', reservation.toMap());
  }

  @override
  Future<void> updateReservationStatus(int id, ReservationStatus status) async {
    await (await _db).update(
      'reservations',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteReservation(int id) async {
    await (await _db).delete('reservations', where: 'id = ?', whereArgs: [id]);
  }

  // ===== إدارة قائمة الانتظار =====
  @override
  Future<List<QueueEntry>> getQueueEntries() async {
    final maps = await (await _db).query(
      'queue_entries',
      orderBy: 'created_at ASC',
    );
    return [for (final m in maps) QueueEntry.fromMap(m)];
  }

  @override
  Future<int> addQueueEntry(QueueEntry entry) async {
    return await (await _db).insert('queue_entries', entry.toMap());
  }

  @override
  Future<void> updateQueueEntryStatus(int id, QueueStatus status) async {
    await (await _db).update(
      'queue_entries',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteQueueEntry(int id) async {
    await (await _db).delete('queue_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ===== إدارة الوصفات =====
  @override
  Future<List<Recipe>> getRecipes() async {
    final maps = await (await _db).query('recipes', orderBy: 'created_at DESC');
    return [for (final m in maps) Recipe.fromMap(m)];
  }

  @override
  Future<int> createRecipe(Recipe recipe) async {
    final id = await (await _db).insert('recipes', recipe.toMap());
    for (final item in recipe.items) {
      await (await _db).insert(
        'recipe_items',
        item.copyWith(recipeId: id).toMap(),
      );
    }
    return id;
  }

  @override
  Future<void> updateRecipe(Recipe recipe) async {
    await (await _db).update(
      'recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
    // Delete old items and re-insert
    await (await _db).delete(
      'recipe_items',
      where: 'recipe_id = ?',
      whereArgs: [recipe.id],
    );
    for (final item in recipe.items) {
      await (await _db).insert(
        'recipe_items',
        item.copyWith(recipeId: recipe.id).toMap(),
      );
    }
  }

  @override
  Future<void> deleteRecipe(int id) async {
    await (await _db).delete(
      'recipe_items',
      where: 'recipe_id = ?',
      whereArgs: [id],
    );
    await (await _db).delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<RecipeItem>> getRecipeItems(int recipeId) async {
    final maps = await (await _db).query(
      'recipe_items',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
    );
    return [for (final m in maps) RecipeItem.fromMap(m)];
  }

  @override
  Future<void> addRecipeItem(RecipeItem item) async {
    await (await _db).insert('recipe_items', item.toMap());
  }

  @override
  Future<void> deleteRecipeItem(int id) async {
    await (await _db).delete('recipe_items', where: 'id = ?', whereArgs: [id]);
  }
}

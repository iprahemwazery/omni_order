import 'package:sqflite/sqflite.dart';

import '../../core/constants/payment_methods.dart';
import '../../domain/models/admin.dart';
import '../../domain/models/category.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/customer_payment.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/held_cart.dart';
import '../../domain/models/product.dart';
import '../../domain/models/purchase.dart';
import '../../domain/models/purchase_item.dart';
import '../../domain/models/sale.dart';
import '../../domain/models/sale_item.dart';
import '../../domain/models/shift.dart';
import '../../domain/models/store_settings.dart';
import '../../domain/models/summaries.dart';
import '../../domain/models/supplier.dart';
import '../../domain/models/supplier_payment.dart';
import '../../domain/repositories/store_repository.dart';
import '../database/app_database.dart';

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

  // ---- العملاء ----

  @override
  Future<List<Customer>> getCustomers() async {
    final rows = await (await _db).query(
      'customers',
      orderBy: 'name COLLATE NOCASE',
    );
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

  // ---- دفعات العملاء ----

  @override
  Future<List<CustomerPayment>> getCustomerPayments(int customerId) async {
    final rows = await (await _db).query(
      'customer_payments',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return rows.map(CustomerPayment.fromMap).toList();
  }

  @override
  Future<void> addCustomerPayment(CustomerPayment payment) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert('customer_payments', payment.toMap());
      await txn.rawUpdate(
        'UPDATE customers SET balance = MAX(balance - ?, 0) WHERE id = ?',
        [payment.amount, payment.customerId],
      );
    });
  }

  // ---- الموردين ----

  @override
  Future<List<Supplier>> getSuppliers() async {
    final rows = await (await _db).query(
      'suppliers',
      orderBy: 'name COLLATE NOCASE',
    );
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

  // ---- دفعات الموردين ----

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

  @override
  Future<void> addSupplierPayment(SupplierPayment payment) async {
    final db = await _db;
    await db.transaction((txn) async {
      // توزيع المبلغ على فواتير الشراء غير المسددة (الأقدم أولًا)
      var remaining = payment.amount;
      int? firstPurchaseId;
      final targetedPurchaseIds = <int>{};

      if (payment.purchaseId != null && remaining > 0) {
        final targetRows = await txn.query(
          'purchases',
          where: 'id = ? AND supplier_id = ?',
          whereArgs: [payment.purchaseId, payment.supplierId],
          limit: 1,
        );
        if (targetRows.isNotEmpty) {
          final target = targetRows.first;
          final targetId = target['id'] as int;
          final total = (target['total'] as num).toDouble();
          final paidAmount =
              (target['paid_amount'] as num?)?.toDouble() ?? 0;
          final capacity = (total - paidAmount).clamp(0.0, double.infinity);
          if (capacity > 0) {
            final allocate = remaining >= capacity ? capacity : remaining;
            await txn.rawUpdate(
              'UPDATE purchases SET paid_amount = paid_amount + ? WHERE id = ?',
              [allocate, targetId],
            );
            firstPurchaseId = targetId;
            targetedPurchaseIds.add(targetId);
            remaining -= allocate;
          }
        }
      }

      if (remaining > 0) {
        final purchaseRows = await txn.query(
          'purchases',
          where: 'supplier_id = ? AND total > paid_amount',
          whereArgs: [payment.supplierId],
          orderBy: 'created_at ASC, id ASC',
        );
        for (final row in purchaseRows) {
          if (remaining <= 0) break;
          final purchaseId = row['id'] as int;
          if (targetedPurchaseIds.contains(purchaseId)) continue;
          final total = (row['total'] as num).toDouble();
          final paidAmount =
              (row['paid_amount'] as num?)?.toDouble() ?? 0;
          final capacity = (total - paidAmount).clamp(0.0, double.infinity);
          if (capacity <= 0) continue;
          final allocate = remaining >= capacity ? capacity : remaining;
          await txn.rawUpdate(
            'UPDATE purchases SET paid_amount = paid_amount + ? WHERE id = ?',
            [allocate, purchaseId],
          );
          firstPurchaseId ??= purchaseId;
          remaining -= allocate;
        }
      }

      final map = payment.toMap()..remove('id');
      if (firstPurchaseId != null) map['purchase_id'] = firstPurchaseId;
      await txn.insert('supplier_payments', map);

      await txn.rawUpdate(
        'UPDATE suppliers SET balance = MAX(balance - ?, 0) WHERE id = ?',
        [payment.amount, payment.supplierId],
      );
    });
  }

  // ---- المشتريات ----

  @override
  Future<List<Purchase>> getPurchases() async {
    final rows = await (await _db).query(
      'purchases',
      orderBy: 'created_at DESC',
    );
    return rows.map(Purchase.fromMap).toList();
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
    final db = await _db;
    return db.transaction((txn) async {
      int? supplierId = purchase.supplierId;
      var supplierName = purchase.supplierName.trim();

      if (supplierId == null && supplierName.isNotEmpty) {
        final supplierRows = await txn.query(
          'suppliers',
          where: 'LOWER(TRIM(name)) = ?',
          whereArgs: [supplierName.toLowerCase()],
          limit: 1,
        );
        if (supplierRows.isNotEmpty) {
          supplierId = supplierRows.first['id'] as int;
        }
      }
      if (supplierId != null && supplierName.isEmpty) {
        final supplierRows = await txn.query(
          'suppliers',
          where: 'id = ?',
          whereArgs: [supplierId],
          limit: 1,
        );
        if (supplierRows.isNotEmpty) {
          supplierName = (supplierRows.first['name'] as String).trim();
        }
      }

      final purchaseMap = purchase.toMap();
      if (supplierId != null) purchaseMap['supplier_id'] = supplierId;
      final purchaseId = await txn.insert('purchases', purchaseMap);
      for (final item in items) {
        await txn.insert(
          'purchase_items',
          item.toMap()..['purchase_id'] = purchaseId,
        );
        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ?, cost_price = ? WHERE id = ?',
          [item.quantity, item.price, item.productId],
        );
      }

      if (supplierId != null) {
        final remainingDebt = (purchase.total - purchase.paidAmount).clamp(
          0.0,
          double.infinity,
        );
        await txn.rawUpdate(
          'UPDATE suppliers SET balance = balance + ? WHERE id = ?',
          [remainingDebt, supplierId],
        );
      }

      return purchaseId;
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
      whereArgs: [
        _dayKey(day),
        _dayKey(day.add(const Duration(days: 1))),
      ],
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

    final entries = byDay.values.toList()..sort((a, b) => b.day.compareTo(a.day));
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
      var sql = 'SELECT COALESCE(SUM(amount), 0) AS amt, COUNT(*) AS cnt '
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
      whereArgs: [
        _dayKey(day),
        _dayKey(day.add(const Duration(days: 1))),
      ],
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
      // تحديث مديونية العميل داخل نفس المعاملة لضمان الاتساق.
      if (sale.paymentMethod == PaymentMethod.deferred && sale.customerId != null) {
        await txn.rawUpdate(
          'UPDATE customers SET balance = balance + ? WHERE id = ?',
          [sale.total, sale.customerId],
        );
      }
      return saleId;
    });
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
        {
          'refunded': 1,
          'refunded_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [saleId],
      );

      // Cancel effect on customer deferred debt if the sale was آجل
      if (sale.paymentMethod == PaymentMethod.deferred && sale.customerId != null) {
        await txn.rawUpdate(
          'UPDATE customers SET balance = MAX(balance - ?, 0) WHERE id = ?',
          [sale.total, sale.customerId],
        );
      }
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
  Future<Shift> ensureOpenShift(String cashierName, {DateTime? openedAt}) async {
    final existing = await getOpenShift(cashierName);
    if (existing != null) return existing;
    final shift = Shift(
      cashierName: cashierName,
      openedAt: openedAt ?? DateTime.now(),
    );
    final id = await (await _db).insert('shifts', shift.toMap());
    return Shift(
      id: id,
      cashierName: cashierName,
      openedAt: shift.openedAt,
    );
  }

  @override
  Future<ShiftReport> getShiftReport(Shift shift) async {
    final db = await _db;
    final from = shift.openedAt.toIso8601String();
    final to = (shift.closedAt ?? DateTime.now()).toIso8601String();
    final args = [shift.cashierName, from, to];

    final methodRows = await db.rawQuery(
      '''
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
      ''',
      args,
    );

    double totalOf(String method, String column) {
      for (final row in methodRows) {
        if (row['payment_method'] == method) {
          return (row[column] as num?)?.toDouble() ?? 0;
        }
      }
      return 0;
    }

    final refundRows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS cnt, COALESCE(SUM(total), 0) AS total
      FROM sales
      WHERE cashier_name = ? AND refunded = 1
        AND refunded_at >= ? AND refunded_at < ?
      ''',
      args,
    );
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

  /// مفتاح يوم بصيغة ISO قابلة للمقارنة: 'yyyy-MM-ddT00:00:00.000'.
  static String _dayKey(DateTime day) =>
      DateTime(day.year, day.month, day.day).toIso8601String();

  /// يحوّل مفتاح 'yyyy-MM-dd' إلى تاريخ محلي.
  static DateTime _parseDayKey(String key) =>
      DateTime.parse('${key}T00:00:00');
}

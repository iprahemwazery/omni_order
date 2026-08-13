import 'package:sqflite/sqflite.dart';

import '../../domain/models/admin.dart';
import '../../domain/models/category.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/customer_payment.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/product.dart';
import '../../domain/models/purchase.dart';
import '../../domain/models/purchase_item.dart';
import '../../domain/models/sale.dart';
import '../../domain/models/sale_item.dart';
import '../../domain/models/store_settings.dart';
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
  Future<List<Expense>> getExpenses() async {
    final rows = await (await _db).query(
      'expenses',
      orderBy: 'created_at DESC',
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
  Future<List<Sale>> getSales() async {
    final rows = await (await _db).query('sales', orderBy: 'created_at DESC');
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
  Future<List<SaleItem>> getAllSaleItems() async {
    final rows = await (await _db).query('sale_items');
    return rows.map(SaleItem.fromMap).toList();
  }

  @override
  Future<int> createSale({
    required Sale sale,
    required List<SaleItem> items,
  }) async {
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
        {'refunded': 1},
        where: 'id = ?',
        whereArgs: [saleId],
      );

      // Cancel effect on customer deferred debt if the sale was آجل
      if (sale.paymentMethod == 'آجل' && sale.customerId != null) {
        await txn.rawUpdate(
          'UPDATE customers SET balance = MAX(balance - ?, 0) WHERE id = ?',
          [sale.total, sale.customerId],
        );
      }
    });
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
    );
  }

  @override
  Future<void> saveSettings(StoreSettings settings) async {
    await setSetting('store_name', settings.storeName);
    await setSetting('store_phone', settings.phone);
    await setSetting('currency', settings.currency);
    await setSetting('dark_mode', settings.darkMode ? '1' : '0');
    await setSetting('font_scale', '${settings.fontScale}');
  }
}

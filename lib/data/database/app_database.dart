import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show databaseFactorySqflitePlugin;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants.dart';

/// قاعدة البيانات المحلية (SQLite) — إنشاء الجداول والترحيل وإدارة الاتصال.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;
  String? _path;

  Future<Database> get database async => _db ??= await _open();

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) {
      await db.close();
    }
  }

  /// مسار ملف قاعدة البيانات الحالي (يُستدعى بعد فتح القاعدة).
  String? get path => _path;

  Future<Database> _open() async {
    final factory = _isDesktop() ? _initFfi() : databaseFactorySqflitePlugin;

    final path = p.join(await factory.getDatabasesPath(), AppConstants.dbName);
    _path = path;
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppConstants.dbVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute(_productsTable);
          await db.execute(_salesTable);
          await db.execute(_saleItemsTable);
          await db.execute(_settingsTable);
          await db.execute(_categoriesTable);
          await db.execute(_customersTable);
          await db.execute(_expensesTable);
          await db.execute(_adminsTable);
          await db.execute(_purchasesTable);
          await db.execute(_purchaseItemsTable);
          await db.execute(_customerPaymentsTable);
          await db.execute(_suppliersTable);
          await db.execute(_supplierPaymentsTable);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              'ALTER TABLE products ADD COLUMN category_id INTEGER',
            );
            await db.execute(
              "ALTER TABLE sales ADD COLUMN discount REAL NOT NULL DEFAULT 0",
            );
            await db.execute(
              "ALTER TABLE sales ADD COLUMN payment_method TEXT NOT NULL DEFAULT 'نقدي'",
            );
            await db.execute(
              'ALTER TABLE sales ADD COLUMN customer_id INTEGER',
            );
            await db.execute(_categoriesTable);
            await db.execute(_customersTable);
            await db.execute(_expensesTable);
          }
          if (oldVersion < 3) {
            await db.execute(_adminsTable);
          } else if (oldVersion == 3) {
            await db.execute(
              "ALTER TABLE admins ADD COLUMN role TEXT NOT NULL DEFAULT 'cashier'",
            );
            await db.execute(
              "UPDATE admins SET role = 'super_admin' WHERE is_super_admin = 1",
            );
          }
          if (oldVersion < 4) {
            await db.execute('ALTER TABLE sales ADD COLUMN cashier_name TEXT');
          }
          if (oldVersion < 5) {
            await db.execute(
              'ALTER TABLE products ADD COLUMN cost_price REAL NOT NULL DEFAULT 0',
            );
            await db.execute(
              'ALTER TABLE products ADD COLUMN low_stock_threshold REAL NOT NULL DEFAULT 0',
            );
            await db.execute('ALTER TABLE products ADD COLUMN barcode TEXT');
            await db.execute('ALTER TABLE sales ADD COLUMN note TEXT');
            await db.execute(
              'ALTER TABLE sales ADD COLUMN refunded INTEGER NOT NULL DEFAULT 0',
            );
            await db.execute(_purchasesTable);
            await db.execute(_purchaseItemsTable);
            await db.execute(_customerPaymentsTable);
          }
          if (oldVersion < 6) {
            await db.execute(_suppliersTable);
            await db.execute(_supplierPaymentsTable);
          }
          if (oldVersion < 7) {
            await _ensureColumnExists(
              db,
              'sale_items',
              'cost_price',
              'REAL NOT NULL DEFAULT 0',
            );
            await _ensureColumnExists(
              db,
              'sales',
              'invoice_number',
              'INTEGER NOT NULL DEFAULT 1',
            );
          }
          if (oldVersion < 8) {
            await _ensureColumnExists(
              db,
              'purchases',
              'paid_amount',
              'REAL NOT NULL DEFAULT 0',
            );
          }
          if (oldVersion < 9) {
            // ربط فاتورة الشراء بالمورد (بدلًا من الاسم فقط)
            await _ensureColumnExists(
              db,
              'purchases',
              'supplier_id',
              'INTEGER',
            );
            // ربط دفعة السداد بفاتورة الشراء المحددة
            await _ensureColumnExists(
              db,
              'supplier_payments',
              'purchase_id',
              'INTEGER',
            );
            // backfill: تحديد المورد لكل فاتورة موجودة حسب الاسم
            await db.execute('''
              UPDATE purchases SET supplier_id = (
                SELECT MIN(s.id) FROM suppliers s
                WHERE LOWER(TRIM(s.name)) = LOWER(TRIM(purchases.supplier_name))
              )
              WHERE supplier_id IS NULL AND TRIM(supplier_name) != ''
            ''');
            // backfill: توزيع الدفعات التاريخية على الفواتير (الأقدم أولًا)
            await _backfillHistoricalSupplierPayments(db);
          }
        },
      ),
    );
  }

  /// يوزّع الدفعات التاريخية المسجلة قبل ربطها بالفواتير على فواتير المورد
  /// (الأقدم أولًا) حتى يظهر المتبقي/المدفوع في خانة كل فاتورة بشكل صحيح.
  static Future<void> _backfillHistoricalSupplierPayments(Database db) async {
    final supplierRows = await db.query('suppliers');
    for (final supplierRow in supplierRows) {
      final supplierId = supplierRow['id'] as int;
      final paymentRows = await db.query(
        'supplier_payments',
        where: 'supplier_id = ?',
        whereArgs: [supplierId],
        orderBy: 'created_at ASC, id ASC',
      );
      if (paymentRows.isEmpty) continue;
      final totalPaid = paymentRows.fold<double>(
        0.0,
        (sum, row) => sum + ((row['amount'] as num).toDouble()),
      );
      if (totalPaid <= 0) continue;

      final purchaseRows = await db.query(
        'purchases',
        where: 'supplier_id = ? AND total > paid_amount',
        whereArgs: [supplierId],
        orderBy: 'created_at ASC, id ASC',
      );
      var remaining = totalPaid;
      for (final purchaseRow in purchaseRows) {
        if (remaining <= 0) break;
        final purchaseId = purchaseRow['id'] as int;
        final total = (purchaseRow['total'] as num).toDouble();
        final paidAmount =
            (purchaseRow['paid_amount'] as num?)?.toDouble() ?? 0;
        final capacity = (total - paidAmount).clamp(0.0, double.infinity);
        if (capacity <= 0) continue;
        final allocate = remaining >= capacity ? capacity : remaining;
        await db.rawUpdate(
          'UPDATE purchases SET paid_amount = paid_amount + ? WHERE id = ?',
          [allocate, purchaseId],
        );
        remaining -= allocate;
      }
    }
  }

  static Future<void> _ensureColumnExists(
    Database db,
    String tableName,
    String columnName,
    String columnDefinition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final exists = columns.any(
      (column) => (column['name'] as String?) == columnName,
    );
    if (!exists) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition',
      );
    }
  }

  static bool _isDesktop() =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  static DatabaseFactory _initFfi() {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }

  static const String _productsTable = '''
    CREATE TABLE products(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      price REAL NOT NULL,
      stock REAL NOT NULL DEFAULT 0,
      unit TEXT NOT NULL DEFAULT 'قطعة',
      category_id INTEGER,
      cost_price REAL NOT NULL DEFAULT 0,
      low_stock_threshold REAL NOT NULL DEFAULT 0,
      barcode TEXT,
      created_at TEXT NOT NULL
    )
  ''';

  static const String _salesTable = '''
    CREATE TABLE sales(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_number INTEGER NOT NULL DEFAULT 1,
      total REAL NOT NULL,
      items_count INTEGER NOT NULL,
      discount REAL NOT NULL DEFAULT 0,
      payment_method TEXT NOT NULL DEFAULT 'نقدي',
      customer_id INTEGER,
      cashier_name TEXT,
      note TEXT,
      refunded INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL
    )
  ''';

  static const String _saleItemsTable = '''
    CREATE TABLE sale_items(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id INTEGER NOT NULL,
      product_id INTEGER,
      name TEXT NOT NULL,
      price REAL NOT NULL,
      cost_price REAL NOT NULL DEFAULT 0,
      quantity REAL NOT NULL,
      subtotal REAL NOT NULL,
      FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE
    )
  ''';

  static const String _settingsTable = '''
    CREATE TABLE settings(
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''';

  static const String _categoriesTable = '''
    CREATE TABLE categories(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''';

  static const String _customersTable = '''
    CREATE TABLE customers(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT NOT NULL DEFAULT '',
      balance REAL NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL
    )
  ''';

  static const String _expensesTable = '''
    CREATE TABLE expenses(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      amount REAL NOT NULL,
      created_at TEXT NOT NULL
    )
  ''';

  static const String _adminsTable = '''
    CREATE TABLE admins(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'cashier',
      created_at TEXT NOT NULL
    )
  ''';

  static const String _purchasesTable = '''
    CREATE TABLE purchases(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      supplier_name TEXT NOT NULL DEFAULT '',
      total REAL NOT NULL,
      paid_amount REAL NOT NULL DEFAULT 0,
      note TEXT,
      created_at TEXT NOT NULL
    )
  ''';

  static const String _purchaseItemsTable = '''
    CREATE TABLE purchase_items(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      purchase_id INTEGER NOT NULL,
      product_id INTEGER,
      name TEXT NOT NULL,
      quantity REAL NOT NULL,
      price REAL NOT NULL,
      subtotal REAL NOT NULL,
      FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE CASCADE
    )
  ''';

  static const String _customerPaymentsTable = '''
    CREATE TABLE customer_payments(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_id INTEGER NOT NULL,
      amount REAL NOT NULL,
      created_at TEXT NOT NULL
    )
  ''';

  static const String _suppliersTable = '''
    CREATE TABLE suppliers(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT NOT NULL DEFAULT '',
      address TEXT NOT NULL DEFAULT '',
      balance REAL NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL
    )
  ''';

  static const String _supplierPaymentsTable = '''
    CREATE TABLE supplier_payments(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      supplier_id INTEGER NOT NULL,
      amount REAL NOT NULL,
      created_at TEXT NOT NULL
    )
  ''';
}

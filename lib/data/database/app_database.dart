import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' show databaseFactorySqflitePlugin;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants.dart';

/// قاعدة البيانات المحلية (SQLite) — إنشاء الجداول والترحيل وإدارة الاتصال.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  /// تجاوز مسار مجلد قاعدة البيانات (تُستخدم في الاختبارات فقط).
  static String? overrideDatabasesPath;

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

    final path = await _resolveDbPath(factory);
    _path = path;
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppConstants.dbVersion,
        onConfigure: (db) async {
          // تسريع الكتابة وتحسين التزامن تحت ضغط العمليات الكثيرة (WAL).
          await db.execute('PRAGMA foreign_keys = ON');
          await db.rawQuery('PRAGMA journal_mode = WAL');
          await db.rawQuery('PRAGMA synchronous = NORMAL');
        },
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
          await db.execute(_shiftsTable);
          await db.execute(_heldCartsTable);
          await db.execute(_heldCartItemsTable);
          await db.execute(_hallsTable);
          await db.execute(_restaurantTablesTable);
          await db.execute(_employeesTable);
          await db.execute(_ordersTable);
          await db.execute(_orderItemsTable);
          await db.execute(_employeeAdvancesTable);
          await db.execute(_orderStatusHistoryTable);
          await db.execute(_riderTransactionsTable);
          await db.execute(_couponsTable);
          // جداول كانت تُنشأ في الترحيلات فقط — أُضيفت هنا حتى تكتمل
          // قواعد البيانات الجديدة (القائمة/الحجوزات/الوصفات).
          await db.execute(_reservationsTable);
          await db.execute(_queueEntriesTable);
          await db.execute(_recipesTable);
          await db.execute(_recipeItemsTable);
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
          if (oldVersion < 10) {
            await _ensureColumnExists(
              db,
              'sales',
              'tax_rate',
              'REAL NOT NULL DEFAULT 0',
            );
            await _ensureColumnExists(
              db,
              'sales',
              'tax_amount',
              'REAL NOT NULL DEFAULT 0',
            );
          }
          if (oldVersion < 11) {
            // فهارس لتسريع البحث والتصفية عند نمو البيانات
            // (آلاف الفواتير والبنود يوميًا).
            await _createIndex(db, 'idx_sales_created_at', 'sales', 'created_at');
            await _createIndex(db, 'idx_sales_customer', 'sales', 'customer_id');
            await _createIndex(
              db,
              'idx_sales_invoice_number',
              'sales',
              'invoice_number',
            );
            await _createIndex(db, 'idx_sale_items_sale', 'sale_items', 'sale_id');
            await _createIndex(
              db,
              'idx_sale_items_product',
              'sale_items',
              'product_id',
            );
            await _createIndex(
              db,
              'idx_expenses_created_at',
              'expenses',
              'created_at',
            );
            await _createIndex(
              db,
              'idx_purchases_created_at',
              'purchases',
              'created_at',
            );
            await _createIndex(
              db,
              'idx_purchases_supplier',
              'purchases',
              'supplier_id',
            );
            await _createIndex(
              db,
              'idx_purchase_items_purchase',
              'purchase_items',
              'purchase_id',
            );
            await _createIndex(
              db,
              'idx_customer_payments_customer',
              'customer_payments',
              'customer_id',
            );
            await _createIndex(
              db,
              'idx_supplier_payments_supplier',
              'supplier_payments',
              'supplier_id',
            );
            await _createIndex(
              db,
              'idx_supplier_payments_purchase',
              'supplier_payments',
              'purchase_id',
            );
            await _createIndex(db, 'idx_products_name', 'products', 'name');
          }
          if (oldVersion < 12) {
            // المبلغ المدفوع والجزء المدفوع بالشبكة (لحساب الباقي والدفع المختلط).
            await _ensureColumnExists(
              db,
              'sales',
              'amount_tendered',
              'REAL NOT NULL DEFAULT 0',
            );
            await _ensureColumnExists(
              db,
              'sales',
              'card_amount',
              'REAL NOT NULL DEFAULT 0',
            );
          }
          if (oldVersion < 13) {
            // الورديات: تُفتح تلقائيًا عند أول بيع وتُغلق يدويًا من Z-Report.
            await db.execute(_shiftsTable);
            // الفواتير المعلقة (Hold Invoice) مع بنودها.
            await db.execute(_heldCartsTable);
            await db.execute(_heldCartItemsTable);
            // توقيت المرتجع لإسناده إلى الوردية التي حدث فيها.
            await _ensureColumnExists(
              db,
              'sales',
              'refunded_at',
              'TEXT',
            );
          }
          if (oldVersion < 14) {
            // === تحويل نظام المحلات إلى نظام مطعم ===
            // جداول الصالات والترابيزات
            await db.execute(_hallsTable);
            await db.execute(_restaurantTablesTable);
            // جدول الموظفين
            await db.execute(_employeesTable);
            // جداول الطلبات وبنودها
            await db.execute(_ordersTable);
            await db.execute(_orderItemsTable);
            // تعديلات جدول المنتجات: إضافة أعمدة المنيو
            await _ensureColumnExists(
              db,
              'products',
              'is_available',
              'INTEGER NOT NULL DEFAULT 1',
            );
            await _ensureColumnExists(
              db,
              'products',
              'preparation_time',
              'INTEGER NOT NULL DEFAULT 0',
            );
            await _ensureColumnExists(
              db,
              'products',
              'is_raw_material',
              'INTEGER NOT NULL DEFAULT 0',
            );
            // فهارس جديدة
            await _createIndex(db, 'idx_orders_table', 'orders', 'table_id');
            await _createIndex(
              db,
              'idx_orders_status',
              'orders',
              'status',
            );
            await _createIndex(
              db,
              'idx_orders_created_at',
              'orders',
              'created_at',
            );
            await _createIndex(
              db,
              'idx_order_items_order',
              'order_items',
              'order_id',
            );
            await _createIndex(
              db,
              'idx_restaurant_tables_hall',
              'restaurant_tables',
              'hall_id',
            );
            await _createIndex(
              db,
              'idx_restaurant_tables_status',
              'restaurant_tables',
              'status',
            );
            await _createIndex(
              db,
              'idx_employees_role',
              'employees',
              'role',
            );
          }
          if (oldVersion < 15) {
            // === نظام التوصيل + السلف + المنيو الاحترافي ===
            // أعمدة جديدة في جدول الطلبات للتوصيل
            await _ensureColumnExists(
              db, 'orders', 'order_type', "TEXT NOT NULL DEFAULT 'hall'",
            );
            await _ensureColumnExists(
              db, 'orders', 'delivery_address', "TEXT NOT NULL DEFAULT ''",
            );
            await _ensureColumnExists(
              db, 'orders', 'delivery_phone', "TEXT NOT NULL DEFAULT ''",
            );
            await _ensureColumnExists(
              db, 'orders', 'delivery_notes', "TEXT NOT NULL DEFAULT ''",
            );
            await _ensureColumnExists(
              db, 'orders', 'delivery_person_name', "TEXT NOT NULL DEFAULT ''",
            );
            await _ensureColumnExists(
              db, 'orders', 'delivery_fee', 'REAL NOT NULL DEFAULT 0',
            );
            await _ensureColumnExists(
              db, 'orders', 'hall_id', 'INTEGER',
            );
            // سعر النص كيلو في المنتجات
            await _ensureColumnExists(
              db, 'products', 'half_price', 'REAL NOT NULL DEFAULT 0',
            );
            // جدول سلف الموظفين
            await db.execute(_employeeAdvancesTable);
            // فهارس جديدة
            await _createIndex(
              db, 'idx_orders_order_type', 'orders', 'order_type',
            );
            await _createIndex(
              db, 'idx_orders_hall_id', 'orders', 'hall_id',
            );
            await _createIndex(
              db, 'idx_employee_advances_employee',
              'employee_advances', 'employee_id',
            );
            await _createIndex(
              db, 'idx_employee_advances_created_at',
              'employee_advances', 'created_at',
            );
          }
          if (oldVersion < 16) {
            await _ensureColumnExists(
              db, 'orders', 'rider_id', 'INTEGER',
            );
            await db.execute(_orderStatusHistoryTable);
            await _createIndex(
              db, 'idx_osh_order', 'order_status_history', 'order_id',
            );
            await _createIndex(
              db, 'idx_osh_status', 'order_status_history', 'status',
            );
          }
          if (oldVersion < 17) {
            await _ensureColumnExists(
              db, 'sales', 'order_type', "TEXT NOT NULL DEFAULT 'عميل_عادي'",
            );
            await _ensureColumnExists(
              db, 'sales', 'table_name', "TEXT NOT NULL DEFAULT ''",
            );
            await _ensureColumnExists(
              db, 'sales', 'customer_name', "TEXT NOT NULL DEFAULT ''",
            );
          }
          if (oldVersion < 18) {
            await db.execute(_riderTransactionsTable);
            await _createIndex(
              db, 'idx_rider_tx_rider', 'rider_transactions', 'rider_id',
            );
            await _createIndex(
              db, 'idx_rider_tx_created', 'rider_transactions', 'created_at',
            );
            await _createIndex(
              db, 'idx_rider_tx_order', 'rider_transactions', 'order_id',
            );
          }
          if (oldVersion < 19) {
            await db.execute(_couponsTable);
            await _createIndex(db, 'idx_coupons_code', 'coupons', 'code');
          }
          if (oldVersion < 20) {
            await _ensureColumnExists(
              db, 'customers', 'loyalty_points', 'INTEGER NOT NULL DEFAULT 0',
            );
            await _ensureColumnExists(
              db, 'customers', 'address', "TEXT NOT NULL DEFAULT ''",
            );
            await _ensureColumnExists(
              db, 'customers', 'notes', "TEXT NOT NULL DEFAULT ''",
            );
          }
          if (oldVersion < 21) {
            await _ensureColumnExists(
              db, 'sales', 'tip', 'REAL NOT NULL DEFAULT 0',
            );
          }
          if (oldVersion < 22) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS reservations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                table_id INTEGER NOT NULL,
                table_number INTEGER NOT NULL,
                customer_name TEXT NOT NULL DEFAULT '',
                customer_phone TEXT NOT NULL DEFAULT '',
                party_size INTEGER NOT NULL DEFAULT 2,
                reservation_time TEXT NOT NULL,
                note TEXT NOT NULL DEFAULT '',
                status TEXT NOT NULL DEFAULT 'confirmed',
                created_at TEXT NOT NULL,
                FOREIGN KEY (table_id) REFERENCES tables(id) ON DELETE CASCADE
              )
            ''');
          }
          if (oldVersion < 23) {
            await _ensureColumnExists(
              db, 'products', 'image_path', "TEXT NOT NULL DEFAULT ''",
            );
          }
          if (oldVersion < 24) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS queue_entries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                customer_name TEXT NOT NULL DEFAULT '',
                customer_phone TEXT NOT NULL DEFAULT '',
                party_size INTEGER NOT NULL DEFAULT 2,
                status TEXT NOT NULL DEFAULT 'waiting',
                note TEXT NOT NULL DEFAULT '',
                created_at TEXT NOT NULL
              )
            ''');
          }
          if (oldVersion < 25) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS recipes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                product_id INTEGER NOT NULL,
                product_name TEXT NOT NULL DEFAULT '',
                created_at TEXT NOT NULL,
                FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS recipe_items (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                recipe_id INTEGER NOT NULL,
                raw_material_id INTEGER NOT NULL,
                raw_material_name TEXT NOT NULL DEFAULT '',
                quantity REAL NOT NULL DEFAULT 0,
                unit TEXT NOT NULL DEFAULT 'كجم',
                FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
                FOREIGN KEY (raw_material_id) REFERENCES products(id) ON DELETE CASCADE
              )
            ''');
          }
          if (oldVersion < 26) {
            // === وحدات الشراء المرنة (شراء بالكرتونة / بيع بالقطعة) ===
            // وحدة الشراء بالجملة للصنف + عدد الوحدات الأساسية داخل العبوة.
            await _ensureColumnExists(
              db, 'products', 'package_unit', "TEXT NOT NULL DEFAULT ''",
            );
            await _ensureColumnExists(
              db, 'products', 'units_per_package', 'REAL NOT NULL DEFAULT 0',
            );
            // وصف الصنف (مكونات الوجبة) يظهر في المنيو.
            await _ensureColumnExists(
              db, 'products', 'description', "TEXT NOT NULL DEFAULT ''",
            );
            // وحدة الشراء الفعلية ومعامل التحويل لكل بند في فاتورة الشراء.
            await _ensureColumnExists(
              db, 'purchase_items', 'unit', "TEXT NOT NULL DEFAULT ''",
            );
            await _ensureColumnExists(
              db, 'purchase_items', 'conversion_factor', 'REAL NOT NULL DEFAULT 1',
            );
          }
          if (oldVersion < 27) {
            // === إكمال المخطط الناقص في القواعد القديمة (فشل إضافة
            // العملاء/الحجوزات/الوصفات/المشتريات المربوطة بمورد) ===
            await _ensureColumnExists(
              db, 'customers', 'address', "TEXT NOT NULL DEFAULT ''",
            );
            await _ensureColumnExists(
              db, 'customers', 'loyalty_points', 'INTEGER NOT NULL DEFAULT 0',
            );
            await _ensureColumnExists(
              db, 'customers', 'notes', "TEXT NOT NULL DEFAULT ''",
            );
            await _ensureColumnExists(db, 'purchases', 'supplier_id', 'INTEGER');
            await _ensureColumnExists(
              db, 'supplier_payments', 'purchase_id', 'INTEGER',
            );

            // جداول ناقصة تمامًا في القواعد المنشأة حديثًا قبل الإصلاح.
            await db.execute(_queueEntriesTable);
            await db.execute(_recipesTable);
            await db.execute(_recipeItemsTable);

            // جدول الحجوزات: إن وُجد بمرجع مفتاح أجنبي خاطئ (tables)
            // يُعاد إنشاؤه بالمرجع الصحيح (restaurant_tables).
            final reservationSql = await db.rawQuery(
              "SELECT sql FROM sqlite_master WHERE type='table' "
              "AND name='reservations'",
            );
            final existingSql = reservationSql.isNotEmpty
                ? (reservationSql.first['sql'] as String?) ?? ''
                : '';
            if (existingSql.contains('REFERENCES tables(')) {
              await db.execute('DROP TABLE reservations');
            }
            await db.execute(_reservationsTable);
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

  static Future<void> _createIndex(
    Database db,
    String indexName,
    String tableName,
    String columnName,
  ) async {
    final rows = await db.rawQuery('PRAGMA index_list($tableName)');
    final exists = rows.any((row) => row['name'] == indexName);
    if (!exists) {
      await db.execute(
        'CREATE INDEX $indexName ON $tableName($columnName)',
      );
    }
  }

  static bool _isDesktop() =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  static DatabaseFactory _initFfi() {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }

  /// تحديد مسار ملف القاعدة في مجلد بيانات التطبيق الرسمي (ثابت على كل
  /// الأنظمة ولا يتأثر بمكان التشغيل أو flutter clean)، مع ترحيل أي قاعدة
  /// قديمة كانت محفوظة داخل .dart_tool عند أول تشغيل حتى لا تضيع البيانات.
  Future<String> _resolveDbPath(DatabaseFactory factory) async {
    if (overrideDatabasesPath != null) {
      return p.join(overrideDatabasesPath!, AppConstants.dbName);
    }

    final newPath = p.join(await _resolveBaseDir(), AppConstants.dbName);

    // ترحيل القاعدة من المسار القديم (المرتبط بمجلد المشروع) إن وُجدت.
    try {
      final legacy =
          p.join(await factory.getDatabasesPath(), AppConstants.dbName);
      final legacyFile = File(legacy);
      if (!File(newPath).existsSync() && legacyFile.existsSync()) {
        for (final suffix in ['', '-wal', '-shm']) {
          final source = File('$legacy$suffix');
          if (source.existsSync()) {
            await source.copy('$newPath$suffix');
          }
        }
      }
    } catch (_) {
      // تجاهل فشل الترحيل — يُفتح ملف جديد فارغ في المسار الثابت.
    }

    return newPath;
  }

  /// المجلد الأساسي لبيانات التطبيق: مجلد الدعم الرسمي، مع بدائل آمنة.
  Future<String> _resolveBaseDir() async {
    try {
      return (await getApplicationSupportDirectory()).path;
    } catch (_) {
      final home =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (home != null && home.isNotEmpty) {
        return p.join(home, '.omni_order');
      }
      return Directory.systemTemp.path;
    }
  }

  static const String _productsTable = '''
    CREATE TABLE products(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      price REAL NOT NULL,
      half_price REAL NOT NULL DEFAULT 0,
      stock REAL NOT NULL DEFAULT 0,
      unit TEXT NOT NULL DEFAULT 'قطعة',
      category_id INTEGER,
      cost_price REAL NOT NULL DEFAULT 0,
      low_stock_threshold REAL NOT NULL DEFAULT 0,
      barcode TEXT,
      is_available INTEGER NOT NULL DEFAULT 1,
      preparation_time INTEGER NOT NULL DEFAULT 0,
      is_raw_material INTEGER NOT NULL DEFAULT 0,
      image_path TEXT NOT NULL DEFAULT '',
      package_unit TEXT NOT NULL DEFAULT '',
      units_per_package REAL NOT NULL DEFAULT 0,
      description TEXT NOT NULL DEFAULT '',
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
      tax_rate REAL NOT NULL DEFAULT 0,
      tax_amount REAL NOT NULL DEFAULT 0,
      payment_method TEXT NOT NULL DEFAULT 'نقدي',
      customer_id INTEGER,
      cashier_name TEXT,
      note TEXT,
      refunded INTEGER NOT NULL DEFAULT 0,
      refunded_at TEXT,
      amount_tendered REAL NOT NULL DEFAULT 0,
      card_amount REAL NOT NULL DEFAULT 0,
      tip REAL NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      order_type TEXT NOT NULL DEFAULT 'عميل_عادي',
      table_name TEXT NOT NULL DEFAULT '',
      customer_name TEXT NOT NULL DEFAULT ''
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
      address TEXT NOT NULL DEFAULT '',
      balance REAL NOT NULL DEFAULT 0,
      loyalty_points INTEGER NOT NULL DEFAULT 0,
      notes TEXT NOT NULL DEFAULT '',
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
      supplier_id INTEGER,
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
      unit TEXT NOT NULL DEFAULT '',
      conversion_factor REAL NOT NULL DEFAULT 1,
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
      purchase_id INTEGER,
      amount REAL NOT NULL,
      created_at TEXT NOT NULL
    )
  ''';

  static const String _shiftsTable = '''
    CREATE TABLE shifts(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cashier_name TEXT NOT NULL,
      opened_at TEXT NOT NULL,
      closed_at TEXT
    )
  ''';

  static const String _heldCartsTable = '''
    CREATE TABLE held_carts(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      saved_at TEXT NOT NULL,
      discount REAL NOT NULL DEFAULT 0,
      payment_method TEXT NOT NULL DEFAULT 'نقدي',
      customer_id INTEGER,
      note TEXT,
      cashier_name TEXT NOT NULL DEFAULT '',
      items_count INTEGER NOT NULL DEFAULT 0,
      total REAL NOT NULL DEFAULT 0
    )
  ''';

  static const String _heldCartItemsTable = '''
    CREATE TABLE held_cart_items(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      held_cart_id INTEGER NOT NULL,
      product_id INTEGER,
      name TEXT NOT NULL,
      price REAL NOT NULL,
      cost_price REAL NOT NULL DEFAULT 0,
      quantity REAL NOT NULL,
      subtotal REAL NOT NULL,
      FOREIGN KEY (held_cart_id) REFERENCES held_carts(id) ON DELETE CASCADE
    )
  ''';

  static const String _hallsTable = '''
    CREATE TABLE halls(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      capacity INTEGER NOT NULL DEFAULT 0,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL
    )
  ''';

  static const String _restaurantTablesTable = '''
    CREATE TABLE restaurant_tables(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      hall_id INTEGER NOT NULL,
      number INTEGER NOT NULL,
      capacity INTEGER NOT NULL DEFAULT 4,
      status TEXT NOT NULL DEFAULT 'available',
      current_order_id INTEGER,
      created_at TEXT NOT NULL,
      FOREIGN KEY (hall_id) REFERENCES halls(id) ON DELETE CASCADE
    )
  ''';

  static const String _employeesTable = '''
    CREATE TABLE employees(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT NOT NULL DEFAULT '',
      role TEXT NOT NULL DEFAULT 'waiter',
      salary REAL NOT NULL DEFAULT 0,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL
    )
  ''';

  static const String _ordersTable = '''
    CREATE TABLE orders(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      table_id INTEGER,
      hall_id INTEGER,
      employee_id INTEGER,
      rider_id INTEGER,
      status TEXT NOT NULL DEFAULT 'pending',
      order_type TEXT NOT NULL DEFAULT 'hall',
      total REAL NOT NULL DEFAULT 0,
      discount REAL NOT NULL DEFAULT 0,
      tax_rate REAL NOT NULL DEFAULT 0,
      tax_amount REAL NOT NULL DEFAULT 0,
      payment_method TEXT NOT NULL DEFAULT 'نقدي',
      cashier_name TEXT,
      note TEXT,
      is_takeaway INTEGER NOT NULL DEFAULT 0,
      refunded INTEGER NOT NULL DEFAULT 0,
      refunded_at TEXT,
      amount_tendered REAL NOT NULL DEFAULT 0,
      card_amount REAL NOT NULL DEFAULT 0,
      delivery_address TEXT NOT NULL DEFAULT '',
      delivery_phone TEXT NOT NULL DEFAULT '',
      delivery_notes TEXT NOT NULL DEFAULT '',
      delivery_person_name TEXT NOT NULL DEFAULT '',
      delivery_fee REAL NOT NULL DEFAULT 0,
      completed_at TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (table_id) REFERENCES restaurant_tables(id),
      FOREIGN KEY (hall_id) REFERENCES halls(id),
      FOREIGN KEY (rider_id) REFERENCES employees(id)
    )
  ''';

  static const String _orderItemsTable = '''
    CREATE TABLE order_items(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      price REAL NOT NULL,
      quantity REAL NOT NULL,
      subtotal REAL NOT NULL,
      notes TEXT NOT NULL DEFAULT '',
      status TEXT NOT NULL DEFAULT 'pending',
      FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
    )
  ''';

  static const String _employeeAdvancesTable = '''
    CREATE TABLE employee_advances(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      employee_id INTEGER NOT NULL,
      amount REAL NOT NULL,
      type TEXT NOT NULL DEFAULT 'advance',
      note TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL,
      FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
    )
  ''';

  static const String _orderStatusHistoryTable = '''
    CREATE TABLE order_status_history(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER NOT NULL,
      status TEXT NOT NULL,
      note TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL,
      FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
    )
  ''';

  static const String _riderTransactionsTable = '''
    CREATE TABLE rider_transactions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      rider_id INTEGER NOT NULL,
      type TEXT NOT NULL,
      amount REAL NOT NULL DEFAULT 0,
      order_id INTEGER,
      note TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL,
      FOREIGN KEY (rider_id) REFERENCES employees(id) ON DELETE CASCADE,
      FOREIGN KEY (order_id) REFERENCES orders(id)
    )
  ''';

  static const String _couponsTable = '''
    CREATE TABLE coupons(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL UNIQUE,
      description TEXT NOT NULL DEFAULT '',
      discount_type TEXT NOT NULL DEFAULT 'percent',
      discount_value REAL NOT NULL DEFAULT 0,
      min_order REAL NOT NULL DEFAULT 0,
      max_uses INTEGER NOT NULL DEFAULT 0,
      used_count INTEGER NOT NULL DEFAULT 0,
      is_active INTEGER NOT NULL DEFAULT 1,
      expires_at TEXT,
      created_at TEXT NOT NULL
    )
  ''';

  // ==== جداول كانت تُنشأ في الترحيلات فقط — أصبحت جزءًا من المخطط الأساسي ====

  static const String _reservationsTable = '''
    CREATE TABLE IF NOT EXISTS reservations(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      table_id INTEGER NOT NULL,
      table_number INTEGER NOT NULL,
      customer_name TEXT NOT NULL DEFAULT '',
      customer_phone TEXT NOT NULL DEFAULT '',
      party_size INTEGER NOT NULL DEFAULT 2,
      reservation_time TEXT NOT NULL,
      note TEXT NOT NULL DEFAULT '',
      status TEXT NOT NULL DEFAULT 'confirmed',
      created_at TEXT NOT NULL,
      FOREIGN KEY (table_id) REFERENCES restaurant_tables(id) ON DELETE CASCADE
    )
  ''';

  static const String _queueEntriesTable = '''
    CREATE TABLE IF NOT EXISTS queue_entries(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_name TEXT NOT NULL DEFAULT '',
      customer_phone TEXT NOT NULL DEFAULT '',
      party_size INTEGER NOT NULL DEFAULT 2,
      status TEXT NOT NULL DEFAULT 'waiting',
      note TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL
    )
  ''';

  static const String _recipesTable = '''
    CREATE TABLE IF NOT EXISTS recipes(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      product_name TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL,
      FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
    )
  ''';

  static const String _recipeItemsTable = '''
    CREATE TABLE IF NOT EXISTS recipe_items(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      recipe_id INTEGER NOT NULL,
      raw_material_id INTEGER NOT NULL,
      raw_material_name TEXT NOT NULL DEFAULT '',
      quantity REAL NOT NULL DEFAULT 0,
      unit TEXT NOT NULL DEFAULT 'كجم',
      FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
      FOREIGN KEY (raw_material_id) REFERENCES products(id) ON DELETE CASCADE
    )
  ''';
}

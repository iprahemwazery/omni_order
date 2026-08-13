import 'package:omni_order/domain/models/admin.dart';
import 'package:omni_order/domain/models/category.dart';
import 'package:omni_order/domain/models/customer.dart';
import 'package:omni_order/domain/models/customer_payment.dart';
import 'package:omni_order/domain/models/expense.dart';
import 'package:omni_order/domain/models/product.dart';
import 'package:omni_order/domain/models/purchase.dart';
import 'package:omni_order/domain/models/purchase_item.dart';
import 'package:omni_order/domain/models/sale.dart';
import 'package:omni_order/domain/models/sale_item.dart';
import 'package:omni_order/domain/models/store_settings.dart';
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
  Future<List<Expense>> getExpenses() async => List.of(expenses);

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
  Future<List<Sale>> getSales() async => List.of(sales);

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

  @override
  Future<List<SaleItem>> getAllSaleItems() async => [
    for (final items in saleItems.values) ...items,
  ];

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
      paymentMethod: sale.paymentMethod,
      customerId: sale.customerId,
      cashierName: sale.cashierName,
      note: sale.note,
      refunded: sale.refunded,
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
    sales[index] = sale.copyWith(refunded: true);
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
    );
  }

  @override
  Future<void> saveSettings(StoreSettings value) async {
    settings['store_name'] = value.storeName;
    settings['store_phone'] = value.phone;
    settings['currency'] = value.currency;
    settings['dark_mode'] = value.darkMode ? '1' : '0';
    settings['font_scale'] = '${value.fontScale}';
  }
}

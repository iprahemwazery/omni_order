import '../models/admin.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../models/customer_payment.dart';
import '../models/expense.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../models/purchase_item.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/store_settings.dart';
import '../models/supplier.dart';
import '../models/supplier_payment.dart';

/// عقد (واجهة) المستودع الذي يخزّن بيانات المتجر محليًا.
///
/// الطبقة العليا (Presentation) تتعامل مع هذه الواجهة فقط،
/// بينما طبقة الـ Data توفر التنفيذ الحقيقي (SQLite).
abstract interface class StoreRepository {
  Future<void> init();

  // الأدمن
  Future<List<Admin>> getAdmins();
  Future<Admin?> getAdminByUsername(String username);
  Future<int> addAdmin(Admin admin);
  Future<void> updateAdmin(Admin admin);
  Future<void> deleteAdmin(int id);

  // المنتجات
  Future<List<Product>> getProducts();
  Future<int> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(int id);

  // تحديث الكمية بمقدار (سالبة عند البيع)
  Future<void> updateStock(int productId, double delta);

  // التصنيفات
  Future<List<Category>> getCategories();
  Future<int> addCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(int id);

  // العملاء
  Future<List<Customer>> getCustomers();
  Future<int> addCustomer(Customer customer);
  Future<void> updateCustomer(Customer customer);
  Future<void> deleteCustomer(int id);

  // الموردين
  Future<List<Supplier>> getSuppliers();
  Future<int> addSupplier(Supplier supplier);
  Future<void> updateSupplier(Supplier supplier);
  Future<void> deleteSupplier(int id);

  // دفعات العملاء
  Future<List<CustomerPayment>> getCustomerPayments(int customerId);
  Future<void> addCustomerPayment(CustomerPayment payment);

  // دفعات الموردين
  Future<List<SupplierPayment>> getSupplierPayments(int supplierId);
  Future<void> addSupplierPayment(SupplierPayment payment);

  // المشتريات
  Future<List<Purchase>> getPurchases();
  Future<List<PurchaseItem>> getPurchaseItems(int purchaseId);

  /// ينشئ فاتورة شراء مع بنودها ويزيد المخزون ويحدّث سعر التكلفة (معاملة واحدة).
  Future<int> createPurchase({
    required Purchase purchase,
    required List<PurchaseItem> items,
  });

  // المصروفات
  Future<List<Expense>> getExpenses();
  Future<int> addExpense(Expense expense);
  Future<void> deleteExpense(int id);

  // المبيعات
  Future<List<Sale>> getSales();
  Future<Sale?> getSale(int id);
  Future<List<SaleItem>> getSaleItems(int saleId);
  Future<List<SaleItem>> getAllSaleItems();

  /// ينشئ الفاتورة مع بنودها ويخصم المخزون في معاملة واحدة (Atomic).
  Future<int> createSale({required Sale sale, required List<SaleItem> items});

  /// مرتجع فاتورة: يعيد البضاعة للمخزون، ويعيد رصيد العميل (لو آجل)،
  /// ويعلّم الفاتورة كمرتجع (لا تُحتسب في الإيرادات) — معاملة واحدة.
  Future<void> refundSale(int saleId);

  // إعدادات المتجر
  Future<String?> getSetting(String key);
  Future<void> setSetting(String key, String value);
  Future<StoreSettings> getSettings();
  Future<void> saveSettings(StoreSettings settings);
}

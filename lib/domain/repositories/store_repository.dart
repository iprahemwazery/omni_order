import '../models/admin.dart';
import '../models/category.dart';
import '../models/coupon.dart';
import '../models/customer.dart';
import '../models/employee.dart';
import '../models/employee_advance.dart';
import '../models/expense.dart';
import '../models/hall.dart';
import '../models/held_cart.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/order_status_history.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../models/purchase_item.dart';
import '../models/queue_entry.dart';
import '../models/recipe.dart';
import '../models/reservation.dart';
import '../models/restaurant_table.dart';
import '../models/rider_transaction.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/shift.dart';
import '../models/store_settings.dart';
import '../models/summaries.dart';
import '../models/supplier.dart';
import '../models/supplier_payment.dart';

/// عقد (واجهة) المستودع الذي يخزّن بيانات التطبيق محليًا.
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

  // المنتجات / المنيو
  Future<List<Product>> getProducts();
  Future<int> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(int id);

  /// إضافة منتجات بشكل جماعي (استيراد منيو).
  Future<List<int>> addProductsBulk(List<Product> products);

  // تحديث الكمية بمقدار (سالبة عند البيع)
  Future<void> updateStock(int productId, double delta);

  // التصنيفات
  Future<List<Category>> getCategories();
  Future<int> addCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(int id);

  // المصروفات
  Future<List<Expense>> getExpenses({int? limit});
  Future<int> addExpense(Expense expense);
  Future<void> deleteExpense(int id);

  // المبيعات (النظام القديم - محفوظ للتوافق)
  Future<List<Sale>> getSales({int? limit});
  Future<Sale?> getSale(int id);
  Future<List<SaleItem>> getSaleItems(int saleId);

  /// ملخص المبيعات محسوبًا بـ SQL.
  Future<SalesTotals> getSalesTotals();
  Future<List<DailySaleTotals>> getDailySalesTotals(int days);
  Future<List<Sale>> getSalesOn(DateTime day);
  Future<List<DayHistoryEntry>> getDayHistory();
  Future<ExpenseTotals> getExpenseTotals();
  Future<List<Expense>> getExpensesOn(DateTime day);
  Future<ProfitAnalytics> getProfitAnalytics();
  Future<List<TopProduct>> topProducts({int limit});

  /// ينشئ الفاتورة مع بنودها ويخصم المخزون في معاملة واحدة (Atomic).
  Future<int> createSale({required Sale sale, required List<SaleItem> items});

  /// جلب الفواتير الآجلة (الغير مسددة) — لتعرف אילو الترابيزات أو أسماء الدليفري مشغولة.
  Future<List<Sale>> getDeferredSales();

  /// سداد فاتورة آجلة: يغيّر طريقة الدفع ويحدّث المبلغ المدفوع.
  Future<void> settleSale({
    required int saleId,
    required String paymentMethod,
    required double amountTendered,
  });

  /// مرتجع فاتورة.
  Future<void> refundSale(int saleId);

  // الوردية (Z-Report)
  Future<Shift?> getOpenShift(String cashierName);
  Future<Shift?> getLatestShift(String cashierName);
  Future<Shift> ensureOpenShift(String cashierName, {DateTime? openedAt});
  Future<ShiftReport> getShiftReport(Shift shift);
  Future<Shift?> closeShift(String cashierName);

  // الفواتير المعلقة (Hold Invoice)
  Future<int> holdCart({
    required HeldCart cart,
    required List<HeldCartItem> items,
  });
  Future<List<HeldCart>> getHeldCarts();
  Future<List<HeldCartItem>> getHeldCartItems(int heldCartId);
  Future<void> deleteHeldCart(int heldCartId);

  // ===== إدارة الصالات =====
  Future<List<Hall>> getHalls();
  Future<int> addHall(Hall hall);
  Future<void> updateHall(Hall hall);
  Future<void> deleteHall(int id);

  /// تقرير يومي لصالة محددة.
  Future<HallDailyReport> getHallDailyReport(int hallId, DateTime date);

  // ===== إدارة الترابيزات =====
  Future<List<RestaurantTable>> getTables();
  Future<List<RestaurantTable>> getTablesByHall(int hallId);
  Future<int> addTable(RestaurantTable table);
  Future<void> updateTable(RestaurantTable table);
  Future<void> deleteTable(int id);
  Future<void> updateTableStatus(int tableId, TableStatus status, {int? orderId});
  Future<RestaurantTable?> getTable(int id);

  /// جلب كل الطلبات النشطة على تريبية معينة.
  Future<List<RestaurantOrder>> getTableOrders(int tableId);

  /// سداد كل طلبات التريبية (الدفع وإ freesها).
  Future<double> payTable(int tableId, String paymentMethod);

  // ===== إدارة الموظفين =====
  Future<List<Employee>> getEmployees();
  Future<List<Employee>> getActiveEmployees();
  Future<List<Employee>> getDeliveryPersons();
  Future<int> addEmployee(Employee employee);
  Future<void> updateEmployee(Employee employee);
  Future<void> deleteEmployee(int id);
  Future<Employee?> getEmployee(int id);

  // ===== سلف الموظفين =====
  Future<int> addEmployeeAdvance(EmployeeAdvance advance);
  Future<List<EmployeeAdvance>> getEmployeeAdvances(int employeeId, {DateTime? date});
  Future<DailyEmployeeReport> getEmployeeDailyReport(int employeeId, DateTime date);

  // ===== نظام الطلبات =====
  Future<List<RestaurantOrder>> getOrders({int? limit, String? status, String? orderType});
  Future<RestaurantOrder?> getOrder(int id);
  Future<List<OrderItem>> getOrderItems(int orderId);

  /// ينشئ طلب جديد مع بنودها في معاملة واحدة.
  Future<int> createOrder({
    required RestaurantOrder order,
    required List<OrderItem> items,
  });

  /// يحدّث حالة الطلب.
  Future<void> updateOrderStatus(int orderId, OrderStatus status, {String note});

  /// سجل تغييرات حالة الطلب.
  Future<void> addOrderStatusHistory(OrderStatusHistory entry);
  Future<List<OrderStatusHistory>> getOrderStatusHistory(int orderId);

  /// يحدّث حالة بند الطلب.
  Future<void> updateOrderItemStatus(int orderItemId, String status);

  /// يُلغى طلب (مع إرجاع حالة التريبية).
  Future<void> cancelOrder(int orderId);

  /// طلبات نشطة (pending + preparing).
  Future<List<RestaurantOrder>> getActiveOrders();

  /// طلبات التوصيل النشطة.
  Future<List<RestaurantOrder>> getActiveDeliveryOrders();

  /// طلبات المطبخ: pending + preparing + ready (لشاشة المطبخ KDS).
  Future<List<RestaurantOrder>> getKitchenOrders();

  /// عدد الطلبات النشطة.
  Future<int> getActiveOrdersCount();

  /// عدد الترابيزات المشغولة.
  Future<int> getOccupiedTablesCount();

  /// عدد الموظفين النشطين.
  Future<int> getActiveEmployeesCount();

  // ===== رصيد المندوبين =====
  Future<List<RiderTransaction>> getRiderTransactions(int riderId);
  Future<double> getRiderBalance(int riderId);
  Future<int> addRiderTransaction(RiderTransaction transaction);
  Future<List<RestaurantOrder>> getRiderOutstandingOrders(int riderId);

  // ===== إدارة الموردين =====
  Future<List<Supplier>> getSuppliers();
  Future<int> addSupplier(Supplier supplier);
  Future<void> updateSupplier(Supplier supplier);
  Future<void> deleteSupplier(int id);
  Future<Supplier?> getSupplier(int id);

  // ===== إدارة المشتريات =====
  Future<List<Purchase>> getPurchases({int? limit});
  Future<Purchase?> getPurchase(int id);
  Future<List<PurchaseItem>> getPurchaseItems(int purchaseId);
  Future<int> createPurchase({required Purchase purchase, required List<PurchaseItem> items});
  Future<void> settlePurchase({required int purchaseId, required double amount});
  Future<List<SupplierPayment>> getSupplierPayments(int supplierId);

  // ===== إدارة الكوبونات =====
  Future<List<Coupon>> getCoupons();
  Future<int> addCoupon(Coupon coupon);
  Future<void> updateCoupon(Coupon coupon);
  Future<void> deleteCoupon(int id);
  Future<Coupon?> getCouponByCode(String code);
  Future<void> useCoupon(int couponId);

  // ===== إدارة العملاء =====
  Future<List<Customer>> getCustomers();
  Future<int> addCustomer(Customer customer);
  Future<void> updateCustomer(Customer customer);
  Future<void> deleteCustomer(int id);
  Future<Customer?> getCustomer(int id);
  Future<Customer?> getCustomerByPhone(String phone);
  Future<void> addLoyaltyPoints(int customerId, int points);

  // ===== إدارة الحجوزات =====
  Future<List<Reservation>> getReservations();
  Future<int> createReservation(Reservation reservation);
  Future<void> updateReservationStatus(int id, ReservationStatus status);
  Future<void> deleteReservation(int id);

  // ===== إدارة قائمة الانتظار =====
  Future<List<QueueEntry>> getQueueEntries();
  Future<int> addQueueEntry(QueueEntry entry);
  Future<void> updateQueueEntryStatus(int id, QueueStatus status);
  Future<void> deleteQueueEntry(int id);

  // ===== إدارة الوصفات =====
  Future<List<Recipe>> getRecipes();
  Future<int> createRecipe(Recipe recipe);
  Future<void> updateRecipe(Recipe recipe);
  Future<void> deleteRecipe(int id);
  Future<List<RecipeItem>> getRecipeItems(int recipeId);
  Future<void> addRecipeItem(RecipeItem item);
  Future<void> deleteRecipeItem(int id);

  // إعدادات المتجر
  Future<String?> getSetting(String key);
  Future<void> setSetting(String key, String value);
  Future<StoreSettings> getSettings();
  Future<void> saveSettings(StoreSettings settings);
}

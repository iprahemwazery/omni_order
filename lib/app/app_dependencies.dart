import '../domain/repositories/store_repository.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/auth_usecases.dart';
import '../features/categories/data/repositories/categories_repository_impl.dart';
import '../features/categories/domain/repositories/categories_repository.dart';
import '../features/categories/domain/usecases/categories_usecases.dart';
import '../features/coupons/data/repositories/coupon_repository_impl.dart';
import '../features/coupons/domain/repositories/coupon_repository.dart';
import '../features/coupons/domain/usecases/coupon_usecases.dart';
import '../features/customers/data/repositories/customer_repository_impl.dart';
import '../features/customers/domain/repositories/customer_repository.dart';
import '../features/customers/domain/usecases/customer_usecases.dart';
import '../features/delivery/data/repositories/delivery_repository_impl.dart';
import '../features/delivery/domain/repositories/delivery_repository.dart';
import '../features/delivery/domain/usecases/delivery_usecases.dart';
import '../features/employees/data/repositories/employees_repository_impl.dart';
import '../features/employees/domain/repositories/employees_repository.dart';
import '../features/employees/domain/usecases/employees_usecases.dart';
import '../features/expenses/data/repositories/expenses_repository_impl.dart';
import '../features/expenses/domain/repositories/expenses_repository.dart';
import '../features/expenses/domain/usecases/expenses_usecases.dart';
import '../features/halls/data/repositories/halls_repository_impl.dart';
import '../features/halls/domain/repositories/halls_repository.dart';
import '../features/halls/domain/usecases/halls_usecases.dart';
import '../features/home/data/repositories/home_repository_impl.dart';
import '../features/home/domain/repositories/home_repository.dart';
import '../features/home/domain/usecases/home_usecases.dart';
import '../features/kitchen/data/repositories/kitchen_repository_impl.dart';
import '../features/kitchen/domain/repositories/kitchen_repository.dart';
import '../features/kitchen/domain/usecases/kitchen_usecases.dart';
import '../features/orders/data/repositories/orders_repository_impl.dart';
import '../features/orders/domain/repositories/orders_repository.dart';
import '../features/orders/domain/usecases/orders_usecases.dart';
import '../features/products/data/repositories/products_repository_impl.dart';
import '../features/products/domain/repositories/products_repository.dart';
import '../features/products/domain/usecases/products_usecases.dart';
import '../features/queue/data/repositories/queue_repository_impl.dart';
import '../features/queue/domain/repositories/queue_repository.dart';
import '../features/queue/domain/usecases/queue_usecases.dart';
import '../features/recipes/data/repositories/recipe_repository_impl.dart';
import '../features/recipes/domain/repositories/recipe_repository.dart';
import '../features/recipes/domain/usecases/recipe_usecases.dart';
import '../features/reservations/data/repositories/reservation_repository_impl.dart';
import '../features/reservations/domain/repositories/reservation_repository.dart';
import '../features/reservations/domain/usecases/reservation_usecases.dart';
import '../features/rider_balance/data/repositories/rider_balance_repository_impl.dart';
import '../features/rider_balance/domain/repositories/rider_balance_repository.dart';
import '../features/rider_balance/domain/usecases/rider_balance_usecases.dart';
import '../features/sales/data/repositories/sales_repository_impl.dart';
import '../features/sales/domain/repositories/sales_repository.dart';
import '../features/sales/domain/usecases/sales_usecases.dart';
import '../features/settings/data/repositories/settings_repository_impl.dart';
import '../features/settings/domain/repositories/settings_repository.dart';
import '../features/settings/domain/usecases/settings_usecases.dart';
import '../features/suppliers/data/repositories/supplier_repository_impl.dart';
import '../features/suppliers/domain/repositories/supplier_repository.dart';
import '../features/suppliers/domain/usecases/supplier_usecases.dart';
import '../features/tables/data/repositories/tables_repository_impl.dart';
import '../features/tables/domain/repositories/tables_repository.dart';
import '../features/tables/domain/usecases/tables_usecases.dart';
import '../features/waiter/data/repositories/waiter_repository_impl.dart';
import '../features/waiter/domain/repositories/waiter_repository.dart';
import '../features/waiter/domain/usecases/waiter_usecases.dart';

class AppDependencies {
  AppDependencies(this.storeRepository);

  final StoreRepository storeRepository;

  late final AuthRepository authRepository = AuthRepositoryImpl(
    storeRepository,
  );
  late final CategoriesRepository categoriesRepository =
      CategoriesRepositoryImpl(storeRepository);
  late final CouponRepository couponRepository = CouponRepositoryImpl(
    storeRepository,
  );
  late final CustomerRepository customerRepository = CustomerRepositoryImpl(
    storeRepository,
  );
  late final DeliveryRepository deliveryRepository = DeliveryRepositoryImpl(
    storeRepository,
  );
  late final EmployeesRepository employeesRepository = EmployeesRepositoryImpl(
    storeRepository,
  );
  late final ExpensesRepository expensesRepository = ExpensesRepositoryImpl(
    storeRepository,
  );
  late final HallsRepository hallsRepository = HallsRepositoryImpl(
    storeRepository,
  );
  late final HomeRepository homeRepository = HomeRepositoryImpl(
    storeRepository,
  );
  late final KitchenRepository kitchenRepository = KitchenRepositoryImpl(
    storeRepository,
  );
  late final OrdersRepository ordersRepository = OrdersRepositoryImpl(
    storeRepository,
  );
  late final ProductsRepository productsRepository = ProductsRepositoryImpl(
    storeRepository,
  );
  late final QueueRepository queueRepository = QueueRepositoryImpl(
    storeRepository,
  );
  late final RecipeRepository recipeRepository = RecipeRepositoryImpl(
    storeRepository,
  );
  late final ReservationRepository reservationRepository =
      ReservationRepositoryImpl(storeRepository);
  late final RiderBalanceRepository riderBalanceRepository =
      RiderBalanceRepositoryImpl(storeRepository);
  late final SalesRepository salesRepository = SalesRepositoryImpl(
    storeRepository,
  );
  late final SettingsRepository settingsRepository = SettingsRepositoryImpl(
    storeRepository,
  );
  late final SupplierRepository supplierRepository = SupplierRepositoryImpl(
    storeRepository,
  );
  late final TablesRepository tablesRepository = TablesRepositoryImpl(
    storeRepository,
  );
  late final WaiterRepository waiterRepository = WaiterRepositoryImpl(
    storeRepository,
  );

  late final LoginUseCase login = LoginUseCase(authRepository);
  late final GetProductsUseCase getProducts = GetProductsUseCase(
    productsRepository,
  );
  late final CreateProductUseCase createProduct = CreateProductUseCase(
    productsRepository,
  );
  late final UpdateProductUseCase updateProduct = UpdateProductUseCase(
    productsRepository,
  );
  late final DeleteProductUseCase deleteProduct = DeleteProductUseCase(
    productsRepository,
  );
  late final ImportProductsUseCase importProducts = ImportProductsUseCase(
    productsRepository,
  );
  late final GetCategoriesUseCase getCategories = GetCategoriesUseCase(
    categoriesRepository,
  );
  late final CreateCategoryUseCase createCategory = CreateCategoryUseCase(
    categoriesRepository,
  );
  late final UpdateCategoryUseCase updateCategory = UpdateCategoryUseCase(
    categoriesRepository,
  );
  late final DeleteCategoryUseCase deleteCategory = DeleteCategoryUseCase(
    categoriesRepository,
  );
  late final GetExpensesUseCase getExpenses = GetExpensesUseCase(
    expensesRepository,
  );
  late final GetExpenseTotalsUseCase getExpenseTotals = GetExpenseTotalsUseCase(
    expensesRepository,
  );
  late final GetExpensesOnDateUseCase getExpensesOnDate =
      GetExpensesOnDateUseCase(expensesRepository);
  late final CreateExpenseUseCase createExpense = CreateExpenseUseCase(
    expensesRepository,
  );
  late final DeleteExpenseUseCase deleteExpense = DeleteExpenseUseCase(
    expensesRepository,
  );
  late final GetSalesUseCase getSales = GetSalesUseCase(salesRepository);
  late final GetSalesTotalsUseCase getSalesTotals = GetSalesTotalsUseCase(
    salesRepository,
  );
  late final GetSaleItemsUseCase getSaleItems = GetSaleItemsUseCase(
    salesRepository,
  );
  late final GetDailySalesTotalsUseCase getDailySalesTotals =
      GetDailySalesTotalsUseCase(salesRepository);
  late final GetSalesOnDateUseCase getSalesOnDate = GetSalesOnDateUseCase(
    salesRepository,
  );
  late final GetDayHistoryUseCase getDayHistory = GetDayHistoryUseCase(
    salesRepository,
  );
  late final GetProfitAnalyticsUseCase getProfitAnalytics =
      GetProfitAnalyticsUseCase(salesRepository);
  late final GetTopProductsUseCase getTopProducts = GetTopProductsUseCase(
    salesRepository,
  );
  late final GetDeferredSalesUseCase getDeferredSales = GetDeferredSalesUseCase(
    salesRepository,
  );
  late final CreateSaleUseCase createSale = CreateSaleUseCase(salesRepository);
  late final RefundSaleUseCase refundSale = RefundSaleUseCase(salesRepository);
  late final SettleSaleUseCase settleSale = SettleSaleUseCase(salesRepository);
  late final GetSettingsUseCase getSettings = GetSettingsUseCase(
    settingsRepository,
  );
  late final SaveSettingsUseCase saveSettings = SaveSettingsUseCase(
    settingsRepository,
  );
  late final GetOrders getOrders = GetOrders(ordersRepository);
  late final GetOrderDetails getOrderDetails = GetOrderDetails(
    ordersRepository,
  );
  late final CreateOrder createOrder = CreateOrder(ordersRepository);
  late final UpdateOrderStatus updateOrderStatus = UpdateOrderStatus(
    ordersRepository,
  );
  late final CancelOrder cancelOrder = CancelOrder(ordersRepository);
  late final GetTables getTables = GetTables(tablesRepository);
  late final GetTableOrders getTableOrders = GetTableOrders(tablesRepository);
  late final PayTable payTable = PayTable(tablesRepository);
  late final GetHalls getHalls = GetHalls(hallsRepository);
  late final AddHall addHall = AddHall(hallsRepository);
  late final UpdateHall updateHall = UpdateHall(hallsRepository);
  late final DeleteHall deleteHall = DeleteHall(hallsRepository);
  late final ToggleHallActive toggleHallActive = ToggleHallActive(
    hallsRepository,
  );
  late final GetHallDailyReport getHallDailyReport = GetHallDailyReport(
    hallsRepository,
  );
  late final GetEmployees getEmployees = GetEmployees(employeesRepository);
  late final AddEmployee addEmployee = AddEmployee(employeesRepository);
  late final UpdateEmployee updateEmployee = UpdateEmployee(
    employeesRepository,
  );
  late final DeleteEmployee deleteEmployee = DeleteEmployee(
    employeesRepository,
  );
  late final ToggleEmployeeActive toggleEmployeeActive = ToggleEmployeeActive(
    employeesRepository,
  );
  late final AddEmployeeAdvance addEmployeeAdvance = AddEmployeeAdvance(
    employeesRepository,
  );
  late final GetEmployeeAdvances getEmployeeAdvances = GetEmployeeAdvances(
    employeesRepository,
  );
  late final GetEmployeeDailyReport getEmployeeDailyReport =
      GetEmployeeDailyReport(employeesRepository);
  late final GetActiveDeliveryOrders getActiveDeliveryOrders =
      GetActiveDeliveryOrders(deliveryRepository);
  late final UpdateDeliveryStatus updateDeliveryStatus = UpdateDeliveryStatus(
    deliveryRepository,
  );
  late final CompleteDelivery completeDelivery = CompleteDelivery(
    deliveryRepository,
  );
  late final GetKitchenOrders getKitchenOrders = GetKitchenOrders(
    kitchenRepository,
  );
  late final GetKitchenOrderItems getKitchenOrderItems = GetKitchenOrderItems(
    kitchenRepository,
  );
  late final UpdateKitchenOrderStatus updateKitchenOrderStatus =
      UpdateKitchenOrderStatus(kitchenRepository);
  late final GetRiderBalanceData getRiderBalanceData = GetRiderBalanceData(
    riderBalanceRepository,
  );
  late final RecordRiderSettlement recordRiderSettlement =
      RecordRiderSettlement(riderBalanceRepository);
  late final RecordRiderAdvance recordRiderAdvance = RecordRiderAdvance(
    riderBalanceRepository,
  );
  late final GetCouponsUseCase getCoupons = GetCouponsUseCase(couponRepository);
  late final CreateCouponUseCase createCoupon = CreateCouponUseCase(
    couponRepository,
  );
  late final UpdateCouponUseCase updateCoupon = UpdateCouponUseCase(
    couponRepository,
  );
  late final DeleteCouponUseCase deleteCoupon = DeleteCouponUseCase(
    couponRepository,
  );
  late final ValidateCouponUseCase validateCoupon = ValidateCouponUseCase(
    couponRepository,
  );
  late final GetCustomersUseCase getCustomers = GetCustomersUseCase(
    customerRepository,
  );
  late final FindCustomerByPhoneUseCase findCustomerByPhone =
      FindCustomerByPhoneUseCase(customerRepository);
  late final CreateCustomerUseCase createCustomer = CreateCustomerUseCase(
    customerRepository,
  );
  late final UpdateCustomerUseCase updateCustomer = UpdateCustomerUseCase(
    customerRepository,
  );
  late final DeleteCustomerUseCase deleteCustomer = DeleteCustomerUseCase(
    customerRepository,
  );
  late final AddCustomerLoyaltyPointsUseCase addCustomerLoyaltyPoints =
      AddCustomerLoyaltyPointsUseCase(customerRepository);
  late final GetHomeDashboardUseCase getHomeDashboard = GetHomeDashboardUseCase(
    homeRepository,
  );
  late final GetQueueEntriesUseCase getQueueEntries = GetQueueEntriesUseCase(
    queueRepository,
  );
  late final AddQueueEntryUseCase addQueueEntry = AddQueueEntryUseCase(
    queueRepository,
  );
  late final UpdateQueueEntryStatusUseCase updateQueueEntryStatus =
      UpdateQueueEntryStatusUseCase(queueRepository);
  late final DeleteQueueEntryUseCase deleteQueueEntry = DeleteQueueEntryUseCase(
    queueRepository,
  );
  late final GetRecipesUseCase getRecipes = GetRecipesUseCase(recipeRepository);
  late final CreateRecipeUseCase createRecipe = CreateRecipeUseCase(
    recipeRepository,
  );
  late final UpdateRecipeUseCase updateRecipe = UpdateRecipeUseCase(
    recipeRepository,
  );
  late final DeleteRecipeUseCase deleteRecipe = DeleteRecipeUseCase(
    recipeRepository,
  );
  late final GetReservationsUseCase getReservations = GetReservationsUseCase(
    reservationRepository,
  );
  late final CreateReservationUseCase createReservation =
      CreateReservationUseCase(reservationRepository);
  late final UpdateReservationStatusUseCase updateReservationStatus =
      UpdateReservationStatusUseCase(reservationRepository);
  late final DeleteReservationUseCase deleteReservation =
      DeleteReservationUseCase(reservationRepository);
  late final GetSuppliersUseCase getSuppliers = GetSuppliersUseCase(
    supplierRepository,
  );
  late final CreateSupplierUseCase createSupplier = CreateSupplierUseCase(
    supplierRepository,
  );
  late final UpdateSupplierUseCase updateSupplier = UpdateSupplierUseCase(
    supplierRepository,
  );
  late final DeleteSupplierUseCase deleteSupplier = DeleteSupplierUseCase(
    supplierRepository,
  );
  late final GetPurchasesUseCase getPurchases = GetPurchasesUseCase(
    supplierRepository,
  );
  late final CreatePurchaseUseCase createPurchase = CreatePurchaseUseCase(
    supplierRepository,
  );
  late final SettlePurchaseUseCase settlePurchase = SettlePurchaseUseCase(
    supplierRepository,
  );
  late final GetPurchaseItemsUseCase getPurchaseItems = GetPurchaseItemsUseCase(
    supplierRepository,
  );
  late final GetSupplierPaymentsUseCase getSupplierPayments =
      GetSupplierPaymentsUseCase(supplierRepository);
  late final GetWaiterTables getWaiterTables = GetWaiterTables(
    waiterRepository,
  );
  late final SubmitWaiterOrder submitWaiterOrder = SubmitWaiterOrder(
    waiterRepository,
  );
}

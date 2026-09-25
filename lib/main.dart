import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_dependencies.dart';
import 'core/config/supabase_config.dart';
import 'core/constants.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/repositories/store_repository_impl.dart';
import 'data/services/auth_service.dart';
import 'data/services/backup_service.dart';
import 'data/services/license_service.dart';
import 'domain/repositories/store_repository.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/auth/presentation/auth_state.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/setup_screen.dart';
import 'features/categories/presentation/categories_cubit.dart';
import 'features/employees/presentation/employees_cubit.dart';
import 'features/expenses/presentation/expenses_cubit.dart';
import 'features/halls/presentation/halls_cubit.dart';
import 'features/license/presentation/activation_screen.dart';
import 'features/license/presentation/license_cubit.dart';
import 'features/orders/presentation/orders_cubit.dart';
import 'features/orders/domain/usecases/orders_usecases.dart';
import 'features/tables/domain/usecases/tables_usecases.dart';
import 'features/employees/domain/usecases/employees_usecases.dart';
import 'features/kitchen/domain/usecases/kitchen_usecases.dart';
import 'features/waiter/domain/usecases/waiter_usecases.dart';
import 'features/products/presentation/products_cubit.dart';
import 'features/sales/presentation/cart_cubit.dart';
import 'features/sales/presentation/sales_cubit.dart';
import 'features/settings/presentation/backup_cubit.dart';
import 'features/settings/presentation/settings_cubit.dart';
import 'shared/widgets/app_shell.dart';
import 'features/tables/presentation/tables_cubit.dart';
import 'features/delivery/presentation/delivery_cubit.dart';
import 'features/kitchen/presentation/kitchen_cubit.dart';
import 'features/suppliers/presentation/suppliers_cubit.dart';
import 'features/coupons/presentation/coupons_cubit.dart';
import 'features/customers/presentation/customers_cubit.dart';
import 'features/reservations/presentation/reservations_cubit.dart';
import 'features/queue/presentation/queue_cubit.dart';
import 'features/recipes/presentation/recipes_cubit.dart';
import 'features/rider_balance/presentation/rider_balance_cubit.dart';

Future<void> main() => bootstrapApp();

/// تهيئة الخدمات وفتح قاعدة البيانات ثم تشغيل التطبيق.
/// تُستدعى أيضًا من زر "إعادة المحاولة" في [InitErrorScreen].
Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }

  final repository = StoreRepositoryImpl(AppDatabase.instance);
  try {
    await repository.init();
  } catch (e, s) {
    debugPrint('Database init failed: $e\n$s');
    runApp(InitErrorScreen(error: '$e'));
    return;
  }
  runApp(OmniOrderApp(repository: repository));
}

/// شاشة خطأ بديلة عند فشل فتح قاعدة البيانات (بدل شاشة بيضاء).
class InitErrorScreen extends StatelessWidget {
  const InitErrorScreen({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'تعذر فتح قاعدة البيانات',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => bootstrapApp(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// التطبيق الرئيسي — يستقبل المستودع لتسهيل الاختبارات،
/// ويُوفّر لكل فيتشر Cubit مستقل (Feature-first Clean Architecture).
///
/// نقطة التركيب (composition root): تُنشأ الخدمات هنا مرة واحدة وتُمرّر
/// صراحةً للـcubits، مع إتاحة استبدالها ببديلات اختبارية.
class OmniOrderApp extends StatelessWidget {
  OmniOrderApp({
    super.key,
    required this.repository,
    AuthService? authService,
    LicenseService? licenseService,
  }) : authService = authService ?? AuthService(),
       licenseService = licenseService ?? LicenseService(),
       dependencies = AppDependencies(repository);

  final StoreRepository repository;
  final AuthService authService;
  final LicenseService licenseService;
  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<GetOrders>.value(value: dependencies.getOrders),
          RepositoryProvider<GetOrderDetails>.value(
            value: dependencies.getOrderDetails,
          ),
          RepositoryProvider<CancelOrder>.value(
            value: dependencies.cancelOrder,
          ),
          RepositoryProvider<UpdateOrderStatus>.value(
            value: dependencies.updateOrderStatus,
          ),
          RepositoryProvider<GetTables>.value(value: dependencies.getTables),
          RepositoryProvider<GetEmployees>.value(
            value: dependencies.getEmployees,
          ),
          RepositoryProvider<GetKitchenOrderItems>.value(
            value: dependencies.getKitchenOrderItems,
          ),
          RepositoryProvider<GetWaiterTables>.value(
            value: dependencies.getWaiterTables,
          ),
          RepositoryProvider<SubmitWaiterOrder>.value(
            value: dependencies.submitWaiterOrder,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => AuthCubit(
                repository,
                authService: authService,
                login: dependencies.login,
              )..init(),
            ),
            BlocProvider(create: (_) => LicenseCubit(licenseService)..init()),
            BlocProvider(
              create: (_) => ProductsCubit(
                repository,
                getProducts: dependencies.getProducts,
                createProduct: dependencies.createProduct,
                updateProduct: dependencies.updateProduct,
                deleteProduct: dependencies.deleteProduct,
                importProducts: dependencies.importProducts,
              )..init(),
            ),
            BlocProvider(
              create: (_) => CategoriesCubit(
                repository,
                getCategories: dependencies.getCategories,
                createCategory: dependencies.createCategory,
                deleteCategory: dependencies.deleteCategory,
              )..init(),
            ),
            BlocProvider(
              create: (_) => ExpensesCubit(
                repository,
                getExpenses: dependencies.getExpenses,
                getExpenseTotals: dependencies.getExpenseTotals,
                getExpensesOnDate: dependencies.getExpensesOnDate,
                createExpense: dependencies.createExpense,
                deleteExpense: dependencies.deleteExpense,
              )..init(),
            ),
            BlocProvider(
              create: (_) => SalesCubit(
                repository,
                getSales: dependencies.getSales,
                getSalesTotals: dependencies.getSalesTotals,
                getSaleItems: dependencies.getSaleItems,
                refundSale: dependencies.refundSale,
                settleSale: dependencies.settleSale,
                getDailySalesTotals: dependencies.getDailySalesTotals,
                getSalesOnDate: dependencies.getSalesOnDate,
                getDayHistory: dependencies.getDayHistory,
                getProfitAnalytics: dependencies.getProfitAnalytics,
                getTopProducts: dependencies.getTopProducts,
                getDeferredSales: dependencies.getDeferredSales,
              )..init(),
            ),
            BlocProvider(
              create: (_) => SettingsCubit(
                repository,
                getSettings: dependencies.getSettings,
                saveSettings: dependencies.saveSettings,
              )..init(),
            ),
            BlocProvider(create: (_) => BackupCubit(BackupService())),
            BlocProvider(
              create: (_) => HallsCubit(
                repository,
                getHalls: dependencies.getHalls,
                addHall: dependencies.addHall,
                updateHall: dependencies.updateHall,
                deleteHall: dependencies.deleteHall,
                toggleHallActive: dependencies.toggleHallActive,
                getHallDailyReport: dependencies.getHallDailyReport,
              )..init(),
            ),
            BlocProvider(
              create: (_) => TablesCubit(
                repository,
                getTables: dependencies.getTables,
                getHalls: dependencies.getHalls,
                getTableOrders: dependencies.getTableOrders,
                payTable: dependencies.payTable,
              )..init(),
            ),
            BlocProvider(
              create: (_) => EmployeesCubit(
                repository,
                getEmployees: dependencies.getEmployees,
                addEmployee: dependencies.addEmployee,
                updateEmployee: dependencies.updateEmployee,
                deleteEmployee: dependencies.deleteEmployee,
                toggleEmployeeActive: dependencies.toggleEmployeeActive,
                addEmployeeAdvance: dependencies.addEmployeeAdvance,
                getEmployeeAdvances: dependencies.getEmployeeAdvances,
                getEmployeeDailyReport: dependencies.getEmployeeDailyReport,
              )..init(),
            ),
            BlocProvider(
              create: (context) => CartCubit(
                repository: repository,
                productsCubit: context.read<ProductsCubit>(),
                salesCubit: context.read<SalesCubit>(),
                createSale: dependencies.createSale,
              ),
            ),
            BlocProvider(
              create: (context) => OrdersCubit(
                repository: repository,
                productsCubit: context.read<ProductsCubit>(),
                createOrder: dependencies.createOrder,
              ),
            ),
            BlocProvider(
              create: (_) => DeliveryCubit(
                repository,
                getActiveDeliveryOrders: dependencies.getActiveDeliveryOrders,
                updateDeliveryStatus: dependencies.updateDeliveryStatus,
                completeDelivery: dependencies.completeDelivery,
              )..init(),
            ),
            BlocProvider(
              create: (_) => KitchenCubit(
                repository,
                getKitchenOrders: dependencies.getKitchenOrders,
                updateKitchenOrderStatus: dependencies.updateKitchenOrderStatus,
              ),
            ),
            BlocProvider(
              create: (_) => SuppliersCubit(
                repository,
                getSuppliers: dependencies.getSuppliers,
                createSupplier: dependencies.createSupplier,
                updateSupplier: dependencies.updateSupplier,
                deleteSupplier: dependencies.deleteSupplier,
                getPurchases: dependencies.getPurchases,
                createPurchase: dependencies.createPurchase,
                settlePurchase: dependencies.settlePurchase,
                getPurchaseItems: dependencies.getPurchaseItems,
                getSupplierPayments: dependencies.getSupplierPayments,
              )..init(),
            ),
            BlocProvider(
              create: (_) => CouponsCubit(
                repository,
                getCoupons: dependencies.getCoupons,
                createCoupon: dependencies.createCoupon,
                updateCoupon: dependencies.updateCoupon,
                deleteCoupon: dependencies.deleteCoupon,
                validateCoupon: dependencies.validateCoupon,
              )..init(),
            ),
            BlocProvider(
              create: (_) => CustomersCubit(
                repository,
                getCustomers: dependencies.getCustomers,
                createCustomer: dependencies.createCustomer,
                updateCustomer: dependencies.updateCustomer,
                deleteCustomer: dependencies.deleteCustomer,
                addLoyaltyPoints: dependencies.addCustomerLoyaltyPoints,
              )..init(),
            ),
            BlocProvider(
              create: (_) => QueueCubit(
                repository: repository,
                getQueueEntries: dependencies.getQueueEntries,
                addQueueEntry: dependencies.addQueueEntry,
                updateQueueEntryStatus: dependencies.updateQueueEntryStatus,
                deleteQueueEntry: dependencies.deleteQueueEntry,
              )..load(),
            ),
            BlocProvider(
              create: (_) => RecipesCubit(
                repository: repository,
                getRecipes: dependencies.getRecipes,
                createRecipe: dependencies.createRecipe,
                updateRecipe: dependencies.updateRecipe,
                deleteRecipe: dependencies.deleteRecipe,
              )..load(),
            ),
            BlocProvider(
              create: (_) => RiderBalanceCubit(
                repository,
                getRiderBalanceData: dependencies.getRiderBalanceData,
                recordRiderSettlement: dependencies.recordRiderSettlement,
                recordRiderAdvance: dependencies.recordRiderAdvance,
              )..init(),
            ),
            BlocProvider(
              create: (_) => ReservationsCubit(
                repository: repository,
                getReservations: dependencies.getReservations,
                createReservation: dependencies.createReservation,
                updateReservationStatus: dependencies.updateReservationStatus,
                deleteReservation: dependencies.deleteReservation,
              )..load(),
            ),
          ],
          child: MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const _AuthGate(),
          ),
        ),
      ),
    );
  }
}

/// بوابة الترخيص وتسجيل الدخول: تعرض شاشة التحميل ثم تفعيل الترخيص
/// أو إعداد أول مرة أو تسجيل الدخول أو الشاشة الرئيسية حسب الحالة.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.loading:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.activation:
            return const ActivationScreen();
          case AuthStatus.setup:
            return const SetupScreen();
          case AuthStatus.unauthenticated:
            return const LoginScreen();
          case AuthStatus.authenticated:
            return const AppShell();
        }
      },
    );
  }
}

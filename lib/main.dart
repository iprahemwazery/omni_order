import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/supabase_config.dart';
import 'core/constants.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/repositories/store_repository_impl.dart';
import 'data/services/auth_service.dart';
import 'data/services/license_service.dart';
import 'domain/repositories/store_repository.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/auth/presentation/auth_state.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/setup_screen.dart';
import 'features/categories/presentation/categories_cubit.dart';
import 'features/customers/presentation/customers_cubit.dart';
import 'features/expenses/presentation/expenses_cubit.dart';
import 'features/license/presentation/activation_screen.dart';
import 'features/license/presentation/license_cubit.dart';
import 'features/products/presentation/products_cubit.dart';
import 'features/purchases/presentation/purchases_cubit.dart';
import 'features/sales/presentation/cart_cubit.dart';
import 'features/sales/presentation/sales_cubit.dart';
import 'features/settings/presentation/settings_cubit.dart';
import 'features/suppliers/presentation/suppliers_cubit.dart';
import 'features/home/presentation/home_screen.dart';

Future<void> main() async {
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
      theme: AppTheme.light(),
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
                  onPressed: () => main(),
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
class OmniOrderApp extends StatelessWidget {
  const OmniOrderApp({
    super.key,
    required this.repository,
    this.authService,
    this.licenseService,
  });

  final StoreRepository repository;
  final AuthService? authService;
  final LicenseService? licenseService;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
      child: MultiBlocProvider(
        providers: [
        BlocProvider(
          create: (_) =>
              AuthCubit(repository, authService: authService)..init(),
        ),
        BlocProvider(
          create: (_) =>
              LicenseCubit(licenseService ?? LicenseService())..init(),
        ),
        BlocProvider(create: (_) => ProductsCubit(repository)..init()),
        BlocProvider(create: (_) => CategoriesCubit(repository)..init()),
        BlocProvider(create: (_) => CustomersCubit(repository)..init()),
        BlocProvider(create: (_) => SuppliersCubit(repository)..init()),
        BlocProvider(create: (_) => ExpensesCubit(repository)..init()),
        BlocProvider(create: (_) => SalesCubit(repository)..init()),
        BlocProvider(create: (_) => SettingsCubit(repository)..init()),
        BlocProvider(
          create: (context) =>
              PurchasesCubit(repository, context.read<ProductsCubit>())..init(),
        ),
        BlocProvider(
          create: (context) => CartCubit(
            repository: repository,
            productsCubit: context.read<ProductsCubit>(),
            customersCubit: context.read<CustomersCubit>(),
            salesCubit: context.read<SalesCubit>(),
          ),
        ),
        ],
        child: MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
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
            return HomeScreen();
        }
      },
    );
  }
}

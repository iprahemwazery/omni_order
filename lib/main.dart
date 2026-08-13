import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/supabase_config.dart';
import 'core/constants.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/repositories/store_repository_impl.dart';
import 'data/services/auth_service.dart';
import 'domain/repositories/store_repository.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/auth/presentation/auth_state.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/role_selection_screen.dart';
import 'features/auth/presentation/setup_screen.dart';
import 'features/categories/presentation/categories_cubit.dart';
import 'features/customers/presentation/customers_cubit.dart';
import 'features/expenses/presentation/expenses_cubit.dart';
import 'features/products/presentation/products_cubit.dart';
import 'features/purchases/presentation/purchases_cubit.dart';
import 'features/sales/presentation/cart_cubit.dart';
import 'features/sales/presentation/sales_cubit.dart';
import 'features/settings/presentation/settings_cubit.dart';
import 'features/suppliers/presentation/suppliers_cubit.dart';
import 'features/home/presentation/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  final repository = StoreRepositoryImpl(AppDatabase.instance);
  await repository.init();
  runApp(OmniOrderApp(repository: repository));
}

/// التطبيق الرئيسي — يستقبل المستودع لتسهيل الاختبارات،
/// ويُوفّر لكل فيتشر Cubit مستقل (Feature-first Clean Architecture).
class OmniOrderApp extends StatelessWidget {
  const OmniOrderApp({super.key, required this.repository, this.authService});

  final StoreRepository repository;
  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              AuthCubit(repository, authService: authService)..init(),
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
    );
  }
}

/// بوابة تسجيل الدخول: تعرض شاشة التحميل ثم إعداد أول مرة أو تسجيل الدخول
/// أو الشاشة الرئيسية حسب حالة الدخول.
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
          case AuthStatus.setup:
            return const SetupScreen();
          case AuthStatus.unauthenticated:
            return const LoginScreen();
          case AuthStatus.chooseRole:
            return const RoleSelectionScreen();
          case AuthStatus.authenticated:
            return HomeScreen();
        }
      },
    );
  }
}

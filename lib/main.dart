import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:veridian/providers/localization_provider.dart';
import 'package:veridian/providers/theme_provider.dart';
import 'package:veridian/screens/auth/login_screen.dart';
import 'package:veridian/services/account_service.dart';
import 'package:veridian/services/assistant_service.dart';
import 'package:veridian/services/bill_service.dart';
import 'package:veridian/services/card_service.dart';
import 'package:veridian/services/loan_service.dart';
import 'package:veridian/services/local_storage_service.dart';
import 'package:veridian/services/transaction_service.dart';
import 'package:veridian/services/payment_service.dart';
import 'package:veridian/services/transfer_service.dart';
import 'package:veridian/services/user_service.dart';
import 'package:veridian/theme.dart';
import 'package:veridian/services/support_service.dart';
import 'package:veridian/services/shopping_service.dart';
import 'package:veridian/services/business_service.dart';
import 'package:veridian/services/career_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStorageService.init();
  final themeProvider = ThemeProvider();
  await themeProvider.init();
  final localizationProvider = LocalizationProvider();
  await localizationProvider.init();

  runApp(
    MyApp(
      themeProvider: themeProvider,
      localizationProvider: localizationProvider,
    ),
  );
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  final LocalizationProvider localizationProvider;

  const MyApp({
    super.key,
    required this.themeProvider,
    required this.localizationProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localizationProvider),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => AccountService()),
        ChangeNotifierProvider(create: (_) => CardService()),
        ChangeNotifierProvider(create: (_) => TransactionService()),
        ChangeNotifierProvider(create: (_) => BillService()),
        ChangeNotifierProvider(create: (_) => LoanService()),
        ChangeNotifierProvider(create: (_) => TransferService()),
        ChangeNotifierProvider(create: (_) => PaymentService()),
        ChangeNotifierProvider(create: (_) => SupportService()),
        ChangeNotifierProxyProvider<UserService, AssistantService>(
          create: (_) => AssistantService(),
          update: (_, user, assistant) =>
              assistant!..bindUser(user.currentUser?.id),
        ),
        ChangeNotifierProvider(create: (_) => ShoppingService()),
        ChangeNotifierProvider(create: (_) => BusinessService()),
        ChangeNotifierProvider(create: (_) => CareerService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Veridian Banking',
            locale: Locale(
                context.watch<LocalizationProvider>().currentLanguage.name),
            supportedLocales: const [Locale('ru'), Locale('kk'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            builder: (context, child) {
              final viewport = MediaQuery.sizeOf(context);
              final isDesktop = viewport.width > 500;
              final frameWidth = isDesktop ? 420.0 : viewport.width;
              final radius = BorderRadius.circular(isDesktop ? 32 : 0);
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;

              // The root Material gives the routed child a bounded, painted
              // surface. It avoids an unbounded Center/Container chain on web.
              return Material(
                color: isDark ? VeridianColors.shell : const Color(0xFFE1E9E8),
                child: Center(
                  child: SizedBox(
                    width: frameWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: radius,
                        border: isDesktop
                            ? Border.all(
                                color: theme.colorScheme.outline, width: 1)
                            : null,
                        boxShadow: isDesktop
                            ? [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: isDark ? 0.5 : 0.12),
                                  blurRadius: 36,
                                  offset: const Offset(0, 16),
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: radius,
                        child: Material(
                          color: theme.scaffoldBackgroundColor,
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              size: Size(frameWidth, viewport.height),
                            ),
                            child: child ?? const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}

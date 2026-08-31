import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'services/secure_storage_service.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/setup_wizard_screen.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/auth/screens/pending_verification_screen.dart';
import 'features/auth/screens/access_expired_screen.dart';
import 'features/admin/auth/admin_pin_screen.dart';
import 'features/admin/dashboard/admin_dashboard_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/dashboard/settings_screen.dart';
import 'widgets/connectivity_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (error) {
    throw StateError(
      'Failed to load .env. Create it from .env.example and set SUPABASE_URL and SUPABASE_ANON_KEY. Error: $error',
    );
  }

  AppConstants.validateSupabaseConfig();

  final secureStorage = SecureStorageService.instance;
  await secureStorage.migrateSensitivePrefsToSecureStorage();
  await secureStorage.migrateSupabaseAuthSessionFromSharedPreferences(
    AppConstants.supabasePersistSessionKey,
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: secureStorage.createSupabaseSessionStorage(
        persistSessionKey: AppConstants.supabasePersistSessionKey,
      ),
      pkceAsyncStorage: secureStorage.createSupabasePkceStorage(),
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const PatenteQuizApp(),
    ),
  );
}

/// Enables mouse-drag scrolling so the app works correctly on Android
/// emulators (e.g. Bluestacks) and desktop environments.
class EmulatorScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class PatenteQuizApp extends StatefulWidget {
  const PatenteQuizApp({super.key});

  @override
  State<PatenteQuizApp> createState() => _PatenteQuizAppState();
}

class _PatenteQuizAppState extends State<PatenteQuizApp> {
  /// Lets the auth listener navigate without needing a BuildContext.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _listenForPasswordRecovery();
  }

  /// When the user taps the reset link in their email, Supabase opens the app
  /// via the deep link and emits `passwordRecovery` with a recovery session.
  /// Send them straight to the reset screen.
  void _listenForPasswordRecovery() {
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppConstants.routeResetPassword,
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageProvider, ThemeProvider>(
      builder: (context, languageProvider, themeProvider, child) {
        return MaterialApp(
          title: 'Desh Bangla Patente',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          
          // Localization configuration
          locale: languageProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('it'), // Italian
            Locale('bn'), // Bangla
          ],
          
          // Emulator / desktop scroll fix
          scrollBehavior: EmulatorScrollBehavior(),

          // Theme configuration
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          
          // Routing
          initialRoute: AppConstants.routeSplash,
          routes: {
            AppConstants.routeSplash: (context) => const SplashScreen(),
            AppConstants.routeSetupWizard: (context) => const ConnectivityWrapper(child: SetupWizardScreen()),
            AppConstants.routeAuth: (context) => const ConnectivityWrapper(child: AuthScreen()),
            AppConstants.routeSignup: (context) => const ConnectivityWrapper(child: SignupScreen()),
            AppConstants.routeForgotPassword: (context) => const ConnectivityWrapper(child: ForgotPasswordScreen()),
            AppConstants.routeResetPassword: (context) => const ConnectivityWrapper(child: ResetPasswordScreen()),
            AppConstants.routeHome: (context) => const ConnectivityWrapper(child: DashboardScreen()),
            AppConstants.routeSettings: (context) => const ConnectivityWrapper(child: SettingsScreen()),
            AppConstants.routePendingVerification: (context) => const ConnectivityWrapper(child: PendingVerificationScreen()),
            AppConstants.routeAccessExpired: (context) => const ConnectivityWrapper(child: AccessExpiredScreen()),
            AppConstants.routeAdminPin: (context) => const AdminPinScreen(),
            AppConstants.routeAdminDashboard: (context) => const AdminDashboardScreen(),
          },
        );
      },
    );
  }
}

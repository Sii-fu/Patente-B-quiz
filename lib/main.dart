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
import 'features/auth/screens/pending_verification_screen.dart';
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
  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageProvider, ThemeProvider>(
      builder: (context, languageProvider, themeProvider, child) {
        return MaterialApp(
          title: 'Desh Bangla Patente',
          debugShowCheckedModeBanner: false,
          
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
            AppConstants.routeHome: (context) => const ConnectivityWrapper(child: DashboardScreen()),
            AppConstants.routeSettings: (context) => const ConnectivityWrapper(child: SettingsScreen()),
            AppConstants.routePendingVerification: (context) => const ConnectivityWrapper(child: PendingVerificationScreen()),
            AppConstants.routeAdminPin: (context) => const AdminPinScreen(),
            AppConstants.routeAdminDashboard: (context) => const AdminDashboardScreen(),
          },
        );
      },
    );
  }
}

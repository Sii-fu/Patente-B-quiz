import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // SharedPreferences Keys
  static const String keyFirstTimeUser = 'is_first_time_user';
  static const String keyCompletedSetup = 'completed_setup';
  static const String keyLicenseType = 'license_type';
  static const String keyDrivingSchoolCode = 'driving_school_code';
  static const String keyGuestMode = 'guest_mode';
  static const String keyLanguageSelected = 'language_selected';

  // Sensitive keys must be stored in FlutterSecureStorage.
  static const List<String> sensitiveStorageKeys = [
    keyFirstTimeUser,
    keyCompletedSetup,
    keyLicenseType,
    keyDrivingSchoolCode,
    keyGuestMode,
  ];
  
  // Supabase Configuration
  static const String envSupabaseUrl = 'SUPABASE_URL';
  static const String envSupabaseAnonKey = 'SUPABASE_ANON_KEY';

  static String get supabaseUrl => dotenv.env[envSupabaseUrl]?.trim() ?? '';
  static String get supabaseAnonKey =>
      dotenv.env[envSupabaseAnonKey]?.trim() ?? '';

  static String get supabasePersistSessionKey {
    final host = Uri.tryParse(supabaseUrl)?.host;
    if (host == null || host.isEmpty) {
      return 'sb-auth-token';
    }

    final projectRef = host.split('.').first;
    return 'sb-$projectRef-auth-token';
  }

  static void validateSupabaseConfig() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing required .env keys: SUPABASE_URL and SUPABASE_ANON_KEY',
      );
    }
  }
  
  // License Types
  static const List<String> licenseTypes = ['B', 'A', 'AM'];
  
  // Route Names
  static const String routeSplash = '/';
  static const String routeSetupWizard = '/setup';
  static const String routeAuth = '/auth';
  static const String routeSignup = '/signup';
  static const String routeHome = '/home';
  static const String routeSettings = '/settings';
  static const String routePendingVerification = '/pending-verification';
  static const String routeAdminPin = '/admin/pin';
  static const String routeAdminDashboard = '/admin/dashboard';
}

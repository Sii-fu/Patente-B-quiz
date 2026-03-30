class AppConstants {
  // SharedPreferences Keys
  static const String keyFirstTimeUser = 'is_first_time_user';
  static const String keyCompletedSetup = 'completed_setup';
  static const String keyLicenseType = 'license_type';
  static const String keyDrivingSchoolCode = 'driving_school_code';
  static const String keyGuestMode = 'guest_mode';
  static const String keyLanguageSelected = 'language_selected';
  
  // Supabase Configuration
  // TODO: Replace with your actual Supabase URL and Anon Key
  static const String supabaseUrl = 'https://gtlzxkfkfzndfsuqiyge.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_kyLq2y70LrUjFP9CtKZI5w_9q6whpz2';
  
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

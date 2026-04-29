import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/secure_storage_service.dart';
import '../../utils/constants.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isGuest = false;
  String? _userEmail;
  String? _licenseType;
  String? _schoolCode;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final secureStorage = SecureStorageService.instance;
    final session = Supabase.instance.client.auth.currentSession;

    final isGuest =
        await secureStorage.readBool(AppConstants.keyGuestMode) ?? false;
    final licenseType =
        await secureStorage.readString(AppConstants.keyLicenseType);
    final schoolCode =
        await secureStorage.readString(AppConstants.keyDrivingSchoolCode);

    setState(() {
      _isGuest = isGuest;
      _userEmail = session?.user.email;
      _licenseType = licenseType;
      _schoolCode = schoolCode;
    });
  }

  Future<void> _logout() async {
    // Clear guest mode
    await SecureStorageService.instance.writeBool(AppConstants.keyGuestMode, false);
    
    // Sign out from Supabase
    await Supabase.instance.client.auth.signOut();
    
    if (mounted) {
      // Navigate back to auth screen
      Navigator.pushReplacementNamed(context, AppConstants.routeAuth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: AppLocalizations.of(context)!.homeLogout,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _isGuest 
                      ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isGuest ? Icons.person_outline : Icons.check_circle_outline,
                  size: 50,
                  color: _isGuest 
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Status text
              Text(
                _isGuest ? AppLocalizations.of(context)!.homeGuestMode : AppLocalizations.of(context)!.homeRegisteredUser,
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // User info
              if (!_isGuest && _userEmail != null) ...[
                Text(
                  _userEmail!,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],

              // License info
              if (_licenseType != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${AppLocalizations.of(context)!.homeLicense}: $_licenseType',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // School code
              if (_schoolCode != null && _schoolCode!.isNotEmpty) ...[
                Text(
                  '${AppLocalizations.of(context)!.homeSchool}: $_schoolCode',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],

              const SizedBox(height: 48),

              // Info box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.homeOnboardingComplete,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.homeOnboardingInfo,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Guest mode warning
              if (_isGuest)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.secondary),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.homeGuestWarning,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

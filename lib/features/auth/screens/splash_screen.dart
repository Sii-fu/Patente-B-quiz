import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/theme.dart';
import '../../../providers/language_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/profile.dart';
import '../../admin/dashboard/admin_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showLanguageSelection = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _checkLanguageSelection();
  }

  Future<void> _checkLanguageSelection() async {
    // Add a small delay for splash effect
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final languageSelected = prefs.getBool(AppConstants.keyLanguageSelected) ?? false;

    if (!languageSelected) {
      // Show language selection
      setState(() {
        _showLanguageSelection = true;
      });
    } else {
      // Language already selected, proceed with normal flow
      _checkInitialRoute();
    }
  }

  Future<void> _onLanguageSelected(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyLanguageSelected, true);
    
    if (!mounted) return;
    
    // Set the selected language
    await Provider.of<LanguageProvider>(context, listen: false).setLanguage(locale);
    
    // Proceed with normal flow
    setState(() {
      _showLanguageSelection = false;
    });
    
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    if (_isNavigating) return;
    _isNavigating = true;

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();

    // Auto-complete setup with default Patente B license (skip Setup Wizard)
    final isFirstTime = prefs.getBool(AppConstants.keyFirstTimeUser) ?? true;
    if (isFirstTime) {
      await prefs.setBool(AppConstants.keyFirstTimeUser, false);
      await prefs.setString(AppConstants.keyLicenseType, 'B');
      await prefs.setString(AppConstants.keyDrivingSchoolCode, '');
      await prefs.setBool(AppConstants.keyCompletedSetup, true);
    }

    final completedSetup = prefs.getBool(AppConstants.keyCompletedSetup) ?? false;
    if (!completedSetup) {
      await prefs.setString(AppConstants.keyLicenseType, 'B');
      await prefs.setString(AppConstants.keyDrivingSchoolCode, '');
      await prefs.setBool(AppConstants.keyCompletedSetup, true);
    }

    // Check B: Is there an active Supabase session?
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // User is logged in - check if admin or regular user
      try {
        final profileData = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', session.user.id)
            .single();
        
        final profile = Profile.fromJson(profileData);
        
        if (profile.isAdmin) {
          // Admin user - navigate to PIN screen
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
            );
          }
        } else {
          // Regular user - go to Home
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppConstants.routeHome);
          }
        }
      } catch (e) {
        // Error fetching profile, default to home
        debugPrint('Error fetching profile: $e');
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppConstants.routeHome);
        }
      }
    } else {
      // No active session - go to Auth
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppConstants.routeAuth);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: _showLanguageSelection
                ? _buildLanguageSelection(context)
                : _buildSplashContent(context, l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildSplashContent(BuildContext context, AppLocalizations? l10n) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App Logo/Icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: 180,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 40),
        // App Name
        Text(
          l10n?.appTitle ?? 'Patente B Quiz',
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Subtitle
        Text(
          l10n?.splashPreparing ?? 'Preparati per l\'esame',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary.withOpacity(0.9),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 24),
        // Motto
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: theme.colorScheme.onPrimary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            "স্বপ্ন দেখি আমিও পারবো",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 60),
        // Loading indicator
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelection(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/icon/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Title
          Text(
            'Select Language\nSeleziona Lingua\nভাষা নির্বাচন করুন',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          // Language options
          _buildLanguageButton(
            context,
            'English',
            '🇬🇧',
            const Locale('en'),
          ),
          const SizedBox(height: 16),
          _buildLanguageButton(
            context,
            'Italiano',
            '🇮🇹',
            const Locale('it'),
          ),
          const SizedBox(height: 16),
          _buildLanguageButton(
            context,
            'বাংলা',
            '🇧🇩',
            const Locale('bn'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    String label,
    String flag,
    Locale locale,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _onLanguageSelected(locale),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

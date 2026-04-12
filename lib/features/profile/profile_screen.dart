import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../models/profile.dart';
import '../auth/screens/splash_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  Profile? _profile;
  String? _userEmail;
  String _selectedLicenseType = 'B';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      setState(() => _isLoading = true);

      _userEmail = user.email;

      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      final profile = Profile.fromJson(response);
      
      setState(() {
        _profile = profile;
        _nameController.text = profile.fullName ?? '';
        _phoneController.text = profile.username ?? '';
        _selectedLicenseType = profile.licenseType;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.profileLoadError}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      setState(() => _isSaving = true);

      await Supabase.instance.client.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'username': _phoneController.text.trim(),
        'license_type': _selectedLicenseType,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profileSaveSuccess),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        
        await _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.profileSaveError}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profileLogout),
        content: Text(l10n.profileLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.profileConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      
      await Supabase.instance.client.auth.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
      ),
      body: Column(
        children: [
          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Avatar
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Account Information Section
                    Text(
                      l10n.profileAccountInfo,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Email (Read-only)
                    TextFormField(
                      initialValue: _userEmail ?? '',
                      decoration: InputDecoration(
                        labelText: l10n.profileEmail,
                        prefixIcon: const Icon(Icons.email_outlined),
                        enabled: false,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.profileFullName,
                        hintText: l10n.profileFullNameHint,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.profileFullNameHint;
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: l10n.profilePhone,
                        hintText: l10n.profilePhoneHint,
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // License Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedLicenseType,
                      decoration: InputDecoration(
                        labelText: l10n.profileLicenseType,
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      items: [
                        DropdownMenuItem(value: 'B', child: Text(l10n.licenseB)),
                        DropdownMenuItem(value: 'A', child: Text(l10n.licenseA)),
                        DropdownMenuItem(value: 'AM', child: Text(l10n.licenseAM)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedLicenseType = value);
                        }
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // // Statistics Section (if profile loaded)
                    // if (_profile != null) ...[
                    //   Text(
                    //     l10n.profileStats,
                    //     style: theme.textTheme.titleLarge?.copyWith(
                    //       fontWeight: FontWeight.bold,
                    //     ),
                    //   ),
                      
                    //   const SizedBox(height: 16),
                      
                    //   Row(
                    //     children: [
                    //       Expanded(
                    //         child: _buildStatCard(
                    //           context: context,
                    //           icon: Icons.quiz_outlined,
                    //           label: l10n.profileTotalQuizzes,
                    //           value: _profile!.totalQuizzesTaken.toString(),
                    //           theme: theme,
                    //         ),
                    //       ),
                    //       const SizedBox(width: 12),
                    //       Expanded(
                    //         child: _buildStatCard(
                    //           context: context,
                    //           icon: Icons.star_outline,
                    //           label: l10n.profileAverageScore,
                    //           value: '${_profile!.averageScore.toStringAsFixed(1)}%',
                    //           theme: theme,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                      
                    //   const SizedBox(height: 12),
                      
                    //   Row(
                    //     children: [
                    //       Expanded(
                    //         child: _buildStatCard(
                    //           context: context,
                    //           icon: Icons.emoji_events_outlined,
                    //           label: l10n.profileLevel,
                    //           value: _profile!.currentLevel.toString(),
                    //           theme: theme,
                    //         ),
                    //       ),
                    //       const SizedBox(width: 12),
                    //       Expanded(
                    //         child: _buildStatCard(
                    //           context: context,
                    //           icon: Icons.trending_up,
                    //           label: l10n.profileXP,
                    //           value: _profile!.xp.toString(),
                    //           theme: theme,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                      
                    //   const SizedBox(height: 32),
                    // ],
                    
                    // const SizedBox(height: 32),
                    
                    // Save Button
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      icon: _isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isSaving ? l10n.profileSaving : l10n.profileSaveButton,
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Settings Button
                    OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pushNamed(context, AppConstants.routeSettings);
                      },
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(l10n.dashboardSettings),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Logout Button
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: Text(l10n.profileLogout),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

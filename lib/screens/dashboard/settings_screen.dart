import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  String _buildNumber = '';
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
        _buildNumber = '1';
      });
    }
  }

  Future<void> _saveNotificationsSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _saveSoundSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
    setState(() => _soundEnabled = value);
  }

  Future<void> _saveVibrationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
    setState(() => _vibrationEnabled = value);
  }

  Future<void> _clearCache() async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsClearCacheTitle),
        content: Text(l10n.settingsClearCacheMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.settingsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_profile_data');
      await prefs.remove('cached_questions');
      await prefs.remove('cached_categories');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsCacheCleared),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showPrivacyPolicy() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsPrivacyPolicy),
        content: SingleChildScrollView(
          child: Text(l10n.settingsPrivacyPolicyContent),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.settingsClose),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsTermsOfService),
        content: SingleChildScrollView(
          child: Text(l10n.settingsTermsOfServiceContent),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.settingsClose),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.drive_eta, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.appTitle),
                  Text(
                    '${l10n.settingsVersion} $_appVersion ($_buildNumber)',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Text(l10n.settingsAboutContent),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.settingsClose),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Appearance Section
          _buildSectionHeader(l10n.settingsAppearance, theme),
          
          // Language
          _buildSettingsTile(
            icon: Icons.language,
            title: l10n.settingsLanguage,
            trailing: DropdownButton<Locale>(
              value: languageProvider.locale,
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(
                  value: const Locale('en'),
                  child: Text(l10n.languageEnglish),
                ),
                DropdownMenuItem(
                  value: const Locale('it'),
                  child: Text(l10n.languageItalian),
                ),
                DropdownMenuItem(
                  value: const Locale('bn'),
                  child: Text(l10n.languageBangla),
                ),
              ],
              onChanged: (locale) {
                if (locale != null) {
                  HapticFeedback.mediumImpact();
                  languageProvider.setLanguage(locale);
                }
              },
            ),
            theme: theme,
          ),
          
          // Dark Mode
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: l10n.settingsDarkMode,
            subtitle: l10n.settingsDarkModeDesc,
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              HapticFeedback.mediumImpact();
              themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
            theme: theme,
          ),
          
          const Divider(height: 32),
          
          // Notifications Section
          _buildSectionHeader(l10n.settingsNotifications, theme),
          
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: l10n.settingsNotificationsEnable,
            subtitle: l10n.settingsNotificationsDesc,
            value: _notificationsEnabled,
            onChanged: (value) {
              HapticFeedback.mediumImpact();
              _saveNotificationsSetting(value);
            },
            theme: theme,
          ),
          
          const Divider(height: 32),
          
          // Quiz Settings Section
          _buildSectionHeader(l10n.settingsQuizSettings, theme),
          
          _buildSwitchTile(
            icon: Icons.volume_up_outlined,
            title: l10n.settingsSoundEffects,
            subtitle: l10n.settingsSoundEffectsDesc,
            value: _soundEnabled,
            onChanged: (value) {
              HapticFeedback.mediumImpact();
              _saveSoundSetting(value);
            },
            theme: theme,
          ),
          
          _buildSwitchTile(
            icon: Icons.vibration,
            title: l10n.settingsVibration,
            subtitle: l10n.settingsVibrationDesc,
            value: _vibrationEnabled,
            onChanged: (value) {
              HapticFeedback.mediumImpact();
              _saveVibrationSetting(value);
            },
            theme: theme,
          ),
          
          const Divider(height: 32),
          
          // Data & Storage Section
          _buildSectionHeader(l10n.settingsDataStorage, theme),
          
          _buildActionTile(
            icon: Icons.delete_outline,
            title: l10n.settingsClearCache,
            subtitle: l10n.settingsClearCacheDesc,
            onTap: _clearCache,
            theme: theme,
          ),
          
          const Divider(height: 32),
          
          // Support Section
          _buildSectionHeader(l10n.settingsSupport, theme),
          
          _buildActionTile(
            icon: Icons.help_outline,
            title: l10n.settingsHelpCenter,
            subtitle: l10n.settingsHelpCenterDesc,
            onTap: () => _launchUrl('mailto:support@deshbanglapatente.com'),
            showArrow: true,
            theme: theme,
          ),
          
          _buildActionTile(
            icon: Icons.bug_report_outlined,
            title: l10n.settingsReportBug,
            subtitle: l10n.settingsReportBugDesc,
            onTap: () => _launchUrl('mailto:bugs@deshbanglapatente.com?subject=Bug%20Report'),
            showArrow: true,
            theme: theme,
          ),
          
          _buildActionTile(
            icon: Icons.star_outline,
            title: l10n.settingsRateApp,
            subtitle: l10n.settingsRateAppDesc,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.settingsRateAppSoon),
                  backgroundColor: theme.colorScheme.primary,
                ),
              );
            },
            showArrow: true,
            theme: theme,
          ),
          
          _buildActionTile(
            icon: Icons.share_outlined,
            title: l10n.settingsShareApp,
            subtitle: l10n.settingsShareAppDesc,
            onTap: () {
              HapticFeedback.mediumImpact();
            },
            showArrow: true,
            theme: theme,
          ),
          
          const Divider(height: 32),
          
          // Legal Section
          _buildSectionHeader(l10n.settingsLegal, theme),
          
          _buildActionTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.settingsPrivacyPolicy,
            onTap: _showPrivacyPolicy,
            showArrow: true,
            theme: theme,
          ),
          
          _buildActionTile(
            icon: Icons.description_outlined,
            title: l10n.settingsTermsOfService,
            onTap: _showTermsOfService,
            showArrow: true,
            theme: theme,
          ),
          
          _buildActionTile(
            icon: Icons.info_outline,
            title: l10n.settingsAbout,
            onTap: _showAboutDialog,
            showArrow: true,
            theme: theme,
          ),
          
          const SizedBox(height: 24),
          
          // Version Info
          Center(
            child: Text(
              '${l10n.settingsVersion} $_appVersion ($_buildNumber)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Center(
            child: Text(
              '© 2025 Desh Bangla Patente',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  l10n.settingsDisclaimerTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.settingsDisclaimerContent,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
    required ThemeData theme,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeData theme,
  }) {
    return SwitchListTile(
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showArrow = false,
    required ThemeData theme,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: showArrow
          ? Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            )
          : null,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}

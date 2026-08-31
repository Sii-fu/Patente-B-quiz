import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/profile.dart';
import '../../../utils/constants.dart';
import '../../../utils/date_format_helper.dart';
import '../../../utils/theme.dart';

/// Shown to a student whose account is approved but whose course access period
/// has ended (`profiles.verified_until` is in the past).
///
/// Used both as a named route ([AppConstants.routeAccessExpired]) after login
/// and directly by the dashboard gate on a cold start.
class AccessExpiredScreen extends StatefulWidget {
  /// When the access period ended, if known. Shown under the message.
  final DateTime? expiredOn;

  /// Called when the user taps Refresh. When null, the screen re-queries the
  /// profile itself and navigates to home if access has been restored.
  final VoidCallback? onRefresh;

  const AccessExpiredScreen({super.key, this.expiredOn, this.onRefresh});

  @override
  State<AccessExpiredScreen> createState() => _AccessExpiredScreenState();
}

class _AccessExpiredScreenState extends State<AccessExpiredScreen> {
  bool _isChecking = false;

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();

    if (widget.onRefresh != null) {
      widget.onRefresh!();
      return;
    }

    setState(() => _isChecking = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final profile = Profile.fromJson(response);
      if (!mounted) return;

      if (profile.isAccessValid) {
        Navigator.pushReplacementNamed(context, AppConstants.routeHome);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(AppLocalizations.of(context)!.accessExpiredMessage),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Error checking status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _logout() async {
    HapticFeedback.mediumImpact();
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppConstants.routeAuth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_clock,
                      size: 80,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Title
                  Text(
                    l10n.accessExpiredTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Message
                  Text(
                    l10n.accessExpiredMessage,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (widget.expiredOn != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${l10n.accessExpiredOn}: '
                      '${formatExpiryDate(context, widget.expiredOn!)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Contact instructor note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.accessExpiredContact,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Refresh Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isChecking ? null : _refresh,
                      icon: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(l10n.pendingVerificationRefresh),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface,
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Logout Button
                  TextButton.icon(
                    onPressed: _logout,
                    icon: Icon(
                      Icons.logout,
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                    label: Text(
                      l10n.profileLogout,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

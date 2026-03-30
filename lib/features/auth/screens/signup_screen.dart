import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedLicenseType = 'B';

  // Focus nodes for better UX
  final _fullNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Haptic feedback
    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final l10n = AppLocalizations.of(context)!;

      // 1. Create user in Supabase Auth
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'full_name': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim(),
        },
      );

      if (authResponse.user == null) {
        throw Exception(l10n.signupErrorGeneral);
      }

      final userId = authResponse.user!.id;

      // 2. Update profile in profiles table
      // The trigger on_auth_user_created creates a basic profile row,
      // we need to UPDATE it (not upsert) with the complete user data
      // Using update with eq() to target the specific row created by trigger
      try {
        await supabase.from('profiles').update({
          'full_name': _fullNameController.text.trim(),
          'username': _phoneController.text.trim(), // Phone stored in username column
          'license_type': _selectedLicenseType,
        }).eq('id', userId);
      } catch (profileError) {
        // If update fails (e.g., RLS issue before email confirmation),
        // try upsert as fallback
        debugPrint('Profile update failed, trying upsert: $profileError');
        await supabase.from('profiles').upsert({
          'id': userId,
          'full_name': _fullNameController.text.trim(),
          'username': _phoneController.text.trim(),
          'license_type': _selectedLicenseType,
        }, onConflict: 'id');
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.signupSuccessMessage),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 5),
          ),
        );

        // Navigate back to auth screen for login
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = e.message;
        
        // Handle common error cases with localized messages
        if (e.message.contains('already registered') || 
            e.message.contains('already exists')) {
          errorMessage = AppLocalizations.of(context)!.signupErrorEmailExists;
        } else if (e.message.contains('weak password')) {
          errorMessage = AppLocalizations.of(context)!.signupErrorWeakPassword;
        } else if (e.message.contains('invalid email')) {
          errorMessage = AppLocalizations.of(context)!.authErrorEmailInvalid;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        final isNetworkError = errorMessage.contains('SocketException') ||
            errorMessage.contains('Failed host lookup') ||
            errorMessage.contains('No address associated');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNetworkError
                  ? AppLocalizations.of(context)!.signupErrorNetwork
                  : '${AppLocalizations.of(context)!.signupErrorGeneral}: ${e.toString().split('\n').first}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: Duration(seconds: isNetworkError ? 5 : 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateFullName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.signupErrorFullNameRequired;
    }
    if (value.trim().length < 2) {
      return l10n.signupErrorFullNameShort;
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.signupErrorPhoneRequired;
    }
    // Remove spaces and common separators for validation
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleanPhone.length < 8) {
      return l10n.signupErrorPhoneShort;
    }
    // Check for valid phone format (digits, optional + prefix)
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(cleanPhone)) {
      return l10n.signupErrorPhoneInvalid;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.authErrorEmail;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return l10n.authErrorEmailInvalid;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.authErrorPassword;
    }
    if (value.length < 6) {
      return l10n.authErrorPasswordShort;
    }
    // Check for at least one number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return l10n.signupErrorPasswordNeedsNumber;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.signupErrorConfirmPasswordRequired;
    }
    if (value != _passwordController.text) {
      return l10n.signupErrorPasswordsDoNotMatch;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signupTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  l10n.signupHeaderTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.signupHeaderSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name Field
                TextFormField(
                  controller: _fullNameController,
                  focusNode: _fullNameFocus,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.signupFullName,
                    hintText: l10n.signupFullNameHint,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: _validateFullName,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_phoneFocus);
                  },
                ),
                const SizedBox(height: 16),

                // Phone Number Field
                TextFormField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.signupPhone,
                    hintText: l10n.signupPhoneHint,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    helperText: l10n.signupPhoneHelper,
                  ),
                  validator: _validatePhone,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_emailFocus);
                  },
                ),
                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.authEmail,
                    hintText: l10n.authEmailHint,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_passwordFocus);
                  },
                ),
                const SizedBox(height: 16),


                // Password Field
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  textInputAction: TextInputAction.next,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: l10n.authPassword,
                    hintText: l10n.signupPasswordHint,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    helperText: l10n.signupPasswordHelper,
                  ),
                  validator: _validatePassword,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_confirmPasswordFocus);
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  textInputAction: TextInputAction.done,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: l10n.signupConfirmPassword,
                    hintText: l10n.signupConfirmPasswordHint,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: _validateConfirmPassword,
                  onFieldSubmitted: (_) {
                    _handleSignup();
                  },
                ),
                const SizedBox(height: 32),

                // Signup Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            l10n.signupButton,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Already have account link
                Center(
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Text(
                      l10n.signupAlreadyHaveAccount,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Terms and Privacy notice
                Center(
                  child: Text(
                    l10n.signupTermsNotice,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

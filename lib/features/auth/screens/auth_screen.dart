import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/constants.dart';
import '../../../services/apple_auth_service.dart';
import '../../../services/secure_storage_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null && mounted) {
        // User logged in successfully - check if admin or regular user
        await _navigateBasedOnRole(session.user.id);
      }
    });
  }

  Future<void> _navigateBasedOnRole(String userId) async {
    try {
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      final role = profileData['role'] as String? ?? 'user';
      final isVerified = profileData['is_verified'] as bool? ?? false;
      final isAdmin = role == 'admin';
      
      if (!mounted) return;
      
      if (isAdmin) {
        // Admin user - navigate to PIN verification screen
        Navigator.pushReplacementNamed(context, AppConstants.routeAdminPin);
      } else if (!isVerified) {
        // Regular user but not verified - show pending verification screen
        Navigator.pushReplacementNamed(context, AppConstants.routePendingVerification);
      } else {
        // Regular verified user - go to Home
        Navigator.pushReplacementNamed(context, AppConstants.routeHome);
      }
    } catch (e) {
      // Error fetching profile, default to home
      debugPrint('Error fetching profile for role check: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppConstants.routeHome);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Future<void> _signInWithGoogle() async {
  //   setState(() {
  //     _isLoading = true;
  //   });
  //   try {
  //     // Initialize Google Sign In
  //     final GoogleSignIn googleSignIn = GoogleSignIn(
  //       clientId: 'YOUR_GOOGLE_CLIENT_ID', // TODO: Add your Google Client ID
  //     );
  //     // Trigger Google Sign In flow
  //     final googleUser = await googleSignIn.signIn();
  //     if (googleUser == null) {
  //       // User cancelled the sign-in
  //       setState(() {
  //         _isLoading = false;
  //       });
  //       return;
  //     }
  //     final googleAuth = await googleUser.authentication;
  //     final accessToken = googleAuth.accessToken;
  //     final idToken = googleAuth.idToken;
  //     if (accessToken == null || idToken == null) {
  //       throw Exception('Missing Google Auth Token');
  //     }
  //     // Sign in to Supabase with Google credentials
  //     await Supabase.instance.client.auth.signInWithIdToken(
  //       provider: OAuthProvider.google,
  //       idToken: idToken,
  //       accessToken: accessToken,
  //     );
  //     // Navigation handled by auth state listener
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('${AppLocalizations.of(context)!.authErrorGoogle}: $e'),
  //           backgroundColor: Theme.of(context).colorScheme.error,
  //         ),
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }
  //   }
  // }
  // Future<void> _signInWithFacebook() async {
  //   setState(() {
  //     _isLoading = true;
  //   });
  //   try {
  //     // // Note: Facebook login requires additional setup in Supabase dashboard
  //     // // and the flutter_facebook_auth package
  //     // await Supabase.instance.client.auth.signInWithOAuth(
  //     //   OAuthProvider.facebook,
  //     //   redirectTo: 'YOUR_APP_SCHEME://login-callback', // TODO: Configure
  //     // );
        //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('${AppLocalizations.of(context)!.authErrorFacebook}: $e'),
  //           backgroundColor: Theme.of(context).colorScheme.error,
  //         ),
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }
  //   }
  // }

  Future<void> _submitEmailAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Login
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Navigation handled by auth state listener
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a network error
        final errorMessage = e.toString();
        final isNetworkError = errorMessage.contains('SocketException') || 
                               errorMessage.contains('Failed host lookup') ||
                               errorMessage.contains('No address associated');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNetworkError 
                ? 'Errore di connessione: Controlla la tua connessione internet\n\nPuoi continuare come ospite senza accesso'
                : 'Errore: ${e.toString().split('\n').first}'
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: Duration(seconds: isNetworkError ? 6 : 3),
            action: isNetworkError ? SnackBarAction(
              label: 'OSPITE',
              textColor: Colors.white,
              onPressed: _continueAsGuest,
            ) : null,
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

  Future<void> _continueAsGuest() async {
    await SecureStorageService.instance.writeBool(
      AppConstants.keyGuestMode,
      true,
    );
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppConstants.routeHome);
    }
  }

  // ── Apple Sign-In (iOS App Store requirement) ──────────────────────────────
  Future<void> _signInWithApple() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      await AppleAuthService.instance.signIn();
      // Navigation handled by onAuthStateChange listener in initState
    } on SignInWithAppleAuthorizationException catch (e) {
      // User cancelled — not an error worth reporting
      if (e.code == AuthorizationErrorCode.canceled) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple Sign-In failed: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple Sign-In error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // App Icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // App Name
                Text(
                  AppLocalizations.of(context)!.appTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                // Motto
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "স্বপ্ন দেখি আমিও পারবো",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Header
                Text(
                  AppLocalizations.of(context)!.authWelcomeBack,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.authSubtitleLogin,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 32),

                // // Social Login Buttons
                // ElevatedButton.icon(
                //   onPressed: _isLoading ? null : _signInWithGoogle,
                //   icon: const Icon(Icons.g_mobiledata, size: 28),
                //   label: Text(AppLocalizations.of(context)!.authContinueGoogle),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Theme.of(context).colorScheme.surface,
                //     foregroundColor: Theme.of(context).colorScheme.onSurface,
                //     side: BorderSide(color: Theme.of(context).colorScheme.outline),
                //   ),
                // ),
                // const SizedBox(height: 12),
                // ElevatedButton.icon(
                //   onPressed: _isLoading ? null : _signInWithFacebook,
                //   icon: const Icon(Icons.facebook, size: 24),
                //   label: Text(AppLocalizations.of(context)!.authContinueFacebook),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: const Color(0xFF1877F2),
                //     foregroundColor: Colors.white,
                //   ),
                // ),
                // const SizedBox(height: 32),

                // // Divider
                // Row(
                //   children: [
                //     Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
                //     Padding(
                //       padding: const EdgeInsets.symmetric(horizontal: 16),
                //       child: Text(
                //         AppLocalizations.of(context)!.authOr,
                //         style: Theme.of(context).textTheme.bodyMedium,
                //       ),
                //     ),
                //     Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
                //   ],
                // ),
                // const SizedBox(height: 32),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.authEmail,
                    hintText: AppLocalizations.of(context)!.authEmailHint,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.authErrorEmail;
                    }
                    if (!value.contains('@')) {
                      return AppLocalizations.of(context)!.authErrorEmailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.authPassword,
                    hintText: AppLocalizations.of(context)!.authPasswordHint,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.authErrorPassword;
                    }
                    if (value.length < 6) {
                      return AppLocalizations.of(context)!.authErrorPasswordShort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitEmailAuth,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(AppLocalizations.of(context)!.authLogin),
                  ),
                ),
                const SizedBox(height: 16),

                // Navigate to Signup
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppConstants.routeSignup);
                    },
                    child: Text(
                      AppLocalizations.of(context)!.authToggleSignup,
                    ),
                  ),
                ),

                // ── Sign in with Apple (iOS only – App Store requirement) ────
                // Apple guideline: if you offer any 3rd-party login you MUST
                // also offer Sign in with Apple on iOS/macOS.
                if (defaultTargetPlatform == TargetPlatform.iOS ||
                    defaultTargetPlatform == TargetPlatform.macOS) ...
                  [
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                              color: theme.colorScheme.outline.withOpacity(0.4)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                              color: theme.colorScheme.outline.withOpacity(0.4)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Official Apple-branded button (style follows Apple HIG)
                    SignInWithAppleButton(
                      onPressed: _isLoading ? () {} : _signInWithApple,
                      style: theme.brightness == Brightness.dark
                          ? SignInWithAppleButtonStyle.white
                          : SignInWithAppleButtonStyle.black,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(12)),
                      height: 52,
                    ),
                    const SizedBox(height: 8),
                  ],
                // const SizedBox(height: 20),

                // // Guest Mode
                // Center(
                //   child: TextButton(
                //     onPressed: _continueAsGuest,
                //     child: Text(
                //       AppLocalizations.of(context)!.authGuestMode,
                //       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                //             color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                //             decoration: TextDecoration.underline,
                //           ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles "Sign in with Apple" via Supabase auth.
///
/// Apple mandates that any iOS app offering third-party login (e.g. Google)
/// MUST also offer "Sign in with Apple" — failure to comply causes App Store
/// rejection. This service satisfies that requirement.
class AppleAuthService {
  AppleAuthService._();
  static final AppleAuthService instance = AppleAuthService._();

  /// Returns `true` if running on a platform that supports Sign in with Apple
  /// (iOS 13+, macOS 10.15+). Use this to conditionally show the button.
  static Future<bool> get isAvailable =>
      SignInWithApple.isAvailable();

  /// Generates a cryptographically random nonce string.
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the SHA256 hash of [input] as a hex string.
  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Triggers the Apple Sign-In sheet and signs into Supabase.
  ///
  /// Returns the [AuthResponse] on success, or throws on failure.
  /// The caller should catch exceptions and show appropriate UI.
  Future<AuthResponse> signIn() async {
    // 1. Generate a secure nonce – Apple will sign it and Supabase will verify it
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    // 2. Request credentials from Apple
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Apple Sign-In: identityToken was null.');
    }

    // 3. Exchange Apple ID token with Supabase
    final response = await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce, // Supabase verifies sha256(nonce) == hashedNonce
    );

    // 4. Apple only sends the user's full name on the FIRST sign-in.
    //    Persist it to profiles immediately before it's lost forever.
    final givenName = credential.givenName;
    final familyName = credential.familyName;
    if (givenName != null || familyName != null) {
      final fullName = [givenName, familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');
      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'full_name': fullName})
            .eq('id', response.user!.id);
      } catch (e) {
        debugPrint('AppleAuthService: could not persist full name – $e');
      }
    }

    return response;
  }
}

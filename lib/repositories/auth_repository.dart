import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown by [AuthRepository] with a message that is safe to show to users.
class AuthRepositoryException implements Exception {
  final String message;
  const AuthRepositoryException(this.message);

  @override
  String toString() => message;
}

/// Wraps Supabase Auth calls related to sign-in and password recovery.
class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  /// Deep link Supabase redirects to after the user taps the reset email.
  ///
  /// The scheme must match the one registered in
  /// `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`,
  /// and must be allow-listed in Supabase → Authentication → URL Configuration.
  static const String passwordResetRedirectUrl =
      'io.supabase.gtlzxkfkfzndfsuqiyge://reset-password';

  /// Sends a password recovery email containing both a deep link and a
  /// 6-digit OTP code.
  Future<void> sendPasswordResetEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      throw const AuthRepositoryException('Please enter your email address.');
    }

    try {
      await _supabase.auth.resetPasswordForEmail(
        trimmed,
        redirectTo: passwordResetRedirectUrl,
      );
    } on AuthException catch (e) {
      debugPrint('sendPasswordResetEmail AuthException: ${e.message}');
      throw AuthRepositoryException(_mapAuthError(e));
    } catch (e) {
      debugPrint('sendPasswordResetEmail error: $e');
      throw AuthRepositoryException(_mapGenericError(e));
    }
  }

  /// Verifies the 6-digit recovery code the user typed manually.
  ///
  /// On success Supabase establishes a recovery session, which is what lets
  /// [updatePassword] succeed.
  Future<void> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.recovery,
      );
    } on AuthException catch (e) {
      debugPrint('verifyRecoveryOtp AuthException: ${e.message}');
      throw AuthRepositoryException(_mapAuthError(e));
    } catch (e) {
      debugPrint('verifyRecoveryOtp error: $e');
      throw AuthRepositoryException(_mapGenericError(e));
    }
  }

  /// Sets a new password for the active recovery session, then signs out so
  /// the user re-authenticates with the new credentials.
  Future<void> updatePassword(String newPassword) async {
    if (_supabase.auth.currentSession == null) {
      throw const AuthRepositoryException(
        'Your reset link has expired. Please request a new one.',
      );
    }

    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      debugPrint('updatePassword AuthException: ${e.message}');
      throw AuthRepositoryException(_mapAuthError(e));
    } catch (e) {
      debugPrint('updatePassword error: $e');
      throw AuthRepositoryException(_mapGenericError(e));
    }

    // Sign out only after the password change actually succeeded, so a
    // failure leaves the recovery session intact for a retry.
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Sign out after password update failed: $e');
    }
  }

  String _mapAuthError(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('rate limit') ||
        message.contains('too many requests') ||
        e.statusCode == '429') {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (message.contains('invalid') && message.contains('email')) {
      return 'That email address does not look valid.';
    }
    if (message.contains('expired')) {
      return 'That code has expired. Please request a new one.';
    }
    if (message.contains('token') || message.contains('otp')) {
      return 'That code is not valid. Please check it and try again.';
    }
    if (message.contains('should be different') ||
        message.contains('same as the old')) {
      return 'Please choose a password different from your current one.';
    }
    if (message.contains('password') && message.contains('short')) {
      return 'That password is too short.';
    }
    return e.message;
  }

  String _mapGenericError(Object e) {
    final text = e.toString();
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('No address associated')) {
      return 'Connection error. Please check your internet and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

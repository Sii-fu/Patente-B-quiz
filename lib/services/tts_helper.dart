import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io';

/// Singleton TTS Helper for robust text-to-speech functionality
/// Supports Italian (it-IT), English (en-US), and Bangla (bn-BD/bn-IN)
/// Handles missing language data gracefully and works on all Android devices
class TtsHelper {
  // Singleton instance
  static final TtsHelper _instance = TtsHelper._internal();
  factory TtsHelper() => _instance;
  TtsHelper._internal();

  // FlutterTts instance
  final FlutterTts _flutterTts = FlutterTts();
  
  // Track initialization state
  bool _isInitialized = false;
  String _currentLanguage = 'it-IT';

  /// Initialize TTS with optimal settings for educational content
  /// This is now called automatically on first use (lazy initialization)
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Set speech rate (0.5 = slower, clearer for studying)
      _flutterTts.setSpeechRate(0.5);
      
      // Set volume to maximum for clarity
      _flutterTts.setVolume(1.0);
      
      // Set pitch to normal
      _flutterTts.setPitch(1.0);

      // Set completion handler
      _flutterTts.setCompletionHandler(() {
        debugPrint('TTS: Speech completed');
      });

      // Set error handler
      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS: Error occurred: $msg');
      });

      // Android-specific settings for better compatibility (non-blocking)
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          _flutterTts.setSharedInstance(true);
        } catch (e) {
          debugPrint('TTS: Could not set shared instance: $e');
        }
      }
      
      _isInitialized = true;
      debugPrint('TTS: Initialized successfully');
    } catch (e) {
      debugPrint('TTS: Initialization error: $e');
      // Still mark as initialized to prevent blocking
      _isInitialized = true;
    }
  }

  /// Speak text in the specified language with intelligent fallback handling
  /// 
  /// [text] - The text to speak
  /// [languageCode] - Language code: 'it', 'en', or 'bn' (or full codes like 'it-IT')
  /// [force] - If true, attempts to speak even if language check fails
  /// [awaitCompletion] - If true, waits for speech to complete before returning
  Future<bool> speak(String text, String languageCode, {bool force = false, bool awaitCompletion = true}) async {
    // Lazy initialization
    if (!_isInitialized) {
      init(); // Non-blocking fire and forget
    }

    if (text.trim().isEmpty) {
      debugPrint('TTS: Empty text provided');
      return false;
    }

    try {
      // Stop any currently playing audio (non-blocking)
      stop();

      // Normalize language code
      final normalizedCode = _normalizeLanguageCode(languageCode);
      // Check for TTS engine presence (Bluestacks/emulator fix)
      try {
        List<dynamic>? languages = await _flutterTts.getLanguages;
        if (languages == null || languages.isEmpty) {
          debugPrint('TTS: Engine missing! No languages available. Please install a TTS engine.');
          return false;
        }
      } catch (e) {
        debugPrint('TTS: getLanguages check failed: $e');
        // Proceed — some devices/emulators may throw here but still work on setLanguage/speak.
      }
      
      // Set language and speak immediately (simplified approach)
      try {
        await _flutterTts.setLanguage(normalizedCode);
        
        if (awaitCompletion) {
          await _flutterTts.awaitSpeakCompletion(true);
        }
        
        await _flutterTts.speak(text);
        debugPrint('TTS: Speaking in $normalizedCode');
        return true;
      } catch (e) {
        debugPrint('TTS: Primary language failed, trying fallback: $e');
        
        // Try English fallback
        try {
          await _flutterTts.setLanguage('en-US');
          
          if (awaitCompletion) {
            await _flutterTts.awaitSpeakCompletion(true);
          }
          
          await _flutterTts.speak(text);
          debugPrint('TTS: Speaking in fallback en-US');
          return true;
        } catch (e2) {
          debugPrint('TTS: English fallback failed: $e2');
          
          // Last resort: Italian
          try {
            await _flutterTts.setLanguage('it-IT');
            
            if (awaitCompletion) {
              await _flutterTts.awaitSpeakCompletion(true);
            }
            
            await _flutterTts.speak(text);
            debugPrint('TTS: Speaking in fallback it-IT');
            return true;
          } catch (e3) {
            debugPrint('TTS: All fallbacks failed: $e3');
            return false;
          }
        }
      }
    } catch (e) {
      debugPrint('TTS: Speak error: $e');
      return false;
    }
  }



  /// Normalize language code to full format (e.g., 'it' → 'it-IT')
  String _normalizeLanguageCode(String code) {
    final lowerCode = code.toLowerCase();
    
    // Already in full format
    if (lowerCode.contains('-')) {
      return _formatLanguageCode(lowerCode);
    }
    
    // Map short codes to full codes
    switch (lowerCode) {
      case 'it':
      case 'ita':
        return 'it-IT';
      case 'en':
      case 'eng':
        return 'en-US';
      case 'bn':
      case 'ben':
        return 'bn-BD'; // Primary Bangla locale
      default:
        return code; // Return as-is if unknown
    }
  }

  /// Format language code with proper casing (e.g., 'it-it' → 'it-IT')
  String _formatLanguageCode(String code) {
    final parts = code.split('-');
    if (parts.length == 2) {
      return '${parts[0].toLowerCase()}-${parts[1].toUpperCase()}';
    }
    return code;
  }

  /// Stop any currently playing speech (non-blocking)
  void stop() {
    try {
      _flutterTts.stop();
    } catch (e) {
      debugPrint('TTS: Stop error: $e');
    }
  }

  /// Pause speech (if supported by platform)
  void pause() {
    try {
      _flutterTts.pause();
    } catch (e) {
      debugPrint('TTS: Pause not supported: $e');
    }
  }

  /// Set speech rate (0.0 - 1.0, where 0.5 is recommended for studying)
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('TTS: Set speech rate error: $e');
    }
  }

  /// Set volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('TTS: Set volume error: $e');
    }
  }

  /// Get list of available languages on the device
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return (languages as List).map((lang) => lang.toString()).toList();
    } catch (e) {
      debugPrint('TTS: Get languages error: $e');
      return [];
    }
  }

  /// Check if a specific language is available on the device
  Future<bool> isLanguageAvailable(String languageCode) async {
    try {
      final normalized = _normalizeLanguageCode(languageCode);
      final languages = await getAvailableLanguages();
      
      // Check exact match first
      if (languages.contains(normalized)) {
        return true;
      }
      
      // Check if base language exists (e.g., 'it' in 'it-IT')
      final base = normalized.split('-').first;
      return languages.any((lang) => lang.toLowerCase().startsWith(base));
    } catch (e) {
      debugPrint('TTS: Language check error: $e');
      return false;
    }
  }

  /// Check if a language is installed and prompt installation if not (Android only)
  /// Returns true if language is installed, false if not
  Future<bool> checkAndPromptInstall(String languageCode) async {
    if (!Platform.isAndroid) {
      debugPrint('TTS: Install check only works on Android');
      return await isLanguageAvailable(languageCode);
    }

    try {
      final normalized = _normalizeLanguageCode(languageCode);
      
      // Check if the specific language is installed
      final isInstalled = await _flutterTts.isLanguageInstalled(normalized);
      debugPrint('TTS: Language $normalized installed: $isInstalled');

      if (!isInstalled) {
        // Language not installed - return false (caller should handle UI)
        return false;
      } else {
        // Language is installed - set it as current
        await _flutterTts.setLanguage(normalized);
        _currentLanguage = normalized;
        return true;
      }
    } catch (e) {
      debugPrint('TTS: Check and install error: $e');
      // Fallback to availability check
      return await isLanguageAvailable(languageCode);
    }
  }

  /// Launch Android TTS data installation settings
  /// Call this when user confirms they want to install missing language
  Future<void> launchTtsInstallation() async {
    if (!Platform.isAndroid) {
      debugPrint('TTS: Installation intent only works on Android');
      return;
    }

    try {
      final intent = AndroidIntent(
        action: 'android.speech.tts.engine.INSTALL_TTS_DATA',
      );
      await intent.launch();
      debugPrint('TTS: Launched installation intent');
    } catch (e) {
      debugPrint('TTS: Could not launch installation: $e');
    }
  }

  /// Get current language
  String get currentLanguage => _currentLanguage;

  /// Check if TTS is initialized
  bool get isInitialized => _isInitialized;
}

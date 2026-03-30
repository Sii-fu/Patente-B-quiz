import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Manages cache versioning to detect when local data is stale
/// Compares local cache version with server version to trigger updates
class CacheVersionManager {
  static const String _versionKey = 'cache_version';
  static const String _lastCheckKey = 'cache_version_last_check';
  static const String _serverVersionKey = 'server_cache_version';
  
  final SupabaseClient _supabase;
  
  CacheVersionManager({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Get current local cache version
  Future<int> getLocalVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_versionKey) ?? 0;
  }

  /// Set local cache version (called after successful download)
  Future<void> setLocalVersion(int version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_versionKey, version);
    await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
  }

  /// Increment local version (for manual cache updates)
  Future<void> incrementLocalVersion() async {
    final currentVersion = await getLocalVersion();
    await setLocalVersion(currentVersion + 1);
  }

  /// Get server cache version from metadata table
  /// Returns 0 if metadata doesn't exist or on error
  Future<int> getServerVersion() async {
    try {
      final response = await _supabase
          .from('app_metadata')
          .select('cache_version')
          .eq('key', 'content_version')
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ CacheVersionManager: No server version found');
        return 0;
      }

      return (response['cache_version'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('❌ CacheVersionManager: Error fetching server version - $e');
      return 0;
    }
  }

  /// Check if local cache is stale compared to server
  /// Returns true if server version is newer than local
  Future<bool> isStale() async {
    final localVersion = await getLocalVersion();
    final serverVersion = await getServerVersion();
    
    debugPrint('📦 CacheVersionManager: Local=$localVersion, Server=$serverVersion');
    
    return serverVersion > localVersion;
  }

  /// Check if we should check for updates (rate limiting)
  /// Only checks once per hour to avoid excessive API calls
  Future<bool> shouldCheckForUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckString = prefs.getString(_lastCheckKey);
    
    if (lastCheckString == null) return true;
    
    try {
      final lastCheck = DateTime.parse(lastCheckString);
      final hoursSinceCheck = DateTime.now().difference(lastCheck).inHours;
      
      // Check at most once per hour
      return hoursSinceCheck >= 1;
    } catch (e) {
      return true; // If parsing fails, allow check
    }
  }

  /// Update last check timestamp without changing version
  Future<void> updateLastCheckTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
  }

  /// Get cache age in days
  Future<int> getCacheAgeDays() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckString = prefs.getString(_lastCheckKey);
    
    if (lastCheckString == null) return -1;
    
    try {
      final lastCheck = DateTime.parse(lastCheckString);
      return DateTime.now().difference(lastCheck).inDays;
    } catch (e) {
      return -1;
    }
  }

  /// Check for updates and return result with version info
  Future<CacheUpdateCheck> checkForUpdates() async {
    try {
      final localVersion = await getLocalVersion();
      final serverVersion = await getServerVersion();
      final cacheAge = await getCacheAgeDays();
      
      await updateLastCheckTimestamp();
      
      return CacheUpdateCheck(
        localVersion: localVersion,
        serverVersion: serverVersion,
        isStale: serverVersion > localVersion,
        cacheAgeDays: cacheAge,
      );
    } catch (e) {
      debugPrint('❌ CacheVersionManager: Error checking for updates - $e');
      return CacheUpdateCheck(
        localVersion: await getLocalVersion(),
        serverVersion: 0,
        isStale: false,
        cacheAgeDays: -1,
        error: e.toString(),
      );
    }
  }

  /// Clear version data (for testing/reset)
  Future<void> clearVersionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_versionKey);
    await prefs.remove(_lastCheckKey);
    await prefs.remove(_serverVersionKey);
  }
}

/// Result of cache update check
class CacheUpdateCheck {
  final int localVersion;
  final int serverVersion;
  final bool isStale;
  final int cacheAgeDays;
  final String? error;

  CacheUpdateCheck({
    required this.localVersion,
    required this.serverVersion,
    required this.isStale,
    required this.cacheAgeDays,
    this.error,
  });

  /// Get user-friendly message about cache status
  String getMessage() {
    if (error != null) {
      return 'Could not check for updates';
    }
    
    if (isStale) {
      return 'New content available (v$serverVersion). Current: v$localVersion';
    }
    
    if (cacheAgeDays >= 0) {
      return 'Content is up to date (${cacheAgeDays}d old)';
    }
    
    return 'Content is up to date';
  }

  /// Check if update is recommended (stale or very old)
  bool get shouldUpdate => isStale || cacheAgeDays > 7;
}

import 'local_db.dart';

/// Singleton provider for AppDatabase
/// Ensures only one database instance exists throughout the app lifecycle
class DatabaseProvider {
  static AppDatabase? _database;

  /// Get the singleton database instance
  static AppDatabase get instance {
    _database ??= AppDatabase();
    return _database!;
  }

  /// Close and reset the database (for testing or cleanup)
  static Future<void> reset() async {
    await _database?.close();
    _database = null;
  }
}

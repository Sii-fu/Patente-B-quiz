import 'package:supabase_flutter/supabase_flutter.dart';
import 'quiz_repository.dart';

/// Singleton provider for repositories
/// Ensures only one repository instance exists throughout the app lifecycle
/// This prevents memory leaks and ensures consistent state
class RepositoryProvider {
  static QuizRepository? _quizRepository;

  /// Get the singleton QuizRepository instance
  static QuizRepository get quizRepository {
    _quizRepository ??= QuizRepository(
      supabaseClient: Supabase.instance.client,
    );
    return _quizRepository!;
  }

  /// Reset repositories (for testing or cleanup)
  static void reset() {
    _quizRepository = null;
  }

  /// Reset only quiz repository
  static void resetQuizRepository() {
    _quizRepository = null;
  }
}

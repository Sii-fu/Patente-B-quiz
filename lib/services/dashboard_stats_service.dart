import 'package:shared_preferences/shared_preferences.dart';
import '../database/local_db.dart';
import '../database/database_provider.dart';

/// Service to manage dashboard statistics including:
/// - Daily streak tracking
/// - Overall progress calculation
/// - Completed chapters count
/// - Error tracking
class DashboardStatsService {
  static const String _keyLastStudyDate = 'last_study_date';
  static const String _keyCurrentStreak = 'current_streak';
  static const String _keyLongestStreak = 'longest_streak';
  static const String _keyTotalQuizzesTaken = 'total_quizzes_taken';
  static const String _keyTotalCorrectAnswers = 'total_correct_answers';
  static const String _keyTotalQuestions = 'total_questions_answered';
  static const String _keyTotalErrors = 'total_errors';
  static const String _keyCompletedChapters = 'completed_chapters_ids';
  
  SharedPreferences? _prefs;
  final AppDatabase database;
  
  DashboardStatsService({required this.database});
  
  /// Initialize the service - must be called before using
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  /// Factory method to create an initialized instance
  static Future<DashboardStatsService> create({AppDatabase? database}) async {
    final service = DashboardStatsService(database: database ?? DatabaseProvider.instance);
    await service.init();
    return service;
  }
  
  // ====== STREAK MANAGEMENT ======
  
  /// Get the current daily streak
  int get currentStreak => _prefs?.getInt(_keyCurrentStreak) ?? 0;
  
  /// Get the longest streak ever achieved
  int get longestStreak => _prefs?.getInt(_keyLongestStreak) ?? 0;
  
  /// Get the last study date
  DateTime? get lastStudyDate {
    final dateStr = _prefs?.getString(_keyLastStudyDate);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }
  
  /// Record a study session - updates streak accordingly
  /// Call this when user completes a quiz or reads theory
  Future<int> recordStudySession() async {
    if (_prefs == null) await init();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = lastStudyDate;
    
    int newStreak = currentStreak;
    
    if (lastDate == null) {
      // First time studying
      newStreak = 1;
    } else {
      final lastStudyDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final difference = today.difference(lastStudyDay).inDays;
      
      if (difference == 0) {
        // Already studied today, streak stays the same
        newStreak = currentStreak;
      } else if (difference == 1) {
        // Studied yesterday, increment streak
        newStreak = currentStreak + 1;
      } else {
        // Missed a day or more, reset streak
        newStreak = 1;
      }
    }
    
    // Update streak
    await _prefs!.setInt(_keyCurrentStreak, newStreak);
    await _prefs!.setString(_keyLastStudyDate, today.toIso8601String());
    
    // Update longest streak if needed
    if (newStreak > longestStreak) {
      await _prefs!.setInt(_keyLongestStreak, newStreak);
    }
    
    return newStreak;
  }
  
  /// Check if streak needs to be reset (call on app open)
  Future<void> checkAndUpdateStreak() async {
    if (_prefs == null) await init();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = lastStudyDate;
    
    if (lastDate != null) {
      final lastStudyDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final difference = today.difference(lastStudyDay).inDays;
      
      // If more than 1 day has passed, reset streak
      if (difference > 1) {
        await _prefs!.setInt(_keyCurrentStreak, 0);
      }
    }
  }
  
  // ====== QUIZ STATS ======
  
  /// Get total quizzes taken
  int get totalQuizzesTaken => _prefs?.getInt(_keyTotalQuizzesTaken) ?? 0;
  
  /// Get total correct answers
  int get totalCorrectAnswers => _prefs?.getInt(_keyTotalCorrectAnswers) ?? 0;
  
  /// Get total questions answered
  int get totalQuestionsAnswered => _prefs?.getInt(_keyTotalQuestions) ?? 0;
  
  /// Get total errors made
  int get totalErrors => _prefs?.getInt(_keyTotalErrors) ?? 0;
  
  /// Calculate overall progress percentage (based on correct answer rate)
  double get progressPercentage {
    if (totalQuestionsAnswered == 0) return 0.0;
    return (totalCorrectAnswers / totalQuestionsAnswered).clamp(0.0, 1.0);
  }
  
  /// Record quiz result
  Future<void> recordQuizResult({
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    if (_prefs == null) await init();
    
    final errors = totalQuestions - correctAnswers;
    
    await _prefs!.setInt(
      _keyTotalQuizzesTaken, 
      totalQuizzesTaken + 1,
    );
    await _prefs!.setInt(
      _keyTotalCorrectAnswers, 
      totalCorrectAnswers + correctAnswers,
    );
    await _prefs!.setInt(
      _keyTotalQuestions, 
      totalQuestionsAnswered + totalQuestions,
    );
    await _prefs!.setInt(
      _keyTotalErrors, 
      totalErrors + errors,
    );
    
    // Also update streak
    await recordStudySession();
  }
  
  // ====== CHAPTER PROGRESS ======
  
  /// Get list of completed chapter IDs
  List<int> get completedChapterIds {
    final idsStr = _prefs?.getStringList(_keyCompletedChapters) ?? [];
    return idsStr.map((s) => int.tryParse(s) ?? 0).where((id) => id > 0).toList();
  }
  
  /// Get completed chapters count
  int get completedChaptersCount => completedChapterIds.length;
  
  /// Mark a chapter as completed
  Future<void> markChapterCompleted(int chapterId) async {
    if (_prefs == null) await init();
    
    final ids = completedChapterIds;
    if (!ids.contains(chapterId)) {
      ids.add(chapterId);
      await _prefs!.setStringList(
        _keyCompletedChapters,
        ids.map((id) => id.toString()).toList(),
      );
      
      // Also update streak when completing a chapter
      await recordStudySession();
    }
  }
  
  /// Check if a chapter is completed
  bool isChapterCompleted(int chapterId) {
    return completedChapterIds.contains(chapterId);
  }
  
  /// Get chapter completion based on reading progress from database
  Future<int> getCompletedChaptersFromDB() async {
    try {
      final chapters = await database.getAllTheoryChapters();
      
      int completedCount = 0;
      for (final chapter in chapters) {
        final progress = await database.getChapterProgress(chapter.id);
        // Consider chapter completed if 80%+ is read
        if (progress >= 80.0) {
          completedCount++;
          // Also mark in local prefs for offline access
          await markChapterCompleted(chapter.id);
        }
      }
      
      return completedCount;
    } catch (e) {
      // Fallback to locally stored count
      return completedChaptersCount;
    }
  }
  
  // ====== DASHBOARD DATA MODEL ======
  
  /// Get all dashboard stats at once
  Future<DashboardStats> getDashboardStats() async {
    if (_prefs == null) await init();
    
    // Check streak on load
    await checkAndUpdateStreak();
    
    // Get completed chapters from DB if available
    final chaptersFromDB = await getCompletedChaptersFromDB();
    
    return DashboardStats(
      streak: currentStreak,
      longestStreak: longestStreak,
      progressPercentage: progressPercentage,
      completedChapters: chaptersFromDB > 0 ? chaptersFromDB : completedChaptersCount,
      totalQuizzesTaken: totalQuizzesTaken,
      totalErrors: totalErrors,
      totalCorrectAnswers: totalCorrectAnswers,
      totalQuestionsAnswered: totalQuestionsAnswered,
    );
  }
  
  // ====== RESET ======
  
  /// Reset all stats (for debugging or account switch)
  Future<void> resetAllStats() async {
    if (_prefs == null) await init();
    
    await _prefs!.remove(_keyLastStudyDate);
    await _prefs!.remove(_keyCurrentStreak);
    await _prefs!.remove(_keyLongestStreak);
    await _prefs!.remove(_keyTotalQuizzesTaken);
    await _prefs!.remove(_keyTotalCorrectAnswers);
    await _prefs!.remove(_keyTotalQuestions);
    await _prefs!.remove(_keyTotalErrors);
    await _prefs!.remove(_keyCompletedChapters);
  }
}

/// Data class holding all dashboard statistics
class DashboardStats {
  final int streak;
  final int longestStreak;
  final double progressPercentage;
  final int completedChapters;
  final int totalQuizzesTaken;
  final int totalErrors;
  final int totalCorrectAnswers;
  final int totalQuestionsAnswered;
  
  const DashboardStats({
    required this.streak,
    required this.longestStreak,
    required this.progressPercentage,
    required this.completedChapters,
    required this.totalQuizzesTaken,
    required this.totalErrors,
    required this.totalCorrectAnswers,
    required this.totalQuestionsAnswered,
  });
  
  /// Default empty stats
  static const empty = DashboardStats(
    streak: 0,
    longestStreak: 0,
    progressPercentage: 0.0,
    completedChapters: 0,
    totalQuizzesTaken: 0,
    totalErrors: 0,
    totalCorrectAnswers: 0,
    totalQuestionsAnswered: 0,
  );
}

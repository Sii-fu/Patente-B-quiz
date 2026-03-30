import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for syncing user statistics with Supabase profiles table
/// Handles: daily_streak, last_study_date, total_quizzes_taken, average_score
class ProfileStatsService {
  final SupabaseClient _supabase;
  
  ProfileStatsService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Get the current user's ID
  String? get _userId => _supabase.auth.currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => _userId != null;

  // ====== FETCH PROFILE STATS ======

  /// Fetch current profile stats from Supabase
  Future<ProfileStats> getProfileStats() async {
    if (!isAuthenticated) {
      return ProfileStats.empty;
    }

    try {
      final response = await _supabase
          .from('profiles')
          .select('daily_streak, last_study_date, total_quizzes_taken, average_score, xp, current_level')
          .eq('id', _userId!)
          .single();

      return ProfileStats.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching profile stats: $e');
      return ProfileStats.empty;
    }
  }

  // ====== UPDATE STREAK ======

  /// Record a study session and update streak
  /// Call this when user completes a quiz or reads theory
  Future<int> recordStudySession() async {
    if (!isAuthenticated) return 0;

    try {
      // Fetch current stats
      final currentStats = await getProfileStats();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      int newStreak = currentStats.dailyStreak;
      
      if (currentStats.lastStudyDate == null) {
        // First time studying
        newStreak = 1;
      } else {
        final lastStudyDay = DateTime(
          currentStats.lastStudyDate!.year,
          currentStats.lastStudyDate!.month,
          currentStats.lastStudyDate!.day,
        );
        final difference = today.difference(lastStudyDay).inDays;

        if (difference == 0) {
          // Already studied today, streak stays the same
          newStreak = currentStats.dailyStreak;
        } else if (difference == 1) {
          // Studied yesterday, increment streak
          newStreak = currentStats.dailyStreak + 1;
        } else {
          // Missed a day or more, reset streak
          newStreak = 1;
        }
      }

      // Update in Supabase
      await _supabase.from('profiles').update({
        'daily_streak': newStreak,
        'last_study_date': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).eq('id', _userId!);

      return newStreak;
    } catch (e) {
      debugPrint('Error recording study session: $e');
      return 0;
    }
  }

  /// Check and reset streak if user missed a day (call on app open)
  Future<void> checkAndUpdateStreak() async {
    if (!isAuthenticated) return;

    try {
      final currentStats = await getProfileStats();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (currentStats.lastStudyDate != null) {
        final lastStudyDay = DateTime(
          currentStats.lastStudyDate!.year,
          currentStats.lastStudyDate!.month,
          currentStats.lastStudyDate!.day,
        );
        final difference = today.difference(lastStudyDay).inDays;

        // If more than 1 day has passed, reset streak
        if (difference > 1) {
          await _supabase.from('profiles').update({
            'daily_streak': 0,
            'updated_at': now.toIso8601String(),
          }).eq('id', _userId!);
        }
      }
    } catch (e) {
      debugPrint('Error checking streak: $e');
    }
  }

  // ====== RECORD QUIZ RESULT ======

  /// Record a completed quiz and update stats
  Future<void> recordQuizResult({
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    if (!isAuthenticated) return;

    try {
      // Fetch current stats
      final currentStats = await getProfileStats();
      
      // Calculate new values
      final newTotalQuizzes = currentStats.totalQuizzesTaken + 1;
      
      // Calculate new average score
      // Formula: ((oldAvg * oldCount) + newScore) / newCount
      final newScore = (correctAnswers / totalQuestions) * 100;
      final oldTotalScore = currentStats.averageScore * currentStats.totalQuizzesTaken;
      final newAverageScore = (oldTotalScore + newScore) / newTotalQuizzes;
      
      // Calculate XP gain (10 XP per correct answer)
      final xpGain = correctAnswers * 10;
      final newXp = currentStats.xp + xpGain;
      
      // Calculate level (simple formula: level = sqrt(xp / 100))
      final newLevel = (newXp / 100).floor() + 1;

      // Update in Supabase
      await _supabase.from('profiles').update({
        'total_quizzes_taken': newTotalQuizzes,
        'average_score': newAverageScore,
        'xp': newXp,
        'current_level': newLevel,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _userId!);

      // Also update streak
      await recordStudySession();
    } catch (e) {
      debugPrint('Error recording quiz result: $e');
      rethrow; // Let caller handle the error
    }
  }

  // ====== DASHBOARD STATS ======

  /// Get all stats needed for dashboard in one call
  Future<DashboardStats> getDashboardStats() async {
    if (!isAuthenticated) {
      return DashboardStats.empty;
    }

    try {
      // Check streak on load
      await checkAndUpdateStreak();
      
      // Fetch updated stats
      final profileStats = await getProfileStats();
      
      return DashboardStats(
        streak: profileStats.dailyStreak,
        totalQuizzesTaken: profileStats.totalQuizzesTaken,
        averageScore: profileStats.averageScore,
        progressPercentage: profileStats.averageScore / 100,
        xp: profileStats.xp,
        level: profileStats.level,
        completedChapters: 0, // TODO: Fetch from Supabase when theory progress table is added
        longestStreak: profileStats.dailyStreak, // Longest streak tracked separately if needed
      );
    } catch (e) {
      debugPrint('Error getting dashboard stats: $e');
      return DashboardStats.empty;
    }
  }
}

/// Data class for profile statistics from Supabase
class ProfileStats {
  final int dailyStreak;
  final DateTime? lastStudyDate;
  final int totalQuizzesTaken;
  final double averageScore;
  final int xp;
  final int level;

  const ProfileStats({
    required this.dailyStreak,
    this.lastStudyDate,
    required this.totalQuizzesTaken,
    required this.averageScore,
    required this.xp,
    required this.level,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      dailyStreak: json['daily_streak'] ?? 0,
      lastStudyDate: json['last_study_date'] != null
          ? DateTime.tryParse(json['last_study_date'])
          : null,
      totalQuizzesTaken: json['total_quizzes_taken'] ?? 0,
      averageScore: (json['average_score'] ?? 0.0).toDouble(),
      xp: json['xp'] ?? 0,
      level: json['current_level'] ?? 1,
    );
  }

  static const empty = ProfileStats(
    dailyStreak: 0,
    lastStudyDate: null,
    totalQuizzesTaken: 0,
    averageScore: 0.0,
    xp: 0,
    level: 1,
  );
}

/// Data class for dashboard display
class DashboardStats {
  final int streak;
  final int totalQuizzesTaken;
  final double averageScore;
  final double progressPercentage;
  final int xp;
  final int level;
  final int completedChapters;
  final int longestStreak;
  final int totalErrors;
  final int totalCorrectAnswers;
  final int totalQuestionsAnswered;

  const DashboardStats({
    required this.streak,
    required this.totalQuizzesTaken,
    required this.averageScore,
    required this.progressPercentage,
    required this.xp,
    required this.level,
    this.completedChapters = 0,
    this.longestStreak = 0,
    this.totalErrors = 0,
    this.totalCorrectAnswers = 0,
    this.totalQuestionsAnswered = 0,
  });

  static const empty = DashboardStats(
    streak: 0,
    totalQuizzesTaken: 0,
    averageScore: 0.0,
    progressPercentage: 0.0,
    xp: 0,
    level: 1,
    completedChapters: 0,
    longestStreak: 0,
    totalErrors: 0,
    totalCorrectAnswers: 0,
    totalQuestionsAnswered: 0,
  );
}

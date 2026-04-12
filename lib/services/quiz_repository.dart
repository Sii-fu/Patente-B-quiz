import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question.dart';
import '../models/quiz_session.dart';
import '../utils/retry_helper.dart';

/// Repository for fetching quiz questions (online-only)
/// All data is fetched directly from Supabase
class QuizRepository {
  final SupabaseClient _supabase;

  QuizRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  // ====== MAIN FETCH METHODS ======

  /// Fetch questions for a specific topic
  Future<List<Question>> getQuestionsForTopic(int topicId) async {
    return await RetryHelper.execute(
      operation: () async {
        // First, get all subtopics for this topic
        final subtopicsResponse = await _supabase
            .from('subtopics')
            .select('id')
            .eq('topic_id', topicId);

        final subtopicData = List<Map<String, dynamic>>.from(subtopicsResponse);
        final subtopicIds = subtopicData.map((s) => s['id'] as int).toList();

        if (subtopicIds.isEmpty) {
          return <Question>[];
        }

        // Then fetch questions for these subtopics
        final questionsResponse = await _supabase
            .from('questions')
            .select()
            .inFilter('subtopic_id', subtopicIds);

        final data = List<Map<String, dynamic>>.from(questionsResponse);
        return data.map((json) => Question.fromJson(json)).toList();
      },
      maxAttempts: 3,
    );
  }

  /// Fetch questions for a specific subtopic
  Future<List<Question>> getQuestionsForSubtopic(int subtopicId) async {
    return await RetryHelper.execute(
      operation: () async {
        final response = await _supabase
            .from('questions')
            .select()
            .eq('subtopic_id', subtopicId);

        final data = List<Map<String, dynamic>>.from(response);
        return data.map((json) => Question.fromJson(json)).toList();
      },
      maxAttempts: 3,
    );
  }

  /// Get random questions for exam mode (30 questions)
  Future<List<Question>> getRandomQuestions({int count = 30}) async {
    final response = await _supabase
        .from('questions')
        .select()
        .limit(count * 2); // Fetch more for better randomization
    
    final data = List<Map<String, dynamic>>.from(response);
    data.shuffle(); // Shuffle in Dart for randomness
    return data.take(count).map((json) => Question.fromJson(json)).toList();
  }

  /// Get all questions
  Future<List<Question>> getAllQuestions() async {
    final response = await _supabase.from('questions').select();
    final data = List<Map<String, dynamic>>.from(response);
    return data.map((json) => Question.fromJson(json)).toList();
  }

  // ====== CATEGORIES AND TOPICS ======

  /// Get all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _supabase
        .from('categories')
        .select()
        .order('display_order', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get topics by category ID
  Future<List<Map<String, dynamic>>> getTopicsByCategory(int categoryId) async {
    final response = await _supabase
        .from('topics')
        .select()
        .eq('category_id', categoryId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get all topics
  Future<List<Map<String, dynamic>>> getAllTopics() async {
    final response = await _supabase.from('theory_chapters').select();
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get subtopics by topic ID
  Future<List<Map<String, dynamic>>> getSubtopicsByTopic(int topicId) async {
    final response = await _supabase
        .from('subtopics')
        .select()
        .eq('topic_id', topicId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get question count for a specific subtopic
  Future<int> getQuestionCountForSubtopic(int subtopicId) async {
    try {
      final response = await _supabase
          .from('questions')
          .select('id')
          .eq('subtopic_id', subtopicId)
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      // Fallback to regular query if count fails
      final response = await _supabase
          .from('questions')
          .select('id')
          .eq('subtopic_id', subtopicId);
      return (response as List).length;
    }
  }

  /// Get question counts for multiple subtopics efficiently
  Future<Map<int, int>> getQuestionCountsForSubtopics(List<int> subtopicIds) async {
    if (subtopicIds.isEmpty) return {};
    
    final counts = <int, int>{};
    await Future.wait(
      subtopicIds.map((id) async {
        counts[id] = await getQuestionCountForSubtopic(id);
      })
    );
    return counts;
  }

  /// Get questions for multiple subtopics (batch query)
  Future<List<Question>> getQuestionsForSubtopics(List<int> subtopicIds) async {
    if (subtopicIds.isEmpty) return [];
    
    final response = await _supabase
        .from('questions')
        .select()
        .inFilter('subtopic_id', subtopicIds);
    
    final data = List<Map<String, dynamic>>.from(response);
    return data.map((json) => Question.fromJson(json)).toList();
  }

  // ====== QUIZ RESULT SUBMISSION ======

  /// Submit quiz result to Supabase
  Future<SubmissionResult> submitQuizResult(
    QuizSession session,
    List<QuizAnswer> answers,
  ) async {
    try {
      // Insert quiz session first
      await _supabase.from('quiz_sessions').insert(session.toJson());

      // Insert all answers
      if (answers.isNotEmpty) {
        await _supabase.from('quiz_answers').insert(
              answers.map((a) => a.toJson()).toList(),
            );
      }

      return SubmissionResult(
        success: true,
        status: SubmissionStatus.submitted,
        message: 'Quiz result submitted successfully!',
      );
    } catch (e) {
      return SubmissionResult(
        success: false,
        status: SubmissionStatus.failed,
        message: 'Failed to submit quiz result: ${e.toString()}',
        error: e,
      );
    }
  }

  // ====== STATISTICS ======

  /// Get statistics about available questions
  Future<QuestionStats> getQuestionStats() async {
    final response = await _supabase
        .from('questions')
        .select('id');

    final data = List<Map<String, dynamic>>.from(response);
    return QuestionStats(totalQuestions: data.length);
  }
}

// ====== MODELS ======

class QuestionStats {
  final int totalQuestions;

  QuestionStats({required this.totalQuestions});

  @override
  String toString() => '$totalQuestions questions from Supabase';
}

enum SubmissionStatus {
  submitted,
  failed,
}

class SubmissionResult {
  final bool success;
  final SubmissionStatus status;
  final String message;
  final Object? error;

  SubmissionResult({
    required this.success,
    required this.status,
    required this.message,
    this.error,
  });

  bool get isOnline => status == SubmissionStatus.submitted;
  bool get hasFailed => status == SubmissionStatus.failed;
}

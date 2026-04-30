import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/homework_set.dart';
import '../models/homework_score.dart';
import '../models/question.dart';
import '../models/theory_card.dart';
import '../models/theory_chapter.dart';

class HomeworkRepository {
  HomeworkRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<List<HomeworkSet>> getHomeworkSets() async {
    try {
      final response = await _supabase
          .from('homework_sets')
          .select()
          .order('created_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(response);
      return rows.map(HomeworkSet.fromJson).toList();
    } catch (e) {
      debugPrint('Error fetching homework sets: $e');
      return [];
    }
  }

  Future<HomeworkSet?> getHomeworkSetById(String homeworkSetId) async {
    try {
      final response = await _supabase
          .from('homework_sets')
          .select()
          .eq('id', homeworkSetId)
          .single();
      return HomeworkSet.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      debugPrint('Error fetching homework set by id: $e');
      return null;
    }
  }

  Future<List<HomeworkScore>> getHomeworkScores(String homeworkSetId) async {
    try {
      final response = await _supabase
          .from('homework_scores')
          .select()
          .eq('homework_id', homeworkSetId)
          .order('submitted_at', ascending: false);
      final rows = List<Map<String, dynamic>>.from(response);
      return rows.map(HomeworkScore.fromJson).toList();
    } catch (e) {
      debugPrint('Error fetching homework scores: $e');
      return [];
    }
  }

  Future<List<HomeworkSet>> getPublishedHomeworkSets() async {
    try {
      final response = await _supabase
          .from('homework_sets')
          .select()
          .inFilter('status', const ['scheduled', 'active', 'completed'])
          .order('start_at', ascending: true)
          .order('created_at', ascending: false);
      final rows = List<Map<String, dynamic>>.from(response);
      return rows.map(HomeworkSet.fromJson).toList();
    } catch (e) {
      debugPrint('Error fetching published homeworks: $e');
      return [];
    }
  }

  Future<Map<String, HomeworkScore>> getCurrentUserHomeworkScoreMap({
    List<String>? homeworkIds,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return <String, HomeworkScore>{};

    try {
      var query = _supabase.from('homework_scores').select().eq('user_id', userId);
      if (homeworkIds != null && homeworkIds.isNotEmpty) {
        query = query.inFilter('homework_id', homeworkIds);
      }
      final response = await query.order('submitted_at', ascending: false);
      final rows = List<Map<String, dynamic>>.from(response);
      final scores = rows.map(HomeworkScore.fromJson).toList();

      final result = <String, HomeworkScore>{};
      for (final score in scores) {
        result.putIfAbsent(score.homeworkSetId, () => score);
      }
      return result;
    } catch (e) {
      debugPrint('Error fetching user homework score map: $e');
      return <String, HomeworkScore>{};
    }
  }

  Future<HomeworkScore?> getCurrentUserHomeworkScore(String homeworkId) async {
    final map = await getCurrentUserHomeworkScoreMap(homeworkIds: <String>[homeworkId]);
    return map[homeworkId];
  }

  Future<List<HomeworkScore>> getHomeworkLeaderboard(
    String homeworkId, {
    int limit = 100,
  }) async {
    try {
      final response = await _supabase
          .from('homework_scores')
          .select('*, profiles(full_name, username, avatar_url)')
          .eq('homework_id', homeworkId)
          .order('score', ascending: false)
          .order('time_taken_seconds', ascending: true)
          .limit(limit);
      final rows = List<Map<String, dynamic>>.from(response);
      return rows.map(HomeworkScore.fromJson).toList();
    } catch (e) {
      debugPrint('Error fetching homework leaderboard: $e');
      return [];
    }
  }

  Future<int?> getCurrentUserRank({
    required String homeworkId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('homework_scores')
          .select('user_id')
          .eq('homework_id', homeworkId)
          .order('score', ascending: false)
          .order('time_taken_seconds', ascending: true)
          .range(0, 4999);
      final rows = List<Map<String, dynamic>>.from(response);
      for (var i = 0; i < rows.length; i++) {
        if ((rows[i]['user_id']).toString() == userId) {
          return i + 1;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching current user rank: $e');
      return null;
    }
  }

  Future<List<Question>> getHomeworkQuestions(String homeworkSetId) async {
    try {
      final links = await _supabase
          .from('homework_questions')
          .select('question_id, order_index')
          .eq('homework_id', homeworkSetId)
          .order('order_index', ascending: true)
          .order('id', ascending: true);
      final linkRows = List<Map<String, dynamic>>.from(links);
      final questionIds = linkRows
          .map((row) => row['question_id'] as int?)
          .whereType<int>()
          .toList();
      if (questionIds.isEmpty) return [];

      final response = await _supabase
          .from('questions')
          .select()
          .inFilter('id', questionIds);
      final rows = List<Map<String, dynamic>>.from(response);
      final questions = rows.map(Question.fromJson).toList();
      final questionOrder = <int, int>{};
      for (var i = 0; i < questionIds.length; i++) {
        questionOrder[questionIds[i]] = i;
      }
      questions.sort((a, b) {
        final aIndex = questionOrder[a.id] ?? 1 << 30;
        final bIndex = questionOrder[b.id] ?? 1 << 30;
        return aIndex.compareTo(bIndex);
      });
      return questions;
    } catch (e) {
      debugPrint('Error fetching homework questions: $e');
      return [];
    }
  }

  Future<List<Question>> getPreparedHomeworkQuestions(HomeworkSet homework) async {
    final questions = await getHomeworkQuestions(homework.id);
    if (questions.isEmpty) return questions;

    final prepared = List<Question>.from(questions);
    if (homework.shuffleQuestions) {
      prepared.shuffle();
    }
    return prepared;
  }

  Future<HomeworkAttemptResult> submitHomeworkAttempt({
    required HomeworkSet homework,
    required List<Question> questions,
    required Map<int, bool> userAnswers,
    required int durationSeconds,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated.');
    }

    int wrongCount = 0;
    int correctCount = 0;
    int unansweredCount = 0;

    final List<Map<String, dynamic>> answersData = [];
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final selected = userAnswers[i];
      final isUnanswered = selected == null;
      final isCorrect = selected != null && selected == question.isTrue;

      if (isUnanswered) {
        unansweredCount++;
      } else if (isCorrect) {
        correctCount++;
      } else {
        wrongCount++;
      }

      answersData.add({
        'user_id': userId,
        'question_id': question.id,
        'selected_true': selected ?? false,
        'is_correct': isCorrect,
      });
    }

    final totalErrors = wrongCount + unansweredCount;
    final isPassed = totalErrors <= 4;
    final score = questions.isEmpty ? 0.0 : (correctCount / questions.length) * 100.0;

    final sessionInsert = await _supabase
        .from('quiz_sessions')
        .insert({
          'user_id': userId,
          'mode': 'simulation',
          'total_questions': questions.length,
          'errors_count': totalErrors,
          'is_passed': isPassed,
          'duration_seconds': durationSeconds,
        })
        .select('id')
        .single();

    final sessionId = (sessionInsert['id']).toString();
    for (final row in answersData) {
      row['session_id'] = sessionId;
    }
    if (answersData.isNotEmpty) {
      await _supabase.from('quiz_answers').insert(answersData);
    }

    try {
      await _supabase.from('homework_scores').upsert(
        {
          'homework_id': homework.id,
          'user_id': userId,
          'session_id': sessionId,
          'score': double.parse(score.toStringAsFixed(2)),
          'correct_count': correctCount,
          'wrong_count': wrongCount,
          'unanswered_count': unansweredCount,
          'time_taken_seconds': durationSeconds,
          'submitted_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'homework_id,user_id',
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw Exception(
          'Retry submission is blocked by homework_scores RLS update policy.',
        );
      }
      rethrow;
    }

    return HomeworkAttemptResult(
      homeworkId: homework.id,
      sessionId: sessionId,
      correctCount: correctCount,
      wrongCount: wrongCount,
      unansweredCount: unansweredCount,
      totalQuestions: questions.length,
      score: score,
      durationSeconds: durationSeconds,
      submittedAt: DateTime.now(),
    );
  }

  Future<String?> createHomework({
    required String title,
    String? description,
    required int timeLimitMinutes,
    DateTime? startsAt,
    DateTime? endsAt,
    required bool shuffleQuestions,
    required bool retryAllowed,
    bool isDraft = false,
    required List<int> questionIds,
  }) async {
    if (questionIds.isEmpty) {
      throw Exception('Cannot create homework without questions.');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated.');
    }

    final setPayload = {
      'title': title,
      'description': description,
      'question_count': questionIds.length,
      'time_limit_minutes': timeLimitMinutes,
      'start_at': startsAt?.toIso8601String(),
      'end_at': endsAt?.toIso8601String(),
      'shuffle_questions': shuffleQuestions,
      'shuffle_answers': false,
      'retry_allowed': retryAllowed,
      'status': _resolveStatus(
        isDraft: isDraft,
        startsAt: startsAt,
        endsAt: endsAt,
      ),
      'created_by': userId,
    };

    final insertedSet = await _supabase
        .from('homework_sets')
        .insert(setPayload)
        .select('id')
        .single();

    final homeworkSetId = (insertedSet['id']).toString();
    final linkPayload = questionIds.asMap().entries.map((entry) {
      return {
        'homework_id': homeworkSetId,
        'question_id': entry.value,
        'order_index': entry.key,
      };
    }).toList();

    await _supabase.from('homework_questions').insert(linkPayload);
    return homeworkSetId;
  }

  Future<bool> updateHomework({
    required String homeworkSetId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    DateTime? startsAt,
    DateTime? endsAt,
    required bool shuffleQuestions,
    required bool retryAllowed,
    bool isDraft = false,
    required List<int> questionIds,
  }) async {
    if (questionIds.isEmpty) {
      throw Exception('Cannot save homework without questions.');
    }

    final payload = {
      'title': title,
      'description': description,
      'question_count': questionIds.length,
      'time_limit_minutes': timeLimitMinutes,
      'start_at': startsAt?.toIso8601String(),
      'end_at': endsAt?.toIso8601String(),
      'shuffle_questions': shuffleQuestions,
      'shuffle_answers': false,
      'retry_allowed': retryAllowed,
      'status': _resolveStatus(
        isDraft: isDraft,
        startsAt: startsAt,
        endsAt: endsAt,
      ),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('homework_sets').update(payload).eq('id', homeworkSetId);
    await _supabase
        .from('homework_questions')
        .delete()
        .eq('homework_id', homeworkSetId);
    await _supabase.from('homework_questions').insert(questionIds
        .asMap()
        .entries
        .map(
          (entry) => {
            'homework_id': homeworkSetId,
            'question_id': entry.value,
            'order_index': entry.key,
          },
        )
        .toList());
    return true;
  }

  Future<bool> deleteHomework(String homeworkSetId) async {
    try {
      await _supabase
          .from('homework_questions')
          .delete()
          .eq('homework_id', homeworkSetId);
      await _supabase
          .from('homework_scores')
          .delete()
          .eq('homework_id', homeworkSetId);
      await _supabase.from('homework_sets').delete().eq('id', homeworkSetId);
      return true;
    } catch (e) {
      debugPrint('Error deleting homework: $e');
      return false;
    }
  }

  Future<List<TheoryChapter>> getTheoryChapters() async {
    final response = await _supabase
        .from('theory_chapters')
        .select()
        .order('id', ascending: true);
    final rows = List<Map<String, dynamic>>.from(response);
    return rows.map(TheoryChapter.fromJson).toList();
  }

  Future<List<TheoryCard>> getTheoryCardsByChapter(int chapterId) async {
    final response = await _supabase
        .from('theory_cards')
        .select()
        .eq('chapter_id', chapterId)
        .order('id', ascending: true);
    final rows = List<Map<String, dynamic>>.from(response);
    return rows.map(TheoryCard.fromJson).toList();
  }

  Future<List<Question>> getQuestionsByTheoryCard(int theoryCardId) async {
    final card = await _supabase
        .from('theory_cards')
        .select('subtopic_id')
        .eq('id', theoryCardId)
        .single();
    final subtopicId = card['subtopic_id'] as int?;
    if (subtopicId == null) return [];

    final response = await _supabase
        .from('questions')
        .select()
        .eq('subtopic_id', subtopicId)
        .order('id', ascending: true);
    final rows = List<Map<String, dynamic>>.from(response);
    return rows.map(Question.fromJson).toList();
  }

  Future<List<Question>> getQuestionsBySubtopicPaged({
    required int subtopicId,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _supabase
        .from('questions')
        .select()
        .eq('subtopic_id', subtopicId);

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or(
        'text_it.ilike.%$q%,text_en.ilike.%$q%,text_bn.ilike.%$q%',
      );
    }

    final response = await query
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);
    final rows = List<Map<String, dynamic>>.from(response);
    return rows.map(Question.fromJson).toList();
  }

  Future<List<Question>> getRandomQuestionsToFill({
    required List<int> selectedQuestionIds,
    required int targetCount,
  }) async {
    if (targetCount <= selectedQuestionIds.length) return [];
    final needed = targetCount - selectedQuestionIds.length;

    // Pull a larger randomizable pool and shuffle client-side.
    final response = await _supabase.from('questions').select().limit(needed * 8);
    final rows = List<Map<String, dynamic>>.from(response);
    rows.shuffle();

    final excluded = selectedQuestionIds.toSet();
    final picked = <Question>[];
    for (final row in rows) {
      final q = Question.fromJson(row);
      if (!excluded.contains(q.id)) {
        picked.add(q);
      }
      if (picked.length >= needed) break;
    }
    return picked;
  }

  Future<List<HomeworkSet>> getHomeworkSetsByLifecycle(
    HomeworkLifecycle lifecycle,
  ) async {
    final all = await getHomeworkSets();
    final result = all.where((h) => h.lifecycle == lifecycle).toList();
    if (lifecycle == HomeworkLifecycle.active ||
        lifecycle == HomeworkLifecycle.upcoming ||
        lifecycle == HomeworkLifecycle.completed) {
      result.sort((a, b) {
        final aTime = a.startsAt ?? a.createdAt;
        final bTime = b.startsAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
    }
    return result;
  }

  Future<int> getSubmissionCount(String homeworkSetId) async {
    try {
      final response = await _supabase
          .from('homework_scores')
          .select('id')
          .eq('homework_id', homeworkSetId)
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      debugPrint('Error fetching submission count: $e');
      return 0;
    }
  }

  Future<HomeworkSet> enrichHomeworkStats(HomeworkSet set) async {
    final submissionCount = await getSubmissionCount(set.id);
    return HomeworkSet(
      id: set.id,
      title: set.title,
      description: set.description,
      timeLimitMinutes: set.timeLimitMinutes,
      startsAt: set.startsAt,
      endsAt: set.endsAt,
      shuffleQuestions: set.shuffleQuestions,
      retryAllowed: set.retryAllowed,
      status: set.status,
      isDraft: set.isDraft,
      createdBy: set.createdBy,
      createdAt: set.createdAt,
      questionCount: set.questionCount,
      submissionCount: submissionCount,
    );
  }

  String _resolveStatus({
    required bool isDraft,
    DateTime? startsAt,
    DateTime? endsAt,
  }) {
    if (isDraft) return 'draft';

    final now = DateTime.now().toUtc();
    final start = startsAt?.toUtc();
    final end = endsAt?.toUtc();

    if (start != null && start.isAfter(now)) {
      return 'scheduled';
    }
    if (end != null && end.isBefore(now)) {
      return 'completed';
    }
    return 'active';
  }
}

class HomeworkAttemptResult {
  const HomeworkAttemptResult({
    required this.homeworkId,
    required this.sessionId,
    required this.correctCount,
    required this.wrongCount,
    required this.unansweredCount,
    required this.totalQuestions,
    required this.score,
    required this.durationSeconds,
    required this.submittedAt,
  });

  final String homeworkId;
  final String sessionId;
  final int correctCount;
  final int wrongCount;
  final int unansweredCount;
  final int totalQuestions;
  final double score;
  final int durationSeconds;
  final DateTime submittedAt;
}
